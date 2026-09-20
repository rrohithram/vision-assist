import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/sms_service.dart';
import '../services/sos_service.dart';

/// The panel shown once an SOS has been dispatched.
///
/// Reports what actually reached whom - a message handed to the radio is not
/// the same as one still sitting in a composer - and offers the manual
/// fallbacks (call, re-send, share location) for when it did not.
class SosResultDialog extends StatefulWidget {
  final SosResult result;
  final VoidCallback onClose;

  const SosResultDialog({
    super.key,
    required this.result,
    required this.onClose,
  });

  @override
  State<SosResultDialog> createState() => _SosResultDialogState();
}

class _SosResultDialogState extends State<SosResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final SosService _sos = SosService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationUrl = widget.result.locationData?['googleMapsUrl'] as String?;
    final latitude = widget.result.locationData?['latitude'] as double?;
    final longitude = widget.result.locationData?['longitude'] as double?;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red[900]!,
              Colors.red[800]!,
              Colors.red[900]!,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with animated icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.sosEmergencyHeading,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.result.success
                        ? AppLocalizations.of(context)!.sosHelpRequested
                        : AppLocalizations.of(context)!.sosAlertFailed,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emergency Summary
                    if (widget.result.emergencySummary != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.result.emergencySummary!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Status Section
                    _buildStatusSection(),

                    // Location Section
                    if (locationUrl != null || (latitude != null && longitude != null)) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.sosLocationHeading,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (locationUrl != null)
                              SelectableText(
                                locationUrl,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              )
                            else if (latitude != null && longitude != null)
                              SelectableText(
                                AppLocalizations.of(context)!.sosCoordinates(
                                  latitude.toStringAsFixed(6),
                                  longitude.toStringAsFixed(6),
                                ),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),

            // Footer with close button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: widget.onClose,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.actionClose,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    final l10n = AppLocalizations.of(context)!;
    final List<Widget> statusItems = [];

    // Call status
    if (widget.result.callMade == true) {
      statusItems.add(_buildStatusItem(
        icon: Icons.phone,
        label: l10n.sosEmergencyCallLabel,
        status: l10n.sosCallMade,
        color: Colors.green,
      ));
    } else if (widget.result.callMade == false) {
      statusItems.add(_buildStatusItem(
        icon: Icons.phone_disabled,
        label: l10n.sosEmergencyCallLabel,
        status: l10n.sosCallNotMade,
        color: Colors.orange,
      ));
    }

    // Message status, read from the structured result rather than parsed back
    // out of a display string.
    for (final delivery in widget.result.smsDeliveries) {
      final Color color;
      final String status;
      switch (delivery.result.status) {
        case SmsDeliveryStatus.sentDirectly:
          color = Colors.green;
          status = l10n.sosSmsSent;
        case SmsDeliveryStatus.composerOpened:
          color = Colors.orange;
          status = l10n.sosSmsNeedsSend;
        case SmsDeliveryStatus.failed:
          color = Colors.red;
          status = l10n.sosSmsFailed;
      }

      statusItems.add(_buildStatusItem(
        icon: Icons.message,
        label: l10n.sosSmsTo(delivery.contactName),
        status: status,
        color: color,
      ));
    }

    if (statusItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.sosStatusHeading,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...statusItems,
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String status,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Call button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await _sos.makeEmergencyCall();
            },
            icon: const Icon(Icons.phone, color: Colors.white, size: 24),
            label: Text(
              AppLocalizations.of(context)!.sosCallNumber(_sos.emergencyNumber),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // SMS button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              if (_sos.contacts.isNotEmpty) {
                await _sos.sendSMS(
                  _sos.contacts.first.phoneNumber,
                  widget.result.smsMessage ?? 'Emergency!',
                );
              }
            },
            icon: const Icon(Icons.message, color: Colors.white, size: 24),
            label: Text(
              AppLocalizations.of(context)!.sosSendSms,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
          ),
        ),
      ],
    );
  }
}
