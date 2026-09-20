import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'call_state_service.dart';
import 'location_service.dart';
import 'gemini_service.dart';
import 'sms_service.dart';
import 'tts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

/// The phrases SosService speaks, supplied by the UI layer.
///
/// The service has no BuildContext and so cannot reach AppLocalizations
/// itself. HomeScreen injects these whenever the locale resolves; the English
/// defaults keep the service usable in tests and before that happens.
class SosStrings {
  final String Function(String seconds) sequenceActivated;
  final String Function(String seconds) secondsRemaining;
  final String sequenceCancelled;
  final String spokenCallMessage;

  const SosStrings({
    required this.sequenceActivated,
    required this.secondsRemaining,
    required this.sequenceCancelled,
    required this.spokenCallMessage,
  });

  static String _defaultActivated(String seconds) =>
      'Emergency sequence activated. Calling in $seconds seconds. '
      'To cancel, tap anywhere on the screen or press a volume button.';

  static String _defaultSeconds(String seconds) => '$seconds seconds';

  static const SosStrings fallback = SosStrings(
    sequenceActivated: _defaultActivated,
    secondsRemaining: _defaultSeconds,
    sequenceCancelled: 'Emergency sequence cancelled.',
    spokenCallMessage: 'Hello. This is an automated emergency call. '
        'The user may be unable to respond. Please send help. '
        'Location details sent via text message.',
  );
}

/// Where the SOS flow currently is.
enum SosPhase {
  /// Nothing happening.
  idle,

  /// Counting down before alerting. Cancellable.
  countdown,

  /// Contacting help right now (building the message, sending, dialling).
  dispatching,

  /// Help has been contacted; the spoken loop may still be running.
  alerting,
}

/// SOS service for emergency situations.
/// Handles emergency calls, SMS, and context generation.
class SosService extends ChangeNotifier {
  static final SosService _instance = SosService._internal();
  factory SosService() => _instance;
  SosService._internal();

  final LocationService _location = LocationService();
  final GeminiService _gemini = GeminiService();
  final TtsService _tts = TtsService();
  final SmsService _sms = SmsService();
  final CallStateService _callState = CallStateService();

  // Emergency contacts
  List<EmergencyContact> _emergencyContacts = [];

  // Dialled only when no emergency contact is saved. Varies by region, so it
  // is persisted like any other setting rather than hardcoded.
  String _emergencyNumber = AppConfig.emergencyNumber;

  SosPhase _phase = SosPhase.idle;
  int _currentCountdown = _countdownSeconds;
  Timer? _sosTimer;
  Timer? _speakTimer;
  Timer? _fallbackSpeakTimer;

  static const int _countdownSeconds = 10;
  static const String _contactsKey = 'emergency_contacts';
  static const String _emergencyNumberKey = 'emergency_number';

  /// Localized phrases, injected by the UI layer.
  SosStrings strings = SosStrings.fallback;

  SosPhase get phase => _phase;

  /// True while a countdown is running - the window in which the user can
  /// still call it off. Drives the cancel overlay.
  bool get isCountdownActive => _phase == SosPhase.countdown;

  /// True from the moment a sequence starts until it is cancelled or stood
  /// down, including while help is being contacted.
  bool get isSosActive => _phase != SosPhase.idle;

  /// True once help has actually been contacted.
  bool get isAlerting => _phase == SosPhase.alerting;

  /// Whether anything is cancellable right now. A dispatch in flight is still
  /// worth standing down, because the spoken loop and repeat sends continue.
  bool get isCancellable => _phase != SosPhase.idle;

  int get currentCountdown => _currentCountdown;

  /// Number dialled when no contact is saved.
  String get emergencyNumber => _emergencyNumber;

  /// Overrides the fallback emergency number. Persists immediately.
  Future<void> setEmergencyNumber(String number) async {
    final trimmed = number.trim();
    if (trimmed.isEmpty) return;

    _emergencyNumber = trimmed;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emergencyNumberKey, trimmed);
    } catch (e) {
      debugPrint('Could not save emergency number: $e');
    }
  }

  /// Loads saved emergency contacts from storage.
  ///
  /// Contacts used to live only in memory, and initialize() overwrote them
  /// with a hardcoded '112' on every launch - so a contact added in settings
  /// was gone on restart, and the alert SMS went to an emergency-services
  /// number that does not receive text messages in most countries.
  ///
  /// [contacts] seeds the list only when nothing has been saved yet.
  Future<void> initialize({
    List<EmergencyContact>? contacts,
    String? emergencyNumber,
  }) async {
    if (emergencyNumber != null) {
      _emergencyNumber = emergencyNumber;
    }

    await _loadEmergencyNumber();
    await _loadContacts();

    if (_emergencyContacts.isEmpty && contacts != null && contacts.isNotEmpty) {
      _emergencyContacts = List.of(contacts);
      await _persistContacts();
    }

    notifyListeners();
  }

  Future<void> _loadEmergencyNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_emergencyNumberKey);
      if (stored != null && stored.trim().isNotEmpty) {
        _emergencyNumber = stored.trim();
      }
    } catch (e) {
      debugPrint('Could not load emergency number: $e');
    }
  }

  Future<void> _loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_contactsKey);
      if (stored == null) return;

      final decoded = json.decode(stored);
      if (decoded is! List) return;

      _emergencyContacts = decoded
          .whereType<Map>()
          .map((e) => EmergencyContact.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Could not load emergency contacts: $e');
    }
  }

  Future<void> _persistContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _contactsKey,
        json.encode(_emergencyContacts.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Could not save emergency contacts: $e');
    }
  }

  /// Pick a contact from the phone storage
  Future<EmergencyContact?> pickContact() async {
    debugPrint('Picking contact...');
    try {
      var status = await Permission.contacts.request();
      debugPrint('Contact Permission Status: $status');

      if (status.isPermanentlyDenied) {
        openAppSettings();
        return null;
      }

      if (status.isGranted) {
        final contact = await FlutterContacts.openExternalPick();
        debugPrint('Picked Contact: ${contact?.displayName}');

        if (contact != null) {
          String? phone;
          if (contact.phones.isNotEmpty) {
            // Prefer mobile, then whatever is first.
            phone = contact.phones
                .firstWhere(
                  (p) => p.label == PhoneLabel.mobile,
                  orElse: () => contact.phones.first,
                )
                .number;
          }

          if (phone != null) {
            final ec = EmergencyContact(
              name: contact.displayName,
              phoneNumber: phone,
            );
            addContact(ec);
            return ec;
          }
          debugPrint('No phone number found for contact');
        }
      }
    } catch (e) {
      debugPrint('Error picking contact: $e');
    }
    return null;
  }

  /// Start the SOS countdown.
  ///
  /// Returns false when a sequence is already running, so callers can tell the
  /// difference between "started" and "ignored".
  Future<bool> startSosSequence({String? context}) async {
    if (_phase != SosPhase.idle) return false;
    _phase = SosPhase.countdown;
    _currentCountdown = _countdownSeconds;
    notifyListeners();

    // Only promise routes that actually work without sight. A tap anywhere and
    // any volume button both reach cancelSos(); voice needs the mic to already
    // be listening, so it is not advertised as the primary route.
    _tts.speak(strings.sequenceActivated('$_countdownSeconds'));

    _sosTimer?.cancel();
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Guard against a cancel that raced this tick.
      if (_phase != SosPhase.countdown) {
        timer.cancel();
        return;
      }

      _currentCountdown--;
      notifyListeners();

      if (_currentCountdown > 0) {
        if (_currentCountdown == 5) {
          _tts.speak(strings.secondsRemaining('5'));
        }
        if (_currentCountdown <= 3) _tts.speak('$_currentCountdown');
      } else {
        timer.cancel();
        _triggerAutomatedSOS(context: context);
      }
    });

    return true;
  }

  /// Cancel an in-flight SOS - countdown, spoken loop and all.
  ///
  /// Safe to call at any time; a no-op when nothing is running.
  bool cancelSos() {
    if (_phase == SosPhase.idle) return false;

    _phase = SosPhase.idle;
    _currentCountdown = _countdownSeconds;
    _sosTimer?.cancel();
    _sosTimer = null;
    _speakTimer?.cancel();
    _speakTimer = null;
    _fallbackSpeakTimer?.cancel();
    _fallbackSpeakTimer = null;
    unawaited(_callState.stopListening());

    _tts.speak(strings.sequenceCancelled);
    notifyListeners();
    return true;
  }

  /// Stand down after help has been contacted, without the "cancelled"
  /// announcement. Lets a later emergency start a fresh sequence.
  void standDown() {
    if (_phase == SosPhase.idle) return;
    _phase = SosPhase.idle;
    _currentCountdown = _countdownSeconds;
    _sosTimer?.cancel();
    _sosTimer = null;
    _speakTimer?.cancel();
    _speakTimer = null;
    _fallbackSpeakTimer?.cancel();
    _fallbackSpeakTimer = null;
    unawaited(_callState.stopListening());
    notifyListeners();
  }

  Future<void> _triggerAutomatedSOS({String? context}) async {
    if (_phase != SosPhase.countdown) return;
    _phase = SosPhase.dispatching;
    notifyListeners();

    await triggerSOS(
      additionalContext: context,
      fallDetected: context?.toLowerCase().contains('fall') ?? false,
      shouldCall: true,
      shouldText: true,
    );

    // Only advance to alerting if we were not cancelled mid-dispatch.
    if (_phase == SosPhase.dispatching) {
      _phase = SosPhase.alerting;
      notifyListeners();
    }
  }

  /// Add an emergency contact. Persists immediately.
  Future<void> addContact(EmergencyContact contact) async {
    if (_emergencyContacts.any((c) => c.phoneNumber == contact.phoneNumber)) {
      return;
    }
    _emergencyContacts.add(contact);
    notifyListeners();
    await _persistContacts();
  }

  /// Remove an emergency contact. Persists immediately.
  Future<void> removeContact(String phoneNumber) async {
    _emergencyContacts.removeWhere((c) => c.phoneNumber == phoneNumber);
    notifyListeners();
    await _persistContacts();
  }

  /// Get all emergency contacts
  List<EmergencyContact> get contacts => List.unmodifiable(_emergencyContacts);

  /// Drops the in-memory list without touching storage, so a test can simulate
  /// a fresh launch against this singleton.
  @visibleForTesting
  void contactsForTestOnlyClearMemory() => _emergencyContacts = [];

  /// Trigger SOS - generates message and optionally calls/texts
  Future<SosResult> triggerSOS({
    String? additionalContext,
    bool? fallDetected,
    List<String>? detectedObstacles,
    bool shouldCall = false,
    bool shouldText = true,
  }) async {
    try {
      final locationData = await _location.getLocationForSOS();

      String emergencySummary = await _gemini.generateEmergencySummary(
        location: locationData,
        lastInstruction: additionalContext,
        fallDetected: fallDetected,
        detectedObstacles: detectedObstacles,
      );

      String smsMessage = _buildSmsMessage(emergencySummary, locationData);

      // Send SMS to all emergency contacts.
      List<String> smsResults = [];
      final smsDeliveries = <SosSmsDelivery>[];
      int deliveredCount = 0;
      if (shouldText && _emergencyContacts.isNotEmpty) {
        final numbers =
            _emergencyContacts.map((c) => c.phoneNumber).toList(growable: false);
        final results = await _sms.sendToAll(numbers, smsMessage);

        for (var i = 0; i < results.length; i++) {
          final contact = _emergencyContacts.firstWhere(
            (c) => c.phoneNumber == results[i].phoneNumber,
            orElse: () => _emergencyContacts[i],
          );
          smsResults.add(results[i].describe(contact.name));
          smsDeliveries.add(SosSmsDelivery(
            contactName: contact.name,
            result: results[i],
          ));
          if (results[i].reachedRecipient) deliveredCount++;
        }
      }

      // Make emergency call if requested.
      bool callMade = false;
      if (shouldCall) {
        if (_emergencyContacts.isNotEmpty) {
          callMade = await makeEmergencyCall(
            phoneNumber: _emergencyContacts.first.phoneNumber,
          );
        } else {
          callMade = await makeEmergencyCall();
        }

        if (callMade) {
          _startSpeakingLoop(emergencySummary);
        }
      }

      return SosResult(
        success: true,
        emergencySummary: emergencySummary,
        locationData: locationData,
        smsMessage: smsMessage,
        smsResults: smsResults,
        smsDeliveries: smsDeliveries,
        messagesDelivered: deliveredCount,
        callMade: callMade,
      );
    } catch (e) {
      debugPrint('SOS error: $e');
      return SosResult(success: false, error: e.toString());
    }
  }

  /// Build SMS message with location
  String _buildSmsMessage(String summary, Map<String, dynamic> locationData) {
    StringBuffer message = StringBuffer();
    message.writeln('EMERGENCY ALERT');
    message.writeln();
    message.writeln(summary);
    message.writeln();

    if (locationData['googleMapsUrl'] != null) {
      message.writeln('Location: ${locationData['googleMapsUrl']}');
    } else if (locationData['latitude'] != null) {
      message.writeln(
        'Coordinates: ${locationData['latitude']}, ${locationData['longitude']}',
      );
    }

    message.writeln();
    message.writeln(
      'This is an automated emergency message from the Accessibility Navigator app.',
    );

    return message.toString();
  }

  /// Send a single SMS. Prefers a direct send over the composer.
  Future<bool> sendSMS(String phoneNumber, String message) async {
    final result = await _sms.send(phoneNumber, message);
    return result.status != SmsDeliveryStatus.failed;
  }

  /// Make emergency call
  Future<bool> makeEmergencyCall({String? phoneNumber}) async {
    try {
      final number = phoneNumber ?? _emergencyNumber;
      final Uri callUri = Uri(scheme: 'tel', path: number);

      var status = await Permission.phone.request();
      if (status.isGranted) {
        bool? res = await FlutterPhoneDirectCaller.callNumber(number);
        if (res == true) return true;
      }

      // Fall back to handing the dialler to the OS.
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Call error: $e');
      return false;
    }
  }

  /// Call first emergency contact
  Future<bool> callFirstContact() async {
    if (_emergencyContacts.isEmpty) {
      return makeEmergencyCall();
    }
    return makeEmergencyCall(phoneNumber: _emergencyContacts.first.phoneNumber);
  }

  /// Repeat a spoken message so whoever answers the call hears the situation.
  ///
  /// Starts as soon as the call is actually answered - detected via
  /// [CallStateService] - rather than assuming pickup after a fixed delay,
  /// which used to talk over a call that was still ringing or reached
  /// voicemail. Falls back to a fixed delay if the platform cannot report
  /// call state (permission denied, unsupported device).
  void _startSpeakingLoop(String summary) {
    _speakTimer?.cancel();
    _fallbackSpeakTimer?.cancel();

    final String msg = strings.spokenCallMessage;
    var started = false;

    void beginSpeaking() {
      if (started) return;
      started = true;
      unawaited(_callState.stopListening());

      if (_phase == SosPhase.idle) return;

      debugPrint('Starting emergency voice loop');
      _tts.speak(msg);

      _speakTimer?.cancel();
      _speakTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
        if (_phase == SosPhase.idle) {
          timer.cancel();
          _speakTimer = null;
          return;
        }
        _tts.speak(msg);
      });
    }

    _callState.onCallAnswered = beginSpeaking;
    unawaited(_callState.startListening());

    // Covers devices/permission states where call-answered never arrives.
    _fallbackSpeakTimer = Timer(const Duration(seconds: 15), beginSpeaking);
  }

  /// Quick SOS - just sends SMS to all contacts
  Future<bool> quickSOS({String? additionalContext}) async {
    final result = await triggerSOS(
      additionalContext: additionalContext,
      shouldCall: false,
      shouldText: true,
    );
    return result.success;
  }

  /// Full SOS - sends SMS and makes call
  Future<bool> fullSOS({String? additionalContext}) async {
    final result = await triggerSOS(
      additionalContext: additionalContext,
      shouldCall: true,
      shouldText: true,
    );
    return result.success;
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    _speakTimer?.cancel();
    _fallbackSpeakTimer?.cancel();
    unawaited(_callState.stopListening());
    super.dispose();
  }
}

/// Emergency contact model
class EmergencyContact {
  final String name;
  final String phoneNumber;
  final String? relationship;

  EmergencyContact({
    required this.name,
    required this.phoneNumber,
    this.relationship,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phoneNumber': phoneNumber,
        'relationship': relationship,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        name: json['name'] as String,
        phoneNumber: json['phoneNumber'] as String,
        relationship: json['relationship'] as String?,
      );
}

/// One emergency message, and what became of it.
class SosSmsDelivery {
  final String contactName;
  final SmsResult result;

  const SosSmsDelivery({required this.contactName, required this.result});

  bool get delivered => result.reachedRecipient;
  bool get awaitingUser => result.status == SmsDeliveryStatus.composerOpened;
}

/// Result of SOS trigger
class SosResult {
  final bool success;
  final String? error;
  final String? emergencySummary;
  final Map<String, dynamic>? locationData;
  final String? smsMessage;
  final List<String>? smsResults;

  /// Per-contact delivery outcome, paired with the contact it was for.
  /// The UI used to re-parse [smsResults] by splitting on ':' and comparing
  /// against the word "Sent", which silently stopped matching when the wording
  /// changed - every delivered message then rendered as a failure.
  final List<SosSmsDelivery> smsDeliveries;

  /// How many contacts actually received the message without needing a tap.
  final int messagesDelivered;
  final bool? callMade;

  SosResult({
    required this.success,
    this.error,
    this.emergencySummary,
    this.locationData,
    this.smsMessage,
    this.smsResults,
    this.smsDeliveries = const [],
    this.messagesDelivered = 0,
    this.callMade,
  });
}
