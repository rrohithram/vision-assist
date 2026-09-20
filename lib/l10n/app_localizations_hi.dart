// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'एक्सेसिबिलिटी नेविगेटर';

  @override
  String get initializing => 'आरंभ हो रहा है...';

  @override
  String get readyCameraActive => 'तैयार। कैमरा सक्रिय है।';

  @override
  String get cameraInitFailed =>
      'कैमरा आरंभ करने में विफल। कृपया अनुमतियां जांचें।';

  @override
  String get errorStartingApp =>
      'ऐप शुरू करने में त्रुटि। कृपया पुनरारंभ करें।';

  @override
  String get appReadySpeak =>
      'ऐप तैयार है। कैमरा सक्रिय है और बाधाओं की तलाश कर रहा है।';

  @override
  String get cameraEnabled => 'कैमरा सक्षम';

  @override
  String get cameraDisabled => 'कैमरा अक्षम';

  @override
  String get cameraScanning => 'कैमरा सक्षम। बाधाओं की तलाश की जा रही है।';

  @override
  String get navigationStarted => 'नेविगेशन शुरू हो रहा है';

  @override
  String get navigationStopped => 'नेविगेशन रुक गया';

  @override
  String get navigationStoppedCameraActive =>
      'नेविगेशन रुक गया। कैमरा सक्रिय है।';

  @override
  String get youHaveArrived => 'आप पहुंच गए हैं।';

  @override
  String get sosActivated => 'SOS सक्रिय हो गया।';

  @override
  String get sosEmergencyHelpRequested =>
      'आपातकालीन सहायता का अनुरोध किया गया।';

  @override
  String get autoDescriptionEnabled => 'ऑटो विवरण सक्षम';

  @override
  String get autoDescriptionDisabled => 'ऑटो विवरण अक्षम';

  @override
  String get autoDescriptionPaused => 'ऑटो विवरण रुका हुआ है';

  @override
  String get autoDescriptionResumed => 'ऑटो विवरण फिर से शुरू';

  @override
  String timeIs(String hour, String minute, String suffix) {
    return 'समय है $hour:$minute $suffix';
  }

  @override
  String batteryLevelIs(String level) {
    return 'बैटरी स्तर $level है।';
  }

  @override
  String get checkingLocation => 'स्थान जांचा जा रहा है...';

  @override
  String youAreAtCoordinates(String lat, String lng) {
    return 'आप अक्षांश $lat और देशांतर $lng पर हैं।';
  }

  @override
  String get unableToGetLocation => 'वर्तमान स्थान प्राप्त नहीं हो सका।';

  @override
  String get locationError => 'स्थान त्रुटि।';

  @override
  String get flashlightOn => 'टॉर्च चालू';

  @override
  String get flashlightOff => 'टॉर्च बंद';

  @override
  String get speechSpeedIncreased => 'बोलने की गति बढ़ा दी गई।';

  @override
  String get speechSpeedDecreased => 'बोलने की गति घटा दी गई।';

  @override
  String get alreadyPaused => 'पहले से रुका हुआ है।';

  @override
  String get alreadyActive => 'पहले से सक्रिय है।';

  @override
  String get cameraIsOn => 'कैमरा चालू है';

  @override
  String get cameraIsOff => 'कैमरा बंद है';

  @override
  String get navigationIsActive => 'नेविगेशन सक्रिय है';

  @override
  String get navigationIsNotActive => 'नेविगेशन सक्रिय नहीं है';

  @override
  String get autoDescribeIsOn => 'स्वतः विवरण चालू है';

  @override
  String get autoDescribeIsOff => 'स्वतः विवरण बंद है';

  @override
  String obstacleWarning(String description) {
    return 'सावधान! $description';
  }

  @override
  String get pleaseWaitInitializing =>
      'कृपया प्रतीक्षा करें, ऐप शुरू हो रहा है।';

  @override
  String get couldNotGetLocationGps => 'स्थान नहीं मिला। कृपया जीपीएस जांचें।';

  @override
  String get openingGoogleMaps =>
      'आंतरिक दिशा-निर्देश नहीं मिले। गूगल मैप्स खोला जा रहा है।';

  @override
  String get couldNotOpenGoogleMaps => 'गूगल मैप्स नहीं खुल सका।';

  @override
  String get sosError =>
      'एसओएस में त्रुटि। कृपया स्वयं कॉल करने का प्रयास करें।';

  @override
  String get contactAdded => 'संपर्क जोड़ा गया';

  @override
  String get pleaseSpecifyLocationName => 'कृपया स्थान का नाम बताएं।';

  @override
  String navigatingTo(String name) {
    return '$name की ओर नेविगेट किया जा रहा है।';
  }

  @override
  String locationSavedAs(String name) {
    return 'स्थान $name के रूप में सहेजा गया।';
  }

  @override
  String get failedToSaveLocation =>
      'स्थान सहेजने में विफल। नाम पहले से मौजूद हो सकता है।';

  @override
  String get listeningForCommand => 'आदेश सुना जा रहा है';

  @override
  String get cameraNotReady => 'कैमरा तैयार नहीं है';

  @override
  String get capturingPhoto => 'फ़ोटो ली जा रही है';

  @override
  String textDetected(String text) {
    return 'पाठ मिला: $text';
  }

  @override
  String get analyzingSceneWithAi => 'एआई से दृश्य का विश्लेषण किया जा रहा है';

  @override
  String get photoCapturedNoGemini => 'फ़ोटो ली गई। एआई विवरण उपलब्ध नहीं है।';

  @override
  String get errorCapturingPhoto => 'फ़ोटो लेने में त्रुटि';

  @override
  String get readingTextFromCamera => 'कैमरे से पाठ पढ़ा जा रहा है';

  @override
  String textFound(String text) {
    return 'पाठ मिला: $text';
  }

  @override
  String get noTextDetectedInView => 'दृश्य में कोई पाठ नहीं मिला';

  @override
  String get errorReadingText => 'पाठ पढ़ने में त्रुटि';

  @override
  String get sosCancelledCameraActive => 'एसओएस रद्द। कैमरा सक्रिय।';

  @override
  String get fallDetectedTapToCancel =>
      'गिरना पता चला। रद्द करने के लिए कहीं भी टैप करें।';

  @override
  String get sosTriggeredTapToCancel =>
      'एसओएस सक्रिय। रद्द करने के लिए कहीं भी टैप करें।';

  @override
  String sosSequenceActivated(String seconds) {
    return 'आपातकालीन अनुक्रम सक्रिय। $seconds सेकंड में कॉल किया जाएगा। रद्द करने के लिए स्क्रीन पर कहीं भी टैप करें या वॉल्यूम बटन दबाएं।';
  }

  @override
  String sosSecondsRemaining(String seconds) {
    return '$seconds सेकंड';
  }

  @override
  String get sosSequenceCancelled => 'आपातकालीन अनुक्रम रद्द कर दिया गया।';

  @override
  String get sosSpokenCallMessage =>
      'नमस्ते। यह एक स्वचालित आपातकालीन कॉल है। उपयोगकर्ता उत्तर देने में असमर्थ हो सकता है। कृपया मदद भेजें। स्थान का विवरण संदेश द्वारा भेजा गया है।';

  @override
  String get emergencyContactsTitle => 'आपातकालीन संपर्क';

  @override
  String get noContactsYet =>
      'अभी कोई संपर्क नहीं। किसी ऐसे व्यक्ति को जोड़ें जो मदद कर सके।';

  @override
  String get addContactButton => 'संपर्क जोड़ें';

  @override
  String get addEmergencyContactTitle => 'आपातकालीन संपर्क जोड़ें';

  @override
  String get contactNameLabel => 'नाम';

  @override
  String get contactPhoneLabel => 'फ़ोन नंबर';

  @override
  String removeContactLabel(String name) {
    return '$name को हटाएं';
  }

  @override
  String get actionCancel => 'रद्द करें';

  @override
  String get actionAdd => 'जोड़ें';

  @override
  String get actionClose => 'बंद करें';

  @override
  String contactRemoved(String name) {
    return '$name हटा दिया गया';
  }

  @override
  String get contactNeedsNameAndNumber => 'नाम और फ़ोन नंबर दोनों दर्ज करें।';

  @override
  String get initializingCamera => 'कैमरा शुरू हो रहा है...';

  @override
  String get listeningIndicator => 'सुन रहा है...';

  @override
  String get destinationHint => 'गंतव्य (वैकल्पिक)';

  @override
  String get actionStart => 'शुरू';

  @override
  String get actionStop => 'रोकें';

  @override
  String get actionSos => 'एसओएस';

  @override
  String get actionCameraOn => 'कैमरा चालू';

  @override
  String get actionCameraOff => 'कैमरा बंद';

  @override
  String get actionAutoOn => 'स्वतः चालू';

  @override
  String get actionAutoOff => 'स्वतः बंद';

  @override
  String get actionNext => 'अगला';

  @override
  String get actionContacts => 'संपर्क';

  @override
  String get actionMap => 'नक्शा';

  @override
  String get actionPhoto => 'फ़ोटो';

  @override
  String get actionCapturing => 'ली जा रही है...';

  @override
  String get actionReadText => 'पाठ पढ़ें';

  @override
  String get actionVoice => 'आवाज़';

  @override
  String get actionSettings => 'सेटिंग्स';

  @override
  String get actionTutorial => 'ट्यूटोरियल';

  @override
  String get demoModeOn => 'डेमो चालू';

  @override
  String get demoModeOff => 'डेमो बंद';

  @override
  String get cancelEmergencyHint =>
      'आपातकाल रद्द करें। रद्द करने के लिए कहीं भी टैप करें।';

  @override
  String get emergencyNumberTitle => 'आपातकालीन नंबर';

  @override
  String get emergencyNumberHelp =>
      'केवल तब डायल किया जाता है जब कोई आपातकालीन संपर्क सहेजा न हो। 112 यूरोप और भारत में काम करता है; अमेरिका में 911।';

  @override
  String emergencyNumberSaved(String number) {
    return 'आपातकालीन नंबर $number पर सेट किया गया';
  }

  @override
  String testBuildWarning(String number) {
    return 'परीक्षण बिल्ड: एसओएस $number डायल करता है, आपातकालीन सेवाओं को नहीं।';
  }

  @override
  String get sosEmergencyHeading => 'एसओएस आपातकाल';

  @override
  String get sosHelpRequested => 'मदद का अनुरोध किया गया है';

  @override
  String get sosAlertFailed => 'आपातकालीन अलर्ट विफल';

  @override
  String get sosStatusHeading => 'स्थिति';

  @override
  String get sosLocationHeading => 'स्थान';

  @override
  String get sosEmergencyCallLabel => 'आपातकालीन कॉल';

  @override
  String get sosCallMade => 'किया गया';

  @override
  String get sosCallNotMade => 'नहीं किया गया';

  @override
  String sosSmsTo(String name) {
    return '$name को संदेश';
  }

  @override
  String get sosSmsSent => 'भेजा गया';

  @override
  String sosCallNumber(String number) {
    return '$number पर कॉल करें';
  }

  @override
  String get sosSendSms => 'संदेश भेजें';

  @override
  String sosCoordinates(String lat, String lng) {
    return 'निर्देशांक: $lat, $lng';
  }

  @override
  String get voiceCommandTitle => 'आवाज़ आदेश';

  @override
  String get voiceTapMicToSpeak => 'बोलने के लिए माइक टैप करें';

  @override
  String get voiceProcessing => 'संसाधित हो रहा है...';

  @override
  String get voiceEnterCommand => 'आदेश दर्ज करें';

  @override
  String get voiceExecute => 'चलाएं';

  @override
  String get voiceUnavailableTyped =>
      'आवाज़ पहचान उपलब्ध नहीं है। कृपया अपना आदेश टाइप करें।';

  @override
  String get mapTitle => 'लाइव नक्शा';

  @override
  String get mapDestination => 'गंतव्य';

  @override
  String get mapLocationInvalid => 'स्थान मान्य नहीं है';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsTextSize => 'पाठ का आकार';

  @override
  String get settingsButtonSize => 'बटन का आकार';

  @override
  String get settingsContrast => 'कंट्रास्ट';

  @override
  String get settingsVibration => 'कंपन की तीव्रता';

  @override
  String get settingsVoiceSpeed => 'आवाज़ की गति';

  @override
  String get settingsCommandDelay => 'आदेश विलंब';

  @override
  String get settingsCommandDelayHelp => 'आवाज़ आदेश चलाने से पहले रुकें';

  @override
  String get voiceUseKeyboard => 'इसके बजाय आदेश टाइप करें';

  @override
  String get voiceUseMicrophone => 'इसके बजाय आदेश बोलें';

  @override
  String get voiceUnavailable =>
      'आवाज़ आदेश उपलब्ध नहीं हैं। जांचें कि माइक्रोफ़ोन की अनुमति दी गई है।';

  @override
  String get voiceNothingHeard =>
      'मुझे कुछ सुनाई नहीं दिया। फिर से कोशिश करें।';

  @override
  String get voiceNotUnderstood =>
      'मैं समझ नहीं पाया। आदेशों की सूची सुनने के लिए मदद कहें।';

  @override
  String get voiceHelpList =>
      'आप कह सकते हैं: नेविगेशन शुरू करो, रुको, अगला, दोहराओ, बताओ, सामने क्या है, कैमरा चालू, कैमरा बंद, टॉर्च चालू, पाठ पढ़ो, आसपास क्या है, समय, बैटरी, मैं कहाँ हूँ, तेज़, धीरे, चुप, जारी, स्थिति, कहीं ले चलो, या एसओएस।';

  @override
  String get nearbyPlacesSearching => 'आसपास की जगहें खोजी जा रही हैं';

  @override
  String get nearbyPlacesNone => 'मुझे आसपास कुछ नहीं मिला';

  @override
  String get nearbyPlacesUnavailable => 'आसपास की जगहें अभी उपलब्ध नहीं हैं';

  @override
  String nearbyPlacesFound(String places) {
    return 'आसपास: $places';
  }

  @override
  String nearbyPlaceItem(String name, String distance) {
    return '$name, $distance मीटर';
  }

  @override
  String get semanticsStart => 'नेविगेशन शुरू करें';

  @override
  String get semanticsStop => 'नेविगेशन बंद करें';

  @override
  String get semanticsSos => 'आपातकालीन एसओएस';

  @override
  String get semanticsNext => 'अगला चरण';

  @override
  String get semanticsCameraOn => 'बाधा पहचान, चालू';

  @override
  String get semanticsCameraOff => 'बाधा पहचान, बंद';

  @override
  String get semanticsAutoDescribeOn => 'बोलकर विवरण, चालू';

  @override
  String get semanticsAutoDescribeOff => 'बोलकर विवरण, बंद';

  @override
  String get semanticsPhoto => 'फ़ोटो का विवरण दें';

  @override
  String get semanticsReadText => 'पाठ पढ़ें';

  @override
  String get semanticsVoice => 'आवाज़ आदेश';

  @override
  String get hintDestinationField =>
      'आप कहाँ जाना चाहते हैं लिखें, फिर नेविगेशन शुरू करें दबाएँ';

  @override
  String get hintNavigate =>
      'ऊपर दिए गंतव्य तक बोलकर दिशा-निर्देश शुरू करता है';

  @override
  String get hintStopNavigation =>
      'आप जिस मार्ग पर चल रहे हैं उसे समाप्त करता है';

  @override
  String get hintSos =>
      'दस सेकंड की गिनती शुरू करता है, फिर आपके आपातकालीन संपर्कों को संदेश और कॉल करता है। गिनती के दौरान रद्द करने के लिए स्क्रीन पर कहीं भी टैप करें';

  @override
  String get hintNext => 'आपके मार्ग की अगली दिशा पढ़ता है';

  @override
  String get hintCamera => 'बाधा पहचान को चालू या बंद करता है';

  @override
  String get hintAutoDescribe =>
      'आसपास के स्वचालित बोले गए विवरण को चालू या बंद करता है';

  @override
  String get hintContacts =>
      'आपातकाल में संपर्क किए जाने वाले लोगों की सूची खोलता है';

  @override
  String get hintMap => 'आपके स्थान का लाइव मानचित्र खोलता है';

  @override
  String get hintPhoto => 'फ़ोटो लेता है और बताता है कि उसमें क्या है';

  @override
  String get hintReadText => 'कैमरे को दिखने वाला कोई भी पाठ पढ़कर सुनाता है';

  @override
  String get hintVoice =>
      'आवाज़ आदेश खोलता है। आप स्क्रीन पर तीन बार टैप भी कर सकते हैं';

  @override
  String get hintSettings => 'पाठ का आकार, भाषण और आपातकालीन सेटिंग्स खोलता है';

  @override
  String get hintTutorial => 'ऐप का उपयोग कैसे करें यह बताता है';

  @override
  String get hintDemoMode =>
      'लाइव सेवाओं के बजाय नमूना डेटा के साथ ऐप चलाता है';

  @override
  String get settingsBackgroundProtection => 'पृष्ठभूमि में गिरावट सुरक्षा';

  @override
  String get settingsBackgroundProtectionHelp =>
      'ऐप बंद होने या स्क्रीन बंद होने पर भी गिरने पर नज़र रखता है। एक स्थायी सूचना दिखेगी और थोड़ी अधिक बैटरी खर्च होगी।';

  @override
  String get settingsBackgroundProtectionOn =>
      'पृष्ठभूमि गिरावट सुरक्षा चालू की गई';

  @override
  String get settingsBackgroundProtectionOff =>
      'पृष्ठभूमि गिरावट सुरक्षा बंद की गई';

  @override
  String get backgroundSosBannerTitle => 'संभावित गिरावट का पता चला';

  @override
  String get backgroundSosBannerBody =>
      'जल्द ही मदद के लिए कॉल किया जाएगा। यदि आप ठीक हैं तो रद्द करें दबाएं।';

  @override
  String get backgroundSosCancelButton => 'आपातकाल रद्द करें';

  @override
  String get settingsAddFromContacts => 'संपर्कों से जोड़ें';

  @override
  String get settingsNoContactSelected =>
      'कोई संपर्क नहीं चुना गया, या अनुमति अस्वीकृत';

  @override
  String get settingsResetDefaults => 'डिफ़ॉल्ट पर रीसेट करें';

  @override
  String get settingsResetDone => 'सेटिंग्स डिफ़ॉल्ट पर रीसेट की गईं';

  @override
  String settingsCurrentValue(String value) {
    return 'वर्तमान: $value';
  }

  @override
  String settingsErrorGeneric(String message) {
    return 'त्रुटि: $message';
  }

  @override
  String get settingsNoContacts => 'कोई संपर्क नहीं जोड़ा गया';

  @override
  String tutorialTitle(String current, String total) {
    return 'ट्यूटोरियल ($current / $total)';
  }

  @override
  String get tutorialNext => 'अगला';

  @override
  String get tutorialPrevious => 'पिछला';

  @override
  String get tutorialFinish => 'समाप्त';

  @override
  String get tutorialComplete =>
      'ट्यूटोरियल पूरा हुआ। अब आप ऐप का उपयोग कर सकते हैं।';

  @override
  String get tutorialWelcomeTitle => 'स्वागत है';

  @override
  String get tutorialWelcomeBody =>
      'GaBN में आपका स्वागत है। यह ऐप आपके कैमरे और आवाज़ आदेशों की मदद से सुरक्षित रूप से चलने में सहायता करता है।';

  @override
  String get tutorialCameraTitle => 'कैमरा पूर्वावलोकन';

  @override
  String get tutorialCameraBody =>
      'कैमरा पूर्वावलोकन दिखाता है कि आपके सामने क्या है। फ़ोन को सीधा, आगे की ओर रखें।';

  @override
  String get tutorialObstacleTitle => 'बाधा पहचान';

  @override
  String get tutorialObstacleBody =>
      'ऐप आपके सामने की वस्तुओं का पता लगाता है। यह बताएगा कि आगे कौन सी बाधाएं हैं और वे कहां हैं।';

  @override
  String get tutorialSosTitle => 'आपातकालीन एसओएस';

  @override
  String get tutorialSosBody =>
      'अलर्ट भेजने के लिए एसओएस बटन दबाएं या फ़ोन को ज़ोर से हिलाएं। आपका स्थान आपके आपातकालीन संपर्कों को भेजा जाता है। रद्द करने के लिए कहीं भी टैप करें या वॉल्यूम बटन दबाएं।';

  @override
  String get tutorialVoiceTitle => 'आवाज़ आदेश';

  @override
  String get tutorialVoiceBody =>
      'आप ऐप को आवाज़ से नियंत्रित कर सकते हैं। सभी आदेश सुनने के लिए \"help\" कहें, या \"navigate to\" के बाद स्थान का नाम कहें।';

  @override
  String get tutorialPhotoTitle => 'फ़ोटो लेना';

  @override
  String get tutorialPhotoBody =>
      'फ़ोटो लेने के लिए फ़ोटो बटन दबाएं या वॉल्यूम बटन दो बार दबाएं। ऐप बताएगा कि उसे क्या दिखता है।';

  @override
  String get tutorialTextTitle => 'पाठ पढ़ना';

  @override
  String get tutorialTextBody =>
      'कैमरे में दिखने वाला कोई भी पाठ पढ़ने के लिए पाठ पढ़ें बटन दबाएं, या \"read text\" कहें।';

  @override
  String get tutorialSavedTitle => 'सहेजे गए स्थान';

  @override
  String get tutorialSavedBody =>
      'आप अपना वर्तमान स्थान सहेज सकते हैं और बाद में \"navigate to\" और नाम कहकर वहां जा सकते हैं, जैसे \"navigate to home\"।';

  @override
  String get tutorialSettingsTitle => 'सेटिंग्स';

  @override
  String get tutorialSettingsBody =>
      'ऐप को उपयोग में आसान बनाने के लिए सेटिंग्स में पाठ का आकार, बटन का आकार और कंट्रास्ट समायोजित करें।';

  @override
  String get sosSmsNeedsSend => 'आपको भेजें दबाना होगा';

  @override
  String get sosSmsFailed => 'विफल';

  @override
  String routeFound(String distance, String duration) {
    return 'मार्ग मिल गया। $distance। $duration।';
  }

  @override
  String get saveLocationTitle => 'स्थान सहेजें';

  @override
  String settingsTextSizeSet(String value) {
    return 'पाठ का आकार $value पर सेट किया गया';
  }

  @override
  String settingsButtonSizeSet(String value) {
    return 'बटन का आकार $value प्रतिशत पर सेट किया गया';
  }

  @override
  String settingsContrastSet(String value) {
    return 'कंट्रास्ट $value पर सेट किया गया';
  }

  @override
  String settingsVibrationSet(String value) {
    return 'कंपन की तीव्रता $value प्रतिशत';
  }

  @override
  String settingsCommandDelaySet(String value) {
    return 'आदेश विलंब $value मिलीसेकंड';
  }

  @override
  String settingsVoiceSpeedSet(String value) {
    return 'आवाज़ की गति $value';
  }

  @override
  String contactAddedNamed(String name) {
    return '$name को आपातकालीन संपर्कों में जोड़ा गया';
  }

  @override
  String sosCallingContact(String name) {
    return 'कॉल किया जा रहा है: $name';
  }

  @override
  String get sosOverlayHeading => 'आपातकालीन एसओएस';

  @override
  String get actionCancelUpper => 'रद्द करें';

  @override
  String get sosEmergencyServices => 'आपातकालीन सेवाएं';
}
