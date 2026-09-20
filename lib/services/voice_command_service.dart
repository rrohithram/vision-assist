import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'settings_service.dart';

/// Voice Command Service with real speech recognition
class VoiceCommandService extends ChangeNotifier {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  
  String _lastRecognizedWords = '';
  String get lastRecognizedWords => _lastRecognizedWords;
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  /// Recognition locale, e.g. `en_US` or `hi_IN`. Kept in step with the app
  /// locale so a Hindi user is not forced to issue commands in English.
  String localeId = 'en_US';

  /// Points recognition at [languageCode] ('en', 'hi', ...).
  void setLocale(String languageCode) {
    const localeIds = {'en': 'en_US', 'hi': 'hi_IN'};
    localeId = localeIds[languageCode] ?? 'en_US';
  }

  // Core navigation callbacks
  VoidCallback? onStartNavigation;
  VoidCallback? onStopNavigation;
  VoidCallback? onNextStep;
  VoidCallback? onSOS;
  VoidCallback? onHelp;
  VoidCallback? onRepeat;
  VoidCallback? onTime;
  VoidCallback? onBattery;
  VoidCallback? onLocation;
  
  // New callbacks for enhanced functionality
  VoidCallback? onDescribeScene;
  VoidCallback? onToggleCamera;
  VoidCallback? onCameraEnable;
  VoidCallback? onCameraDisable;
  VoidCallback? onSpeedUp;
  VoidCallback? onSlowDown;
  VoidCallback? onPause;
  VoidCallback? onResume;
  VoidCallback? onNearbyPlaces;
  VoidCallback? onReadObstacles;
  VoidCallback? onStatus;
  
  // Flashlight commands
  VoidCallback? onFlashlightOn;
  VoidCallback? onFlashlightOff;
  
  void Function(String text)? onUnrecognizedCommand;

  /// Speech recognition could not be started at all - no engine, no
  /// microphone permission, or the device is offline with no on-device
  /// model. Without this the user hears "listening", says something, and
  /// gets silence back with no way to tell what went wrong.
  VoidCallback? onSpeechUnavailable;

  /// The microphone opened and closed without recognising anything.
  VoidCallback? onNothingHeard;

  /// Consulted before any other routing when the user says something
  /// cancel-shaped. Returns true if it consumed the command.
  ///
  /// Without this, "cancel" fell through to [onStopNavigation] and merely
  /// stopped navigation while an emergency countdown kept running.
  bool Function()? onCancelEmergency;

  /// Set when a recognition result arrives, so the status handler can tell a
  /// session that heard nothing from one that produced a command.
  bool _sawResult = false;

  Future<void> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: _handleSpeechError,
      onStatus: _handleSpeechStatus,
    );
    debugPrint('VoiceCommandService initialized. Available: $_isAvailable');
  }

  void _handleSpeechError(Object error) {
    debugPrint('Speech recognition error: $error');
    final wasListening = _isListening;
    _isListening = false;
    notifyListeners();

    // An error that ends a session the user deliberately started needs to be
    // audible - they are standing there waiting for a reply.
    if (wasListening && !_sawResult) onNothingHeard?.call();
  }

  void _handleSpeechStatus(String status) {
    debugPrint('Speech recognition status: $status');
    if (status != 'done' && status != 'notListening') return;

    final wasListening = _isListening;
    _isListening = false;
    notifyListeners();

    if (wasListening && !_sawResult) onNothingHeard?.call();
  }

  /// Start listening for voice commands (activated by gesture)
  Future<void> startListening() async {
    // Prevent re-entry if already initializing or listening
    if (_isListening) return;

    if (!_isAvailable) {
      // One retry: the engine is often unavailable only because permission
      // had not been granted the first time around.
      _isAvailable = await _speech.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
      );

      if (!_isAvailable) {
        debugPrint('Speech recognition not available');
        notifyListeners();
        onSpeechUnavailable?.call();
        return;
      }
    }

    _sawResult = false;
    _isListening = true;
    notifyListeners();

    try {
      // Ensure we don't start if system says we are listening
      if (_speech.isListening) {
         await _speech.stop();
      }

      await _speech.listen(
        onResult: (result) {
          _lastRecognizedWords = result.recognizedWords;

          if (result.finalResult) {
            // Speech finished, process the command
            debugPrint('Final result: ${result.recognizedWords}');
            _sawResult = result.recognizedWords.trim().isNotEmpty;
            processCommand(result.recognizedWords);
            stopListening();
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
          partialResults: false,
        ),
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  /// Stop listening and release resources immediately
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      // cancel() is more aggressive/safer for releasing microphone than stop()
      await _speech.cancel(); 
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
    _isListening = false;
    notifyListeners();
  }

  /// Buffer between the microphone closing and a command running.
  ///
  /// The mic and the TTS engine conflict on some devices if they overlap, so
  /// there is always a floor here. Exposed so tests do not have to wait it out.
  @visibleForTesting
  static Duration minCommandDelay = const Duration(milliseconds: 500);

  /// Routes a recognised phrase to the matching handler.
  ///
  /// Returns a Future so callers - and tests - can tell when routing finished.
  /// It used to be `void ... async`, which made completion unobservable.
  Future<void> processCommand(String text) async {
    final command = text.toLowerCase().trim();
    if (command.isEmpty) return;
    
    _lastRecognizedWords = command;
    debugPrint('Processing command: $command');

    // Force stop if not already
    if (_isListening) {
      await stopListening();
    }

    // Waiting here prevents the native crash where mic and TTS overlap.
    final extraDelay = Duration(milliseconds: SettingsService().commandDelay);
    await Future.delayed(minCommandDelay + extraDelay);
    
    // An emergency in progress outranks everything else. Anything that reads
    // as "make it stop" must reach the SOS cancel, not navigation.
    if (_isCancelPhrase(command) && (onCancelEmergency?.call() ?? false)) {
      return;
    }

    // Navigation commands - check for "navigate to" or "go to" first
    if (_has(command, _kNavigateTo)) {
      onUnrecognizedCommand?.call(command);
    } else if (_has(command, _kStartWords) && _has(command, _kNavigation)) {
      onStartNavigation?.call();
    }
    // Device commands are matched before the bare stop/cancel below, because
    // they carry their own "stop": "stop camera" used to end navigation
    // instead of switching the camera off.
    else if (_has(command, _kCamera)) {
      if (_has(command, _kOffWords)) {
        onCameraDisable?.call();
      } else if (_has(command, _kOnWords)) {
        onCameraEnable?.call();
      } else {
        onToggleCamera?.call();
      }
    } else if (_has(command, _kLight)) {
      if (_has(command, _kOffWords)) {
        onFlashlightOff?.call();
      } else {
        onFlashlightOn?.call();
      }
    } else if (_has(command, _kStop)) {
      onStopNavigation?.call();
    } else if (_has(command, _kNext)) {
      onNextStep?.call();
    }
    // Help and repeat. "help me" is a cry for help, not a request for the
    // command list, so it is excluded here and caught by the SOS branch.
    else if (_has(command, _kHelp) && !_has(command, _kHelpMe)) {
      onHelp?.call();
    } else if (_has(command, _kRepeat)) {
      onRepeat?.call();
    }
    // Emergency
    else if (_has(command, _kSos) || _has(command, _kHelpMe)) {
      onSOS?.call();
    }
    // Information commands
    else if (_has(command, _kTime)) {
      onTime?.call();
    } else if (_has(command, _kBattery)) {
      onBattery?.call();
    } else if (_has(command, _kLocation)) {
      onLocation?.call();
    }
    // Scene and obstacle commands
    else if (_has(command, _kDescribe)) {
      onDescribeScene?.call();
    } else if (_has(command, _kObstacles)) {
      onReadObstacles?.call();
    }
    // Speed control
    else if (_has(command, _kFaster)) {
      onSpeedUp?.call();
    } else if (_has(command, _kSlower)) {
      onSlowDown?.call();
    }
    // Pause/Resume
    else if (_has(command, _kPause)) {
      onPause?.call();
    } else if (_has(command, _kResume)) {
      onResume?.call();
    }
    // Nearby places
    else if (_has(command, _kNearby)) {
      onNearbyPlaces?.call();
    }
    // Status
    else if (_has(command, _kStatus)) {
      onStatus?.call();
    }
    // Unrecognized - pass to handler
    else {
      onUnrecognizedCommand?.call(command);
    }
  }

  // -------------------------------------------------------------------
  // Command vocabulary
  // -------------------------------------------------------------------
  //
  // Every intent lists its trigger words in both shipped languages. The app
  // points the recogniser at hi_IN for Hindi users, so what comes back is
  // Devanagari - and every rule here used to match English substrings only,
  // which meant voice control, the primary way a blind user drives this app,
  // did nothing at all in Hindi. Matching is plain substring containment, so
  // the two scripts can share one list without colliding.

  static bool _has(String command, List<String> words) =>
      words.any(command.contains);

  static const _kNavigateTo = [
    'navigate to', 'go to',
    'ले चलो', 'जाना है', 'चलना है',
  ];
  static const _kStartWords = ['start', 'begin', 'शुरू', 'चालू', 'चालु'];
  static const _kNavigation = [
    'navigation', 'navigate',
    'नेविगेशन', 'रास्ता', 'रास्ते',
  ];

  static const _kCamera = ['camera', 'vision', 'कैमरा', 'कैमरे'];
  static const _kLight = [
    'flashlight', 'torch', 'light',
    'टॉर्च', 'रोशनी', 'बत्ती', 'लाइट',
  ];

  static const _kOffWords = [
    'off', 'disable', 'stop',
    'बंद', 'बन्द', 'हटा',
  ];
  static const _kOnWords = [
    'on', 'enable', 'start',
    'चालू', 'चालु', 'शुरू',
  ];

  static const _kStop = [
    'stop', 'cancel', 'end',
    'बंद', 'बन्द', 'रोको', 'रुको', 'रद्द',
  ];
  static const _kNext = [
    'next', 'continue',
    'अगला', 'अगले', 'आगे बढ़',
  ];

  static const _kHelp = ['help', 'मदद', 'सहायता'];
  static const _kHelpMe = ['help me', 'मदद करो', 'बचाओ'];
  static const _kRepeat = [
    'repeat', 'say again', 'again',
    'दोहरा', 'फिर से कहो', 'फिर बोलो',
  ];
  static const _kSos = [
    'sos', 'emergency',
    'एसओएस', 'आपातकाल', 'आपात',
  ];

  static const _kTime = ['time', 'clock', 'समय', 'टाइम', 'बजे'];
  static const _kBattery = ['battery', 'power', 'बैटरी'];
  static const _kLocation = [
    'where', 'location', 'address',
    'कहाँ', 'कहां', 'स्थान', 'लोकेशन', 'पता',
  ];

  static const _kDescribe = [
    'describe', 'see', 'look',
    'बताओ', 'देखो', 'वर्णन', 'क्या दिख',
  ];
  static const _kObstacles = [
    'obstacle', 'ahead', 'front',
    'बाधा', 'सामने', 'रुकावट',
  ];

  static const _kFaster = [
    'faster', 'speed up', 'quick',
    'तेज़', 'तेज', 'जल्दी',
  ];
  static const _kSlower = ['slower', 'slow down', 'धीरे', 'धीमा'];

  static const _kPause = [
    'pause', 'quiet', 'mute',
    'चुप', 'शांत', 'विराम',
  ];
  static const _kResume = [
    'resume', 'unmute', 'speak',
    'जारी', 'बोलो', 'फिर बोल',
  ];

  static const _kNearby = [
    'nearby', 'around', 'places',
    'आसपास', 'आस-पास', 'पास में', 'नज़दीक', 'नजदीक',
  ];
  static const _kStatus = ['status', 'स्थिति', 'हालत'];

  /// Releases the microphone without destroying this notifier.
  ///
  /// Deliberately NOT `dispose()`. This is a process-lifetime singleton, so
  /// calling ChangeNotifier.dispose() on it is unrecoverable: every later
  /// notifyListeners() throws and the factory keeps returning the same dead
  /// instance, so voice commands stay broken for the rest of the process.
  /// HomeScreen tears its services down whenever it is disposed - including on
  /// every hot restart - which is exactly when that used to happen.
  Future<void> release() async {
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('Error releasing speech recogniser: $e');
    }
    _isListening = false;
  }

  /// Words a distressed user is likely to reach for to call off an alert.
  ///
  /// Bilingual for the same reason as the routing table above, and more
  /// urgently: this is the phrase list standing between a false positive and
  /// an unwanted call to emergency services.
  static bool _isCancelPhrase(String command) {
    const phrases = [
      'cancel',
      'stop',
      'abort',
      'never mind',
      'nevermind',
      'i am fine',
      "i'm fine",
      'i am ok',
      "i'm ok",
      'i am okay',
      "i'm okay",
      'false alarm',
      'no emergency',
      // Hindi
      'रद्द',
      'रोको',
      'रुको',
      'बंद करो',
      'ठीक हूँ',
      'ठीक हूं',
      'मैं ठीक',
      'रहने दो',
      'गलती',
      'कोई आपातकाल नहीं',
    ];
    return phrases.any(command.contains);
  }

  // The spoken command list lives in the ARB files as `voiceHelpList`, not
  // here: a hardcoded English sentence in a service is unreachable by the
  // localization tests and drifted out of step with the routing table above.
}
