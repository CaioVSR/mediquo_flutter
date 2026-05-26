/// Error codes shared between the Dart layer and the native platform code.
///
/// The native Android and iOS implementations complete a failed platform call
/// with one of these codes. `MediquoException.fromPlatformException` maps each
/// code onto a strongly typed exception, so the three languages must agree on
/// the exact string values declared here.
abstract final class MediquoErrorCode {
  /// The native SDK failed to initialise with the provided API key.
  static const String initializationFailed = 'initialization_failed';

  /// The native SDK failed to authenticate the patient.
  static const String authenticationFailed = 'authentication_failed';

  /// The native SDK failed to present the professional-list interface.
  static const String openFailed = 'open_failed';

  /// The native SDK failed to log the patient out.
  static const String deauthenticationFailed = 'deauthentication_failed';

  /// The native SDK failed to register the push token.
  static const String pushRegistrationFailed = 'push_registration_failed';

  /// An operation was attempted before the SDK was ready (initialised and,
  /// when required, authenticated).
  static const String notInitialized = 'not_initialized';
}
