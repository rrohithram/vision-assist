/// Build-time configuration.
///
/// Keys are injected with `--dart-define` (or `--dart-define-from-file`) rather
/// than bundled as an asset. A `.env` shipped in `pubspec.yaml` assets is
/// readable by anyone who unzips the APK, so it is not a viable place for a
/// live credential.
///
/// Local development:
///   flutter run --dart-define-from-file=dart_defines.json
///
/// Release:
///   flutter build apk --release --dart-define-from-file=dart_defines.json
///
/// `dart_defines.json` is gitignored. See `dart_defines.example.json`.
class AppConfig {
  const AppConfig._();

  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const String geminiModel =
      String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.6-flash');

  /// Number dialled when no emergency contact is saved.
  ///
  /// 112 reaches emergency services across the EU and India; 911 in the US.
  /// Overridable at build time so a test build can be pointed at a phone you
  /// own — an accidental SOS during development otherwise places a real call
  /// to emergency services.
  ///
  ///   flutter run --dart-define=EMERGENCY_NUMBER=5551234567
  static const String emergencyNumber =
      String.fromEnvironment('EMERGENCY_NUMBER', defaultValue: '112');

  static bool get hasMapsKey => googleMapsApiKey.isNotEmpty;
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  /// True when the build dials something other than real emergency services,
  /// so the UI can say so plainly rather than leaving it a surprise.
  static bool get usesTestEmergencyNumber => emergencyNumber != '112';

  /// Names of the keys that were not supplied at build time, so startup can
  /// tell the user which features will be unavailable instead of failing
  /// silently mid-navigation.
  static List<String> get missingKeys => [
        if (!hasMapsKey) 'Google Maps',
        if (!hasGeminiKey) 'Gemini AI',
      ];
}
