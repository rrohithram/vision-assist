import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/services/gemini_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GeminiService gemini;

  setUp(() {
    gemini = GeminiService();
    gemini.reset();
  });

  tearDown(() {
    gemini.reset();
  });

  group('GeminiService model and initialization', () {
    test('default model is gemini-3.6-flash', () {
      expect(GeminiService.defaultModel, 'gemini-3.6-flash');
      expect(GeminiService.fallbackModel, 'gemini-3.5-flash');
    });

    test('initializes with default model gemini-3.6-flash', () {
      gemini.initialize('test-api-key');

      expect(gemini.isReady, isTrue);
      expect(gemini.modelName, 'gemini-3.6-flash');
    });

    test('initializes with custom model name', () {
      gemini.initialize('test-api-key', model: 'gemini-3.8-flash');

      expect(gemini.isReady, isTrue);
      expect(gemini.modelName, 'gemini-3.8-flash');
    });

    test('does not initialize with empty apiKey', () {
      gemini.initialize('');

      expect(gemini.isReady, isFalse);
      expect(gemini.modelName, isNull);
    });
  });

  group('GeminiService fallback and mock behavior', () {
    test('refineInstruction returns original when not initialized', () async {
      final result = await gemini.refineInstruction('Turn right in 50 meters');
      expect(result, 'Turn right in 50 meters');
    });

    test('refineInstruction transforms clock positions in mock mode', () async {
      gemini.useMock = true;
      final result = await gemini.refineInstruction('Turn right and then turn left');
      expect(result, contains('3 o\'clock'));
      expect(result, contains('9 o\'clock'));
    });

    test('generateEmergencySummary provides fallback when uninitialized', () async {
      final summary = await gemini.generateEmergencySummary(
        location: {
          'latitude': 12.9716,
          'longitude': 77.5946,
          'googleMapsUrl': 'https://maps.google.com/?q=12.9716,77.5946',
        },
      );

      expect(summary, contains('12.9716'));
      expect(summary, contains('77.5946'));
    });

    test('generateEmergencySummary in mock mode produces structured alert', () async {
      gemini.useMock = true;
      final summary = await gemini.generateEmergencySummary(
        location: {
          'latitude': 12.9716,
          'longitude': 77.5946,
          'googleMapsUrl': 'https://maps.google.com/?q=12.9716,77.5946',
        },
      );

      expect(summary, contains('EMERGENCY ALERT'));
      expect(summary, contains('12.9716'));
    });

    test('describeImage returns unavailable message when uninitialized', () async {
      final description = await gemini.describeImage('dummy/path.jpg');
      expect(description, contains('Gemini AI not available'));
    });

    test('describeImage returns mock description in mock mode', () async {
      gemini.useMock = true;
      final description = await gemini.describeImage('dummy/path.jpg');
      expect(description, contains('Mock description'));
    });
  });
}
