// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Accessibility Navigator';

  @override
  String get initializing => 'Initializing...';

  @override
  String get readyCameraActive => 'Ready. Camera active.';

  @override
  String get cameraInitFailed =>
      'Camera initialization failed. Please check permissions.';

  @override
  String get errorStartingApp => 'Error starting app. Please restart.';

  @override
  String get appReadySpeak =>
      'App ready. Camera is active and scanning for obstacles.';

  @override
  String get cameraEnabled => 'Camera enabled';

  @override
  String get cameraDisabled => 'Camera disabled';

  @override
  String get cameraScanning => 'Camera enabled. Scanning for obstacles.';

  @override
  String get navigationStarted => 'Starting navigation';

  @override
  String get navigationStopped => 'Navigation stopped';

  @override
  String get navigationStoppedCameraActive =>
      'Navigation stopped. Camera active.';

  @override
  String get youHaveArrived => 'You have arrived.';

  @override
  String get sosActivated => 'SOS activated.';

  @override
  String get sosEmergencyHelpRequested => 'Emergency help requested.';

  @override
  String get autoDescriptionEnabled => 'Auto description enabled';

  @override
  String get autoDescriptionDisabled => 'Auto description disabled';

  @override
  String get autoDescriptionPaused => 'Auto description paused';

  @override
  String get autoDescriptionResumed => 'Auto description resumed';

  @override
  String timeIs(String hour, String minute, String suffix) {
    return 'It is $hour:$minute $suffix';
  }

  @override
  String batteryLevelIs(String level) {
    return 'Battery level is $level.';
  }

  @override
  String get checkingLocation => 'Checking location...';

  @override
  String youAreAtCoordinates(String lat, String lng) {
    return 'You are at latitude $lat and longitude $lng.';
  }

  @override
  String get unableToGetLocation => 'Unable to get current location.';

  @override
  String get locationError => 'Location error.';

  @override
  String get flashlightOn => 'Flashlight on';

  @override
  String get flashlightOff => 'Flashlight off';

  @override
  String get speechSpeedIncreased => 'Speech speed increased.';

  @override
  String get speechSpeedDecreased => 'Speech speed decreased.';

  @override
  String get alreadyPaused => 'Already paused.';

  @override
  String get alreadyActive => 'Already active.';

  @override
  String get cameraIsOn => 'Camera is on';

  @override
  String get cameraIsOff => 'Camera is off';

  @override
  String get navigationIsActive => 'Navigation is active';

  @override
  String get navigationIsNotActive => 'Navigation is not active';

  @override
  String get autoDescribeIsOn => 'Auto describe is on';

  @override
  String get autoDescribeIsOff => 'Auto describe is off';

  @override
  String obstacleWarning(String description) {
    return 'Warning! $description';
  }

  @override
  String get pleaseWaitInitializing => 'Please wait, app is initializing.';

  @override
  String get couldNotGetLocationGps =>
      'Could not get location. Please check GPS.';

  @override
  String get openingGoogleMaps =>
      'Could not find internal directions. Opening Google Maps.';

  @override
  String get couldNotOpenGoogleMaps => 'Could not open Google Maps.';

  @override
  String get sosError => 'Error with SOS. Please try calling manually.';

  @override
  String get contactAdded => 'Contact added';

  @override
  String get pleaseSpecifyLocationName => 'Please specify a location name.';

  @override
  String navigatingTo(String name) {
    return 'Navigating to $name.';
  }

  @override
  String locationSavedAs(String name) {
    return 'Location saved as $name.';
  }

  @override
  String get failedToSaveLocation =>
      'Failed to save location. Name may already exist.';

  @override
  String get listeningForCommand => 'Listening for command';

  @override
  String get cameraNotReady => 'Camera not ready';

  @override
  String get capturingPhoto => 'Capturing photo';

  @override
  String textDetected(String text) {
    return 'Text detected: $text';
  }

  @override
  String get analyzingSceneWithAi => 'Analyzing scene with AI';

  @override
  String get photoCapturedNoGemini =>
      'Photo captured. AI description is not available.';

  @override
  String get errorCapturingPhoto => 'Error capturing photo';

  @override
  String get readingTextFromCamera => 'Reading text from camera';

  @override
  String textFound(String text) {
    return 'Text found: $text';
  }

  @override
  String get noTextDetectedInView => 'No text detected in view';

  @override
  String get errorReadingText => 'Error reading text';

  @override
  String get sosCancelledCameraActive => 'SOS cancelled. Camera active.';

  @override
  String get fallDetectedTapToCancel =>
      'Fall detected. Tap anywhere to cancel.';

  @override
  String get sosTriggeredTapToCancel =>
      'SOS triggered. Tap anywhere to cancel.';

  @override
  String sosSequenceActivated(String seconds) {
    return 'Emergency sequence activated. Calling in $seconds seconds. To cancel, tap anywhere on the screen or press a volume button.';
  }

  @override
  String sosSecondsRemaining(String seconds) {
    return '$seconds seconds';
  }

  @override
  String get sosSequenceCancelled => 'Emergency sequence cancelled.';

  @override
  String get sosSpokenCallMessage =>
      'Hello. This is an automated emergency call. The user may be unable to respond. Please send help. Location details sent via text message.';

  @override
  String get emergencyContactsTitle => 'Emergency Contacts';

  @override
  String get noContactsYet => 'No contacts yet. Add someone who can help.';

  @override
  String get addContactButton => 'Add contact';

  @override
  String get addEmergencyContactTitle => 'Add Emergency Contact';

  @override
  String get contactNameLabel => 'Name';

  @override
  String get contactPhoneLabel => 'Phone number';

  @override
  String removeContactLabel(String name) {
    return 'Remove $name';
  }

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionClose => 'Close';

  @override
  String contactRemoved(String name) {
    return '$name removed';
  }

  @override
  String get contactNeedsNameAndNumber =>
      'Enter both a name and a phone number.';

  @override
  String get initializingCamera => 'Initializing camera...';

  @override
  String get listeningIndicator => 'Listening...';

  @override
  String get destinationHint => 'Destination (optional)';

  @override
  String get actionStart => 'START';

  @override
  String get actionStop => 'STOP';

  @override
  String get actionSos => 'SOS';

  @override
  String get actionCameraOn => 'CAM ON';

  @override
  String get actionCameraOff => 'CAM OFF';

  @override
  String get actionAutoOn => 'AUTO ON';

  @override
  String get actionAutoOff => 'AUTO OFF';

  @override
  String get actionNext => 'NEXT';

  @override
  String get actionContacts => 'CONTACTS';

  @override
  String get actionMap => 'MAP';

  @override
  String get actionPhoto => 'PHOTO';

  @override
  String get actionCapturing => 'CAPTURING...';

  @override
  String get actionReadText => 'READ TEXT';

  @override
  String get actionVoice => 'VOICE';

  @override
  String get actionSettings => 'SETTINGS';

  @override
  String get actionTutorial => 'TUTORIAL';

  @override
  String get demoModeOn => 'Demo ON';

  @override
  String get demoModeOff => 'Demo OFF';

  @override
  String get cancelEmergencyHint => 'Cancel emergency. Tap anywhere to cancel.';

  @override
  String get emergencyNumberTitle => 'Emergency number';

  @override
  String get emergencyNumberHelp =>
      'Dialled only when no emergency contact is saved. 112 works across Europe and India; 911 in the US.';

  @override
  String emergencyNumberSaved(String number) {
    return 'Emergency number set to $number';
  }

  @override
  String testBuildWarning(String number) {
    return 'Test build: SOS dials $number, not emergency services.';
  }

  @override
  String get sosEmergencyHeading => 'SOS EMERGENCY';

  @override
  String get sosHelpRequested => 'Help has been requested';

  @override
  String get sosAlertFailed => 'Emergency alert failed';

  @override
  String get sosStatusHeading => 'Status';

  @override
  String get sosLocationHeading => 'Location';

  @override
  String get sosEmergencyCallLabel => 'Emergency Call';

  @override
  String get sosCallMade => 'Made';

  @override
  String get sosCallNotMade => 'Not made';

  @override
  String sosSmsTo(String name) {
    return 'Message to $name';
  }

  @override
  String get sosSmsSent => 'Sent';

  @override
  String sosCallNumber(String number) {
    return 'CALL $number';
  }

  @override
  String get sosSendSms => 'SEND MESSAGE';

  @override
  String sosCoordinates(String lat, String lng) {
    return 'Coordinates: $lat, $lng';
  }

  @override
  String get voiceCommandTitle => 'Voice Command';

  @override
  String get voiceTapMicToSpeak => 'Tap mic to speak';

  @override
  String get voiceProcessing => 'Processing...';

  @override
  String get voiceEnterCommand => 'Enter command';

  @override
  String get voiceExecute => 'Execute';

  @override
  String get voiceUnavailableTyped =>
      'Voice recognition is not available. Please type your command.';

  @override
  String get mapTitle => 'Live Map';

  @override
  String get mapDestination => 'Destination';

  @override
  String get mapLocationInvalid => 'Location not valid';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTextSize => 'Text Size';

  @override
  String get settingsButtonSize => 'Button Size';

  @override
  String get settingsContrast => 'Contrast';

  @override
  String get settingsVibration => 'Vibration Intensity';

  @override
  String get settingsVoiceSpeed => 'Voice Speed';

  @override
  String get settingsCommandDelay => 'Command Delay';

  @override
  String get settingsCommandDelayHelp =>
      'Pause before executing voice commands';

  @override
  String get voiceUseKeyboard => 'Type the command instead';

  @override
  String get voiceUseMicrophone => 'Speak the command instead';

  @override
  String get voiceUnavailable =>
      'Voice commands are not available. Check that the microphone permission is granted.';

  @override
  String get voiceNothingHeard => 'I did not hear anything. Try again.';

  @override
  String get voiceNotUnderstood =>
      'I did not understand that. Say help to hear the list of commands.';

  @override
  String get voiceHelpList =>
      'You can say: start navigation, stop, next, repeat, describe, what\'s ahead, camera on, camera off, flashlight on, read text, what\'s nearby, time, battery, where am I, faster, slower, pause, resume, status, navigate to a place, save location, or S O S.';

  @override
  String get nearbyPlacesSearching => 'Looking for places nearby';

  @override
  String get nearbyPlacesNone => 'I could not find anything nearby';

  @override
  String get nearbyPlacesUnavailable =>
      'Nearby places are not available right now';

  @override
  String nearbyPlacesFound(String places) {
    return 'Nearby: $places';
  }

  @override
  String nearbyPlaceItem(String name, String distance) {
    return '$name, $distance metres';
  }

  @override
  String get semanticsStart => 'Start navigation';

  @override
  String get semanticsStop => 'Stop navigation';

  @override
  String get semanticsSos => 'Emergency SOS';

  @override
  String get semanticsNext => 'Next step';

  @override
  String get semanticsCameraOn => 'Obstacle detection, on';

  @override
  String get semanticsCameraOff => 'Obstacle detection, off';

  @override
  String get semanticsAutoDescribeOn => 'Spoken descriptions, on';

  @override
  String get semanticsAutoDescribeOff => 'Spoken descriptions, off';

  @override
  String get semanticsPhoto => 'Describe a photo';

  @override
  String get semanticsReadText => 'Read text';

  @override
  String get semanticsVoice => 'Voice command';

  @override
  String get hintDestinationField =>
      'Type where you want to go, then activate Start navigation';

  @override
  String get hintNavigate =>
      'Starts spoken turn by turn directions to the destination above';

  @override
  String get hintStopNavigation => 'Ends the route you are following';

  @override
  String get hintSos =>
      'Starts a ten second countdown, then texts and calls your emergency contacts. Tap anywhere to cancel during the countdown';

  @override
  String get hintNext => 'Reads the next direction on your route';

  @override
  String get hintCamera => 'Turns obstacle detection on or off';

  @override
  String get hintAutoDescribe =>
      'Turns automatic spoken descriptions of your surroundings on or off';

  @override
  String get hintContacts =>
      'Opens the list of people contacted in an emergency';

  @override
  String get hintMap => 'Opens the live map of your location';

  @override
  String get hintPhoto => 'Takes a photo and describes what is in it';

  @override
  String get hintReadText => 'Reads out any text the camera can see';

  @override
  String get hintVoice =>
      'Opens voice commands. You can also triple tap the screen';

  @override
  String get hintSettings => 'Opens text size, speech and emergency settings';

  @override
  String get hintTutorial => 'Explains how to use the app';

  @override
  String get hintDemoMode =>
      'Runs the app with sample data instead of live services';

  @override
  String get settingsBackgroundProtection => 'Background Fall Protection';

  @override
  String get settingsBackgroundProtectionHelp =>
      'Keeps watching for a fall when the app is closed or the screen is off. Shows a persistent notification and uses a little more battery.';

  @override
  String get settingsBackgroundProtectionOn =>
      'Background fall protection turned on';

  @override
  String get settingsBackgroundProtectionOff =>
      'Background fall protection turned off';

  @override
  String get backgroundSosBannerTitle => 'Possible fall detected';

  @override
  String get backgroundSosBannerBody =>
      'Calling for help soon. Tap Cancel if you are okay.';

  @override
  String get backgroundSosCancelButton => 'Cancel Emergency';

  @override
  String get settingsAddFromContacts => 'Add from Contacts';

  @override
  String get settingsNoContactSelected =>
      'No contact selected, or permission denied';

  @override
  String get settingsResetDefaults => 'Reset to Defaults';

  @override
  String get settingsResetDone => 'Settings reset to defaults';

  @override
  String settingsCurrentValue(String value) {
    return 'Current: $value';
  }

  @override
  String settingsErrorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String get settingsNoContacts => 'No contacts added';

  @override
  String tutorialTitle(String current, String total) {
    return 'Tutorial ($current of $total)';
  }

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialPrevious => 'Previous';

  @override
  String get tutorialFinish => 'Finish';

  @override
  String get tutorialComplete => 'Tutorial complete. You can now use the app.';

  @override
  String get tutorialWelcomeTitle => 'Welcome';

  @override
  String get tutorialWelcomeBody =>
      'Welcome to GaBN. This app helps you navigate safely using your camera and voice commands.';

  @override
  String get tutorialCameraTitle => 'Camera Preview';

  @override
  String get tutorialCameraBody =>
      'The camera preview shows what is in front of you. Keep the phone upright, facing forward.';

  @override
  String get tutorialObstacleTitle => 'Obstacle Detection';

  @override
  String get tutorialObstacleBody =>
      'The app detects objects in front of you. It will tell you what obstacles are ahead and where they are.';

  @override
  String get tutorialSosTitle => 'Emergency SOS';

  @override
  String get tutorialSosBody =>
      'Press the SOS button or shake your phone vigorously to raise an alert. Your location is sent to your emergency contacts. To cancel, tap anywhere or press a volume button.';

  @override
  String get tutorialVoiceTitle => 'Voice Commands';

  @override
  String get tutorialVoiceBody =>
      'You can control the app by voice. Say \"help\" to hear every command, or \"navigate to\" followed by a place name.';

  @override
  String get tutorialPhotoTitle => 'Photo Capture';

  @override
  String get tutorialPhotoBody =>
      'Press the photo button or double-press a volume button to capture a photo. The app will describe what it sees.';

  @override
  String get tutorialTextTitle => 'Text Reading';

  @override
  String get tutorialTextBody =>
      'Use the Read Text button, or say \"read text\", to read any text visible in the camera view.';

  @override
  String get tutorialSavedTitle => 'Saved Locations';

  @override
  String get tutorialSavedBody =>
      'You can save your current location and go back to it later by saying \"navigate to\" and the name, such as \"navigate to home\".';

  @override
  String get tutorialSettingsTitle => 'Settings';

  @override
  String get tutorialSettingsBody =>
      'Adjust text size, button size and contrast in Settings to make the app easier to use.';

  @override
  String get sosSmsNeedsSend => 'Needs you to press send';

  @override
  String get sosSmsFailed => 'Failed';

  @override
  String routeFound(String distance, String duration) {
    return 'Route found. $distance. $duration.';
  }

  @override
  String get saveLocationTitle => 'Save Location';

  @override
  String settingsTextSizeSet(String value) {
    return 'Text size set to $value';
  }

  @override
  String settingsButtonSizeSet(String value) {
    return 'Button size set to $value percent';
  }

  @override
  String settingsContrastSet(String value) {
    return 'Contrast set to $value';
  }

  @override
  String settingsVibrationSet(String value) {
    return 'Vibration intensity $value percent';
  }

  @override
  String settingsCommandDelaySet(String value) {
    return 'Command delay $value milliseconds';
  }

  @override
  String settingsVoiceSpeedSet(String value) {
    return 'Voice speed $value';
  }

  @override
  String contactAddedNamed(String name) {
    return 'Added $name to emergency contacts';
  }

  @override
  String sosCallingContact(String name) {
    return 'Calling: $name';
  }

  @override
  String get sosOverlayHeading => 'EMERGENCY SOS';

  @override
  String get actionCancelUpper => 'CANCEL';

  @override
  String get sosEmergencyServices => 'Emergency services';
}
