# mediquo_flutter example

A minimal app showing the `mediquo_flutter` plugin with plain `setState` (no
state-management library). Enter an `apiKey` and a `clientCode` (patient CPF),
start a session, open the native professional list, and log out — plus Firebase
push-token registration and open-from-notification.

## Run

```sh
cd example
flutter pub get
flutter run
```

Provide real credentials produced by your backend (see the package README for
the authentication flow). The per-platform native setup (the MediQuo Maven repo
and camera/mic permissions on Android; SPM and `Info.plist` entries on iOS — no
Hilt/KSP/Compose needed) is required for the SDK UI to launch on a device. The
Android host is built in CI via `flutter build apk --debug`.
