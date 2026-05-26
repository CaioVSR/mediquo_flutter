import 'package:meta/meta.dart';

/// The provider a push token originates from.
enum MediquoPushTokenType {
  /// A Firebase Cloud Messaging token. Used on Android and, optionally, iOS.
  fcm,

  /// An Apple Push Notification service device token. Used on iOS.
  apns,
}

/// A push notification token to register with the native MediQuo SDK.
///
/// Use the named constructors to make the provider explicit:
///
/// ```dart
/// final token = MediquoPushToken.fcm(fcmToken);
/// ```
@immutable
class MediquoPushToken {
  /// Creates a Firebase Cloud Messaging push token.
  const MediquoPushToken.fcm(this.value) : type = MediquoPushTokenType.fcm;

  /// Creates an Apple Push Notification service push token.
  const MediquoPushToken.apns(this.value) : type = MediquoPushTokenType.apns;

  /// The raw token value supplied by the push provider.
  final String value;

  /// The provider this token belongs to.
  final MediquoPushTokenType type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediquoPushToken &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          type == other.type;

  @override
  int get hashCode => Object.hash(runtimeType, value, type);
}
