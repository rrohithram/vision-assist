# Vision Assist — Accessibility Navigator

An Android navigation aid for blind and low-vision users. The camera watches for
obstacles and announces them, walking directions are spoken turn by turn, and a
fall or a shake raises an emergency alert that texts and calls the people you
choose.

Everything is designed to work without looking at the screen: speech is the
primary output, the whole screen is a touch target during an emergency, and
volume buttons and voice commands cover the rest.

## Features

| | |
|---|---|
| **Obstacle detection** | YOLO26 nano over the camera feed, announced by position and proximity |
| **Navigation** | Google Directions, spoken step by step, with haptic turn cues |
| **Voice control** | Triple-tap or triple volume-press to speak a command |
| **Emergency SOS** | Fall or shake detection → 10-second cancellable countdown → SMS with location, then a call |
| **Background protection** | Optional foreground service keeps fall detection alive with the app closed |
| **What's nearby** | Places within 400 m, nearest first, spoken with distances |
| **Text reading** | On-device OCR of whatever the camera sees |
| **Scene description** | Gemini describes a captured photo |
| **Languages** | English and Hindi, including spoken output and voice recognition |

## Requirements

- Flutter 3.32+ / Dart 3.8+ (developed against Flutter 3.35.7)
- **JDK 17 or 21.** Gradle 9.1 does not support JDK 25, which ships with recent
  Android Studio. If a build fails with `Unsupported class file major version`,
  point Flutter at a supported JDK:
  ```
  flutter config --jdk-dir="/path/to/jdk-21"
  ```
- Android SDK 36, NDK `28.2.13676358` (required by `ultralytics_yolo`)
- Android device with a rear camera. `minSdk` is 24.

## Setup

### 1. API keys

Keys are injected at build time. They are **not** committed and **not** bundled
as an asset — anything in `assets/` can be extracted from the APK with `unzip`.

```bash
cp dart_defines.example.json dart_defines.json
# then fill in your keys
```

| Key | Needed for | Without it |
|---|---|---|
| `GOOGLE_MAPS_API_KEY` | Directions API, map view | Navigation falls back to opening Google Maps |
| `GEMINI_API_KEY` | Photo scene description, SOS message wording | Photo capture still works, description does not |
| `EMERGENCY_NUMBER` | Number dialled when no contact is saved | Defaults to `112` |

`dart_defines.json` is gitignored.

The **native** Maps key is separate, because the Android SDK reads it from the
manifest. Put it in `android/local.properties` (also gitignored):

```properties
MAPS_API_KEY=your-key-here
```

Restrict both keys to your package name and signing certificate in the Google
Cloud console.

The Maps key needs **Directions API** (navigation), **Maps SDK for Android**
(the map view) and **Places API** (the "what's nearby" command) enabled. Each
degrades on its own: without Places, nearby lookups say so out loud and
everything else keeps working.

### 2. Detection model

The app loads YOLO26n from `assets/models/yolo26n.tflite` if present, and
otherwise downloads it once on first run and caches it on the device. Bundling
it means detection works with no network from the very first launch:

```bash
pip install ultralytics
python -c "from ultralytics import YOLO; YOLO('yolo26n.pt').export(format='litert', imgsz=640)"
# copy the resulting .tflite to assets/models/yolo26n.tflite
```

If the model cannot be loaded, the app still runs — navigation, OCR, voice and
SOS are unaffected and obstacle announcements are simply disabled. Look for
`YOLO26n loaded from …` in the log to see which source was used.

#### What gets announced

`ObstacleInterpreter` decides this, and it is pure geometry — no camera or
model needed to test it:

- **Distance is estimated from the larger of width and height**, weighted by
  how low the box sits in the frame. Width alone called a person two metres
  away "far" (narrow but tall) and a parked car across the street "close"
  (wide but distant).
- **Static clutter below the near threshold is dropped**, so the app stops
  narrating the whole street.
- **Vehicles and animals get a wider radius** — hearing about a car early
  costs little, late costs a lot.
- **Anything growing quickly between frames is announced regardless of how
  small it currently looks.** This is how a car closing at speed gets called
  before it arrives, and it is the one case where a far-away object is worth
  mentioning.
- Sampling runs at 1.2 s normally and **speeds up to 0.5 s while a hazard is
  in view**, because approach is measured between consecutive readings and
  the idle rate is too slow to react to traffic. The extra cost is only paid
  when there is something to track.

Thresholds are the constants at the top of `obstacle_interpreter.dart`.

#### Camera lifecycle

Android reclaims the camera from a backgrounded app. The controller must be
**disposed on pause and rebuilt on resume** (`VisionService.handleAppPaused`
/ `handleAppResumed`) — merely stopping the image stream leaves a dead
controller that can never stream again, which made obstacle detection work
exactly once per app launch.

### 3. Crash reporting (optional)

Crashlytics wiring is already in `main.dart`, but it needs a real Firebase
project to report anywhere:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This creates/links a Firebase project, downloads `android/app/google-services.json`,
and overwrites `lib/firebase_options.dart` (currently a placeholder) with real
values. Until you do this, `main.dart` catches the resulting init failure and
just skips crash reporting — the app runs identically either way.

### 4. Background fall protection (optional, off by default)

Settings → "Background Fall Protection" runs fall/shake detection in an
Android foreground service so it keeps working when the app is backgrounded,
the screen is off, or the app is swiped away from recents — without it,
Android eventually suspends or kills the app's isolate, so a fall in that
state can go undetected. It's opt-in because it shows a persistent
notification and uses a little more battery.

The background isolate runs its own copy of the detection/SOS logic and does
**not** have access to the app's custom SMS/call-state platform channels
(those are wired to `MainActivity`'s engine only), so while backgrounded:
- Calling still works normally (real plugins register on every engine).
- The SMS may fall back to opening a composer that needs one tap, instead of
  sending silently.
- The call-answered detection isn't available, so the spoken message uses the
  fixed-delay fallback.
- Alerts speak English only — there's no BuildContext to resolve the locale
  from a headless isolate.

Cancelling a background-triggered alert brings the app to the foreground
automatically and shows a full-screen cancel prompt; tap anywhere on it to
stand the alert down.

**This has not been verified on a real device or emulator** — this
environment has no Android SDK to build against. Test it thoroughly (trigger
a real fall motion with the app backgrounded, confirm the cancel prompt
appears and works, confirm the notification shows the correct
foreground-service type on Android 14+) before relying on it.

### 5. Run

```bash
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

## ⚠️ Testing the SOS path

With no emergency contact saved, an SOS dispatch **calls `112` — real emergency
services** — and fall detection can trigger that without you asking.

Before exercising anything SOS-related, either save a contact you own, or point
the build at your own number:

```bash
flutter run --dart-define=EMERGENCY_NUMBER=5551234567
```

A build carrying an override says so in orange on the Settings screen. The
number is also editable at runtime under Settings → Emergency number.

## Building a release

```bash
flutter build apk --release --split-per-abi \
  --dart-define-from-file=dart_defines.json
```

`--split-per-abi` matters: a universal APK is ~105 MB, because the LiteRT, ML
Kit and Flutter native libraries are duplicated across three architectures.

### Signing

Generate an upload keystore once, and keep it somewhere you will not lose it —
Play ties the app to this key permanently:

```bash
keytool -genkey -v -keystore ~/gabn-upload.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` (gitignored, along with `*.jks`):

```properties
storeFile=/absolute/path/to/gabn-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

The release build picks it up automatically. Without it the build still
works, but falls back to the debug key and logs a warning — that APK cannot
be uploaded to Play.

### Still required before Play

- **`SEND_SMS` declaration.** The app sends emergency messages directly rather
  than opening a composer, because a user who has just fallen cannot press send.
  That is a Play restricted permission and needs a declaration form; emergency
  and safety apps are a permitted use case.
- **A foreground-service justification**, if background fall protection ships
  enabled. The service is declared as type `health`.
- **Minification is off.** The app resolves models and plugin classes
  reflectively and a release-only R8 failure in the SOS path is worse than a
  larger APK, so `isMinifyEnabled` stays false until someone can test a
  minified build on a device. `proguard-rules.pro` is kept current for that day.

The application ID is `com.gabn.navigator`. Change it **now** if you want
something else — it cannot be changed after the first upload to Play.

## Project layout

```
lib/
  config/app_config.dart      Build-time keys and defaults
  l10n/                       ARB files (en, hi) + generated delegates
  screens/
    widgets/                  Presentational pieces of the home screen
  services/                   One concern each; all app-wide singletons
test/                         206 tests, no device required
```

Services are singletons and are **released**, not disposed, when a screen goes
away — several are `ChangeNotifier`s, and disposing one is permanent.

## Accessibility notes

The app is self-voicing: it speaks its own state rather than relying on a
screen reader. That creates one wrinkle worth knowing about.

- Every control carries an explicit **semantic label and hint**, because the
  visible labels are abbreviations chosen to fit the tile (`CAM ON`) and are
  not what anyone wants read aloud. Toggles expose on/off state so TalkBack
  announces it rather than leaving the user to infer it.
- The status banner is a **live region**, so TalkBack announces changes
  without the user going looking for them.
- Because of that live region, routine surroundings commentary goes through
  `TtsService.speakAmbient`, which **stays quiet while a screen reader is
  running** — otherwise the user hears everything twice, overlapping.
  Anything urgent or asked for (obstacle in the path, navigation step, SOS
  countdown, answer to a voice command) uses `speak`/`speakQueued` and is
  never suppressed: a live region is announced at the screen reader's
  discretion and can be swallowed.
- **Colour means identity, not state** (`ControlPalette`). Every action keeps
  one hue for the life of the app, so a user with poor but usable sight finds
  the photo button by its pink and the voice button by its lime without
  reading. Hues are spread deliberately rather than harmonised — the job is
  "tells itself apart out of focus", not "tasteful".
- A toggle that is off **keeps its hue** and changes its fill, icon and label
  instead, so state is never colour-only (WCAG 1.4.1) and the control stays
  findable while off. Red is reserved for emergencies and used nowhere else.
- Tiles are filled with a wash of their own colour rather than outlined: a
  thin border is the first thing to disappear at low acuity, so the colour
  needs area behind it.
- `home_widgets_test.dart` enforces all of this — a 4.5:1 contrast floor
  against both the panel and each tile's own wash, mutual RGB distance
  between every pair of action colours, and the red reservation. Changing a
  colour to something unreadable or ambiguous fails the build.
- **The triple-tap gesture does not work under TalkBack**, which consumes
  taps for explore-by-touch. The `VOICE` button and the triple volume-press
  both do the same thing and work regardless.

### Voice and gesture

These are the only two routes into the app for a fully blind user not
running a screen reader, so they get more defensive treatment than the rest:

- The command table in `voice_command_service.dart` is **bilingual**. The
  recogniser is pointed at `hi_IN` for Hindi users, so what comes back is
  Devanagari; matching is plain substring containment, so both scripts share
  one list per intent. The emergency-cancel phrase list is bilingual too.
- Every way voice can fail now **says so out loud** — engine unavailable,
  nothing heard, phrase not understood. Silence is indistinguishable from
  "still listening" if you cannot see the screen.
- Volume gestures resolve after a 500 ms quiet window, because a triple
  press cannot be told from a double press any earlier. The single-press
  callback is *not* delayed: it is the emergency cancel.

## Development

```bash
flutter analyze          # expected: no issues
flutter test             # expected: all pass
flutter gen-l10n         # after editing lib/l10n/*.arb
```

Adding a user-facing string means adding it to **both** `app_en.arb` and
`app_hi.arb`. Three tests enforce this: every English key must have a Hindi
translation, no Hindi value may be left as its English source, and no bare
English literal may appear inside `Text()` or `speak()` under `lib/screens`.
