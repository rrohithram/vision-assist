import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Accessibility Navigator'**
  String get appTitle;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @readyCameraActive.
  ///
  /// In en, this message translates to:
  /// **'Ready. Camera active.'**
  String get readyCameraActive;

  /// No description provided for @cameraInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Camera initialization failed. Please check permissions.'**
  String get cameraInitFailed;

  /// No description provided for @errorStartingApp.
  ///
  /// In en, this message translates to:
  /// **'Error starting app. Please restart.'**
  String get errorStartingApp;

  /// No description provided for @appReadySpeak.
  ///
  /// In en, this message translates to:
  /// **'App ready. Camera is active and scanning for obstacles.'**
  String get appReadySpeak;

  /// No description provided for @cameraEnabled.
  ///
  /// In en, this message translates to:
  /// **'Camera enabled'**
  String get cameraEnabled;

  /// No description provided for @cameraDisabled.
  ///
  /// In en, this message translates to:
  /// **'Camera disabled'**
  String get cameraDisabled;

  /// No description provided for @cameraScanning.
  ///
  /// In en, this message translates to:
  /// **'Camera enabled. Scanning for obstacles.'**
  String get cameraScanning;

  /// No description provided for @navigationStarted.
  ///
  /// In en, this message translates to:
  /// **'Starting navigation'**
  String get navigationStarted;

  /// No description provided for @navigationStopped.
  ///
  /// In en, this message translates to:
  /// **'Navigation stopped'**
  String get navigationStopped;

  /// No description provided for @navigationStoppedCameraActive.
  ///
  /// In en, this message translates to:
  /// **'Navigation stopped. Camera active.'**
  String get navigationStoppedCameraActive;

  /// No description provided for @youHaveArrived.
  ///
  /// In en, this message translates to:
  /// **'You have arrived.'**
  String get youHaveArrived;

  /// No description provided for @sosActivated.
  ///
  /// In en, this message translates to:
  /// **'SOS activated.'**
  String get sosActivated;

  /// No description provided for @sosEmergencyHelpRequested.
  ///
  /// In en, this message translates to:
  /// **'Emergency help requested.'**
  String get sosEmergencyHelpRequested;

  /// No description provided for @autoDescriptionEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto description enabled'**
  String get autoDescriptionEnabled;

  /// No description provided for @autoDescriptionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Auto description disabled'**
  String get autoDescriptionDisabled;

  /// No description provided for @autoDescriptionPaused.
  ///
  /// In en, this message translates to:
  /// **'Auto description paused'**
  String get autoDescriptionPaused;

  /// No description provided for @autoDescriptionResumed.
  ///
  /// In en, this message translates to:
  /// **'Auto description resumed'**
  String get autoDescriptionResumed;

  /// No description provided for @timeIs.
  ///
  /// In en, this message translates to:
  /// **'It is {hour}:{minute} {suffix}'**
  String timeIs(String hour, String minute, String suffix);

  /// No description provided for @batteryLevelIs.
  ///
  /// In en, this message translates to:
  /// **'Battery level is {level}.'**
  String batteryLevelIs(String level);

  /// No description provided for @checkingLocation.
  ///
  /// In en, this message translates to:
  /// **'Checking location...'**
  String get checkingLocation;

  /// No description provided for @youAreAtCoordinates.
  ///
  /// In en, this message translates to:
  /// **'You are at latitude {lat} and longitude {lng}.'**
  String youAreAtCoordinates(String lat, String lng);

  /// No description provided for @unableToGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Unable to get current location.'**
  String get unableToGetLocation;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Location error.'**
  String get locationError;

  /// No description provided for @flashlightOn.
  ///
  /// In en, this message translates to:
  /// **'Flashlight on'**
  String get flashlightOn;

  /// No description provided for @flashlightOff.
  ///
  /// In en, this message translates to:
  /// **'Flashlight off'**
  String get flashlightOff;

  /// No description provided for @speechSpeedIncreased.
  ///
  /// In en, this message translates to:
  /// **'Speech speed increased.'**
  String get speechSpeedIncreased;

  /// No description provided for @speechSpeedDecreased.
  ///
  /// In en, this message translates to:
  /// **'Speech speed decreased.'**
  String get speechSpeedDecreased;

  /// No description provided for @alreadyPaused.
  ///
  /// In en, this message translates to:
  /// **'Already paused.'**
  String get alreadyPaused;

  /// No description provided for @alreadyActive.
  ///
  /// In en, this message translates to:
  /// **'Already active.'**
  String get alreadyActive;

  /// No description provided for @cameraIsOn.
  ///
  /// In en, this message translates to:
  /// **'Camera is on'**
  String get cameraIsOn;

  /// No description provided for @cameraIsOff.
  ///
  /// In en, this message translates to:
  /// **'Camera is off'**
  String get cameraIsOff;

  /// No description provided for @navigationIsActive.
  ///
  /// In en, this message translates to:
  /// **'Navigation is active'**
  String get navigationIsActive;

  /// No description provided for @navigationIsNotActive.
  ///
  /// In en, this message translates to:
  /// **'Navigation is not active'**
  String get navigationIsNotActive;

  /// No description provided for @autoDescribeIsOn.
  ///
  /// In en, this message translates to:
  /// **'Auto describe is on'**
  String get autoDescribeIsOn;

  /// No description provided for @autoDescribeIsOff.
  ///
  /// In en, this message translates to:
  /// **'Auto describe is off'**
  String get autoDescribeIsOff;

  /// No description provided for @obstacleWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning! {description}'**
  String obstacleWarning(String description);

  /// No description provided for @pleaseWaitInitializing.
  ///
  /// In en, this message translates to:
  /// **'Please wait, app is initializing.'**
  String get pleaseWaitInitializing;

  /// No description provided for @couldNotGetLocationGps.
  ///
  /// In en, this message translates to:
  /// **'Could not get location. Please check GPS.'**
  String get couldNotGetLocationGps;

  /// No description provided for @openingGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not find internal directions. Opening Google Maps.'**
  String get openingGoogleMaps;

  /// No description provided for @couldNotOpenGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps.'**
  String get couldNotOpenGoogleMaps;

  /// No description provided for @sosError.
  ///
  /// In en, this message translates to:
  /// **'Error with SOS. Please try calling manually.'**
  String get sosError;

  /// No description provided for @contactAdded.
  ///
  /// In en, this message translates to:
  /// **'Contact added'**
  String get contactAdded;

  /// No description provided for @pleaseSpecifyLocationName.
  ///
  /// In en, this message translates to:
  /// **'Please specify a location name.'**
  String get pleaseSpecifyLocationName;

  /// No description provided for @navigatingTo.
  ///
  /// In en, this message translates to:
  /// **'Navigating to {name}.'**
  String navigatingTo(String name);

  /// No description provided for @locationSavedAs.
  ///
  /// In en, this message translates to:
  /// **'Location saved as {name}.'**
  String locationSavedAs(String name);

  /// No description provided for @failedToSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to save location. Name may already exist.'**
  String get failedToSaveLocation;

  /// No description provided for @listeningForCommand.
  ///
  /// In en, this message translates to:
  /// **'Listening for command'**
  String get listeningForCommand;

  /// No description provided for @cameraNotReady.
  ///
  /// In en, this message translates to:
  /// **'Camera not ready'**
  String get cameraNotReady;

  /// No description provided for @capturingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Capturing photo'**
  String get capturingPhoto;

  /// No description provided for @textDetected.
  ///
  /// In en, this message translates to:
  /// **'Text detected: {text}'**
  String textDetected(String text);

  /// No description provided for @analyzingSceneWithAi.
  ///
  /// In en, this message translates to:
  /// **'Analyzing scene with AI'**
  String get analyzingSceneWithAi;

  /// No description provided for @photoCapturedNoGemini.
  ///
  /// In en, this message translates to:
  /// **'Photo captured. AI description is not available.'**
  String get photoCapturedNoGemini;

  /// No description provided for @errorCapturingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Error capturing photo'**
  String get errorCapturingPhoto;

  /// No description provided for @readingTextFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Reading text from camera'**
  String get readingTextFromCamera;

  /// No description provided for @textFound.
  ///
  /// In en, this message translates to:
  /// **'Text found: {text}'**
  String textFound(String text);

  /// No description provided for @noTextDetectedInView.
  ///
  /// In en, this message translates to:
  /// **'No text detected in view'**
  String get noTextDetectedInView;

  /// No description provided for @errorReadingText.
  ///
  /// In en, this message translates to:
  /// **'Error reading text'**
  String get errorReadingText;

  /// No description provided for @sosCancelledCameraActive.
  ///
  /// In en, this message translates to:
  /// **'SOS cancelled. Camera active.'**
  String get sosCancelledCameraActive;

  /// No description provided for @fallDetectedTapToCancel.
  ///
  /// In en, this message translates to:
  /// **'Fall detected. Tap anywhere to cancel.'**
  String get fallDetectedTapToCancel;

  /// No description provided for @sosTriggeredTapToCancel.
  ///
  /// In en, this message translates to:
  /// **'SOS triggered. Tap anywhere to cancel.'**
  String get sosTriggeredTapToCancel;

  /// No description provided for @sosSequenceActivated.
  ///
  /// In en, this message translates to:
  /// **'Emergency sequence activated. Calling in {seconds} seconds. To cancel, tap anywhere on the screen or press a volume button.'**
  String sosSequenceActivated(String seconds);

  /// No description provided for @sosSecondsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String sosSecondsRemaining(String seconds);

  /// No description provided for @sosSequenceCancelled.
  ///
  /// In en, this message translates to:
  /// **'Emergency sequence cancelled.'**
  String get sosSequenceCancelled;

  /// No description provided for @sosSpokenCallMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello. This is an automated emergency call. The user may be unable to respond. Please send help. Location details sent via text message.'**
  String get sosSpokenCallMessage;

  /// No description provided for @emergencyContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContactsTitle;

  /// No description provided for @noContactsYet.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet. Add someone who can help.'**
  String get noContactsYet;

  /// No description provided for @addContactButton.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get addContactButton;

  /// No description provided for @addEmergencyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Emergency Contact'**
  String get addEmergencyContactTitle;

  /// No description provided for @contactNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get contactNameLabel;

  /// No description provided for @contactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get contactPhoneLabel;

  /// No description provided for @removeContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String removeContactLabel(String name);

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @contactRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String contactRemoved(String name);

  /// No description provided for @contactNeedsNameAndNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter both a name and a phone number.'**
  String get contactNeedsNameAndNumber;

  /// No description provided for @initializingCamera.
  ///
  /// In en, this message translates to:
  /// **'Initializing camera...'**
  String get initializingCamera;

  /// No description provided for @listeningIndicator.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listeningIndicator;

  /// No description provided for @destinationHint.
  ///
  /// In en, this message translates to:
  /// **'Destination (optional)'**
  String get destinationHint;

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get actionStart;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'STOP'**
  String get actionStop;

  /// No description provided for @actionSos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get actionSos;

  /// No description provided for @actionCameraOn.
  ///
  /// In en, this message translates to:
  /// **'CAM ON'**
  String get actionCameraOn;

  /// No description provided for @actionCameraOff.
  ///
  /// In en, this message translates to:
  /// **'CAM OFF'**
  String get actionCameraOff;

  /// No description provided for @actionAutoOn.
  ///
  /// In en, this message translates to:
  /// **'AUTO ON'**
  String get actionAutoOn;

  /// No description provided for @actionAutoOff.
  ///
  /// In en, this message translates to:
  /// **'AUTO OFF'**
  String get actionAutoOff;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get actionNext;

  /// No description provided for @actionContacts.
  ///
  /// In en, this message translates to:
  /// **'CONTACTS'**
  String get actionContacts;

  /// No description provided for @actionMap.
  ///
  /// In en, this message translates to:
  /// **'MAP'**
  String get actionMap;

  /// No description provided for @actionPhoto.
  ///
  /// In en, this message translates to:
  /// **'PHOTO'**
  String get actionPhoto;

  /// No description provided for @actionCapturing.
  ///
  /// In en, this message translates to:
  /// **'CAPTURING...'**
  String get actionCapturing;

  /// No description provided for @actionReadText.
  ///
  /// In en, this message translates to:
  /// **'READ TEXT'**
  String get actionReadText;

  /// No description provided for @actionVoice.
  ///
  /// In en, this message translates to:
  /// **'VOICE'**
  String get actionVoice;

  /// No description provided for @actionSettings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get actionSettings;

  /// No description provided for @actionTutorial.
  ///
  /// In en, this message translates to:
  /// **'TUTORIAL'**
  String get actionTutorial;

  /// No description provided for @demoModeOn.
  ///
  /// In en, this message translates to:
  /// **'Demo ON'**
  String get demoModeOn;

  /// No description provided for @demoModeOff.
  ///
  /// In en, this message translates to:
  /// **'Demo OFF'**
  String get demoModeOff;

  /// No description provided for @cancelEmergencyHint.
  ///
  /// In en, this message translates to:
  /// **'Cancel emergency. Tap anywhere to cancel.'**
  String get cancelEmergencyHint;

  /// No description provided for @emergencyNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency number'**
  String get emergencyNumberTitle;

  /// No description provided for @emergencyNumberHelp.
  ///
  /// In en, this message translates to:
  /// **'Dialled only when no emergency contact is saved. 112 works across Europe and India; 911 in the US.'**
  String get emergencyNumberHelp;

  /// No description provided for @emergencyNumberSaved.
  ///
  /// In en, this message translates to:
  /// **'Emergency number set to {number}'**
  String emergencyNumberSaved(String number);

  /// No description provided for @testBuildWarning.
  ///
  /// In en, this message translates to:
  /// **'Test build: SOS dials {number}, not emergency services.'**
  String testBuildWarning(String number);

  /// No description provided for @sosEmergencyHeading.
  ///
  /// In en, this message translates to:
  /// **'SOS EMERGENCY'**
  String get sosEmergencyHeading;

  /// No description provided for @sosHelpRequested.
  ///
  /// In en, this message translates to:
  /// **'Help has been requested'**
  String get sosHelpRequested;

  /// No description provided for @sosAlertFailed.
  ///
  /// In en, this message translates to:
  /// **'Emergency alert failed'**
  String get sosAlertFailed;

  /// No description provided for @sosStatusHeading.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sosStatusHeading;

  /// No description provided for @sosLocationHeading.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get sosLocationHeading;

  /// No description provided for @sosEmergencyCallLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency Call'**
  String get sosEmergencyCallLabel;

  /// No description provided for @sosCallMade.
  ///
  /// In en, this message translates to:
  /// **'Made'**
  String get sosCallMade;

  /// No description provided for @sosCallNotMade.
  ///
  /// In en, this message translates to:
  /// **'Not made'**
  String get sosCallNotMade;

  /// No description provided for @sosSmsTo.
  ///
  /// In en, this message translates to:
  /// **'Message to {name}'**
  String sosSmsTo(String name);

  /// No description provided for @sosSmsSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sosSmsSent;

  /// No description provided for @sosCallNumber.
  ///
  /// In en, this message translates to:
  /// **'CALL {number}'**
  String sosCallNumber(String number);

  /// No description provided for @sosSendSms.
  ///
  /// In en, this message translates to:
  /// **'SEND MESSAGE'**
  String get sosSendSms;

  /// No description provided for @sosCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: {lat}, {lng}'**
  String sosCoordinates(String lat, String lng);

  /// No description provided for @voiceCommandTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Command'**
  String get voiceCommandTitle;

  /// No description provided for @voiceTapMicToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap mic to speak'**
  String get voiceTapMicToSpeak;

  /// No description provided for @voiceProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get voiceProcessing;

  /// No description provided for @voiceEnterCommand.
  ///
  /// In en, this message translates to:
  /// **'Enter command'**
  String get voiceEnterCommand;

  /// No description provided for @voiceExecute.
  ///
  /// In en, this message translates to:
  /// **'Execute'**
  String get voiceExecute;

  /// No description provided for @voiceUnavailableTyped.
  ///
  /// In en, this message translates to:
  /// **'Voice recognition is not available. Please type your command.'**
  String get voiceUnavailableTyped;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Map'**
  String get mapTitle;

  /// No description provided for @mapDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get mapDestination;

  /// No description provided for @mapLocationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Location not valid'**
  String get mapLocationInvalid;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get settingsTextSize;

  /// No description provided for @settingsButtonSize.
  ///
  /// In en, this message translates to:
  /// **'Button Size'**
  String get settingsButtonSize;

  /// No description provided for @settingsContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get settingsContrast;

  /// No description provided for @settingsVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration Intensity'**
  String get settingsVibration;

  /// No description provided for @settingsVoiceSpeed.
  ///
  /// In en, this message translates to:
  /// **'Voice Speed'**
  String get settingsVoiceSpeed;

  /// No description provided for @settingsCommandDelay.
  ///
  /// In en, this message translates to:
  /// **'Command Delay'**
  String get settingsCommandDelay;

  /// No description provided for @settingsCommandDelayHelp.
  ///
  /// In en, this message translates to:
  /// **'Pause before executing voice commands'**
  String get settingsCommandDelayHelp;

  /// No description provided for @voiceUseKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Type the command instead'**
  String get voiceUseKeyboard;

  /// No description provided for @voiceUseMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Speak the command instead'**
  String get voiceUseMicrophone;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice commands are not available. Check that the microphone permission is granted.'**
  String get voiceUnavailable;

  /// No description provided for @voiceNothingHeard.
  ///
  /// In en, this message translates to:
  /// **'I did not hear anything. Try again.'**
  String get voiceNothingHeard;

  /// No description provided for @voiceNotUnderstood.
  ///
  /// In en, this message translates to:
  /// **'I did not understand that. Say help to hear the list of commands.'**
  String get voiceNotUnderstood;

  /// No description provided for @voiceHelpList.
  ///
  /// In en, this message translates to:
  /// **'You can say: start navigation, stop, next, repeat, describe, what\'s ahead, camera on, camera off, flashlight on, read text, what\'s nearby, time, battery, where am I, faster, slower, pause, resume, status, navigate to a place, save location, or S O S.'**
  String get voiceHelpList;

  /// No description provided for @nearbyPlacesSearching.
  ///
  /// In en, this message translates to:
  /// **'Looking for places nearby'**
  String get nearbyPlacesSearching;

  /// No description provided for @nearbyPlacesNone.
  ///
  /// In en, this message translates to:
  /// **'I could not find anything nearby'**
  String get nearbyPlacesNone;

  /// No description provided for @nearbyPlacesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Nearby places are not available right now'**
  String get nearbyPlacesUnavailable;

  /// No description provided for @nearbyPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'Nearby: {places}'**
  String nearbyPlacesFound(String places);

  /// No description provided for @nearbyPlaceItem.
  ///
  /// In en, this message translates to:
  /// **'{name}, {distance} metres'**
  String nearbyPlaceItem(String name, String distance);

  /// No description provided for @semanticsStart.
  ///
  /// In en, this message translates to:
  /// **'Start navigation'**
  String get semanticsStart;

  /// No description provided for @semanticsStop.
  ///
  /// In en, this message translates to:
  /// **'Stop navigation'**
  String get semanticsStop;

  /// No description provided for @semanticsSos.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get semanticsSos;

  /// No description provided for @semanticsNext.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get semanticsNext;

  /// No description provided for @semanticsCameraOn.
  ///
  /// In en, this message translates to:
  /// **'Obstacle detection, on'**
  String get semanticsCameraOn;

  /// No description provided for @semanticsCameraOff.
  ///
  /// In en, this message translates to:
  /// **'Obstacle detection, off'**
  String get semanticsCameraOff;

  /// No description provided for @semanticsAutoDescribeOn.
  ///
  /// In en, this message translates to:
  /// **'Spoken descriptions, on'**
  String get semanticsAutoDescribeOn;

  /// No description provided for @semanticsAutoDescribeOff.
  ///
  /// In en, this message translates to:
  /// **'Spoken descriptions, off'**
  String get semanticsAutoDescribeOff;

  /// No description provided for @semanticsPhoto.
  ///
  /// In en, this message translates to:
  /// **'Describe a photo'**
  String get semanticsPhoto;

  /// No description provided for @semanticsReadText.
  ///
  /// In en, this message translates to:
  /// **'Read text'**
  String get semanticsReadText;

  /// No description provided for @semanticsVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice command'**
  String get semanticsVoice;

  /// No description provided for @hintDestinationField.
  ///
  /// In en, this message translates to:
  /// **'Type where you want to go, then activate Start navigation'**
  String get hintDestinationField;

  /// No description provided for @hintNavigate.
  ///
  /// In en, this message translates to:
  /// **'Starts spoken turn by turn directions to the destination above'**
  String get hintNavigate;

  /// No description provided for @hintStopNavigation.
  ///
  /// In en, this message translates to:
  /// **'Ends the route you are following'**
  String get hintStopNavigation;

  /// No description provided for @hintSos.
  ///
  /// In en, this message translates to:
  /// **'Starts a ten second countdown, then texts and calls your emergency contacts. Tap anywhere to cancel during the countdown'**
  String get hintSos;

  /// No description provided for @hintNext.
  ///
  /// In en, this message translates to:
  /// **'Reads the next direction on your route'**
  String get hintNext;

  /// No description provided for @hintCamera.
  ///
  /// In en, this message translates to:
  /// **'Turns obstacle detection on or off'**
  String get hintCamera;

  /// No description provided for @hintAutoDescribe.
  ///
  /// In en, this message translates to:
  /// **'Turns automatic spoken descriptions of your surroundings on or off'**
  String get hintAutoDescribe;

  /// No description provided for @hintContacts.
  ///
  /// In en, this message translates to:
  /// **'Opens the list of people contacted in an emergency'**
  String get hintContacts;

  /// No description provided for @hintMap.
  ///
  /// In en, this message translates to:
  /// **'Opens the live map of your location'**
  String get hintMap;

  /// No description provided for @hintPhoto.
  ///
  /// In en, this message translates to:
  /// **'Takes a photo and describes what is in it'**
  String get hintPhoto;

  /// No description provided for @hintReadText.
  ///
  /// In en, this message translates to:
  /// **'Reads out any text the camera can see'**
  String get hintReadText;

  /// No description provided for @hintVoice.
  ///
  /// In en, this message translates to:
  /// **'Opens voice commands. You can also triple tap the screen'**
  String get hintVoice;

  /// No description provided for @hintSettings.
  ///
  /// In en, this message translates to:
  /// **'Opens text size, speech and emergency settings'**
  String get hintSettings;

  /// No description provided for @hintTutorial.
  ///
  /// In en, this message translates to:
  /// **'Explains how to use the app'**
  String get hintTutorial;

  /// No description provided for @hintDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Runs the app with sample data instead of live services'**
  String get hintDemoMode;

  /// No description provided for @settingsBackgroundProtection.
  ///
  /// In en, this message translates to:
  /// **'Background Fall Protection'**
  String get settingsBackgroundProtection;

  /// No description provided for @settingsBackgroundProtectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Keeps watching for a fall when the app is closed or the screen is off. Shows a persistent notification and uses a little more battery.'**
  String get settingsBackgroundProtectionHelp;

  /// No description provided for @settingsBackgroundProtectionOn.
  ///
  /// In en, this message translates to:
  /// **'Background fall protection turned on'**
  String get settingsBackgroundProtectionOn;

  /// No description provided for @settingsBackgroundProtectionOff.
  ///
  /// In en, this message translates to:
  /// **'Background fall protection turned off'**
  String get settingsBackgroundProtectionOff;

  /// No description provided for @backgroundSosBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible fall detected'**
  String get backgroundSosBannerTitle;

  /// No description provided for @backgroundSosBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Calling for help soon. Tap Cancel if you are okay.'**
  String get backgroundSosBannerBody;

  /// No description provided for @backgroundSosCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Emergency'**
  String get backgroundSosCancelButton;

  /// No description provided for @settingsAddFromContacts.
  ///
  /// In en, this message translates to:
  /// **'Add from Contacts'**
  String get settingsAddFromContacts;

  /// No description provided for @settingsNoContactSelected.
  ///
  /// In en, this message translates to:
  /// **'No contact selected, or permission denied'**
  String get settingsNoContactSelected;

  /// No description provided for @settingsResetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get settingsResetDefaults;

  /// No description provided for @settingsResetDone.
  ///
  /// In en, this message translates to:
  /// **'Settings reset to defaults'**
  String get settingsResetDone;

  /// No description provided for @settingsCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Current: {value}'**
  String settingsCurrentValue(String value);

  /// No description provided for @settingsErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String settingsErrorGeneric(String message);

  /// No description provided for @settingsNoContacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts added'**
  String get settingsNoContacts;

  /// No description provided for @tutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutorial ({current} of {total})'**
  String tutorialTitle(String current, String total);

  /// No description provided for @tutorialNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// No description provided for @tutorialPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get tutorialPrevious;

  /// No description provided for @tutorialFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get tutorialFinish;

  /// No description provided for @tutorialComplete.
  ///
  /// In en, this message translates to:
  /// **'Tutorial complete. You can now use the app.'**
  String get tutorialComplete;

  /// No description provided for @tutorialWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get tutorialWelcomeTitle;

  /// No description provided for @tutorialWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Welcome to GaBN. This app helps you navigate safely using your camera and voice commands.'**
  String get tutorialWelcomeBody;

  /// No description provided for @tutorialCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera Preview'**
  String get tutorialCameraTitle;

  /// No description provided for @tutorialCameraBody.
  ///
  /// In en, this message translates to:
  /// **'The camera preview shows what is in front of you. Keep the phone upright, facing forward.'**
  String get tutorialCameraBody;

  /// No description provided for @tutorialObstacleTitle.
  ///
  /// In en, this message translates to:
  /// **'Obstacle Detection'**
  String get tutorialObstacleTitle;

  /// No description provided for @tutorialObstacleBody.
  ///
  /// In en, this message translates to:
  /// **'The app detects objects in front of you. It will tell you what obstacles are ahead and where they are.'**
  String get tutorialObstacleBody;

  /// No description provided for @tutorialSosTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get tutorialSosTitle;

  /// No description provided for @tutorialSosBody.
  ///
  /// In en, this message translates to:
  /// **'Press the SOS button or shake your phone vigorously to raise an alert. Your location is sent to your emergency contacts. To cancel, tap anywhere or press a volume button.'**
  String get tutorialSosBody;

  /// No description provided for @tutorialVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Commands'**
  String get tutorialVoiceTitle;

  /// No description provided for @tutorialVoiceBody.
  ///
  /// In en, this message translates to:
  /// **'You can control the app by voice. Say \"help\" to hear every command, or \"navigate to\" followed by a place name.'**
  String get tutorialVoiceBody;

  /// No description provided for @tutorialPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo Capture'**
  String get tutorialPhotoTitle;

  /// No description provided for @tutorialPhotoBody.
  ///
  /// In en, this message translates to:
  /// **'Press the photo button or double-press a volume button to capture a photo. The app will describe what it sees.'**
  String get tutorialPhotoBody;

  /// No description provided for @tutorialTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Text Reading'**
  String get tutorialTextTitle;

  /// No description provided for @tutorialTextBody.
  ///
  /// In en, this message translates to:
  /// **'Use the Read Text button, or say \"read text\", to read any text visible in the camera view.'**
  String get tutorialTextBody;

  /// No description provided for @tutorialSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Locations'**
  String get tutorialSavedTitle;

  /// No description provided for @tutorialSavedBody.
  ///
  /// In en, this message translates to:
  /// **'You can save your current location and go back to it later by saying \"navigate to\" and the name, such as \"navigate to home\".'**
  String get tutorialSavedBody;

  /// No description provided for @tutorialSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tutorialSettingsTitle;

  /// No description provided for @tutorialSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Adjust text size, button size and contrast in Settings to make the app easier to use.'**
  String get tutorialSettingsBody;

  /// No description provided for @sosSmsNeedsSend.
  ///
  /// In en, this message translates to:
  /// **'Needs you to press send'**
  String get sosSmsNeedsSend;

  /// No description provided for @sosSmsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get sosSmsFailed;

  /// No description provided for @routeFound.
  ///
  /// In en, this message translates to:
  /// **'Route found. {distance}. {duration}.'**
  String routeFound(String distance, String duration);

  /// No description provided for @saveLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Location'**
  String get saveLocationTitle;

  /// No description provided for @settingsTextSizeSet.
  ///
  /// In en, this message translates to:
  /// **'Text size set to {value}'**
  String settingsTextSizeSet(String value);

  /// No description provided for @settingsButtonSizeSet.
  ///
  /// In en, this message translates to:
  /// **'Button size set to {value} percent'**
  String settingsButtonSizeSet(String value);

  /// No description provided for @settingsContrastSet.
  ///
  /// In en, this message translates to:
  /// **'Contrast set to {value}'**
  String settingsContrastSet(String value);

  /// No description provided for @settingsVibrationSet.
  ///
  /// In en, this message translates to:
  /// **'Vibration intensity {value} percent'**
  String settingsVibrationSet(String value);

  /// No description provided for @settingsCommandDelaySet.
  ///
  /// In en, this message translates to:
  /// **'Command delay {value} milliseconds'**
  String settingsCommandDelaySet(String value);

  /// No description provided for @settingsVoiceSpeedSet.
  ///
  /// In en, this message translates to:
  /// **'Voice speed {value}'**
  String settingsVoiceSpeedSet(String value);

  /// No description provided for @contactAddedNamed.
  ///
  /// In en, this message translates to:
  /// **'Added {name} to emergency contacts'**
  String contactAddedNamed(String name);

  /// No description provided for @sosCallingContact.
  ///
  /// In en, this message translates to:
  /// **'Calling: {name}'**
  String sosCallingContact(String name);

  /// No description provided for @sosOverlayHeading.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY SOS'**
  String get sosOverlayHeading;

  /// No description provided for @actionCancelUpper.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get actionCancelUpper;

  /// No description provided for @sosEmergencyServices.
  ///
  /// In en, this message translates to:
  /// **'Emergency services'**
  String get sosEmergencyServices;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
