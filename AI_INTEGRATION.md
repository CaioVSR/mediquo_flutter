# mediquo_flutter — AI integration guide

This is the complete, authoritative guide an AI assistant uses to integrate
`mediquo_flutter`. The one-line prompt under
[Integrate with AI](README.md#integrate-with-ai) tells your assistant to fetch
this file; you can also paste it directly. It states the exact public API and the
rules so the assistant generates correct code without guessing.

---

You are integrating the Flutter package **`mediquo_flutter`** into my app. Follow
this specification exactly. Do not invent classes, methods, parameters or
behaviour that are not listed here. If something you need is missing, ask me
instead of guessing.

## What the package is

`mediquo_flutter` is a federated Flutter plugin that bridges the **native**
MediQuo telemedicine SDKs (chat, video calls, professional list). Its public API
is **plain Dart**: a `Mediquo` object with `Future`-returning methods. It imposes
**no state-management library** and exposes no observable state — you reflect the
results in whatever state solution the app already uses (`setState`,
`ChangeNotifier`, Riverpod, Bloc, …). The app performs **no** MediQuo network
calls.

## What I must provide (ask me for these)

- `apiKey`: the partner API key, from my backend.
- `clientCode`: the patient identifier — a CPF, **digits only** — created in
  advance by my backend through the MediQuo Patients API.

Never call MediQuo REST APIs from the app and never embed the partner key in a
way that ships secrets you would not put in a mobile binary; these come from my
backend at runtime.

## Install

```yaml
dependencies:
  mediquo_flutter: ^2.0.0
```

Native setup is required and is the host app's responsibility (summarised at the
end). The package cannot inject it.

## Public API (use only these)

### Entry point

```dart
final mediquo = Mediquo(); // Mediquo({MediquoFlutterPlatform? platform}) — platform is for tests only
```

### Configuration

```dart
// Throws ArgumentError on empty apiKey or non-digit/empty clientCode.
MediquoConfiguration.validated({required String apiKey, required String clientCode});
// Unvalidated alternative:
MediquoConfiguration({required String apiKey, required String clientCode});
```

### Methods

`isSupported()` returns `Future<bool>`. Every other method returns
`Future<void>` and throws a `MediquoException` on failure.

| Method | Use |
| --- | --- |
| `mediquo.isSupported()` | whether this device can run the SDK (always `true` on iOS; Android needs `arm64-v8a`) |
| `mediquo.initialize(String apiKey)` | initialise the SDK |
| `mediquo.authenticate(String clientCode)` | authenticate the patient |
| `mediquo.startSession(MediquoConfiguration configuration)` | initialise **then** authenticate (preferred) |
| `mediquo.openProfessionalList()` | present the native UI |
| `mediquo.openFromNotification(Map<String, Object?> payload)` | open the screen for a tapped push |
| `mediquo.registerPushToken(MediquoPushToken token)` | register a push token |
| `mediquo.logout()` | log the patient out |

### Push tokens

```dart
MediquoPushToken.fcm(String value);      // Android, or iOS via Firebase
MediquoPushToken.apns(String hexValue);  // iOS raw APNs token, as a hex string
enum MediquoPushTokenType { fcm, apns }
```

The package depends on **no** Firebase package. Obtain tokens in the app with
`firebase_messaging` and forward them via `mediquo.registerPushToken(...)`. For a
tapped notification, forward `RemoteMessage.data` via
`mediquo.openFromNotification(...)`.

The per-device token is the app's job (only the device can mint it). The Firebase
**server credential** (service account) that authorises MediQuo's backend to
*send* pushes is configured in MediQuo's portal out-of-band — it is NOT handled
by this package and must never be embedded in the app.

### Errors (sealed hierarchy, thrown by every method)

`MediquoException` (has `message`, `cause`) → `MediquoInitializationException`,
`MediquoAuthenticationException`, `MediquoOpenException`,
`MediquoDeauthenticationException`, `MediquoPushRegistrationException`,
`MediquoNotInitializedException`, `MediquoUnsupportedDeviceException`,
`MediquoPlatformException`.

## Behavioural rules (must respect)

- Check `await mediquo.isSupported()` before offering MediQuo; when it is
  `false` (32-bit or x86 Android devices), hide the entry point. Every other
  call on such a device throws `MediquoUnsupportedDeviceException`.
- Preferred startup: `mediquo.startSession(configuration)` (initialise +
  authenticate in one step; if initialise fails, authenticate is not attempted).
- Preconditions are enforced by the native SDK and surfaced as exceptions:
  - `authenticate` before a successful `initialize` →
    `MediquoNotInitializedException`.
  - `openProfessionalList` / `openFromNotification` / `registerPushToken` /
    `logout` before an authenticated patient → `MediquoNotInitializedException`.
- Wrap every call in `try`/`catch (MediquoException)` and surface `error.message`
  to the user. The package holds no state, so track "busy" / "authenticated"
  yourself (a `bool` with `setState` is enough).

## Canonical example (match this shape — vanilla `setState`, no state library)

```dart
import 'package:flutter/material.dart';
import 'package:mediquo_flutter/mediquo_flutter.dart';

class MediquoScreen extends StatefulWidget {
  const MediquoScreen({
    super.key,
    required this.apiKey,
    required this.clientCode,
  });

  final String apiKey;
  final String clientCode;

  @override
  State<MediquoScreen> createState() => _MediquoScreenState();
}

class _MediquoScreenState extends State<MediquoScreen> {
  final _mediquo = Mediquo();
  bool _busy = false;
  bool _authenticated = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      await _mediquo.startSession(
        MediquoConfiguration.validated(
          apiKey: widget.apiKey,
          clientCode: widget.clientCode,
        ),
      );
      setState(() => _authenticated = true);
    } on MediquoException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) return const Center(child: CircularProgressIndicator());
    return Center(
      child: FilledButton(
        onPressed: _authenticated ? _mediquo.openProfessionalList : _start,
        child: Text(_authenticated ? 'Open MediQuo' : 'Start session'),
      ),
    );
  }
}
```

## Native setup to remind me about

- **Android** (MediQuo SDK 26.x, a self-contained AAR):
  - Toolchain: `compileSdk` **37** (the AAR's `minCompileSdk`; `targetSdk` may
    stay lower), `minSdk` 29, Kotlin `org.jetbrains.kotlin.android` **2.4.0**,
    Android Gradle Plugin **9.1.1**, Gradle **9.3.1**, JDK 17. These are the
    tested versions; do not go lower without telling me.
  - Do **NOT** apply Hilt, KSP or the Compose Gradle plugin and do **NOT** add a
    Compose or Firebase BOM for MediQuo: the SDK brings its own.
  - Add the MediQuo Maven repo to `android/settings.gradle` under
    `dependencyResolutionManagement.repositories`:
    `maven { url = uri("https://mediquo.jfrog.io/artifactory/android-sdk") }`
    (a plugin cannot inject it under `FAIL_ON_PROJECT_REPOS`, the modern default).
    Do NOT add the `com.mediquo:mediquo-sdk` dependency — this plugin declares it.
  - SDK version: the plugin pins `com.mediquo:mediquo-sdk` to `26.8.1`. Remove
    any `mediquo.sdkVersion=3.8.1` left in `android/gradle.properties` from 1.x;
    set `mediquo.sdkVersion` only if MediQuo provides a different 26.x version.
  - Devices: the SDK ships native code for `arm64-v8a` only (~200 MB
    uncompressed). Use `isSupported()` at runtime; prefer an App Bundle so
    devices download only their ABI.
  - Manifest permissions the app declares: `CAMERA`, `RECORD_AUDIO`,
    `MODIFY_AUDIO_SETTINGS`, `BLUETOOTH_CONNECT`, plus
    `<uses-feature android:name="android.hardware.camera" android:required="false" />`.
    The SDK already declares `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK` and
    `POST_NOTIFICATIONS`. No storage permission is needed.
  - Attachments: the plugin declares a `FileProvider`
    (`com.mediquo.mediquo_flutter.MediquoFlutterFileProvider`) on the authority
    `${applicationId}`, which is what the SDK uses. Do NOT declare another
    provider on `${applicationId}` and do NOT add a MediQuo `file_paths.xml`.
  - Push: the SDK registers `com.mediquo.ui.firebase.MediQuoFirebaseService` for
    `com.google.firebase.MESSAGING_EVENT`. If the app receives FCM through
    `firebase_messaging` or OneSignal, remove it in the app manifest
    (`xmlns:tools` on `<manifest>`, then
    `<service android:name="com.mediquo.ui.firebase.MediQuoFirebaseService" tools:node="remove" />`
    inside `<application>`), show MediQuo notifications with the app's own push
    stack, and forward the tapped message's `data` to
    `mediquo.openFromNotification(...)`. On Android a `room_id` opens that chat,
    an incoming-call payload (`type: call_requested`, `call_*` keys) opens the
    call screen, anything else the professional list. For push also add
    Firebase (`google-services.json` + Google Services plugin).
  - R8: the SDK's keep rules ship inside its AAR and the plugin adds the
    remaining `-dontwarn` rules, so a `minifyEnabled` release build needs no
    MediQuo ProGuard setup. (A minified app may still need Flutter's own
    `-dontwarn com.google.android.play.core.**` — a Flutter concern, not ours.)
- **iOS** (Xcode 26): the MediQuo SDK (`MediQuoSDK` 26.1.2) is a binary
  XCFramework and the plugin bundles it for **both** CocoaPods and SPM — do NOT
  add it manually. With CocoaPods (the default) there is no extra step; the
  podspec fetches the XCFramework at `pod install`. If the app uses CocoaPods
  (e.g. a OneSignal Notification Service Extension), keep Flutter SPM disabled to
  avoid SPM/CocoaPods conflicts. To use SPM instead, enable it
  (`flutter config --enable-swift-package-manager`). Either way set the iOS
  **deployment target to 17.0**, add `NSCameraUsageDescription` and
  `NSMicrophoneUsageDescription` to `Info.plist`, set the app Accent Color, and
  enable the Push Notifications capability for push.

## Do not

- Do not call MediQuo REST/portal APIs from the app.
- Do not use the MediQuo web widget — this package uses the native SDKs.
- Do not assume the package manages state or exposes a bloc/stream — it is plain
  `Future`s; you own the state.
- Do not store push tokens across sessions or invent API names.

Now ask me for `apiKey`, `clientCode`, my state-management setup, and whether I
need push, then generate the integration code.
