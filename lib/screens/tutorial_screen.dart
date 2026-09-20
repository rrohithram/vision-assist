import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/tts_service.dart';
import '../services/settings_service.dart';

/// Tutorial screen for first-time users
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final TtsService _tts = TtsService();
  final SettingsService _settings = SettingsService();
  int _currentStep = 0;

  /// Built in didChangeDependencies: the copy comes from AppLocalizations,
  /// which is not reachable from a field initialiser or from initState.
  late List<TutorialStep> _steps;
  bool _announcedFirstStep = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _steps = _buildSteps(l10n);

    if (!_announcedFirstStep) {
      _announcedFirstStep = true;
      _speakCurrentStep();
    }
  }

  List<TutorialStep> _buildSteps(AppLocalizations l10n) => [
        TutorialStep(
          title: l10n.tutorialWelcomeTitle,
          description: l10n.tutorialWelcomeBody,
          icon: Icons.waving_hand,
        ),
        TutorialStep(
          title: l10n.tutorialCameraTitle,
          description: l10n.tutorialCameraBody,
          icon: Icons.camera_alt,
        ),
        TutorialStep(
          title: l10n.tutorialVoiceTitle,
          description: l10n.tutorialVoiceBody,
          icon: Icons.mic,
        ),
        TutorialStep(
          title: l10n.tutorialObstacleTitle,
          description: l10n.tutorialObstacleBody,
          icon: Icons.visibility,
        ),
        TutorialStep(
          title: l10n.tutorialPhotoTitle,
          description: l10n.tutorialPhotoBody,
          icon: Icons.camera,
        ),
        TutorialStep(
          title: l10n.tutorialTextTitle,
          description: l10n.tutorialTextBody,
          icon: Icons.text_fields,
        ),
        TutorialStep(
          title: l10n.tutorialSavedTitle,
          description: l10n.tutorialSavedBody,
          icon: Icons.bookmark,
        ),
        TutorialStep(
          title: l10n.tutorialSettingsTitle,
          description: l10n.tutorialSettingsBody,
          icon: Icons.settings,
        ),
        TutorialStep(
          title: l10n.tutorialSosTitle,
          description: l10n.tutorialSosBody,
          icon: Icons.warning,
        ),
      ];

  void _speakCurrentStep() {
    if (_currentStep < _steps.length) {
      final step = _steps[_currentStep];
      _tts.speak('${step.title}. ${step.description}');
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _speakCurrentStep();
    } else {
      _tts.speak(AppLocalizations.of(context)!.tutorialComplete);
      Navigator.pop(context);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _speakCurrentStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!
            .tutorialTitle('${_currentStep + 1}', '${_steps.length}')),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      step.icon,
                      size: 120 * _settings.buttonSize,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      step.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _settings.textSize * 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      step.description,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: _settings.textSize,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentStep > 0 ? _previousStep : null,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(AppLocalizations.of(context)!.tutorialPrevious),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _nextStep,
                  icon: Icon(_currentStep < _steps.length - 1 ? Icons.arrow_forward : Icons.check),
                  label: Text(_currentStep < _steps.length - 1
                      ? AppLocalizations.of(context)!.tutorialNext
                      : AppLocalizations.of(context)!.tutorialFinish),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

