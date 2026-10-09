# mediquo_flutter example

A minimal app showing the `mediquo_flutter` plugin with plain `setState` (no
state-management library). It checks `isSupported()`, takes an `apiKey` and a
`clientCode` (patient CPF), starts a session, opens the native professional list
or a chat by room id (send camera, gallery and PDF attachments from there), and
logs out, plus Firebase push-token registration and open-from-notification.

## Run

```sh
cd example
flutter pub get
flutter run
```

Provide real credentials produced by your backend (see the package README for
the authentication flow). On Android, run it on an `arm64-v8a` device (the
MediQuo SDK has no 32-bit or x86 native code). The Android host shows the
setup the package README describes: `compileSdk` 37 with AGP 9.1.1, Gradle 9.3.1
and Kotlin 2.4.0, the call and camera permissions, and `MediQuoFirebaseService`
removed because the app receives FCM through `firebase_messaging`. Its release
build runs R8, which CI exercises with `flutter build apk --release`.
