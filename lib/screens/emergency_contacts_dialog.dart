import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../services/sos_service.dart';

/// Manages the people an SOS alert reaches.
///
/// Lifted out of HomeScreen, where it was two inline builders that leaked a
/// TextEditingController on every open and re-showed themselves recursively
/// after each removal. It listens to SosService instead, so the list refreshes
/// in place.
class EmergencyContactsDialog extends StatefulWidget {
  /// Announced to the user after a contact is added or removed.
  final void Function(String message)? onAnnounce;

  const EmergencyContactsDialog({super.key, this.onAnnounce});

  static Future<void> show(
    BuildContext context, {
    void Function(String message)? onAnnounce,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => EmergencyContactsDialog(onAnnounce: onAnnounce),
    );
  }

  @override
  State<EmergencyContactsDialog> createState() =>
      _EmergencyContactsDialogState();
}

class _EmergencyContactsDialogState extends State<EmergencyContactsDialog> {
  final SosService _sos = SosService();
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _sos.addListener(_onContactsChanged);
  }

  @override
  void dispose() {
    _sos.removeListener(_onContactsChanged);
    super.dispose();
  }

  void _onContactsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _remove(EmergencyContact contact, AppLocalizations l10n) async {
    await _sos.removeContact(contact.phoneNumber);
    widget.onAnnounce?.call(l10n.contactRemoved(contact.name));
  }

  Future<void> _add(AppLocalizations l10n) async {
    final contact = await showDialog<EmergencyContact>(
      context: context,
      builder: (_) => const _AddContactDialog(),
    );
    if (contact == null) return;

    await _sos.addContact(contact);
    widget.onAnnounce?.call(l10n.contactAdded);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contacts = _sos.contacts;

    return AlertDialog(
      title: Text(
        l10n.emergencyContactsTitle,
        style: TextStyle(fontSize: _settings.textSize),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contacts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.noContactsYet,
                  style: TextStyle(fontSize: _settings.textSize * 0.9),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(contact.name),
                      subtitle: Text(contact.phoneNumber),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        // Named for screen readers: an unlabelled delete icon
                        // gives no clue which contact it removes.
                        tooltip: l10n.removeContactLabel(contact.name),
                        onPressed: () => _remove(contact, l10n),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _add(l10n),
                icon: const Icon(Icons.add),
                label: Text(l10n.addContactButton),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionClose),
        ),
      ],
    );
  }
}

/// Collects a name and number. Returns the new contact, or null if cancelled.
class _AddContactDialog extends StatefulWidget {
  const _AddContactDialog();

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // The inline version of this dialog never disposed its controllers.
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.pop(
      context,
      EmergencyContact(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.addEmergencyContactTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.contactNameLabel),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.contactNeedsNameAndNumber
                  : null,
            ),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: l10n.contactPhoneLabel),
              onFieldSubmitted: (_) => _submit(),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.contactNeedsNameAndNumber
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(l10n.actionAdd),
        ),
      ],
    );
  }
}
