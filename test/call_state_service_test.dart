import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/services/call_state_service.dart';

/// Coverage for the platform-channel glue behind the SOS call-answered fix:
/// the spoken message must only start once Android reports the call as
/// actually answered, with a safe false when it cannot.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.gabn2/call_state');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<void> simulatePlatformCall(String method) async {
    final message =
        const StandardMethodCodec().encodeMethodCall(MethodCall(method));
    await messenger.handlePlatformMessage(
      'com.gabn2/call_state',
      message,
      (data) {},
    );
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('startListening returns true when the platform starts watching', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'startListening');
      return true;
    });

    final service = CallStateService();
    expect(await service.startListening(), isTrue);
  });

  test('startListening returns false when the platform refuses (e.g. no '
      'READ_PHONE_STATE)', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => false);

    final service = CallStateService();
    expect(await service.startListening(), isFalse);
  });

  test('a MissingPluginException is treated as "not listening", not a crash',
      () async {
    messenger.setMockMethodCallHandler(channel, null);

    final service = CallStateService();
    expect(await service.startListening(), isFalse);
  });

  test('onCallAnswered fires when the platform reports the call answered',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async => true);

    final service = CallStateService();
    var answered = false;
    service.onCallAnswered = () => answered = true;

    await service.startListening();
    await simulatePlatformCall('callAnswered');

    expect(answered, isTrue);
  });

  test('no callback fires after stopListening', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => true);

    final service = CallStateService();
    var calls = 0;
    service.onCallAnswered = () => calls++;

    await service.startListening();
    await service.stopListening();
    await simulatePlatformCall('callAnswered');

    expect(calls, 0);
  });
}
