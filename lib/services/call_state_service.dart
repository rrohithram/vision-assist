import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reports when an in-progress phone call is actually answered.
///
/// Backed by Android's TelephonyManager via a platform channel, so it
/// reflects device-wide call state regardless of which mechanism placed the
/// call (direct dial or handing off to the system dialler).
class CallStateService {
  static const MethodChannel _channel = MethodChannel('com.gabn2/call_state');

  bool _listening = false;

  /// Called once when the watched call moves to the answered (off-hook)
  /// state. Fires at most once per [startListening] call.
  void Function()? onCallAnswered;

  /// Starts watching call state. Returns false when the platform refused -
  /// most commonly because READ_PHONE_STATE has not been granted - so the
  /// caller can fall back to a fixed delay instead.
  Future<bool> startListening() async {
    _channel.setMethodCallHandler(_handleMethodCall);
    try {
      final started = await _channel.invokeMethod<bool>('startListening');
      _listening = started ?? false;
      return _listening;
    } catch (e) {
      debugPrint('CallStateService: could not start listening: $e');
      _listening = false;
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!_listening) return;
    _listening = false;
    try {
      await _channel.invokeMethod('stopListening');
    } catch (e) {
      debugPrint('CallStateService: could not stop listening: $e');
    }
    _channel.setMethodCallHandler(null);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'callAnswered') {
      onCallAnswered?.call();
    }
  }
}
