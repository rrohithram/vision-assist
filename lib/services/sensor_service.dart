import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';

/// Sensor service for accelerometer, gyroscope, and compass data
/// Used for fall detection, orientation checking, and automatic SOS
class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  bool _isInitialized = false;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  /// Clock used for every timing decision below (free-fall/impact/stillness
  /// windows, shake debounce, cooldowns). Overridable so tests can drive the
  /// state machine without waiting on real wall-clock time.
  DateTime Function() _now = DateTime.now;

  @visibleForTesting
  set debugClock(DateTime Function() clock) => _now = clock;

  // Latest sensor values
  AccelerometerEvent? _lastAccelerometer;
  MagnetometerEvent? _lastMagnetometer;

  // Fall detection state machine
  static const double _impactThreshold = 30.0; // High impact threshold
  static const double _shakeThreshold = 25.0; // Vigorous shake threshold
  static const double _freeFallThreshold = 2.5; // Near zero gravity
  DateTime? _lastFallAlert;
  static const Duration _fallCooldown = Duration(seconds: 10);

  // A real fall is free-fall, then impact, then the person stays down.
  // Requiring all three keeps ordinary handling - setting the phone down hard,
  // dropping it into a bag - from dialling the emergency services.
  static const Duration _impactWindow = Duration(milliseconds: 800);
  static const Duration _stillnessDuration = Duration(milliseconds: 1500);
  static const double _stillnessTolerance = 3.5; // m/s^2 around 1g

  // Shake detection for emergency
  int _shakeCount = 0;
  DateTime? _lastShakeTime;
  DateTime? _lastCountedShake;
  static const int _shakesToTriggerSOS = 5; // 5 shakes in 3 seconds
  static const Duration _shakeWindow = Duration(seconds: 3);

  // One burst of movement spans many samples at 20Hz. Without this, a single
  // half-second jolt registers as five shakes and fires SOS instantly.
  static const Duration _shakeDebounce = Duration(milliseconds: 250);

  // Free fall detection
  bool _inFreeFall = false;
  DateTime? _freeFallStart;

  // Impact-then-stillness confirmation
  DateTime? _impactAt;
  DateTime? _stillnessStart;

  // Orientation state with debouncing
  bool _lastOrientationCorrect = true;
  DateTime? _lastOrientationWarning;
  static const Duration _orientationWarningCooldown = Duration(seconds: 5);

  // Callbacks
  void Function()? onFallDetected;
  void Function()? onVigorousShakeDetected; // Triggers SOS
  void Function(bool isCorrect)? onOrientationChanged;
  void Function(String warning)? onOrientationWarning;

  /// Initialize sensor streams
  Future<void> initialize() async {
    if (_isInitialized) return;

    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50), // 20Hz for better fall detection
    ).listen(_handleAccelerometer);

    _magnetometerSubscription = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 200),
    ).listen(_handleMagnetometer);

    _isInitialized = true;
    debugPrint('Sensor service initialized');
  }

  void _handleAccelerometer(AccelerometerEvent event) {
    _lastAccelerometer = event;
    _checkForFall(event);
    _checkForShake(event);
    _checkPhoneOrientation(event);
  }

  void _handleMagnetometer(MagnetometerEvent event) {
    _lastMagnetometer = event;
  }

  /// Feeds a synthetic accelerometer sample through the same path a real
  /// sensor reading takes, so the fall/shake/orientation state machine can be
  /// driven deterministically in tests without a device.
  @visibleForTesting
  void handleAccelerometerEventForTest(AccelerometerEvent event) =>
      _handleAccelerometer(event);

  /// Drops all state accumulated between samples - free-fall/impact phase,
  /// shake count, cooldowns - so each test starts from a clean slate despite
  /// this being a singleton.
  @visibleForTesting
  void resetStateForTest() {
    _resetFallState();
    _lastFallAlert = null;
    _shakeCount = 0;
    _lastShakeTime = null;
    _lastCountedShake = null;
    _lastOrientationCorrect = true;
    _lastOrientationWarning = null;
  }

  /// Fall detection as a three-phase state machine: free fall, then impact,
  /// then the person stays still.
  ///
  /// Requiring all three phases matters because the consequence of a false
  /// positive here is an unwanted emergency call. A bare impact threshold -
  /// which is what this used to be - fires whenever the phone is set down
  /// firmly.
  void _checkForFall(AccelerometerEvent event) {
    final now = _now();
    final double magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Phase 3: an impact landed recently; confirm the user is now still.
    if (_impactAt != null) {
      if (now.difference(_impactAt!) > _stillnessDuration + _impactWindow) {
        // Moved on without settling - they caught themselves. Stand down.
        _resetFallState();
      } else if ((magnitude - 9.81).abs() < _stillnessTolerance) {
        _stillnessStart ??= now;
        if (now.difference(_stillnessStart!) >= _stillnessDuration) {
          _resetFallState();
          _triggerFallAlert();
        }
      } else {
        // Still moving; restart the stillness clock.
        _stillnessStart = null;
      }
      return;
    }

    // Phase 1: free fall (near zero g).
    if (magnitude < _freeFallThreshold) {
      if (!_inFreeFall) {
        _inFreeFall = true;
        _freeFallStart = now;
        debugPrint('Free fall detected');
      }
      return;
    }

    // Phase 2: impact shortly after free fall.
    if (_inFreeFall) {
      final fallDuration = now.difference(_freeFallStart!);
      final withinWindow = fallDuration.inMilliseconds > 100 &&
          fallDuration <= _impactWindow;

      if (magnitude > _impactThreshold && withinWindow) {
        debugPrint('Impact after free fall - waiting for stillness');
        _impactAt = now;
        _stillnessStart = null;
      } else if (fallDuration > _impactWindow) {
        // Free fall ended without a matching impact.
        _inFreeFall = false;
        _freeFallStart = null;
      } else {
        _inFreeFall = false;
        _freeFallStart = null;
      }
    }
  }

  void _resetFallState() {
    _inFreeFall = false;
    _freeFallStart = null;
    _impactAt = null;
    _stillnessStart = null;
  }

  /// Detect vigorous shaking for emergency SOS
  void _checkForShake(AccelerometerEvent event) {
    double magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    if (magnitude > _shakeThreshold) {
      DateTime now = _now();

      // One burst of movement spans several samples at 20Hz. Count at most one
      // shake per debounce interval so the user has to genuinely shake the
      // phone repeatedly rather than jolt it once.
      if (_lastCountedShake != null &&
          now.difference(_lastCountedShake!) < _shakeDebounce) {
        return;
      }

      // Reset count if outside window
      if (_lastShakeTime != null &&
          now.difference(_lastShakeTime!) > _shakeWindow) {
        _shakeCount = 0;
      }

      _lastShakeTime = now;
      _lastCountedShake = now;
      _shakeCount++;

      debugPrint('Shake detected: $_shakeCount/$_shakesToTriggerSOS');

      if (_shakeCount >= _shakesToTriggerSOS) {
        _shakeCount = 0;
        onVigorousShakeDetected?.call();
        debugPrint('Vigorous shake SOS triggered!');
      }
    }
  }

  void _triggerFallAlert() {
    if (_lastFallAlert != null &&
        _now().difference(_lastFallAlert!) < _fallCooldown) {
      return;
    }

    _lastFallAlert = _now();
    onFallDetected?.call();
    debugPrint('Fall alert triggered!');
  }

  /// Check phone orientation with debounced warnings
  void _checkPhoneOrientation(AccelerometerEvent event) {
    // Phone should be roughly vertical with screen facing forward
    // Y-axis: high positive when held upright
    // Z-axis: near zero when screen perpendicular to ground
    // X-axis: near zero when not tilted sideways
    
    bool isVertical = event.y > 5.0 && event.y < 12.0;
    bool isScreenForward = event.z.abs() < 6.0;
    bool isNotTilted = event.x.abs() < 4.0;
    bool isCorrect = isVertical && isScreenForward && isNotTilted;

    // Notify on state change
    if (isCorrect != _lastOrientationCorrect) {
      _lastOrientationCorrect = isCorrect;
      onOrientationChanged?.call(isCorrect);
      
      // Generate specific warning if not correct (with cooldown)
      if (!isCorrect) {
        DateTime now = _now();
        if (_lastOrientationWarning == null ||
            now.difference(_lastOrientationWarning!) > _orientationWarningCooldown) {
          _lastOrientationWarning = now;
          String warning = _getOrientationWarning(event);
          onOrientationWarning?.call(warning);
        }
      }
    }
  }

  /// Get specific orientation warning message
  String _getOrientationWarning(AccelerometerEvent event) {
    if (event.y < 3.0) {
      if (event.z > 6.0) {
        return "Phone is face up. Please hold it upright in front of you.";
      } else if (event.z < -6.0) {
        return "Phone is face down. Please hold it upright with the screen facing you.";
      } else {
        return "Please hold the phone more upright.";
      }
    }
    
    if (event.x > 4.0) {
      return "Phone is tilted right. Please straighten it.";
    } else if (event.x < -4.0) {
      return "Phone is tilted left. Please straighten it.";
    }
    
    if (event.z > 6.0) {
      return "Phone is pointing too far up. Lower it slightly.";
    } else if (event.z < -6.0) {
      return "Phone is pointing too far down. Raise it slightly.";
    }
    
    return "Please hold the phone upright, facing forward.";
  }

  /// Get current compass heading in degrees (0-360)
  double? getCompassHeading() {
    if (_lastMagnetometer == null || _lastAccelerometer == null) return null;

    double heading = atan2(
      _lastMagnetometer!.y,
      _lastMagnetometer!.x,
    ) * (180 / pi);

    if (heading < 0) heading += 360;
    return heading;
  }

  /// Get direction name from heading
  String getDirectionName(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'North';
    if (heading >= 22.5 && heading < 67.5) return 'Northeast';
    if (heading >= 67.5 && heading < 112.5) return 'East';
    if (heading >= 112.5 && heading < 157.5) return 'Southeast';
    if (heading >= 157.5 && heading < 202.5) return 'South';
    if (heading >= 202.5 && heading < 247.5) return 'Southwest';
    if (heading >= 247.5 && heading < 292.5) return 'West';
    return 'Northwest';
  }

  /// Get clock direction (e.g., "12 o'clock" for straight ahead)
  String getClockDirection(double heading, double targetBearing) {
    double diff = targetBearing - heading;
    if (diff < 0) diff += 360;
    if (diff >= 360) diff -= 360;
    
    int hour = (((diff / 30) + 12) % 12).toInt();
    if (hour == 0) hour = 12;
    return "$hour o'clock";
  }

  /// Check if phone is currently held correctly
  bool isPhoneOrientationCorrect() {
    return _lastOrientationCorrect;
  }

  AccelerometerEvent? get currentAccelerometer => _lastAccelerometer;
  MagnetometerEvent? get currentMagnetometer => _lastMagnetometer;

  Future<void> dispose() async {
    await _accelerometerSubscription?.cancel();
    await _magnetometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _magnetometerSubscription = null;
    _isInitialized = false;
  }
}
