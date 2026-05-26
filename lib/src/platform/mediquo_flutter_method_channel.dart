import 'package:flutter/services.dart' show PlatformException;
import 'package:mediquo_flutter/src/exceptions/mediquo_exception.dart';
import 'package:mediquo_flutter/src/messages.g.dart';
import 'package:mediquo_flutter/src/models/mediquo_push_token.dart';
import 'package:mediquo_flutter/src/platform/mediquo_flutter_platform.dart';

/// The default [MediquoFlutterPlatform] implementation.
///
/// Delegates every call to the Pigeon-generated [MediquoHostApi] and translates
/// any [PlatformException] raised by the native side into the matching
/// [MediquoException].
class MediquoFlutterMethodChannel extends MediquoFlutterPlatform {
  /// Creates a [MediquoFlutterMethodChannel].
  ///
  /// The [hostApi] override exists for testing; production code relies on the
  /// default Pigeon host API bound to the platform binary messenger.
  MediquoFlutterMethodChannel({MediquoHostApi? hostApi})
    : _hostApi = hostApi ?? MediquoHostApi();

  final MediquoHostApi _hostApi;

  @override
  Future<void> initialize(String apiKey) =>
      _guard(() => _hostApi.initialize(apiKey));

  @override
  Future<void> authenticate(String clientCode) =>
      _guard(() => _hostApi.authenticate(clientCode));

  @override
  Future<void> openProfessionalList() => _guard(_hostApi.openProfessionalList);

  @override
  Future<void> deauthenticate() => _guard(_hostApi.deauthenticate);

  @override
  Future<void> registerPushToken(MediquoPushToken token) => _guard(
    () => _hostApi.registerPushToken(token.value, token.type._pigeon),
  );

  @override
  Future<void> openFromRemoteNotification(Map<String, Object?> payload) =>
      _guard(() => _hostApi.openFromRemoteNotification(payload));

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on PlatformException catch (exception) {
      throw MediquoException.fromPlatformException(exception);
    }
  }
}

extension on MediquoPushTokenType {
  PushTokenType get _pigeon => switch (this) {
    MediquoPushTokenType.fcm => PushTokenType.fcm,
    MediquoPushTokenType.apns => PushTokenType.apns,
  };
}
