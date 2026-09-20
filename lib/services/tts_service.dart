import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'settings_service.dart';

/// Text-to-Speech service for accessibility announcements.
///
/// Every call swallows platform failures. Speech is the primary output channel
/// for this app, but a dead TTS engine must never take down the caller - the
/// SOS path in particular speaks while dispatching help, and an exception
/// there would abort the dispatch.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Guards against a completion handler that never fires, which would
  /// otherwise spin [speakQueued] forever.
  static const Duration _maxSpeechWait = Duration(seconds: 15);

  /// Whether TalkBack (or another screen reader) is driving the device.
  ///
  /// Set from the UI layer, which is the only place that can see
  /// MediaQuery.accessibleNavigation. This app is self-voicing, so with a
  /// screen reader also running the user hears everything twice, overlapping.
  /// Only [speakAmbient] backs off - see the note there for why the rest
  /// keeps talking regardless.
  bool screenReaderActive = false;

  /// Initialize TTS engine with accessibility-optimized settings
  Future<void> initialize({String language = 'en-US'}) async {
    if (_isInitialized) return;

    try {
      await _tts.setLanguage(language);
      await _tts.setSpeechRate(SettingsService().speechRate);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setCancelHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization failed: $e');
      // Leave uninitialized so a later call can retry.
    }
  }

  /// Switch the spoken language, e.g. when the app locale changes.
  Future<void> setLanguage(String language) async {
    try {
      await _tts.setLanguage(language);
    } catch (e) {
      debugPrint('TTS setLanguage failed: $e');
    }
  }

  /// Speak a message immediately, interrupting any current speech
  Future<void> speak(String message) async {
    if (message.isEmpty) return;
    if (!_isInitialized) await initialize();

    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
      _isSpeaking = false;
    }
  }

  /// Speak a message, waiting for current speech to finish.
  ///
  /// Bounded by [_maxSpeechWait]: flutter_tts drops the completion callback
  /// when speech is interrupted, and an unbounded wait would hang here.
  Future<void> speakQueued(String message) async {
    if (message.isEmpty) return;
    if (!_isInitialized) await initialize();

    final deadline = DateTime.now().add(_maxSpeechWait);
    while (_isSpeaking && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_isSpeaking) {
      debugPrint('TTS wait timed out; speaking over previous utterance.');
      _isSpeaking = false;
    }

    try {
      await _tts.speak(message);
    } catch (e) {
      debugPrint('TTS speakQueued failed: $e');
      _isSpeaking = false;
    }
  }

  /// Speak routine surroundings commentary - the same text the status banner
  /// is already showing.
  ///
  /// Skipped entirely when a screen reader is running, because the banner is
  /// a semantic live region and TalkBack announces it the moment it changes;
  /// saying it here too just talks over that.
  ///
  /// Reserved for commentary the user can afford to miss. Anything urgent or
  /// asked for - an obstacle in the path, a navigation instruction, an SOS
  /// countdown, the answer to a voice command - goes through [speak] or
  /// [speakQueued] and is never suppressed, because a live region is
  /// announced at the screen reader's discretion and can be swallowed by
  /// whatever it happens to be saying.
  Future<void> speakAmbient(String message) async {
    if (screenReaderActive) return;
    await speakQueued(message);
  }

  /// Stop any current speech
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('TTS stop failed: $e');
    }
    _isSpeaking = false;
  }

  /// Set speech rate (0.0 to 1.0, accessibility default is 0.5)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('TTS setSpeechRate failed: $e');
    }
  }

  /// Set pitch (0.5 to 2.0, default is 1.0)
  Future<void> setPitch(double pitch) async {
    try {
      await _tts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (e) {
      debugPrint('TTS setPitch failed: $e');
    }
  }

  /// Check if TTS is currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Dispose of TTS resources
  Future<void> dispose() async {
    await stop();
    _isInitialized = false;
  }
}
