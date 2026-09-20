import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/tts_service.dart';
import '../services/haptic_service.dart';
import '../services/location_service.dart';
import '../services/sensor_service.dart';
import '../services/navigation_service.dart';
import '../services/gemini_service.dart';
import '../services/vision_service.dart';
import '../services/voice_command_service.dart';
import '../services/sos_service.dart';
import '../services/settings_service.dart';
import 'package:gabn2/l10n/app_localizations.dart';
import '../services/ocr_service.dart';
import '../services/gesture_service.dart';
import '../services/battery_service.dart';
import '../services/saved_locations_service.dart';
import 'settings_screen.dart';
import 'tutorial_screen.dart';
import 'voice_command_dialog.dart';
import 'map_screen.dart'; // Add MapScreen import
import 'emergency_contacts_dialog.dart';
import 'sos_overlay.dart';
import 'sos_result_dialog.dart';
import 'widgets/camera_preview_layer.dart';
import 'widgets/home_control_bar.dart';
import 'widgets/status_banner.dart';
import 'dart:io';
import 'dart:async';

/// Main home screen with accessibility-first design
/// Live camera with obstacle detection, navigation, and SOS features
class HomeScreen extends StatefulWidget {
  final String? mapsApiKey;
  final String? geminiApiKey;
  final String? geminiModel;

  const HomeScreen({
    super.key,
    this.mapsApiKey,
    this.geminiApiKey,
    this.geminiModel,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Services
  final TtsService _tts = TtsService();
  final HapticService _haptic = HapticService();
  final LocationService _location = LocationService();
  final SensorService _sensor = SensorService();
  final NavigationService _navigation = NavigationService();
  final GeminiService _gemini = GeminiService();
  final VisionService _vision = VisionService();
  final VoiceCommandService _voice = VoiceCommandService();
  final SosService _sos = SosService();
  final SettingsService _settings = SettingsService();
  final OcrService _ocr = OcrService();
  final GestureService _gesture = GestureService();
  final BatteryService _battery = BatteryService();
  final SavedLocationsService _savedLocations = SavedLocationsService();

  // State
  bool _isInitialized = false;
  bool _isNavigating = false;
  bool _isMockMode = false;
  String _statusText = ''; // Will be initialized in didChangeDependencies
  String _currentInstruction = '';
  String _sceneDescription = '';
  bool _orientationWarningShown = false;
  final TextEditingController _destinationController = TextEditingController();
  Timer? _autoCloseTimer;

  // Camera
  CameraController? _cameraController;
  
  // Photo capture
  bool _isCapturingPhoto = false;
  
  /// Cached localizations. Resolved once in didChangeDependencies so async
  /// methods never reach for an InheritedWidget across an await - doing so
  /// throws if the widget has been disposed in the meantime.
  late AppLocalizations _l10n;
  bool _initStarted = false;

  // Triple tap detection for voice commands
  DateTime? _lastTapTime;
  int _tapCount = 0;
  static const Duration _tripleTapWindow = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Needed so the full-screen cancel zone appears the moment a countdown
    // starts - without this the build below never re-runs on SOS state change.
    _sos.addListener(_onSosStateChanged);
    // _initializeApp runs from didChangeDependencies instead: it needs
    // localizations, which are not available during initState.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sos.removeListener(_onSosStateChanged);
    _destinationController.dispose();
    _releaseServices();
    super.dispose();
  }

  void _onSosStateChanged() {
    if (mounted) setState(() {});
  }

  /// Points the TTS engine and speech recogniser at the app's locale.
  String? _appliedSpeechLocale;

  void _applySpeechLocale(String languageCode) {
    if (_appliedSpeechLocale == languageCode) return;
    _appliedSpeechLocale = languageCode;

    const ttsLocales = {'en': 'en-US', 'hi': 'hi-IN'};
    _tts.setLanguage(ttsLocales[languageCode] ?? 'en-US');
    _voice.setLocale(languageCode);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera has to be handed back and rebuilt around backgrounding.
    // Android takes it away regardless, and merely stopping the image
    // stream left a dead controller behind that could never stream again -
    // obstacle detection worked exactly once per app launch.
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _vision.handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _vision.handleAppResumed();
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;

    // Keep the spoken output in the same language as the interface. Without
    // this a Hindi user gets a Hindi UI read aloud by an English voice.
    final languageCode = Localizations.localeOf(context).languageCode;
    _applySpeechLocale(languageCode);

    // With TalkBack running, the status banner's live region already speaks
    // the ambient commentary; this stops the app saying it a second time on
    // top. Urgent speech is unaffected - see TtsService.speakAmbient.
    _tts.screenReaderActive = MediaQuery.of(context).accessibleNavigation;

    // SosService has no BuildContext, so its phrases are pushed in from here.
    // These are the most safety-critical strings in the app - the ones that
    // tell the user how to call off an emergency.
    _sos.strings = SosStrings(
      sequenceActivated: _l10n.sosSequenceActivated,
      secondsRemaining: _l10n.sosSecondsRemaining,
      sequenceCancelled: _l10n.sosSequenceCancelled,
      spokenCallMessage: _l10n.sosSpokenCallMessage,
    );

    if (_statusText.isEmpty) {
      _statusText = _l10n.initializing;
    }

    if (!_initStarted) {
      _initStarted = true;
      _initializeApp();
    }
  }

  /// Initialize all services
  Future<void> _initializeApp() async {
    try {
      await _requestPermissions();

      // Initialize core services
      await _tts.initialize();
      await _haptic.initialize();
      await _location.initialize();
      await _sensor.initialize();

      // Initialize API services
      if (widget.mapsApiKey != null && widget.mapsApiKey!.isNotEmpty) {
        _navigation.initialize(widget.mapsApiKey!);
      }
      if (widget.geminiApiKey != null && widget.geminiApiKey!.isNotEmpty) {
        _gemini.initialize(
          widget.geminiApiKey!,
          model: widget.geminiModel ?? GeminiService.defaultModel,
        );
      }

      // Setup sensor callbacks for fall detection and SOS
      _sensor.onFallDetected = _handleFallDetected;
      _sensor.onVigorousShakeDetected = _handleShakeSOS;
      _sensor.onOrientationWarning = _handleOrientationWarning;

      // Initialize vision service with callbacks
      _vision.onCameraReady = (controller) {
        if (mounted) {
          setState(() {
            _cameraController = controller;
          });
          _ocr.setCameraController(controller);
          // Start detection when camera is ready
          _vision.startDetection();
        }
      };
      _vision.onObstacleDetected = _handleObstacleDetected;
      
      // Try to initialize camera (don't block if it fails)
      final visionInitialized = await _vision.initialize();
      if (!visionInitialized) {
        if (mounted) {
          setState(() => _statusText = _l10n.cameraInitFailed);
        }
        await _tts.speak(_l10n.cameraInitFailed);
      } else {
        // Start detection if already initialized
        if (_vision.isInitialized && _vision.cameraController != null) {
          await _vision.startDetection();
        }
      }

      // Initialize voice commands
      await _voice.initialize();
      _setupVoiceCommands();

      // Initialize settings
      await _settings.initialize();
      
      // Sync VisionService with saved settings
      if (!_settings.cameraEnabled) {
        await _vision.disableCamera();
      }

      // Initialize OCR
      await _ocr.initialize();

      // Initialize gesture service
      await _gesture.initialize();
      // A single press is enough to abort a countdown; the multi-press
      // patterns keep their existing meanings otherwise.
      _gesture.onVolumePress = _cancelEmergency;
      _gesture.onVolumeDoublePress = _handleVolumeDoublePress;
      _gesture.onVolumeTriplePress = _handleVolumeTriplePress;

      // Initialize saved locations
      await _savedLocations.initialize();

      // Initialize SOS service
      // No seeded contacts: 112 is the call fallback used when the list is
      // empty, and it cannot receive SMS. Real contacts are loaded from
      // storage and added by the user in settings.
      await _sos.initialize();

      setState(() {
        _isInitialized = true;
        _statusText = _l10n.readyCameraActive;
      });

      await _tts.speak(_l10n.appReadySpeak);
      await _haptic.vibrate();

      // Start obstacle detection immediately
      await _vision.startDetection();

    } catch (e) {
      setState(() => _statusText = 'Error: $e');
      _tts.speak(_l10n.errorStartingApp);
    }
  }

  void _setupVoiceCommands() {
    // Core navigation
    // Checked ahead of every other command, so "cancel" during a countdown
    // stands the emergency down instead of merely stopping navigation.
    _voice.onCancelEmergency = _cancelEmergency;

    // Voice is one of the only two routes into this app for a fully blind
    // user, so every way it can fail has to say so out loud. Silence is
    // indistinguishable from "still listening".
    _voice.onSpeechUnavailable = () => _tts.speak(_l10n.voiceUnavailable);
    _voice.onNothingHeard = () => _tts.speak(_l10n.voiceNothingHeard);

    _voice.onStartNavigation = _startNavigation;
    _voice.onStopNavigation = _stopNavigation;
    _voice.onNextStep = _nextStep;
    _voice.onSOS = _triggerSOS;
    _voice.onHelp = () => _tts.speak(_l10n.voiceHelpList);
    _voice.onRepeat = () {
      if (_currentInstruction.isNotEmpty) {
        _tts.speak(_currentInstruction);
      } else {
        _tts.speak(_vision.getCurrentSceneDescription());
      }
    };
    
    // Time and battery
    _voice.onTime = () {
      _haptic.buttonPress();
      final now = DateTime.now();
      String suffix = now.hour >= 12 ? "PM" : "AM";
      int hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      String minute = now.minute.toString().padLeft(2, '0');
      _tts.speak(_l10n.timeIs(hour.toString(), minute, suffix));
    };
    _voice.onBattery = () async {
      _haptic.buttonPress();
      final batteryLevel = await _battery.getBatteryLevelString();
      _tts.speak(_l10n.batteryLevelIs(batteryLevel));
    };
    
    // Location
    _voice.onLocation = () async {
      _haptic.buttonPress();
      _tts.speak(_l10n.checkingLocation);
      try {
        final loc = await _location.getCurrentLocation();
        if (loc != null) {
          _tts.speak(_l10n.youAreAtCoordinates(loc.latitude.toStringAsFixed(2), loc.longitude.toStringAsFixed(2)));
        } else {
          _tts.speak(_l10n.unableToGetLocation);
        }
      } catch (e) {
        _tts.speak(_l10n.locationError);
      }
    };
    
    // Scene description
    _voice.onDescribeScene = () {
      _haptic.buttonPress();
      _describeScene();
    };
    
    // Obstacle reading
    _voice.onReadObstacles = () {
      _haptic.buttonPress();
      String desc = _vision.getCurrentSceneDescription();
      _tts.speak(desc);
    };

    // Second-stage routing for phrases the service does not have a branch
    // for. Bilingual for the same reason the service's table is: a Hindi
    // speaker's words arrive in Devanagari and matched nothing here either.
    _voice.onUnrecognizedCommand = (command) {
      bool has(List<String> words) => words.any(command.contains);

      if (has(['read text', 'read the text', 'पाठ पढ़', 'पढ़ो', 'लिखा'])) {
        _readTextFromCamera();
      } else if (has(
          ['capture', 'photo', 'picture', 'फ़ोटो', 'फोटो', 'तस्वीर'])) {
        _capturePhotoAndDescribe();
      } else if (has(['settings', 'सेटिंग'])) {
        _openSettings();
      } else if (has(['tutorial', 'how to', 'ट्यूटोरियल', 'कैसे'])) {
        _openTutorial();
      } else if (has(['navigate to', 'go to', 'ले चलो', 'जाना है'])) {
        _handleNavigateToCommand(command);
      } else if (has([
        'save location',
        'save this location',
        'save my location',
        'स्थान सहेज',
        'जगह सहेज',
        'यहाँ सहेज',
      ])) {
        _saveCurrentLocation();
      } else {
        // Nothing matched. Saying so is the whole point - the user has no
        // other way to find out the command did not land.
        _tts.speak(_l10n.voiceNotUnderstood);
      }
    };
    
    // Camera toggle
    _voice.onToggleCamera = () async {
      await _toggleCamera();
    };
    _voice.onCameraEnable = () async {
      await _setCameraState(true);
    };
    _voice.onCameraDisable = () async {
      await _setCameraState(false);
    };

    // Flashlight
    _voice.onFlashlightOn = () async {
      await _vision.setFlashlight(true);
      _tts.speak(_l10n.flashlightOn);
    };
    _voice.onFlashlightOff = () async {
      await _vision.setFlashlight(false);
      _tts.speak(_l10n.flashlightOff);
    };
    
    // Speed control
    _voice.onSpeedUp = () async {
      _haptic.successFeedback();
      await _tts.setSpeechRate(0.7);
      _tts.speak(_l10n.speechSpeedIncreased);
    };
    _voice.onSlowDown = () async {
      _haptic.successFeedback();
      await _tts.setSpeechRate(0.35);
      _tts.speak(_l10n.speechSpeedDecreased);
    };
    
    // Pause/Resume (mute/unmute auto-describe)
    _voice.onPause = () {
      _haptic.buttonPress();
      if (_isAutoDescribing) {
        _isAutoDescribing = false;
        _tts.speak(_l10n.autoDescriptionPaused);
      } else {
        _tts.speak(_l10n.alreadyPaused);
      }
    };
    _voice.onResume = () {
      _haptic.buttonPress();
      if (!_isAutoDescribing) {
        _isAutoDescribing = true;
        _tts.speak(_l10n.autoDescriptionResumed);
      } else {
        _tts.speak(_l10n.alreadyActive);
      }
    };
    
    _voice.onNearbyPlaces = _describeNearbyPlaces;
    
    // Status
    _voice.onStatus = () {
      _haptic.buttonPress();
      String cameraStatus = _vision.isCameraEnabled ? _l10n.cameraIsOn : _l10n.cameraIsOff;
      String navStatus = _isNavigating ? _l10n.navigationIsActive : _l10n.navigationIsNotActive;
      String autoStatus = _isAutoDescribing ? _l10n.autoDescribeIsOn : _l10n.autoDescribeIsOff;
      _tts.speak("$cameraStatus. $navStatus. $autoStatus.");
    };
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.location,
      Permission.microphone,
      Permission.phone,
      Permission.sms,
    ];

    for (var permission in permissions) {
      await permission.request();
    }
  }

  /// Handle fall detected - trigger SOS countdown
  void _handleFallDetected() async {
    if (_sos.isSosActive) return;

    await _haptic.fallDetected();

    if (!mounted) return;
    setState(() => _statusText = _l10n.fallDetectedTapToCancel);

    // Delegate to SOS service
    await _sos.startSosSequence(context: 'Fall detected');
  }

  /// Handle vigorous shake - starts the cancellable SOS countdown.
  ///
  /// Deliberately a countdown rather than an immediate dispatch: shaking is the
  /// easiest gesture to perform by accident, so the user gets the same 10
  /// seconds to call it off that a detected fall gives them.
  void _handleShakeSOS() async {
    if (_sos.isSosActive) return;

    await _haptic.sosConfirmation();
    await _sos.startSosSequence(context: 'Vigorous shaking');

    if (!mounted) return;
    setState(() => _statusText = _l10n.sosTriggeredTapToCancel);
  }

  /// Single entry point for every cancel route: screen tap, volume button,
  /// voice command, or the on-screen button. Returns true if it stood an
  /// emergency down, so the voice service knows the command was consumed.
  bool _cancelEmergency() {
    if (!_sos.isCancellable) return false;

    final cancelled = _sos.cancelSos();
    if (cancelled) {
      _haptic.successFeedback();
      if (mounted) {
        setState(() => _statusText = _l10n.sosCancelledCameraActive);
      }
    }
    return cancelled;
  }

  /// Handle orientation warning
  void _handleOrientationWarning(String warning) async {
    if (!_orientationWarningShown) {
      _orientationWarningShown = true;
      await _tts.speak(warning);
      
      // Reset after cooldown
      Future.delayed(const Duration(seconds: 10), () {
        _orientationWarningShown = false;
      });
    }
  }

  // Auto-describe state (enabled by default as per user request)
  bool _isAutoDescribing = true;
  DateTime? _lastAutoDescriptionTime;
  static const Duration _autoDescribeInterval = Duration(seconds: 5);

  /// Handle obstacle detection with position
  void _handleObstacleDetected(List<DetectionResult> detections, String description) async {
    // Cancel previous auto-close timer
    _autoCloseTimer?.cancel();
    
    // Auto-close description after 5 seconds
    _autoCloseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _sceneDescription = '';
        });
      }
    });

    setState(() {
      _sceneDescription = description;
      // Truncate status text to prevent overflow
      _statusText = description.length > 50 ? '${description.substring(0, 50)}...' : description;
    });

    // Something in the way, or closing on the user. Both jump the queue.
    final urgent = detections.any(
      (d) => (d.position == 'center' && d.isClose) || d.isApproaching,
    );

    if (!_isAutoDescribing) {
      // The user switched announcements off, so nothing is spoken - the
      // toggle used to leave this branch speaking anyway, which is most of
      // what you hear while walking, so turning it off appeared to do
      // nothing at all. A blocking obstacle still buzzes, so silence is not
      // the same as no warning.
      if (urgent) await _haptic.obstacleWarning();
      return;
    }

    if (urgent) {
      await _haptic.obstacleWarning();
      await _tts.stop(); // Interrupt navigation/other speech for safety
      await _tts.speak(_l10n.obstacleWarning(description));
      return;
    }

    // Ambient commentary only. Never over the top of a route instruction.
    if (_isNavigating) return;

    if (_lastAutoDescriptionTime == null ||
        DateTime.now().difference(_lastAutoDescriptionTime!) >
            _autoDescribeInterval) {
      _lastAutoDescriptionTime = DateTime.now();
      await _tts.speakAmbient(description);
    }
  }

  void _toggleAutoDescribe() {
    setState(() {
      _isAutoDescribing = !_isAutoDescribing;
    });
    _tts.speak(_isAutoDescribing ? _l10n.autoDescriptionEnabled : _l10n.autoDescriptionDisabled);
  }

  /// Cancel fall detection SOS
  void _cancelFallSOS() => _cancelEmergency();

  /// Speak what is around the user, nearest first.
  ///
  /// Reads out at most three: a list of five read aloud is impossible to
  /// hold on to, and the nearest few are the ones worth walking to.
  Future<void> _describeNearbyPlaces() async {
    _haptic.buttonPress();
    await _tts.speak(_l10n.nearbyPlacesSearching);

    final position = await _location.getCurrentLocation();
    if (position == null) {
      await _tts.speak(_l10n.unableToGetLocation);
      return;
    }

    final result = await _navigation.findNearbyPlaces(
      latitude: position.latitude,
      longitude: position.longitude,
      limit: 3,
    );

    if (!mounted) return;

    if (!result.success) {
      await _tts.speak(_l10n.nearbyPlacesUnavailable);
      return;
    }
    if (result.places.isEmpty) {
      await _tts.speak(_l10n.nearbyPlacesNone);
      return;
    }

    final spoken = result.places
        .map((p) => _l10n.nearbyPlaceItem(p.name, '${p.distanceMeters}'))
        .join(', ');
    final sentence = _l10n.nearbyPlacesFound(spoken);

    await _tts.speak(sentence);
    setState(() => _sceneDescription = sentence);
  }

  /// Request scene description on demand
  void _describeScene() {
    String description = _vision.getCurrentSceneDescription();
    _tts.speak(description);
    setState(() => _sceneDescription = description);
  }

  /// Toggle camera on/off
  Future<void> _toggleCamera() async {
    bool newStatus = !_vision.isCameraEnabled;
    await _haptic.cameraModeChange(enabled: newStatus);
    await _vision.toggleCamera();
    
    // Save to settings
    await _settings.setCameraEnabled(newStatus);
    
    setState(() {
      if (_vision.isCameraEnabled) {
        _statusText = _l10n.cameraScanning;
      } else {
        _statusText = _l10n.cameraDisabled;
        _sceneDescription = '';
      }
    });
    
    _tts.speak(_vision.isCameraEnabled ? _l10n.cameraEnabled : _l10n.cameraDisabled);
  }

  /// Explicitly set camera state
  Future<void> _setCameraState(bool enable) async {
    if (_vision.isCameraEnabled == enable) {
      await _tts.speak(enable ? 'Camera is already on' : 'Camera is already off');
      return;
    }
    
    await _haptic.cameraModeChange(enabled: enable);
    if (enable) {
      await _vision.enableCamera();
    } else {
      await _vision.disableCamera();
    }
    
    // Save to settings
    await _settings.setCameraEnabled(enable);
    
    setState(() {
      if (_vision.isCameraEnabled) {
        _statusText = 'Camera enabled. Scanning for obstacles.';
      } else {
        _statusText = 'Camera disabled.';
        _sceneDescription = '';
      }
    });

    await _tts.speak(enable ? 'Camera enabled' : 'Camera disabled');
  }

  /// Start navigation
  Future<void> _startNavigation() async {
    if (!_isInitialized) {
      await _tts.speak(_l10n.pleaseWaitInitializing);
      return;
    }

    setState(() {
      _isNavigating = true;
      _statusText = _l10n.navigationStarted;
    });

    await _haptic.turnNotification();
    await _tts.speak(_l10n.navigationStarted);

    final position = await _location.getCurrentLocation();
    if (position == null) {
      await _tts.speak(_l10n.couldNotGetLocationGps);
      setState(() {
        _isNavigating = false;
        _statusText = 'Location error';
      });
      return;
    }

    String destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      destination = 'nearest coffee shop';
    }

    final result = await _navigation.getDirections(
      originLat: position.latitude,
      originLng: position.longitude,
      destination: destination,
    );

    if (!result.success) {
      await _tts.speak(_l10n.openingGoogleMaps);
      
      bool launched = await _navigation.launchGoogleMaps(destination);
      if (!launched) {
        await _tts.speak(_l10n.couldNotOpenGoogleMaps);
        setState(() {
          _isNavigating = false;
          _statusText = 'Navigation failed';
        });
      } else {
        setState(() {
          _isNavigating = false;
          _statusText = 'Opened Google Maps';
        });
      }
      return;
    }

    await _tts.speak(_l10n.routeFound(
      result.totalDistance ?? '',
      result.totalDuration ?? '',
    ));

    _location.onPositionUpdate = _handlePositionUpdate;
    await _location.startTracking();

    _announceCurrentStep();
    setState(() => _statusText = 'Navigating to $destination');
  }

  void _handlePositionUpdate(position) {
    // Check proximity to waypoints
  }

  Future<void> _announceCurrentStep() async {
    String instruction = _navigation.getCurrentVoiceInstruction();
    
    if (_gemini.isReady && !_isMockMode) {
      instruction = await _gemini.refineInstruction(instruction);
    }

    setState(() => _currentInstruction = instruction);
    await _tts.speak(instruction);

    if (_navigation.isCurrentStepATurn()) {
      bool? isLeft = _navigation.isLeftTurn();
      if (isLeft != null) {
        await _haptic.directionFeedback(isLeft: isLeft);
      }
    }
  }

  Future<void> _nextStep() async {
    if (!_isNavigating) return;

    bool hasNext = _navigation.nextStep();
    if (hasNext) {
      await _announceCurrentStep();
    } else {
      await _haptic.navigationComplete();
      await _tts.speak(_l10n.youHaveArrived);
      _stopNavigation();
    }
  }

  void _stopNavigation() async {
    _isNavigating = false;
    await _location.stopTracking();
    _navigation.stopNavigation();

    setState(() {
      _statusText = _l10n.navigationStoppedCameraActive;
      _currentInstruction = '';
    });

    await _tts.speak(_l10n.navigationStopped);
  }

  /// Manual SOS trigger
  Future<void> _triggerSOS() async {
    await _haptic.sosConfirmation();
    await _tts.speak(_l10n.sosActivated);

    if (mounted) setState(() => _statusText = 'SOS ACTIVATED');

    final result = await _sos.triggerSOS(
      additionalContext: _currentInstruction.isNotEmpty
          ? _currentInstruction
          : _sceneDescription,
      detectedObstacles: _vision.currentDetections.map((d) => d.label).toList(),
      shouldCall: true,
      shouldText: true,
    );

    if (result.success) {
      await _tts.speak(_describeSosOutcome(result));
      if (mounted) _showSOSDialog(result);
    } else {
      await _tts.speak(_l10n.sosError);
    }
  }

  /// Tells the user what actually happened, rather than reading the whole
  /// generated summary back at them. Distinguishes messages that were really
  /// sent from ones still sitting in a composer waiting for a tap.
  String _describeSosOutcome(SosResult result) {
    final parts = <String>[];
    final contactCount = _sos.contacts.length;

    if (result.messagesDelivered > 0) {
      parts.add(
        result.messagesDelivered == 1
            ? 'Emergency message sent to 1 contact.'
            : 'Emergency message sent to ${result.messagesDelivered} contacts.',
      );
    } else if (contactCount > 0) {
      parts.add(
        'Could not send automatically. '
        'Your messaging app is open and needs you to press send.',
      );
    } else {
      parts.add('No emergency contacts saved. Add one in settings.');
    }

    if (result.callMade == true) {
      parts.add('Calling for help now.');
    }

    return parts.join(' ');
  }

  void _showSOSDialog(SosResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => SosResultDialog(
        result: result,
        onClose: () {
          Navigator.pop(context);
          _cancelFallSOS();
        },
      ),
    );
  }

  void _showContactsDialog() {
    EmergencyContactsDialog.show(context, onAnnounce: _tts.speak);
  }

  void _toggleMockMode() {
    setState(() {
      _isMockMode = !_isMockMode;
      _navigation.useMock = _isMockMode;
      _gemini.useMock = _isMockMode;
      _vision.useMock = _isMockMode;
    });
    _tts.speak(_isMockMode ? 'Demo mode on' : 'Demo mode off');
  }

  /// Open settings screen
  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  /// Open tutorial screen
  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }

  void _openTutorial() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TutorialScreen()),
    );
  }

  /// Handle navigate to command (e.g., "navigate to home")
  Future<void> _handleNavigateToCommand(String command) async {
    // Extract location name from command
    String locationName = '';
    if (command.contains('navigate to')) {
      locationName = command.split('navigate to').last.trim();
    } else if (command.contains('go to')) {
      locationName = command.split('go to').last.trim();
    }

    if (locationName.isEmpty) {
      await _tts.speak(_l10n.pleaseSpecifyLocationName);
      return;
    }

    // Check saved locations
    final savedLocation = _savedLocations.getLocationByName(locationName);
    if (savedLocation != null) {
      // Navigate to saved location
      _destinationController.text = '${savedLocation.latitude},${savedLocation.longitude}';
      await _tts.speak(_l10n.navigatingTo(locationName));
      await _startNavigation();
    } else {
      // Try as regular destination
      _destinationController.text = locationName;
      await _tts.speak(_l10n.navigatingTo(locationName));
      await _startNavigation();
    }
  }

  /// Save current location with a name
  Future<void> _saveCurrentLocation() async {
    final position = await _location.getCurrentLocation();
    if (position == null) {
      await _tts.speak(_l10n.unableToGetLocation);
      return;
    }

    // The GPS fix above is awaited, so the screen may be gone by now.
    if (!mounted) return;

    // Show dialog to name the location
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          _l10n.saveLocationTitle,
          style: TextStyle(color: Colors.white, fontSize: _settings.textSize),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: Colors.white, fontSize: _settings.textSize),
          decoration: InputDecoration(
            hintText: 'Enter location name (e.g., Home)',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_l10n.actionCancel,
                style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final location = SavedLocation(
        name: result,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final saved = await _savedLocations.saveLocation(location);
      if (saved) {
        await _tts.speak(_l10n.locationSavedAs(location.name));
      } else {
        await _tts.speak(_l10n.failedToSaveLocation);
      }
    }
  }

  /// Show voice command input dialog
  void _showVoiceCommandDialog() {
    showDialog(
      context: context,
      builder: (context) => const VoiceCommandDialog(),
    );
  }

  /// Handle volume button double press (photo capture)
  void _handleVolumeDoublePress() {
    if (_cancelEmergency()) return;
    _haptic.buttonPress();
    _capturePhotoAndDescribe();
  }

  /// Handle volume button triple press (voice command)
  void _handleVolumeTriplePress() async {
    if (_cancelEmergency()) return;
    _haptic.buttonPress();
    await _tts.speak(_l10n.listeningForCommand);
    await _voice.startListening();
  }

  /// Handle triple tap on screen (voice command)
  void _handleTripleTap() {
    // While an emergency is counting down, a single tap anywhere cancels it.
    // Requiring three taps from someone who has just fallen is not reasonable.
    if (_cancelEmergency()) return;

    final now = DateTime.now();

    if (_lastTapTime == null || now.difference(_lastTapTime!) > _tripleTapWindow) {
      _tapCount = 1;
      _lastTapTime = now;
    } else {
      _tapCount++;
      if (_tapCount >= 3) {
        _handleVolumeTriplePress();
        _tapCount = 0;
        _lastTapTime = null;
        return;
      }
    }
    
    // Reset counter after window
    Future.delayed(_tripleTapWindow, () {
      if (_tapCount < 3) {
        _tapCount = 0;
      }
    });
  }


  /// Capture photo and describe with Gemini
  Future<void> _capturePhotoAndDescribe() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _tts.speak(_l10n.cameraNotReady);
      return;
    }

    if (_isCapturingPhoto) return;
    _isCapturingPhoto = true;

    try {
      await _tts.speak(_l10n.capturingPhoto);
      await _haptic.cameraModeChange(enabled: true);

      final image = await _cameraController!.takePicture();

      setState(() {
        _statusText = 'Processing photo...';
      });

      // Read text from image if available
      String ocrText = '';
      try {
        ocrText = await _ocr.recognizeTextFromFile(image.path);
        if (ocrText.isNotEmpty && ocrText != 'No text detected') {
          await _tts.speak(_l10n.textDetected(ocrText));
        }
      } catch (e) {
        debugPrint('OCR error: $e');
      }

      // Get Gemini description
      if (_gemini.isReady && widget.geminiApiKey != null) {
        await _tts.speak(_l10n.analyzingSceneWithAi);
        final description = await _gemini.describeImage(image.path);
        await _tts.speak(description);
        setState(() {
          _sceneDescription = description;
          _statusText = 'Photo analyzed';
        });
      } else {
        await _tts.speak(_l10n.photoCapturedNoGemini);
      }
    } catch (e) {
      debugPrint('Photo capture error: $e');
      await _tts.speak(_l10n.errorCapturingPhoto);
    } finally {
      _isCapturingPhoto = false;
    }
  }

  /// Read text from current camera view
  Future<void> _readTextFromCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _tts.speak(_l10n.cameraNotReady);
      return;
    }

    try {
      await _tts.speak(_l10n.readingTextFromCamera);
      
      // Capture a frame
      final image = await _cameraController!.takePicture();
      
      // Process with OCR
      final text = await _ocr.recognizeTextFromFile(image.path);
      
      if (text.isNotEmpty && text != 'No text detected') {
        await _tts.speak(_l10n.textFound(text));
        setState(() {
          _statusText = 'Text: $text';
        });
      } else {
        await _tts.speak(_l10n.noTextDetectedInView);
      }
      
      // Clean up temporary file
      try {
        final file = File(image.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting temp file: $e');
      }
    } catch (e) {
      debugPrint('Text reading error: $e');
      await _tts.speak(_l10n.errorReadingText);
    }
  }

  /// Releases the hardware these services hold - camera, microphone, GPS,
  /// sensor streams - when this screen goes away.
  ///
  /// Every one of them is an app-wide singleton, so this releases resources
  /// rather than destroying the objects: each resets its initialised flag and
  /// re-initialises on next use. VoiceCommandService gets release() rather
  /// than dispose() because it is a ChangeNotifier, and disposing one is
  /// permanent.
  Future<void> _releaseServices() async {
    await _tts.dispose();
    await _sensor.dispose();
    await _location.dispose();
    await _vision.dispose();
    await _ocr.dispose();
    await _gesture.dispose();
    await _voice.release();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CameraPreviewLayer(
                controller: _cameraController,
                cameraEnabled: _vision.isCameraEnabled,
                contrast: _settings.contrast,
              ),
            ),

            // Catches taps that land on empty areas, so the triple-tap voice
            // gesture works anywhere that is not already a control.
            Positioned.fill(
              child: GestureDetector(
                onTap: _handleTripleTap,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),

            Column(
              children: [
                StatusBanner(
                  statusText: _statusText,
                  sceneDescription: _sceneDescription,
                  isListening: _voice.isListening,
                  textSize: _settings.textSize,
                  contrast: _settings.contrast,
                ),
                const Spacer(),
                HomeControlBar(
                  destinationController: _destinationController,
                  isNavigating: _isNavigating,
                  isCameraEnabled: _vision.isCameraEnabled,
                  isAutoDescribing: _isAutoDescribing,
                  isCapturingPhoto: _isCapturingPhoto,
                  isMockMode: _isMockMode,
                  buttonSize: _settings.buttonSize,
                  contrast: _settings.contrast,
                  onToggleNavigation:
                      _isNavigating ? _stopNavigation : _startNavigation,
                  onSos: _triggerSOS,
                  onToggleCamera: _toggleCamera,
                  onToggleAutoDescribe: _toggleAutoDescribe,
                  onNextStep: _nextStep,
                  onShowContacts: _showContactsDialog,
                  onOpenMap: _openMap,
                  onCapturePhoto: _capturePhotoAndDescribe,
                  onReadText: _readTextFromCamera,
                  onVoiceCommand: _showVoiceCommandDialog,
                  onOpenSettings: _openSettings,
                  onOpenTutorial: _openTutorial,
                  onToggleMockMode: _toggleMockMode,
                ),
              ],
            ),

            const SosOverlay(),

            // Emergency cancel zone. Last child, so it sits above every other
            // control including the SOS overlay - any touch anywhere stands the
            // alert down. Driven by real SOS state rather than by matching on
            // status text, which is what made the old zone unreachable.
            if (_sos.isCancellable)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _cancelFallSOS,
                  onLongPress: _cancelFallSOS,
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    button: true,
                    label: _l10n.cancelEmergencyHint,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
