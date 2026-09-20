import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'sensor_service.dart';
import 'sos_service.dart';

/// Keeps fall/shake detection running via an Android foreground service when
/// the app is not in the foreground - backgrounded, screen off, or swiped
/// away from recents. Without this, Android eventually suspends or kills the
/// isolate driving [SensorService], so a fall while the phone sits
/// screen-off in a pocket could go undetected.
///
/// The background isolate runs its own [SensorService]/[SosService]
/// instances, entirely separate from the ones the foreground UI uses - Dart
/// singletons are per-isolate. Nothing is shared beyond what is persisted to
/// disk (contacts, emergency number) and the `invoke`/`on` bridge the plugin
/// provides, which is how cancellation crosses the isolate boundary: see
/// [cancel] and main.dart's `sosStarted`/`sosEnded` listeners.
///
/// Known limitations, given this never runs through the app's usual UI:
/// - Speaks and texts in English only - there is no BuildContext to resolve
///   AppLocalizations from inside a headless isolate.
/// - The custom `com.gabn2/sms` and `com.gabn2/call_state` platform channels
///   are registered on MainActivity's engine only, not this isolate's, so
///   SmsService/CallStateService fall back to their next-best path here (an
///   SMS composer needing a tap, instead of a silent send; a fixed delay
///   instead of call-answered detection). Calling itself still works
///   normally, since flutter_phone_direct_caller and url_launcher are real
///   plugins that register on every engine.
class BackgroundMonitorService {
  static const _notificationChannelId = 'gabn_fall_monitor';
  static const _notificationId = 4321;

  static bool _configured = false;

  /// Registers the service configuration. Safe to call on every app start;
  /// does not itself start the service - see [setEnabled].
  static Future<void> configure() async {
    if (_configured) return;
    _configured = true;

    await FlutterBackgroundService().configure(
      iosConfiguration: IosConfiguration(autoStart: false),
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        foregroundServiceNotificationId: _notificationId,
        foregroundServiceTypes: const [AndroidForegroundType.health],
        initialNotificationTitle: 'GaBN is watching for falls',
        initialNotificationContent: 'Running in the background',
      ),
    );
  }

  /// Starts or stops background monitoring. Callers persist the choice
  /// separately (see SettingsService.backgroundProtectionEnabled); this only
  /// drives the actual service.
  static Future<void> setEnabled(bool enabled) async {
    await configure();
    final service = FlutterBackgroundService();

    if (enabled) {
      await _requestBackgroundPermissions();
      if (!await service.isRunning()) {
        await service.startService();
      }
    } else {
      service.invoke('stopService');
    }
  }

  /// Asks for the two permissions the background path needs beyond what the
  /// app already requests at startup.
  ///
  /// Neither is fatal if refused, so nothing here blocks the service from
  /// starting: without notifications Android shows the mandatory
  /// foreground-service notification silently, and without background
  /// location the emergency message goes out with whatever last fix is
  /// available instead of a fresh one. Detection itself is unaffected.
  static Future<void> _requestBackgroundPermissions() async {
    try {
      // Android 13+. The foreground service notification is what makes the
      // countdown cancellable, so it matters more here than it looks.
      await Permission.notification.request();

      // Android 10+ splits "while using the app" from "all the time", and
      // only grants the latter once the former is already held - which it is
      // by this point, since HomeScreen requests it at startup.
      final always = await Permission.locationAlways.request();
      if (!always.isGranted) {
        debugPrint(
          'Background location denied: an SOS raised while the app is closed '
          'may report a stale position.',
        );
      }
    } catch (e) {
      debugPrint('Background permission request failed: $e');
    }
  }

  /// Tells a running background SOS countdown to stand down. Safe to call
  /// even when nothing is running or the service isn't active.
  static void cancel() {
    FlutterBackgroundService().invoke('cancelSos');
  }
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  // WidgetsFlutterBinding and plugin registration for this isolate's engine
  // are already handled by flutter_background_service_android's own
  // entrypoint() wrapper before it calls this function.
  final androidService = service is AndroidServiceInstance ? service : null;

  final sensor = SensorService();
  final sos = SosService();

  await sensor.initialize();
  await sos.initialize();

  Future<void> updateNotification() async {
    if (androidService == null) return;

    switch (sos.phase) {
      case SosPhase.idle:
        await androidService.setForegroundNotificationInfo(
          title: 'GaBN is watching for falls',
          content: 'Running in the background',
        );
        break;
      case SosPhase.countdown:
        await androidService.setForegroundNotificationInfo(
          title: 'Possible fall detected',
          content: 'Calling for help in ${sos.currentCountdown}s - '
              'open the app to cancel',
        );
        break;
      case SosPhase.dispatching:
      case SosPhase.alerting:
        await androidService.setForegroundNotificationInfo(
          title: 'Emergency alert sent',
          content: 'Contacted your emergency contacts',
        );
        break;
    }
  }

  sos.addListener(() {
    unawaited(updateNotification());

    if (sos.phase == SosPhase.countdown) {
      service.invoke('sosStarted');
      unawaited(androidService?.openApp());
    } else if (sos.phase == SosPhase.idle) {
      service.invoke('sosEnded');
    }
  });

  sensor.onFallDetected = () {
    if (!sos.isSosActive) sos.startSosSequence(context: 'Fall detected');
  };
  sensor.onVigorousShakeDetected = () {
    if (!sos.isSosActive) sos.startSosSequence(context: 'Vigorous shaking');
  };

  service.on('cancelSos').listen((_) => sos.cancelSos());
  service.on('stopService').listen((_) async {
    await sensor.dispose();
    await androidService?.stopSelf();
  });
}
