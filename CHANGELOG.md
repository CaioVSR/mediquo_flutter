# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.0.0

Android moves from the legacy `com.mediquo:mediquo-sdk` 3.8.1 to the rewritten
26.x SDK (`com.mediquo.sdk.MediQuo`, default 26.8.1). The Dart API stays
source-compatible with 1.x; the breaking changes are the host-app requirements
below. iOS is unchanged (MediQuoSDK 26.1.2).

### Breaking

- **Android toolchain.** The 26.x AAR requires `compileSdk` 37 and is built
  with Kotlin 2.4. Tested with AGP 9.1.1, Gradle 9.3.1, Kotlin 2.4.0 and JDK 17;
  `minSdk` stays 29.
- **arm64-v8a only.** The SDK ships its native libraries (~200 MB uncompressed)
  for `arm64-v8a` only. On other ABIs every call now fails with
  `MediquoUnsupportedDeviceException`; check `Mediquo.isSupported()` first.
- **New `MediquoException` subtype.** `MediquoUnsupportedDeviceException`
  (code `unsupported_device`) joins the sealed hierarchy, so exhaustive
  `switch`es over `MediquoException` need a new case.
- **Push service.** The plugin no longer declares
  `com.mediquo.chat.fcm.MediquoFirebaseMessagingService`. The 26.x SDK registers
  its own `com.mediquo.ui.firebase.MediQuoFirebaseService`; apps that receive
  FCM through `firebase_messaging` or OneSignal should remove it with
  `tools:node="remove"` and forward MediQuo payloads to `openFromNotification`.
- **FileProvider authority.** The plugin now declares a `FileProvider` on
  `${applicationId}` (the authority the SDK uses for attachments). Host apps
  must not declare another provider on that authority, and no longer need their
  own `file_paths.xml` for MediQuo.
- **Gradle properties.** `mediquo.composeBomVersion` and
  `mediquo.firebaseMessagingVersion` are gone (the SDK brings its own BOMs). An
  app that still sets `mediquo.sdkVersion=3.8.1` must remove it.
- `registerPushToken` with an APNs token on Android now fails with
  `MediquoPushRegistrationException` instead of being sent as FCM.

### Added

- `Mediquo.isSupported()` (Dart, Pigeon and both platforms): `true` on iOS; on
  Android, `true` only when the device supports `arm64-v8a`.
- Android `openFromNotification` routes `room_id` payloads to that chat and
  incoming-call payloads (`type: call_requested` with `call_*` keys) to the call
  screen; anything else opens the professional list.
- Android incoming calls: the plugin listens to the SDK's event delegate, opens
  the call screen when a call arrives over the socket and closes it when the
  call is rejected.

### Changed

- Android bridge rewritten on the coroutine-based `MediQuo` API, mirroring the
  iOS bridge and keeping the same error codes.
- `consumer-rules.pro` drops the OpenTok/WebRTC keep rules, now shipped by the
  SDK's own `proguard.txt`.
- The podspec version now matches the package (was `1.0.0`), and
  `Package.swift` pins MediQuoSDK to exactly `26.1.2`, like the podspec.

## 1.0.3

### Changed

- Polished dartdoc copy in the `Mediquo` class and library-level docs
  (tightened wording and removed stray typography). Docs only; no API changes.

## 1.0.2

### Added

- Buy Me a Coffee support badge and links in the README (docs only; no API
  changes).

## 1.0.1

### Changed

- Shortened the package description to fit pub.dev's 60–180 character limit
  (restores the valid-pubspec pub points), dropping the "bring your own state
  management" tagline from the `pubspec.yaml` description and the README.

## 1.0.0

### Added

- Initial release of the federated native MediQuo plugin.
- Plain-Dart `Mediquo` facade (`Future`-based) over a Pigeon-typed
  `MediquoFlutterPlatform`; no state-management library imposed.
- `MediquoConfiguration` (with validation), `MediquoPushToken` and the
  `MediquoException` sealed hierarchy.
- Android (Kotlin) and iOS (Swift) bridges to the native SDKs, including push
  token registration and open-from-notification.
- Android Gradle setup supplies the Compose BOM (so the MediQuo SDK's versionless
  Compose dependencies resolve) and bundles R8/ProGuard consumer rules for the
  MediQuo SDK's transitive dependencies (OpenTok/WebRTC video stack, plus
  MediaPipe, Protobuf, gRPC, Jackson and OSGi), so a `minifyEnabled` release build
  needs no manual MediQuo ProGuard setup.
- iOS works with **both** Swift Package Manager and CocoaPods: `Package.swift`
  declares the MediQuo SDK for SPM, and the podspec fetches and vendors the same
  XCFramework (checksum-pinned to `26.1.2`) at `pod install`. Apps that stay on
  CocoaPods — for example with a OneSignal Notification Service Extension — work
  without enabling Flutter SPM.
- Runnable example app with Android and iOS hosts built in CI (`flutter build apk
  --release`, exercising **R8** and the bundled consumer rules; plus iOS via
  **both** CocoaPods and SPM), compiling the native Kotlin and Swift against the
  real MediQuo SDKs and validating the consumer setup on every change.
- Full Dart unit-test coverage.
