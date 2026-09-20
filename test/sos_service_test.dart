import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/services/sos_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression tests for the SOS state machine.
///
/// Each of these covers a defect that would have left a user unable to call off
/// an emergency, or unable to raise a second one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Everything SosService reaches for during a countdown. Without these the
  /// service dies on MissingPluginException before the logic under test runs.
  void stubPlatformChannels() {
    const stubs = <String, Object?>{
      'flutter_tts': 1,
      'com.gabn2/sms': true,
      'com.gabn2/call_state': true,
    };
    for (final entry in stubs.entries) {
      messenger.setMockMethodCallHandler(
        MethodChannel(entry.key),
        (call) async => entry.value,
      );
    }
  }

  void clearPlatformChannels() {
    for (final name in ['flutter_tts', 'com.gabn2/sms', 'com.gabn2/call_state']) {
      messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
  }

  late SosService sos;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    stubPlatformChannels();
    // SosService is a singleton, so state has to be reset between tests.
    sos = SosService();
    sos.standDown();
    for (final contact in sos.contacts.toList()) {
      sos.removeContact(contact.phoneNumber);
    }
  });

  tearDown(() {
    sos.standDown();
    clearPlatformChannels();
  });

  group('countdown lifecycle', () {
    test('starts idle', () {
      expect(sos.phase, SosPhase.idle);
      expect(sos.isSosActive, isFalse);
      expect(sos.isCancellable, isFalse);
    });

    test('startSosSequence enters a cancellable countdown', () async {
      await sos.startSosSequence(context: 'Fall detected');

      expect(sos.phase, SosPhase.countdown);
      expect(sos.isCountdownActive, isTrue);
      expect(sos.isCancellable, isTrue);
      expect(sos.currentCountdown, 10);
    });

    test('countdown ticks down once per second', () {
      fakeAsync((async) {
        sos.startSosSequence();
        async.elapse(const Duration(seconds: 3));

        expect(sos.currentCountdown, 7);
        expect(sos.phase, SosPhase.countdown);

        sos.cancelSos();
        async.flushTimers();
      });
    });

    test('a second start is refused while one is already running', () async {
      final first = await sos.startSosSequence();
      final second = await sos.startSosSequence();

      expect(first, isTrue);
      expect(second, isFalse, reason: 'must not stack countdowns');
    });
  });

  group('cancellation', () {
    test('cancelSos stops the countdown and returns to idle', () {
      fakeAsync((async) {
        sos.startSosSequence();
        async.elapse(const Duration(seconds: 4));

        expect(sos.cancelSos(), isTrue);
        expect(sos.phase, SosPhase.idle);
        expect(sos.currentCountdown, 10);

        // The timer must be dead - letting it run would dispatch anyway.
        async.elapse(const Duration(seconds: 30));
        expect(sos.phase, SosPhase.idle);
      });
    });

    test('cancelSos is a no-op when nothing is running', () {
      expect(sos.cancelSos(), isFalse);
      expect(sos.phase, SosPhase.idle);
    });

    test('cancelling notifies listeners so the UI can drop the overlay', () {
      fakeAsync((async) {
        var notifications = 0;
        void listener() => notifications++;
        sos.addListener(listener);

        sos.startSosSequence();
        async.elapse(const Duration(seconds: 2));
        final beforeCancel = notifications;

        sos.cancelSos();
        expect(notifications, greaterThan(beforeCancel));

        sos.removeListener(listener);
        async.flushTimers();
      });
    });
  });

  group('re-arming after an alert', () {
    test('standDown returns to idle so a later emergency can start', () async {
      await sos.startSosSequence();
      expect(sos.isSosActive, isTrue);

      sos.standDown();
      expect(sos.phase, SosPhase.idle);

      // The original bug: this second call was refused forever, because the
      // active flag was never cleared once a sequence had fired.
      final restarted = await sos.startSosSequence();
      expect(restarted, isTrue, reason: 'a second emergency must be possible');
      expect(sos.phase, SosPhase.countdown);
    });
  });

  group('contacts', () {
    test('add and remove round-trip', () async {
      await sos.addContact(
          EmergencyContact(name: 'Ada', phoneNumber: '555000111'));
      expect(sos.contacts.single.name, 'Ada');

      await sos.removeContact('555000111');
      expect(sos.contacts, isEmpty);
    });

    test('contacts survive a restart', () async {
      await sos.addContact(
          EmergencyContact(name: 'Ada', phoneNumber: '555000111'));

      // Simulate a fresh launch: wipe in-memory state, reload from storage.
      sos.contactsForTestOnlyClearMemory();
      expect(sos.contacts, isEmpty);

      await sos.initialize();

      expect(sos.contacts, hasLength(1),
          reason: 'a contact added in settings must outlive the process');
      expect(sos.contacts.single.name, 'Ada');
      expect(sos.contacts.single.phoneNumber, '555000111');
    });

    test('does not seed an SMS-incapable emergency number over real contacts',
        () async {
      await sos.addContact(
          EmergencyContact(name: 'Ada', phoneNumber: '555000111'));

      await sos.initialize(
        contacts: [EmergencyContact(name: 'Emergency', phoneNumber: '112')],
      );

      expect(sos.contacts.map((c) => c.phoneNumber), ['555000111'],
          reason: 'seeding must not overwrite saved contacts');
    });

    test('duplicate numbers are not added twice', () async {
      await sos.addContact(EmergencyContact(name: 'Ada', phoneNumber: '555'));
      await sos.addContact(EmergencyContact(name: 'Ada dup', phoneNumber: '555'));

      expect(sos.contacts, hasLength(1));
    });

    test('contacts list is unmodifiable', () {
      expect(
        () => sos.contacts.add(
          EmergencyContact(name: 'X', phoneNumber: '1'),
        ),
        throwsUnsupportedError,
      );
    });

    test('EmergencyContact survives a JSON round-trip', () {
      final original = EmergencyContact(
        name: 'Grace',
        phoneNumber: '555999000',
        relationship: 'sister',
      );
      final restored = EmergencyContact.fromJson(original.toJson());

      expect(restored.name, original.name);
      expect(restored.phoneNumber, original.phoneNumber);
      expect(restored.relationship, original.relationship);
    });
  });

  group('emergency number', () {
    test('defaults to the build-time value', () async {
      await sos.initialize();
      expect(sos.emergencyNumber, isNotEmpty);
    });

    test('an explicit number survives a restart', () async {
      await sos.setEmergencyNumber('5551234567');
      expect(sos.emergencyNumber, '5551234567');

      // Fresh launch: initialize() must not reset it to the build default.
      await sos.initialize();
      expect(sos.emergencyNumber, '5551234567');
    });

    test('blank input is ignored rather than wiping the number', () async {
      await sos.setEmergencyNumber('5551234567');
      await sos.setEmergencyNumber('   ');

      expect(sos.emergencyNumber, '5551234567',
          reason: 'an empty field must never leave the user with no number');
    });

    test('surrounding whitespace is trimmed', () async {
      await sos.setEmergencyNumber('  911  ');
      expect(sos.emergencyNumber, '911');
    });

    test('changing it notifies listeners', () async {
      var notified = 0;
      void listener() => notified++;
      sos.addListener(listener);

      await sos.setEmergencyNumber('999');
      expect(notified, greaterThan(0));

      sos.removeListener(listener);
    });
  });
}
