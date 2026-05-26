# mediquo_flutter

[![Buy Me a Coffee](https://img.shields.io/badge/%E2%98%95_Buy_me_a_coffee-support_this_package-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/caiovsr)

A federated Flutter plugin that integrates the **native** [MediQuo](https://mediquo.com)
telemedicine SDKs (chat, video calls and the professional list) through a
clean, plain-Dart API.

## 🤖 TL;DR: let the AI handle it

**Life's too short to read SDK docs.** Paste this into your favorite AI assistant and let it wire MediQuo into your app while you grab a
coffee ☕. [Make it two? Mine's an espresso.](https://buymeacoffee.com/caiovsr)

```text
Integrate the `mediquo_flutter` Flutter package into my project.

Fetch and follow this integration guide exactly:
https://raw.githubusercontent.com/CaioVSR/mediquo_flutter/HEAD/AI_INTEGRATION.md

For the exact API you may also read:
https://pub.dev/documentation/mediquo_flutter/latest/

Then ask me for my apiKey and clientCode and whether I need push notifications,
and implement the integration.
```

It fetches the full guide ([`AI_INTEGRATION.md`](AI_INTEGRATION.md)), asks for your
`apiKey` and `clientCode`, and writes the integration for you. Prefer doing it by
hand? Everything's below. 👇

- 🩺 Native Android & iOS MediQuo SDKs (native UI, native video stack).
- 🍎 iOS integrates via **CocoaPods or Swift Package Manager** (no Flutter SPM required).
- 🧩 Type-safe platform channel generated with [Pigeon](https://pub.dev/packages/pigeon).
- 🟦 Plain-Dart API (`Future`s).
- 🧪 100% unit-test coverage of the Dart layer.
- 🔒 No network calls in the app: credentials are produced server-side.

> **Architecture note.** This package bridges the **native** SDKs (the path the
> MediQuo Android/iOS docs describe). It is not the WebView widget wrapper.

## Quick start

1. Get an `apiKey` (partner key) and a `clientCode` (patient CPF, digits only)
   from your backend. The app makes no MediQuo network calls.
2. Add the dependency (see [Installation](#installation)) and do the per-platform
   [native setup](#platform-setup).
3. Drive everything through a `Mediquo` instance:

```dart
final mediquo = Mediquo();

await mediquo.startSession(
  MediquoConfiguration.validated(apiKey: apiKey, clientCode: clientCode),
);
await mediquo.openProfessionalList();
```

Every method returns a `Future` and throws a `MediquoException` on failure.
The package holds no state: the native SDK owns every screen and session.

## How authentication works

The plugin never talks to the MediQuo APIs. Patient creation and credentials are
a **backend** responsibility:

1. Your backend creates the patient through the MediQuo Patients API and keeps
   the patient's `documentNumber` (a CPF).
2. Your app receives two values from your backend:
   - `apiKey`: the partner API key.
   - `clientCode`: the patient `documentNumber` (CPF, digits only).
3. The plugin initialises and authenticates the native SDK with those values.

The native SDKs authenticate by **CLIENT_CODE (CPF)**, not by the web widget's
JWT access token.

## Installation

```yaml
dependencies:
  mediquo_flutter: ^1.0.0
```

```sh
flutter pub get
```

### Requirements

| Platform | Minimum |
| --- | --- |
| Dart | 3.12 |
| Flutter | 3.44 |
| Android | `minSdk` 29, `compileSdk` 35, JDK 17, Kotlin 2.2 |
| iOS | iOS 17, Xcode 26 |
| MediQuo SDK | Android `3.8.1` · iOS `26.1.2` |

## Platform setup

The native SDKs need host-app configuration that a plugin cannot inject for you.

### Android

The MediQuo native SDK lives in a **private Maven repository** and ships as a
self-contained AAR. Modern Flutter projects resolve repositories centrally
(`FAIL_ON_PROJECT_REPOS`), so the repo must be declared in your **app's** Gradle.

1. **Add the MediQuo Maven repository** to `android/settings.gradle`, inside
   `dependencyResolutionManagement.repositories`. This is the normal path, not an
   exception. You add only the *repository*. The `com.mediquo:mediquo-sdk`
   dependency itself is declared by this plugin.

   ```gradle
   dependencyResolutionManagement {
     repositories {
       google()
       mavenCentral()
       maven { url = uri("https://mediquo.jfrog.io/artifactory/android-sdk") }
       // Add the Vonage Video (TokBox) repo URL MediQuo provides if the build
       // cannot resolve that transitive dependency.
     }
   }
   ```

2. **SDK version.** The plugin pins `com.mediquo:mediquo-sdk` to `3.8.1` by
   default. Override it only to use a different version published by MediQuo:

   ```properties
   # android/gradle.properties
   mediquo.sdkVersion=3.8.1
   ```

3. **Toolchain.** The SDK is compiled with Kotlin 2.2, so that is the only hard
   plugin requirement:

   | Tool | Version |
   | --- | --- |
   | Kotlin (`org.jetbrains.kotlin.android`) | `2.2.0` |
   | JDK | 17 |
   | `compileSdk` | 35 or newer |
   | `minSdk` | 29 |

   You do **not** need Hilt, KSP or the Compose Gradle plugin, and you must
   **not** add a Compose BOM. The AAR is self-contained, and this plugin already
   supplies the Compose BOM via `api platform(...)`. (Applying the Compose plugin
   in an app that has no Compose code fails with
   `IncompatibleComposeRuntimeVersionException`.)

4. **Permissions.** Add `CAMERA` and `RECORD_AUDIO` (video calls) and, for push,
   `POST_NOTIFICATIONS` (Android 13+) to your `AndroidManifest.xml`. The
   [MediQuo Android SDK docs](https://documentacao.mediquo.com.br/sdk-android.html)
   cover the attachment `FileProvider` and the colour/font customisation keys.

   R8/ProGuard rules for the MediQuo SDK's transitive dependencies (the
   OpenTok/WebRTC video stack plus MediaPipe, Protobuf, gRPC, Jackson and OSGi)
   are **bundled** with the plugin (`android/consumer-rules.pro`) and applied
   automatically via `consumerProguardFiles`, so a `minifyEnabled` release build
   needs no MediQuo-specific ProGuard setup. (As with any minified Flutter app you
   may still need Flutter's own `-dontwarn com.google.android.play.core.**` for
   deferred components, a Flutter concern, not a MediQuo one.)

> Verified at **build** time against `com.mediquo:mediquo-sdk:3.8.1`: a real
> consumer app compiles with only the above (no Compose/Hilt/KSP plugins) and a
> **release** build (R8 / `minifyEnabled`) succeeds with the bundled rules.
> Confirm the SDK UI launches at runtime. If a future SDK build ever reports a
> Hilt/Dagger error, apply the Hilt + KSP plugins and make your `Application`
> `@HiltAndroidApp`. Not needed today.

### iOS

The MediQuo iOS SDK (`MediQuoSDK` 26.1.2) ships only as a binary XCFramework. The
plugin bundles it for **both** dependency managers, so you never add the SDK
yourself. Use whichever your app already uses:

- **CocoaPods (default).** No extra setup: the plugin's podspec fetches the
  MediQuo XCFramework (checksum-pinned to `26.1.2`) at `pod install` and vendors
  it. Keep Flutter SPM **disabled**. This is the right path when your app relies
  on CocoaPods (for example a OneSignal Notification Service Extension), where
  enabling Flutter SPM can clash with prebuilt dynamic frameworks.
- **Swift Package Manager.** If you prefer SPM, enable it
  (`flutter config --enable-swift-package-manager`) and the plugin's
  `Package.swift` pulls the same SDK.

Then, with either dependency manager:

1. Set the iOS **deployment target to 17.0** (the SDK's minimum) in your Xcode
   project.
2. Add the usage descriptions to `Info.plist`:

   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>Required to send voice messages.</string>
   <key>NSCameraUsageDescription</key>
   <string>Required to send images and join video calls.</string>
   ```

3. Set your app's **Accent Color** for branding and register for APNs if you use
   push. See the
   [MediQuo iOS SDK docs](https://documentacao.mediquo.com.br/sdk-ios.html).

## Usage

Create a `Mediquo`, keep it wherever your app keeps dependencies, and call its
`Future`-returning methods. Catch `MediquoException` to surface failures.

```dart
import 'package:mediquo_flutter/mediquo_flutter.dart';

final mediquo = Mediquo();

Future<void> startAndOpen(String apiKey, String clientCode) async {
  await mediquo.startSession(
    MediquoConfiguration.validated(apiKey: apiKey, clientCode: clientCode),
  );
  await mediquo.openProfessionalList();
}
```

A complete, runnable sample driven by `setState` lives in [`example/`](example/).

## Push notifications

This package **does not fetch** push tokens and depends on **no** Firebase
package. It only forwards a token you already have to the native SDK. Acquiring
the token is the app's job (typically with
[`firebase_messaging`](https://pub.dev/packages/firebase_messaging)).

End-to-end flow:

1. Your app obtains a token: FCM on Android; FCM or a raw APNs device token on
   iOS.
2. Your app calls `mediquo.registerPushToken(token)` once the patient is
   authenticated.
3. The plugin calls the native `registerPushToken`.
4. The MediQuo backend delivers pushes; MediQuo renders them natively (Android
   via the bundled `MediquoFirebaseMessagingService`, iOS via your notification
   delegate plus `getSDKViewController(forRemotePush:)`).

> **Who provides what.** The per-device token is obtained and registered by your
> **app** (the backend can't; only the device can mint it). The Firebase
> **server credential** (a service account) that authorises MediQuo's backend to
> *send* pushes is given to MediQuo **out-of-band via their portal**. It is
> never handled by this package and must never be embedded in the app.

```dart
final fcmToken = await FirebaseMessaging.instance.getToken();
if (fcmToken != null) {
  await mediquo.registerPushToken(MediquoPushToken.fcm(fcmToken));
}

// iOS using a raw APNs token instead of Firebase (pass it as a hex string):
final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
if (apnsToken != null) {
  await mediquo.registerPushToken(MediquoPushToken.apns(apnsToken));
}
```

Open the right screen when a notification is **tapped** (iOS routes via
`getSDKViewController(forRemotePush:)`; Android deep-links taps natively and
falls back to the professional list):

```dart
// e.g. from firebase_messaging's onMessageOpenedApp / getInitialMessage:
await mediquo.openFromNotification(message.data);
```

The [`example/`](example/) app shows the full wiring (permission request,
`getToken`, `onTokenRefresh`).

> **Android caveat.** FCM delivers messages to a single `FirebaseMessagingService`.
> If your app also consumes its own FCM messages, consolidate them into one
> custom service that forwards MediQuo payloads to the SDK via
> `MediquoSDK.getInstance()?.onFirebaseMessageReceived(remoteMessage)` (native).

## Public API

### Methods (`Mediquo`)

| Method | Purpose |
| --- | --- |
| `initialize(apiKey)` | initialise the SDK |
| `authenticate(clientCode)` | authenticate the patient |
| `startSession(configuration)` | initialise **then** authenticate |
| `openProfessionalList()` | present the native UI |
| `openFromNotification(payload)` | present the screen for a tapped push |
| `registerPushToken(token)` | register a push token |
| `logout()` | log the patient out |

Every method returns `Future<void>` and throws a `MediquoException` on failure.
The package holds no observable state; model the lifecycle in your own state
management.

### Push tokens

`MediquoPushToken.fcm(value)` or `MediquoPushToken.apns(hexValue)`, passed to
`registerPushToken`. See [Push notifications](#push-notifications).

### Errors

Failures are thrown as the sealed `MediquoException` hierarchy
(`MediquoInitializationException`, `MediquoAuthenticationException`,
`MediquoOpenException`, `MediquoDeauthenticationException`,
`MediquoPushRegistrationException`, `MediquoNotInitializedException`,
`MediquoPlatformException`).

## Testing

```sh
flutter analyze        # clean under very_good_analysis
flutter test --coverage
```

The Dart layer (models, exceptions, platform interface, method channel and the
`Mediquo` facade) is fully unit-tested. The native sources follow the documented
MediQuo SDK API.

## Documentation

API documentation is generated by `dart doc` and published on
[pub.dev](https://pub.dev/documentation/mediquo_flutter/latest/). Start from the
`Mediquo` class.

## License

[MIT](LICENSE).
