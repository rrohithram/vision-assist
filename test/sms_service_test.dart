import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/services/sms_service.dart';

/// Tests for the emergency SMS path.
///
/// The defect these guard against: the old implementation opened a messaging
/// composer and recorded "Sent", so an SOS raised by an unconscious user
/// reported success while delivering nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('com.gabn2/sms');

  final sentMessages = <Map<String, String>>[];

  void mockNativeSms({required bool permissionGranted, bool throwOnSend = false}) {
    sentMessages.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'canSendSms':
          return permissionGranted;
        case 'sendSms':
          if (throwOnSend) {
            throw PlatformException(code: 'SEND_FAILED', message: 'radio busy');
          }
          sentMessages.add({
            'phoneNumber': call.arguments['phoneNumber'] as String,
            'message': call.arguments['message'] as String,
          });
          return true;
        default:
          return null;
      }
    });
  }

  setUp(() {
    // The service caches the permission result; a fresh platform override per
    // test only matters because each test constructs its own expectations.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('SmsResult reporting', () {
    test('only a direct send counts as having reached the recipient', () {
      const direct = SmsResult(
        phoneNumber: '555',
        status: SmsDeliveryStatus.sentDirectly,
      );
      const composer = SmsResult(
        phoneNumber: '555',
        status: SmsDeliveryStatus.composerOpened,
      );
      const failed = SmsResult(
        phoneNumber: '555',
        status: SmsDeliveryStatus.failed,
      );

      expect(direct.reachedRecipient, isTrue);
      expect(composer.reachedRecipient, isFalse,
          reason: 'an open composer has delivered nothing');
      expect(failed.reachedRecipient, isFalse);
    });

    test('describe() does not call an unsent message sent', () {
      const composer = SmsResult(
        phoneNumber: '555',
        status: SmsDeliveryStatus.composerOpened,
      );

      final text = composer.describe('Ada');
      expect(text, contains('Ada'));
      expect(text, contains('press send'));
      expect(text.toLowerCase(), isNot(contains('sent to')));
    });
  });

  group('direct sending', () {
    test('sends through the platform channel when permitted', () async {
      mockNativeSms(permissionGranted: true);
      final service = SmsService();

      final result = await service.send('555000111', 'help');

      expect(result.status, SmsDeliveryStatus.sentDirectly);
      expect(result.reachedRecipient, isTrue);
      expect(sentMessages, hasLength(1));
      expect(sentMessages.single['phoneNumber'], '555000111');
      expect(sentMessages.single['message'], 'help');
    });

    test('reaches every contact, not just the first', () async {
      mockNativeSms(permissionGranted: true);
      final service = SmsService();

      final results = await service.sendToAll(
        ['555000111', '555000222', '555000333'],
        'emergency',
      );

      expect(results, hasLength(3));
      expect(results.every((r) => r.reachedRecipient), isTrue);
      expect(sentMessages.map((m) => m['phoneNumber']),
          ['555000111', '555000222', '555000333']);
    });

    test('an empty contact list yields no results and no sends', () async {
      mockNativeSms(permissionGranted: true);
      final service = SmsService();

      final results = await service.sendToAll([], 'emergency');

      expect(results, isEmpty);
      expect(sentMessages, isEmpty);
    });
  });
}
