import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/voice_command_service.dart';
import '../services/tts_service.dart';
import '../services/settings_service.dart';

/// Dialog for voice commands with visual feedback
class VoiceCommandDialog extends StatefulWidget {
  const VoiceCommandDialog({super.key});

  @override
  State<VoiceCommandDialog> createState() => _VoiceCommandDialogState();
}

class _VoiceCommandDialogState extends State<VoiceCommandDialog> {
  final TextEditingController _commandController = TextEditingController();
  final VoiceCommandService _voice = VoiceCommandService();
  final TtsService _tts = TtsService();
  final SettingsService _settings = SettingsService();

  bool _isListening = false;
  bool _showKeyboard = false;
  bool _isProcessingCommand = false;

  @override
  void initState() {
    super.initState();
    _voice.addListener(_onVoiceStateChanged);
    _startListening();
  }

  @override
  void dispose() {
    _voice.removeListener(_onVoiceStateChanged);
    // Only stop listening if we are NOT processing a command
    // If we are processing, the service handles the stop sequence safely
    if (!_isProcessingCommand) {
      _voice.stopListening();
    }
    _commandController.dispose();
    super.dispose();
  }

  void _onVoiceStateChanged() {
    if (mounted) {
      if (_isProcessingCommand) return; // Ignore updates if we are done

      setState(() {
        _isListening = _voice.isListening;
        if (_voice.lastRecognizedWords.isNotEmpty) {
           _commandController.text = _voice.lastRecognizedWords;
        }
      });

      // If listening stopped and we have text, process it automatically after a brief pause
      if (!_isListening && _voice.lastRecognizedWords.isNotEmpty && !_showKeyboard) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && !_isListening && !_isProcessingCommand) {
            _processCommand();
          }
        });
      }
    }
  }

  Future<void> _startListening() async {
    // Resolved before the await: reaching for an InheritedWidget afterwards
    // throws if the dialog was dismissed while the mic was starting.
    final unavailableMessage =
        AppLocalizations.of(context)!.voiceUnavailableTyped;

    await _voice.startListening();

    if (!_voice.isAvailable) {
      if (mounted) {
        setState(() => _showKeyboard = true);
      }
      _tts.speak(unavailableMessage);
    }
  }

  void _toggleInputMode() {
    setState(() {
      _showKeyboard = !_showKeyboard;
      if (_showKeyboard) {
        _voice.stopListening();
      } else {
        _startListening();
      }
    });
  }

  void _processCommand() {
    if (_isProcessingCommand) return;
    
    final command = _commandController.text.trim();
    if (command.isNotEmpty) {
      _isProcessingCommand = true; // Flag to prevent double processing / dispose cleanup
      _voice.processCommand(command);
      
      if (mounted) Navigator.pop(context);
      // Removed immediate TTS "Command processed" to prevent audio conflict crash
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Row(
        children: [
          Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? Colors.redAccent : Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.voiceCommandTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: _settings.textSize,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_showKeyboard)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    _isListening ? AppLocalizations.of(context)!.listeningIndicator : (_commandController.text.isNotEmpty ? AppLocalizations.of(context)!.voiceProcessing : AppLocalizations.of(context)!.voiceTapMicToSpeak),
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  if (_commandController.text.isNotEmpty)
                    Text(
                      '"${_commandController.text}"',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          
          if (_showKeyboard)
            TextField(
              controller: _commandController,
              autofocus: true,
              style: TextStyle(
                color: Colors.white,
                fontSize: _settings.textSize,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.voiceEnterCommand,
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _processCommand(),
            ),
        ],
      ),
      actions: [
        // An unlabelled IconButton reads as a bare "button" to a screen
        // reader, which is no use on the one dialog a blind user relies on.
        Semantics(
          container: true,
          button: true,
          label: _showKeyboard
              ? AppLocalizations.of(context)!.voiceUseMicrophone
              : AppLocalizations.of(context)!.voiceUseKeyboard,
          onTap: _toggleInputMode,
          excludeSemantics: true,
          child: IconButton(
            icon: Icon(_showKeyboard ? Icons.mic : Icons.keyboard),
            color: Colors.white,
            onPressed: _toggleInputMode,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.actionCancel,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        if (_showKeyboard)
          ElevatedButton(
            onPressed: _processCommand,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.voiceExecute),
          ),
      ],
    );
  }
}

