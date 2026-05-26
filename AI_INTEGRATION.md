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
  mediquo_flutter: ^1.0.0
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

Every method returns `Future<void>` and throws a `MediquoException` on failure.

| Method | Use |
| --- | --- |
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
`MediquoNotInitializedException`, `MediquoPlatformException`.

## Behavioural rules (must respect)

- Preferred startup: `mediquo.startSession(configuration)` (initialise +
  authenticate in one step; if initialise fails, authenticate is not attempted).
- Preconditions are enforced by the native SDK and surfaced as exceptions:
  - `authenticate` / `registerPushToken` before a successful `initialize` →
    `MediquoNotInitializedException`.
  - `openProfessionalList` / `openFromNotification` / `logout` before an
    authenticated patient → `MediquoNotInitializedException`.
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

- **Android** (the MediQuo native SDK is a self-contained AAR; keep the host
  setup minimal):
  - Kotlin `org.jetbrains.kotlin.android` `2.2.0` (the SDK is compiled with
    Kotlin 2.2), JDK 17, `compileSdk` 35+, `minSdk` 29.
  - Do **NOT** apply Hilt, KSP or the Compose Gradle plugin, and do **NOT** add a
    Compose BOM. The plugin supplies the Compose BOM via `api platform(...)`.
    Applying the Compose plugin in an app without Compose code fails with
    `IncompatibleComposeRuntimeVersionException`.
  - Add the MediQuo Maven repo to `android/settings.gradle` under
    `dependencyResolutionManagement.repositories`:
    `maven { url = uri("https://mediquo.jfrog.io/artifactory/android-sdk") }`
    (a plugin cannot inject it under `FAIL_ON_PROJECT_REPOS`, the modern default).
    Do NOT add the `com.mediquo:mediquo-sdk` dependency — this plugin declares it.
  - SDK version: the plugin pins `com.mediquo:mediquo-sdk` to `3.8.1`; override
    via `mediquo.sdkVersion=<version>` in `android/gradle.properties` only if
    MediQuo provides a different one.
  - Permissions: `CAMERA`, `RECORD_AUDIO`, and `POST_NOTIFICATIONS` (Android 13+).
    For push add Firebase (`google-services.json` + Google Services plugin).
    R8/ProGuard rules for the MediQuo SDK's transitive deps (video stack,
    MediaPipe, Protobuf, gRPC, Jackson, OSGi) ship with the plugin automatically,
    so a `minifyEnabled` release build needs no MediQuo ProGuard setup. (A
    minified app may still need Flutter's own
    `-dontwarn com.google.android.play.core.**` — a Flutter concern, not ours.)
  - Verified at build time against `mediquo-sdk:3.8.1`. If a future SDK build
    reports a Hilt/Dagger error, apply Hilt + KSP and make the `Application`
    `@HiltAndroidApp` — not needed today.
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
