# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
