import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/com/mediquo/mediquo_flutter/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.mediquo.mediquo_flutter'),
    swiftOut: 'ios/mediquo_flutter/Sources/mediquo_flutter/Messages.g.swift',
    swiftOptions: SwiftOptions(),
    dartPackageName: 'mediquo_flutter',
  ),
)

/// Transport-level push token type shared across the platform channel.
enum PushTokenType {
  /// Firebase Cloud Messaging token (Android, optionally iOS).
  fcm,

  /// Apple Push Notification service device token (iOS).
  apns,
}

/// Host (native) API invoked from Dart.
@HostApi()
abstract class MediquoHostApi {
  /// Initialises the native MediQuo SDK with the partner [apiKey].
  @async
  void initialize(String apiKey);

  /// Authenticates the pre-registered patient identified by [clientCode] (CPF).
  @async
  void authenticate(String clientCode);

  /// Presents the native professional-list interface.
  @async
  void openProfessionalList();

  /// Logs the current patient out of the native SDK.
  @async
  void deauthenticate();

  /// Registers a push [token] of the given [type] with the native SDK.
  @async
  void registerPushToken(String token, PushTokenType type);

  /// Presents the SDK screen that corresponds to a tapped remote notification.
  ///
  /// [payload] is the notification data (for example
  /// `RemoteMessage.data`). On iOS this routes to the deep-linked screen via
  /// `getSDKViewController(forRemotePush:)`; on Android, where the bundled
  /// messaging service already deep-links taps, it falls back to the
  /// professional list.
  @async
  void openFromRemoteNotification(Map<String, Object?> payload);
}
