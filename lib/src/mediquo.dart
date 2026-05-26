import 'package:mediquo_flutter/src/models/mediquo_configuration.dart';
import 'package:mediquo_flutter/src/models/mediquo_push_token.dart';
import 'package:mediquo_flutter/src/platform/mediquo_flutter_platform.dart';

/// The entry point to the MediQuo SDK.
///
/// Every method returns a `Future` that completes when the native operation
/// succeeds and throws a `MediquoException` when it fails. The package holds
/// no observable state and imposes no state-management library: create a
/// `Mediquo`, keep it wherever your app keeps dependencies, and reflect the
/// results of these calls in whatever state solution you already use
/// (`setState`, `ChangeNotifier`, Riverpod, Bloc, …).
///
/// ```dart
/// final mediquo = Mediquo();
/// await mediquo.startSession(
///   MediquoConfiguration.validated(apiKey: apiKey, clientCode: clientCode),
/// );
/// await mediquo.openProfessionalList();
/// ```
class Mediquo {
  /// Creates a [Mediquo].
  ///
  /// [platform] defaults to [MediquoFlutterPlatform.instance] and is injectable
  /// for testing.
  Mediquo({MediquoFlutterPlatform? platform})
    : _platform = platform ?? MediquoFlutterPlatform.instance;

  final MediquoFlutterPlatform _platform;

  /// Initialises the native SDK with the partner [apiKey].
  ///
  /// Throws a `MediquoInitializationException` on failure.
  Future<void> initialize(String apiKey) => _platform.initialize(apiKey);

  /// Authenticates the pre-registered patient identified by [clientCode] (CPF).
  ///
  /// Requires a prior successful [initialize]. Throws a
  /// `MediquoAuthenticationException` on failure, or a
  /// `MediquoNotInitializedException` if the SDK was not initialised.
  Future<void> authenticate(String clientCode) =>
      _platform.authenticate(clientCode);

  /// Initialises the SDK and authenticates the patient in one step.
  ///
  /// Equivalent to [initialize] followed by [authenticate]; if [initialize]
  /// fails, [authenticate] is not attempted and the error propagates.
  Future<void> startSession(MediquoConfiguration configuration) async {
    await _platform.initialize(configuration.apiKey);
    await _platform.authenticate(configuration.clientCode);
  }

  /// Presents the native professional-list interface.
  ///
  /// Requires an authenticated patient. Throws a `MediquoOpenException` on
  /// failure, or a `MediquoNotInitializedException` if no patient is
  /// authenticated.
  Future<void> openProfessionalList() => _platform.openProfessionalList();

  /// Presents the SDK screen for a tapped remote notification.
  ///
  /// [payload] is the notification data (for example `RemoteMessage.data` from
  /// `firebase_messaging`). Requires an authenticated patient.
  Future<void> openFromNotification(Map<String, Object?> payload) =>
      _platform.openFromRemoteNotification(payload);

  /// Registers a push [token] with the native SDK.
  ///
  /// Throws a `MediquoPushRegistrationException` on failure.
  Future<void> registerPushToken(MediquoPushToken token) =>
      _platform.registerPushToken(token);

  /// Logs the current patient out of the native SDK.
  ///
  /// Throws a `MediquoDeauthenticationException` on failure.
  Future<void> logout() => _platform.deauthenticate();
}
