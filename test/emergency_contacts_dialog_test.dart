import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gabn2/l10n/app_localizations.dart';
import 'package:gabn2/screens/emergency_contacts_dialog.dart';
import 'package:gabn2/services/sos_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers the contacts dialog lifted out of HomeScreen.
///
/// Contacts are who an SOS alert actually reaches, so adding and removing them
/// has to work, and the list has to refresh in place rather than by re-showing
/// itself recursively.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late SosService sos;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );
    sos = SosService();
    sos.contactsForTestOnlyClearMemory();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      null,
    );
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    List<String>? announcements,
    String languageCode = 'en',
  }) async {
    await tester.pumpWidget(MaterialApp(
      locale: Locale(languageCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hi')],
      home: Scaffold(
        body: EmergencyContactsDialog(
          onAnnounce: (message) => announcements?.add(message),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('tells the user when no contacts are saved',
      (WidgetTester tester) async {
    await pumpDialog(tester);

    expect(find.textContaining('No contacts yet'), findsOneWidget);
  });

  testWidgets('lists saved contacts with their numbers',
      (WidgetTester tester) async {
    await sos.addContact(
        EmergencyContact(name: 'Ada', phoneNumber: '555000111'));

    await pumpDialog(tester);

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('555000111'), findsOneWidget);
  });

  testWidgets('removing a contact updates the list in place and announces it',
      (WidgetTester tester) async {
    await sos.addContact(
        EmergencyContact(name: 'Ada', phoneNumber: '555000111'));
    final announcements = <String>[];

    await pumpDialog(tester, announcements: announcements);
    expect(find.text('Ada'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('Ada'), findsNothing);
    expect(sos.contacts, isEmpty);
    expect(announcements.single, contains('Ada'));
  });

  testWidgets('adding a contact requires both a name and a number',
      (WidgetTester tester) async {
    await pumpDialog(tester);

    await tester.tap(find.text('Add contact'));
    await tester.pumpAndSettle();

    // Submit empty: the dialog must stay open and no contact is created.
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(sos.contacts, isEmpty);
    expect(find.text('Add Emergency Contact'), findsOneWidget);
  });

  testWidgets('adding a valid contact saves and announces it',
      (WidgetTester tester) async {
    final announcements = <String>[];
    await pumpDialog(tester, announcements: announcements);

    await tester.tap(find.text('Add contact'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Grace');
    await tester.enterText(find.byType(TextFormField).last, '555222333');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(sos.contacts, hasLength(1));
    expect(sos.contacts.single.name, 'Grace');
    expect(sos.contacts.single.phoneNumber, '555222333');
    expect(announcements, isNotEmpty);
  });

  testWidgets('renders in Hindi without falling back to English',
      (WidgetTester tester) async {
    await pumpDialog(tester, languageCode: 'hi');

    expect(find.text('Emergency Contacts'), findsNothing);
    expect(find.text('आपातकालीन संपर्क'), findsOneWidget);
  });

  testWidgets('delete buttons are labelled per contact for screen readers',
      (WidgetTester tester) async {
    await sos.addContact(
        EmergencyContact(name: 'Ada', phoneNumber: '555000111'));

    await pumpDialog(tester);

    final iconButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(iconButton.tooltip, contains('Ada'),
        reason: 'an unlabelled delete icon says nothing about which contact');
  });
}
