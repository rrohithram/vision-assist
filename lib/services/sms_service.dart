import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Outcome of an attempt to deliver an emergency SMS.
enum SmsDeliveryStatus {
  /// Handed to the radio without user interaction. The only status that is
  /// safe to rely on when the user may be incapacitated.
  sentDirectly,

  /// The messaging composer was opened and is waiting on a tap from the user.
  composerOpened,

  /// Nothing was delivered.
  failed,
}

class SmsResult {
  final String phoneNumber;
  final SmsDeliveryStatus status;
  final String? error;

  const SmsResult({
    required this.phoneNumber,
    required this.status,
    this.error,
  });

  bool get reachedRecipient => status == SmsDeliveryStatus.sentDirectly;

  /// Spoken/written description. Deliberately distinguishes "sent" from
  /// "waiting for you to press send" - conflating the two is what made the
  /// previous SOS path report success when nothing had gone out.
  String describe(String contactName) {
    switch (status) {
      case SmsDeliveryStatus.sentDirectly:
        return '$contactName: sent';
      case SmsDeliveryStatus.composerOpened:
        return '$contactName: needs you to press send';
      case SmsDeliveryStatus.failed:
        return '$contactName: failed';
    }
  }
}

/// Sends SMS directly through the platform radio.
///
/// Emergency alerts have to go out when the user cannot act - after a fall,
/// the composer-based `sms:` intent delivers nothing. This sends in the
/// background via SEND_SMS and only falls back to the composer when that
/// permission is unavailable.
class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  static const MethodChannel _channel = MethodChannel('com.gabn2/sms');

  bool? _cachedPermission;

  /// Whether direct (no-interaction) sending is currently possible.
  Future<bool> canSendDirectly() async {
    if (!_isSupportedPlatform) return false;
    try {
      final granted = await _channel.invokeMethod<bool>('canSendSms');
      _cachedPermission = granted ?? false;
      return _cachedPermission!;
    } on PlatformException catch (e) {
      debugPrint('SMS capability check failed: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Requests SEND_SMS. Call this ahead of an emergency, not during one.
  Future<bool> requestPermission() async {
    if (!_isSupportedPlatform) return false;
    final status = await Permission.sms.request();
    _cachedPermission = status.isGranted;
    return status.isGranted;
  }

  /// Delivers [message] to [phoneNumber], preferring a direct send.
  Future<SmsResult> send(String phoneNumber, String message) async {
    if (_isSupportedPlatform) {
      final granted = _cachedPermission ?? await canSendDirectly();
      if (granted) {
        try {
          await _channel.invokeMethod<bool>('sendSms', {
            'phoneNumber': phoneNumber,
            'message': message,
          });
          return SmsResult(
            phoneNumber: phoneNumber,
            status: SmsDeliveryStatus.sentDirectly,
          );
        } on PlatformException catch (e) {
          debugPrint('Direct SMS to $phoneNumber failed: ${e.code} ${e.message}');
          // Fall through to the composer rather than giving up entirely.
        } on MissingPluginException {
          debugPrint('SMS channel unavailable; falling back to composer.');
        }
      }
    }

    return _openComposer(phoneNumber, message);
  }

  /// Delivers the same message to several recipients.
  ///
  /// When direct sending is unavailable only the first recipient gets a
  /// composer - launching several in a row just races them against each other,
  /// and the user can only act on one anyway.
  Future<List<SmsResult>> sendToAll(
    List<String> phoneNumbers,
    String message,
  ) async {
    final results = <SmsResult>[];
    if (phoneNumbers.isEmpty) return results;

    final canSendDirect = _isSupportedPlatform &&
        (_cachedPermission ?? await canSendDirectly());

    if (canSendDirect) {
      for (final number in phoneNumbers) {
        results.add(await send(number, message));
      }
      return results;
    }

    results.add(await _openComposer(phoneNumbers.first, message));
    for (final number in phoneNumbers.skip(1)) {
      results.add(SmsResult(
        phoneNumber: number,
        status: SmsDeliveryStatus.failed,
        error: 'Only one message composer can be opened at a time',
      ));
    }
    return results;
  }

  Future<SmsResult> _openComposer(String phoneNumber, String message) async {
    try {
      final uri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return SmsResult(
          phoneNumber: phoneNumber,
          status: SmsDeliveryStatus.composerOpened,
        );
      }
      return SmsResult(
        phoneNumber: phoneNumber,
        status: SmsDeliveryStatus.failed,
        error: 'No messaging app available',
      );
    } catch (e) {
      debugPrint('SMS composer error: $e');
      return SmsResult(
        phoneNumber: phoneNumber,
        status: SmsDeliveryStatus.failed,
        error: e.toString(),
      );
    }
  }

  bool get _isSupportedPlatform =>
      defaultTargetPlatform == TargetPlatform.android;
}
