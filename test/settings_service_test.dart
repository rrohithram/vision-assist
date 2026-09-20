import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression coverage for resetToDefaults(), which used to reset only
/// textSize/buttonSize/contrast and silently leave the other four settings
/// untouched despite the name implying a full reset.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsService settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsService();
    await settings.initialize();
  });

  test('resetToDefaults restores every setting, not just the first three',
      () async {
    await settings.setTextSize(28.0);
    await settings.setButtonSize(1.8);
    await settings.setContrast(1.6);
    await settings.setCameraEnabled(false);
    await settings.setVibrationIntensity(0.1);
    await settings.setCommandDelay(2000);
    await settings.setSpeechRate(0.9);

    await settings.resetToDefaults();

    expect(settings.textSize, 18.0);
    expect(settings.buttonSize, 1.0);
    expect(settings.contrast, 1.0);
    expect(settings.cameraEnabled, isTrue,
        reason: 'camera-enabled must also be reset');
    expect(settings.vibrationIntensity, 0.5,
        reason: 'vibration intensity must also be reset');
    expect(settings.commandDelay, 0,
        reason: 'command delay must also be reset');
    expect(settings.speechRate, 0.5,
        reason: 'speech rate must also be reset');
  });

  test('reset values survive a reload from storage', () async {
    await settings.setVibrationIntensity(0.1);
    await settings.resetToDefaults();

    await settings.loadSettings();

    expect(settings.vibrationIntensity, 0.5,
        reason: 'reset must clear the persisted value, not just memory');
  });
}
