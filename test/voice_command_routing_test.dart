import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/services/voice_command_service.dart';

/// Covers how a recognised phrase is routed to a handler.
///
/// The routing chain is a long if/else over substring matches, so the order of
/// its branches is load-bearing and easy to break silently. The emergency
/// cancel in particular has to outrank everything: "cancel" used to fall
/// through to the navigation handler, stopping navigation while an SOS
/// countdown carried on to place a call the user could not stop.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late VoiceCommandService voice;
  late List<String> fired;

  /// Records which handler ran, so a test can assert on routing alone.
  void wireAll(VoiceCommandService v) {
    v.onStartNavigation = () => fired.add('startNavigation');
    v.onStopNavigation = () => fired.add('stopNavigation');
    v.onNextStep = () => fired.add('nextStep');
    v.onSOS = () => fired.add('sos');
    v.onHelp = () => fired.add('help');
    v.onRepeat = () => fired.add('repeat');
    v.onTime = () => fired.add('time');
    v.onBattery = () => fired.add('battery');
    v.onLocation = () => fired.add('location');
    v.onDescribeScene = () => fired.add('describeScene');
    v.onReadObstacles = () => fired.add('readObstacles');
    v.onCameraEnable = () => fired.add('cameraEnable');
    v.onCameraDisable = () => fired.add('cameraDisable');
    v.onToggleCamera = () => fired.add('toggleCamera');
    v.onFlashlightOn = () => fired.add('flashlightOn');
    v.onFlashlightOff = () => fired.add('flashlightOff');
    v.onSpeedUp = () => fired.add('speedUp');
    v.onSlowDown = () => fired.add('slowDown');
    v.onPause = () => fired.add('pause');
    v.onResume = () => fired.add('resume');
    v.onNearbyPlaces = () => fired.add('nearbyPlaces');
    v.onStatus = () => fired.add('status');
    v.onUnrecognizedCommand = (text) => fired.add('unrecognized:$text');
    v.onCancelEmergency = () => false; // no emergency running by default
  }

  setUp(() {
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugin.csdcorp.com/speech_to_text'),
      (call) async => call.method == 'initialize' ? true : null,
    );
    // Tests should not sit through the mic/TTS overlap guard.
    VoiceCommandService.minCommandDelay = Duration.zero;

    voice = VoiceCommandService();
    fired = [];
    wireAll(voice);
  });

  tearDown(() {
    VoiceCommandService.minCommandDelay = const Duration(milliseconds: 500);
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugin.csdcorp.com/speech_to_text'),
      null,
    );
  });

  /// The app points the recogniser at hi_IN when the interface is Hindi, so
  /// what comes back is Devanagari. Every rule in the routing chain used to
  /// match English substrings only, which meant a Hindi user speaking Hindi
  /// hit the unrecognised branch every single time - voice control, the main
  /// way a blind user drives this app, did nothing whatsoever.
  group('Hindi commands route the same as English', () {
    final cases = <String, String>{
      'नेविगेशन शुरू करो': 'startNavigation',
      'रुको': 'stopNavigation',
      'अगला': 'nextStep',
      'कैमरा बंद करो': 'cameraDisable',
      'कैमरा चालू करो': 'cameraEnable',
      'टॉर्च चालू': 'flashlightOn',
      'टॉर्च बंद': 'flashlightOff',
      'एसओएस': 'sos',
      'बचाओ': 'sos',
      'समय क्या है': 'time',
      'बैटरी': 'battery',
      'मैं कहाँ हूँ': 'location',
      'बताओ': 'describeScene',
      'सामने क्या है': 'readObstacles',
      'तेज़ बोलो': 'speedUp',
      'धीरे बोलो': 'slowDown',
      'आसपास क्या है': 'nearbyPlaces',
      'स्थिति': 'status',
      'मदद': 'help',
    };

    cases.forEach((phrase, expected) {
      test('"$phrase" -> $expected', () async {
        await voice.processCommand(phrase);
        expect(fired, [expected]);
      });
    });

    test('a Hindi phrase never falls through to the unrecognised branch',
        () async {
      for (final phrase in cases.keys) {
        fired = [];
        wireAll(voice);
        await voice.processCommand(phrase);
        expect(fired.single, isNot(startsWith('unrecognized')),
            reason: '"$phrase" must reach a handler');
      }
    });
  });

  group('Hindi emergency cancel', () {
    const phrases = ['रद्द करो', 'मैं ठीक हूँ', 'रहने दो', 'गलती से'];

    for (final phrase in phrases) {
      test('"$phrase" cancels the emergency', () async {
        var cancelled = false;
        voice.onCancelEmergency = () {
          cancelled = true;
          return true;
        };

        await voice.processCommand(phrase);

        expect(cancelled, isTrue,
            reason: 'a Hindi speaker must be able to call off an SOS by '
                'voice, the same as an English one');
        expect(fired, isEmpty, reason: 'cancel must consume the command');
      });
    }
  });

  group('emergency cancel outranks everything', () {
    setUp(() {
      // Simulate a countdown in progress: the handler consumes the command.
      voice.onCancelEmergency = () {
        fired.add('cancelEmergency');
        return true;
      };
    });

    test('"cancel" cancels the emergency instead of stopping navigation',
        () async {
      await voice.processCommand('cancel');

      expect(fired, ['cancelEmergency']);
      expect(fired, isNot(contains('stopNavigation')),
          reason: 'the original defect: navigation stopped, SOS did not');
    });

    test('"stop" during an emergency cancels it', () async {
      await voice.processCommand('stop');
      expect(fired, ['cancelEmergency']);
    });

    for (final phrase in [
      "i'm fine",
      'i am fine',
      "i'm ok",
      'false alarm',
      'never mind',
      'no emergency',
    ]) {
      test('"$phrase" cancels the emergency', () async {
        await voice.processCommand(phrase);
        expect(fired, ['cancelEmergency'], reason: 'phrase: $phrase');
      });
    }

    test('a non-cancel phrase still routes normally mid-emergency', () async {
      await voice.processCommand('what time is it');
      expect(fired, ['time']);
    });
  });

  group('no emergency running', () {
    test('"cancel" falls through to stopping navigation', () async {
      await voice.processCommand('cancel');

      // With nothing to cancel, onCancelEmergency returns false and the
      // command continues down the chain as before.
      expect(fired, ['stopNavigation']);
    });

    test('"stop" stops navigation', () async {
      await voice.processCommand('stop');
      expect(fired, ['stopNavigation']);
    });
  });

  group('command routing', () {
    final cases = <String, String>{
      'start navigation': 'startNavigation',
      'next': 'nextStep',
      'continue': 'nextStep',
      'sos': 'sos',
      'emergency': 'sos',
      'help me': 'sos',
      'repeat': 'repeat',
      'say again': 'repeat',
      'what time is it': 'time',
      'battery': 'battery',
      'where am i': 'location',
      'describe': 'describeScene',
      "what's ahead": 'readObstacles',
      'camera on': 'cameraEnable',
      'camera off': 'cameraDisable',
      'flashlight on': 'flashlightOn',
      'torch off': 'flashlightOff',
      'faster': 'speedUp',
      'slow down': 'slowDown',
      'pause': 'pause',
      'resume': 'resume',
      'nearby': 'nearbyPlaces',
      'status': 'status',
    };

    cases.forEach((phrase, expected) {
      test('"$phrase" -> $expected', () async {
        await voice.processCommand(phrase);
        expect(fired, [expected], reason: 'phrase: $phrase');
      });
    });

    test('"navigate to the park" is handed on with its destination', () async {
      await voice.processCommand('navigate to the park');
      expect(fired, ['unrecognized:navigate to the park']);
    });

    test('an unknown phrase reaches the fallback handler', () async {
      await voice.processCommand('make me a sandwich');
      expect(fired, ['unrecognized:make me a sandwich']);
    });

    test('empty input routes nowhere', () async {
      await voice.processCommand('   ');
      expect(fired, isEmpty);
    });

    test('routing is case-insensitive', () async {
      await voice.processCommand('SOS');
      expect(fired, ['sos']);
    });
  });

  group('device commands are not swallowed by the generic stop', () {
    // "stop camera" used to match the bare stop/cancel branch and end
    // navigation, even though HomeScreen wires that exact phrasing to the
    // camera. Device branches now sit above it.
    final cases = <String, String>{
      'stop camera': 'cameraDisable',
      'camera stop': 'cameraDisable',
      'turn off the camera': 'cameraDisable',
      'stop the flashlight': 'flashlightOff',
      'turn off torch': 'flashlightOff',
      'camera on': 'cameraEnable',
      'start camera': 'cameraEnable',
      'flashlight on': 'flashlightOn',
    };

    cases.forEach((phrase, expected) {
      test('"$phrase" -> $expected', () async {
        await voice.processCommand(phrase);
        expect(fired, [expected], reason: 'phrase: $phrase');
      });
    });

    test('a bare stop still stops navigation', () async {
      await voice.processCommand('stop');
      expect(fired, ['stopNavigation']);
    });
  });

  group('locale', () {
    test('maps app language to a recognition locale', () {
      voice.setLocale('hi');
      expect(voice.localeId, 'hi_IN');

      voice.setLocale('en');
      expect(voice.localeId, 'en_US');
    });

    test('unknown languages fall back rather than breaking recognition', () {
      voice.setLocale('zz');
      expect(voice.localeId, 'en_US');
    });
  });
}
