import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

/// Gemini AI service for reasoning tasks
/// Used ONLY for refining instructions and emergency summaries
/// NOT for real-time vision or navigation decisions
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const String defaultModel = 'gemini-3.6-flash';
  static const String fallbackModel = 'gemini-3.5-flash';

  GenerativeModel? _model;
  GenerativeModel? _fallbackModel;
  String? _modelName;
  bool _isInitialized = false;

  // Mock mode for testing without API
  bool useMock = false;

  /// Name of the model currently configured
  String? get modelName => _modelName;

  /// Initialize with API key and model name
  void initialize(String apiKey, {String model = defaultModel}) {
    if (apiKey.isEmpty) {
      debugPrint('Gemini API key is empty');
      return;
    }

    _modelName = model;
    _model = GenerativeModel(
      model: model,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
    );
    if (model != fallbackModel) {
      _fallbackModel = GenerativeModel(
        model: fallbackModel,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1024,
        ),
      );
    } else {
      _fallbackModel = null;
    }
    _isInitialized = true;
  }

  /// Helper to generate content with automatic failover to fallback model
  Future<GenerateContentResponse> _generateWithFallback(Iterable<Content> content) async {
    if (_model == null) {
      throw StateError('Gemini model is not initialized');
    }
    try {
      return await _model!.generateContent(content);
    } catch (e) {
      debugPrint('Primary Gemini model ($_modelName) error: $e');
      if (_fallbackModel != null) {
        debugPrint('Retrying with fallback model ($fallbackModel)...');
        return await _fallbackModel!.generateContent(content);
      }
      rethrow;
    }
  }

  /// Reset service state (for testing)
  @visibleForTesting
  void reset() {
    _model = null;
    _fallbackModel = null;
    _modelName = null;
    _isInitialized = false;
    useMock = false;
  }

  /// Refine a navigation instruction into accessibility-friendly language
  Future<String> refineInstruction(String instruction) async {
    if (useMock) {
      return _mockRefineInstruction(instruction);
    }

    if (!_isInitialized || _model == null) {
      return instruction; // Return original if not initialized
    }

    try {
      final prompt = '''
You are helping a blind person navigate. Rewrite this navigation instruction to be:
- Clear and concise
- Using clock positions for directions (e.g., "turn to your 3 o'clock" instead of "turn right")
- Including tactile or environmental cues when possible
- Easy to understand through audio

Original instruction: "$instruction"

Respond with ONLY the refined instruction, no explanations.
''';

      final response = await _generateWithFallback([Content.text(prompt)]);
      return response.text ?? instruction;
    } catch (e) {
      debugPrint('Gemini refinement error: $e');
      return instruction; // Fallback to original
    }
  }

  /// Generate an emergency summary for SOS
  Future<String> generateEmergencySummary({
    required Map<String, dynamic> location,
    String? lastInstruction,
    bool? fallDetected,
    List<String>? detectedObstacles,
  }) async {
    if (useMock) {
      return _mockEmergencySummary(location);
    }

    if (!_isInitialized || _model == null) {
      return _fallbackEmergencySummary(location);
    }

    try {
      final prompt = '''
Generate a brief emergency summary for a blind person's SOS alert. Include:
1. Current situation (1 sentence)
2. Location information
3. Any detected hazards or concerns

Context:
- Location: ${location['googleMapsUrl'] ?? 'Unknown'}
- Coordinates: ${location['latitude']}, ${location['longitude']}
- Last navigation instruction: ${lastInstruction ?? 'None'}
- Fall detected: ${fallDetected ?? false}
- Nearby obstacles: ${detectedObstacles?.join(', ') ?? 'None detected'}

Generate a concise emergency message suitable for text or voice call.
''';

      final response = await _generateWithFallback([Content.text(prompt)]);
      return response.text ?? _fallbackEmergencySummary(location);
    } catch (e) {
      debugPrint('Gemini SOS error: $e');
      return _fallbackEmergencySummary(location);
    }
  }

  /// Mock instruction refinement for testing
  String _mockRefineInstruction(String instruction) {
    // Simple mock transformations
    String refined = instruction
        .replaceAll('turn right', 'turn to your 3 o\'clock')
        .replaceAll('turn left', 'turn to your 9 o\'clock')
        .replaceAll('Turn right', 'Turn to your 3 o\'clock')
        .replaceAll('Turn left', 'Turn to your 9 o\'clock');
    
    return refined;
  }

  /// Mock emergency summary for testing
  String _mockEmergencySummary(Map<String, dynamic> location) {
    final lat = location['latitude'] ?? 'unknown';
    final lng = location['longitude'] ?? 'unknown';
    final url = location['googleMapsUrl'] ?? '';

    return '''
EMERGENCY ALERT: A visually impaired person needs assistance.

Location: Coordinates $lat, $lng
Map Link: $url

The person has activated their SOS emergency button on their navigation app. Please send help to this location immediately.

This is an automated emergency message.
''';
  }

  /// Fallback summary when Gemini is unavailable
  String _fallbackEmergencySummary(Map<String, dynamic> location) {
    final lat = location['latitude'] ?? 'unknown';
    final lng = location['longitude'] ?? 'unknown';
    final url = location['googleMapsUrl'] ?? '';

    return 'EMERGENCY: Blind user needs help at coordinates $lat, $lng. Map: $url';
  }

  /// Describe an image using Gemini Vision
  Future<String> describeImage(String imagePath) async {
    if (useMock) {
      return _mockImageDescription();
    }

    if (!_isInitialized || _model == null) {
      return 'Gemini AI not available. Please check your API key.';
    }

    try {
      final prompt = '''
Describe this image in detail for a visually impaired person. Include:
- Main objects and people
- Layout and spatial relationships
- Colors and visual characteristics
- Any text visible in the image
- Overall scene context
Be concise but descriptive, suitable for text-to-speech.
''';

      // Read image file
      final imageBytes = await File(imagePath).readAsBytes();
      
      // Create content with image
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _generateWithFallback(content);
      return response.text ?? 'Could not generate description';
    } catch (e) {
      debugPrint('Gemini image description error: $e');
      return 'AI description is temporarily unavailable. Please try again.';
    }
  }

  /// Mock image description for testing
  String _mockImageDescription() {
    return 'Mock description: This appears to be a scene with various objects. '
           'The image contains multiple elements that would be better described with a real AI model.';
  }

  /// Check if service is ready
  bool get isReady => _isInitialized && _model != null;
}
