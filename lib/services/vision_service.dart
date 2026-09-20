import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import 'frame_converter.dart';
import 'obstacle_interpreter.dart';
import 'obstacle_vocabulary.dart';

// DetectionResult moved to obstacle_interpreter.dart along with the logic
// that builds it. Re-exported so callers keep importing it from here.
export 'obstacle_interpreter.dart' show DetectionResult, RawDetection;

/// Vision service backed by YOLO26 nano.
///
/// The camera stays owned by the `camera` plugin rather than by the plugin's
/// own `YOLOView`, because the preview is also the source for OCR, photo
/// capture and the torch, none of which `YOLOView` exposes. Frames are pulled
/// off the stream, converted on a background isolate and handed to the
/// detector.
class VisionService {
  static final VisionService _instance = VisionService._internal();
  factory VisionService() => _instance;
  VisionService._internal();

  /// Bundled model, preferred so detection works with no network.
  static const String _assetModelPath = 'assets/models/yolo26n.tflite';

  /// Official model id. The plugin downloads it once and caches it on device.
  /// Used only when the bundled asset is absent.
  static const String _officialModelId = 'yolo26n';

  CameraController? _cameraController;
  YOLO? _detector;

  bool _isInitialized = false;
  bool _isModelReady = false;
  bool _isProcessing = false;
  bool _isDetectionActive = false;
  bool _isCameraEnabled = true;
  bool _isFlashlightOn = false;
  bool _isLowLight = false;

  /// Where the model was actually loaded from, for diagnostics.
  String? _loadedModelSource;

  // Detection state
  final ObstacleInterpreter _interpreter = ObstacleInterpreter();
  List<DetectionResult> _currentDetections = [];
  DateTime? _lastDetectionRun;
  DateTime? _lastLightCheck;

  /// Normal sampling rate. Deliberately slow - most of the time the scene is
  /// static and every extra inference is battery.
  static const Duration _detectionInterval = Duration(milliseconds: 1200);

  /// Used while a hazard is in view. Approach is measured between
  /// consecutive readings, so at the idle rate a car needs 2.4s of being
  /// visible before it can be called as closing, which is too slow for
  /// traffic. The cost is only paid when there is something to track.
  static const Duration _alertInterval = Duration(milliseconds: 500);

  /// Whether the last reading contained anything worth tracking closely.
  bool _trackingHazard = false;

  String _lastAnnouncedDescription = '';

  /// When the in-flight frame started, so a hung one can be abandoned
  /// instead of holding [_isProcessing] shut forever.
  DateTime? _processingSince;
  static const Duration _processingTimeout = Duration(seconds: 10);

  /// Detections below this are dropped. YOLO26 is confident enough that a
  /// higher floor than the 0.25 default keeps chatter down.
  static const double _confidenceThreshold = 0.40;
  static const double _iouThreshold = 0.5;

  // Proximity alert state
  Timer? _blinkTimer;
  bool _isBlinking = false;
  bool _isProximityAlertActive = false;

  // Settings
  bool useMock = false;

  // Callbacks
  void Function(List<DetectionResult> detections, String description)?
      onObstacleDetected;
  void Function(CameraController controller)? onCameraReady;
  void Function(bool enabled)? onCameraToggled;
  void Function(bool on)? onFlashlightChanged;

  // Public getters
  List<DetectionResult> get currentDetections => _currentDetections;
  CameraController? get cameraController => _cameraController;
  bool get isCameraEnabled => _isCameraEnabled;
  bool get isInitialized => _isInitialized;
  bool get isModelReady => _isModelReady;
  bool get isFlashlightOn => _isFlashlightOn;
  String? get loadedModelSource => _loadedModelSource;

  // ---------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
        // Detection only consumes one frame every _detectionInterval (1.2s);
        // without this the camera still hands every sensor frame (~30fps) to
        // Dart just to be discarded, which is pure marshalling cost for
        // battery and UI-thread jank. 15fps keeps the preview smooth while
        // roughly halving that waste.
        fps: 15,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);

      onCameraReady?.call(_cameraController!);

      _isInitialized = true;

      // Model loading is slow and must not hold up the preview: the camera is
      // useful for OCR and capture even before the detector is ready.
      unawaited(_loadModel());

      debugPrint('Vision service initialized');
      return true;
    } catch (e) {
      debugPrint('Vision initialization error: $e');
      return false;
    }
  }

  /// Loads YOLO26n, preferring the bundled asset and falling back to the
  /// plugin's cached download.
  Future<void> _loadModel() async {
    if (_isModelReady) return;

    for (final source in [_assetModelPath, _officialModelId]) {
      try {
        final detector = YOLO(modelPath: source, task: YOLOTask.detect);
        final loaded = await detector.loadModel();
        if (loaded) {
          _detector = detector;
          _isModelReady = true;
          _loadedModelSource = source;
          debugPrint('YOLO26n loaded from $source');
          return;
        }
        debugPrint('YOLO26n did not load from $source');
      } catch (e) {
        debugPrint('YOLO26n load failed from $source: $e');
      }
    }

    debugPrint(
      'YOLO26n unavailable. Obstacle detection is disabled; '
      'the rest of the app still works.',
    );
  }

  Future<void> startDetection() async {
    if (!_isCameraEnabled) return;

    if (!_isInitialized || _cameraController == null) await initialize();
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_isDetectionActive) return;
    _isDetectionActive = true;

    try {
      if (!_cameraController!.value.isStreamingImages) {
        await _cameraController!.startImageStream(_processFrame);
        debugPrint('Detection started');
      }
    } catch (e) {
      debugPrint('Error starting stream: $e');
      _isDetectionActive = false;
    }
  }

  Future<void> stopDetection() async {
    _isDetectionActive = false;
    try {
      if (_cameraController != null &&
          _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    } catch (e) {
      debugPrint('Error stopping stream: $e');
    }
  }

  /// Releases the camera when the app leaves the foreground.
  ///
  /// Android reclaims the camera from a backgrounded app whether or not we
  /// let go of it, which leaves [_cameraController] pointing at a dead
  /// session. Holding on to it was the cause of detection working exactly
  /// once per process: on resume, [startDetection] saw `_isInitialized`
  /// still true, skipped re-initialising, and called `startImageStream` on
  /// the dead controller. That throws, the throw was logged and swallowed,
  /// and obstacle detection was silently finished for the rest of the run.
  ///
  /// The model is deliberately kept loaded - it is slow to load and
  /// unaffected by the camera going away.
  Future<void> handleAppPaused() async {
    await stopDetection();
    await _releaseCamera();
  }

  /// Rebuilds the camera after [handleAppPaused] and starts detecting again.
  Future<void> handleAppResumed() async {
    if (!_isCameraEnabled) return;

    final ready = await initialize();
    if (!ready) {
      debugPrint('Camera did not come back after resume');
      return;
    }
    await startDetection();
  }

  /// Tears down the camera only, leaving the loaded model alone.
  Future<void> _releaseCamera() async {
    _stopBlinking();
    try {
      await _cameraController?.dispose();
    } catch (e) {
      debugPrint('Error disposing camera: $e');
    }
    _cameraController = null;
    _isInitialized = false;

    // A frame that was mid-flight when the camera went away never reaches
    // its `finally`, and a stuck `_isProcessing` wedges the pipeline shut.
    _isProcessing = false;
    _processingSince = null;

    // Sizes measured before the gap say nothing about motion after it.
    _interpreter.reset();
    _trackingHazard = false;
    _lastAnnouncedDescription = '';
  }

  Future<void> dispose() async {
    await stopDetection();
    await _releaseCamera();
    _detector = null;
    _isModelReady = false;
  }

  // ---------------------------------------------------------------------
  // Frame pipeline
  // ---------------------------------------------------------------------

  void _processFrame(CameraImage image) async {
    final now = DateTime.now();
    final interval = _trackingHazard ? _alertInterval : _detectionInterval;
    if (_lastDetectionRun != null &&
        now.difference(_lastDetectionRun!) < interval) {
      return;
    }
    if (!_isModelReady || _detector == null) return;

    if (_isProcessing) {
      // A frame whose isolate hop or inference never came back would
      // otherwise hold this flag forever and stop detection dead with no
      // error anywhere. Nothing here legitimately takes this long.
      final since = _processingSince;
      if (since == null || now.difference(since) < _processingTimeout) return;
      debugPrint('Frame processing wedged; recovering');
    }

    _isProcessing = true;
    _processingSince = now;
    _lastDetectionRun = now;

    try {
      _checkLowLight(image);

      final payload = FramePayload.fromCameraImage(
        image,
        rotationDegrees: _sensorRotationDegrees(),
      );
      if (payload == null) return;

      final jpeg = await encodeFrameForDetection(payload);
      if (jpeg == null || jpeg.isEmpty) return;

      final detections = await _runDetector(jpeg);
      _publishReading(_interpreter.interpret(
        detections.map(_toRawDetection).toList(growable: false),
        now: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Frame processing error: $e');
    } finally {
      _isProcessing = false;
      _processingSince = null;
    }
  }

  static RawDetection _toRawDetection(YOLOResult result) => RawDetection(
        className: result.className,
        confidence: result.confidence,
        box: result.normalizedBox,
      );

  Future<List<YOLOResult>> _runDetector(Uint8List jpeg) async {
    final raw = await _detector!.predict(
      jpeg,
      confidenceThreshold: _confidenceThreshold,
      iouThreshold: _iouThreshold,
    );

    final detections = raw['detections'];
    if (detections is! List) return const [];

    final results = <YOLOResult>[];
    for (final entry in detections) {
      if (entry is Map) {
        try {
          results.add(YOLOResult.fromMap(entry));
        } catch (e) {
          debugPrint('Skipping malformed detection: $e');
        }
      }
    }
    return results;
  }

  /// Rotation needed to present the frame upright to the detector.
  int _sensorRotationDegrees() {
    final controller = _cameraController;
    if (controller == null) return 0;
    if (defaultTargetPlatform == TargetPlatform.iOS) return 0;
    return controller.description.sensorOrientation % 360;
  }

  // ---------------------------------------------------------------------
  // Interpretation
  // ---------------------------------------------------------------------

  /// Pushes a fresh reading out to the UI.
  ///
  /// Scoring, filtering and phrasing all live in [ObstacleInterpreter] -
  /// that logic is pure and worth testing, and none of it needs a camera.
  void _publishReading(ObstacleReading reading) {
    _triggerProximityAlert(reading.dangerousProximity);
    _currentDetections = reading.detections;

    // Keep sampling quickly while anything that can move is in view.
    _trackingHazard = reading.detections.any(
      (d) => d.priority == ObstaclePriority.hazard || d.isApproaching,
    );

    // Do not repeat "path clear" every cycle.
    if (reading.description == ObstacleVocabulary.pathClear &&
        _lastAnnouncedDescription == ObstacleVocabulary.pathClear) {
      return;
    }

    _lastAnnouncedDescription = reading.description;
    onObstacleDetected?.call(reading.detections, reading.description);
  }

  /// Get current scene description
  String getCurrentSceneDescription() {
    if (_lastAnnouncedDescription.isEmpty) {
      return _isModelReady ? 'Processing scene...' : 'Obstacle detection warming up';
    }
    return _lastAnnouncedDescription;
  }

  // ---------------------------------------------------------------------
  // Camera controls
  // ---------------------------------------------------------------------

  Future<void> toggleCamera() async {
    _isCameraEnabled = !_isCameraEnabled;
    if (_isCameraEnabled) {
      await startDetection();
    } else {
      await stopDetection();
    }
    onCameraToggled?.call(_isCameraEnabled);
  }

  Future<void> enableCamera() async {
    if (!_isCameraEnabled) {
      _isCameraEnabled = true;
      await startDetection();
      onCameraToggled?.call(true);
    }
  }

  Future<void> disableCamera() async {
    if (_isCameraEnabled) {
      _isCameraEnabled = false;
      await stopDetection();
      onCameraToggled?.call(false);
    }
  }

  /// Set Manual Flashlight
  Future<void> setFlashlight(bool on) async {
    _isFlashlightOn = on;
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      if (!_isProximityAlertActive) {
        try {
          await _cameraController!
              .setFlashMode(on ? FlashMode.torch : FlashMode.off);
        } catch (e) {
          debugPrint('Error setting flash: $e');
        }
      }
    }
    onFlashlightChanged?.call(on);
  }

  void _triggerProximityAlert(bool active) {
    if (_isProximityAlertActive == active) return;
    _isProximityAlertActive = active;

    if (active) {
      _startBlinking();
    } else {
      _stopBlinking();
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        _cameraController!.setFlashMode(
          (_isFlashlightOn || _isLowLight) ? FlashMode.torch : FlashMode.off,
        );
      }
    }
  }

  void _startBlinking() {
    _blinkTimer?.cancel();
    // 500ms rather than 250ms: the torch is a signal to people nearby, and
    // toggling flash modes twice a second already pushes the camera HAL hard.
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }
      _isBlinking = !_isBlinking;
      _cameraController!
          .setFlashMode(_isBlinking ? FlashMode.torch : FlashMode.off);
      if (_isBlinking) HapticFeedback.heavyImpact();
    });
  }

  void _stopBlinking() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _isBlinking = false;
  }

  /// Check for low light conditions
  void _checkLowLight(CameraImage image) {
    final now = DateTime.now();
    if (_lastLightCheck != null &&
        now.difference(_lastLightCheck!) < const Duration(seconds: 2)) {
      return;
    }
    _lastLightCheck = now;

    final yPlane = image.planes[0];
    if (yPlane.bytes.isEmpty) return;

    var total = 0;
    const step = 100;
    var samples = 0;
    for (var i = 0; i < yPlane.bytes.length; i += step) {
      total += yPlane.bytes[i];
      samples++;
    }
    if (samples == 0) return;

    final average = total / samples;
    final low = average < 40;

    if (low != _isLowLight) {
      _isLowLight = low;
      if (!_isFlashlightOn && !_isProximityAlertActive) {
        _cameraController?.setFlashMode(low ? FlashMode.torch : FlashMode.off);
      }
      debugPrint('Light level: ${average.toStringAsFixed(1)} (low: $low)');
    }
  }
}
