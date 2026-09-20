import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Gesture service for handling hardware button gestures
class GestureService {
  static final GestureService _instance = GestureService._internal();
  factory GestureService() => _instance;
  GestureService._internal();

  MethodChannel? _channel;
  bool _isInitialized = false;

  /// How long to wait after a press before deciding what the gesture was.
  ///
  /// A triple press cannot be told from a double press until the window has
  /// passed with no further press, so the multi-press callbacks always fire
  /// this late. [onVolumePress] is not delayed - cancelling an emergency
  /// cannot wait half a second for a pattern to resolve.
  static const Duration _multiPressWindow = Duration(milliseconds: 500);

  int _volumePressCount = 0;
  Timer? _volumePressTimer;

  // Callbacks
  VoidCallback? onVolumeDoublePress;
  VoidCallback? onVolumeLongPress;
  VoidCallback? onVolumeTriplePress;

  /// Fires on every volume press, before any multi-press pattern resolves.
  /// Used so a single press can abort an emergency countdown - waiting for a
  /// double or triple press to register is too slow for that.
  VoidCallback? onVolumePress;

  /// Initialize gesture service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        _channel = const MethodChannel('com.gabn2/gestures');
        
        // Set up method call handler
        _channel?.setMethodCallHandler(_handleMethodCall);
        
        // Start listening for volume button events
        await _channel?.invokeMethod('startVolumeButtonListener');
      }
      
      _isInitialized = true;
      debugPrint('Gesture service initialized');
    } catch (e) {
      debugPrint('Gesture service initialization error: $e');
      // Continue without gestures if not supported
    }
  }

  /// Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'volumeButtonPressed':
        _handleVolumeButtonPress();
        break;
      default:
        debugPrint('Unknown method call: ${call.method}');
    }
  }

  /// Counts presses, then dispatches once the user has stopped pressing.
  ///
  /// The previous version fired the double-press callback the instant the
  /// second press landed and reset the counter, so the third press started a
  /// fresh count and `>= 3` was unreachable: triple press - the documented
  /// way to reach voice commands without sight - could never fire, and every
  /// attempt at one took a photo instead.
  void _handleVolumeButtonPress() {
    // Always immediate: this is the emergency-cancel route.
    onVolumePress?.call();

    _volumePressCount++;
    _volumePressTimer?.cancel();
    _volumePressTimer = Timer(_multiPressWindow, _dispatchVolumeGesture);
  }

  void _dispatchVolumeGesture() {
    final count = _volumePressCount;
    _volumePressCount = 0;
    _volumePressTimer = null;

    // Three or more, so an over-eager fourth press still reaches voice
    // commands rather than silently doing nothing.
    if (count >= 3) {
      onVolumeTriplePress?.call();
    } else if (count == 2) {
      onVolumeDoublePress?.call();
    }
  }

  /// Feeds a synthetic volume press through the same path a real one takes.
  @visibleForTesting
  void handleVolumePressForTest() => _handleVolumeButtonPress();

  /// Manually trigger volume double press (for testing)
  void triggerVolumeDoublePress() {
    onVolumeDoublePress?.call();
  }

  Future<void> dispose() async {
    _volumePressTimer?.cancel();
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel?.invokeMethod('stopVolumeButtonListener');
      } catch (e) {
        debugPrint('Error stopping volume button listener: $e');
      }
    }
    _isInitialized = false;
  }
}

