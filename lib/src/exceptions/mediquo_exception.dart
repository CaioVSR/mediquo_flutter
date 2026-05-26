import 'package:flutter/foundation.dart' show objectRuntimeType;
import 'package:flutter/services.dart' show PlatformException;
import 'package:mediquo_flutter/src/exceptions/mediquo_error_code.dart';

/// Base type for every error surfaced by the MediQuo plugin.
///
/// [MediquoException] is a sealed hierarchy: an exhaustive `switch` over its
/// subtypes is statically checked by the compiler. Each subtype carries a
/// human-readable [message] and an optional [cause] (typically the underlying
/// [PlatformException]).
///
/// Use [MediquoException.fromPlatformException] to translate a raw platform
/// error into the matching typed exception.
sealed class MediquoException implements Exception {
  /// Creates a [MediquoException] with a [message] and an optional [cause].
  const MediquoException(this.message, {this.cause});

  /// Maps a [PlatformException] raised by the platform channel onto the
  /// matching [MediquoException] subtype using its
  /// [PlatformException.code].
  ///
  /// Unknown codes fall back to [MediquoPlatformException], preserving the
  /// original code for diagnostics.
  factory MediquoException.fromPlatformException(
    PlatformException exception,
  ) {
    final message = exception.message ?? 'Unknown MediQuo platform error.';
    return switch (exception.code) {
      MediquoErrorCode.initializationFailed => MediquoInitializationException(
        message: message,
        cause: exception,
      ),
      MediquoErrorCode.authenticationFailed => MediquoAuthenticationException(
        message: message,
        cause: exception,
      ),
      MediquoErrorCode.openFailed => MediquoOpenException(
        message: message,
        cause: exception,
      ),
      MediquoErrorCode.deauthenticationFailed =>
        MediquoDeauthenticationException(message: message, cause: exception),
      MediquoErrorCode.pushRegistrationFailed =>
        MediquoPushRegistrationException(message: message, cause: exception),
      MediquoErrorCode.notInitialized => MediquoNotInitializedException(
        message: message,
        cause: exception,
      ),
      _ => MediquoPlatformException(
        message: message,
        code: exception.code,
        cause: exception,
      ),
    };
  }

  /// A human-readable description of what went wrong.
  final String message;

  /// The underlying error that triggered this exception, when available.
  final Object? cause;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'MediquoException')}: $message';
}

/// Thrown when the native SDK fails to initialise with the API key.
final class MediquoInitializationException extends MediquoException {
  /// Creates a [MediquoInitializationException].
  const MediquoInitializationException({
    String message = 'Failed to initialise the MediQuo SDK.',
    Object? cause,
  }) : super(message, cause: cause);
}

/// Thrown when the native SDK fails to authenticate the patient.
final class MediquoAuthenticationException extends MediquoException {
  /// Creates a [MediquoAuthenticationException].
  const MediquoAuthenticationException({
    String message = 'Failed to authenticate the patient.',
    Object? cause,
  }) : super(message, cause: cause);
}

/// Thrown when the native SDK fails to present the professional-list UI.
final class MediquoOpenException extends MediquoException {
  /// Creates a [MediquoOpenException].
  const MediquoOpenException({
    String message = 'Failed to open the professional list.',
    Object? cause,
  }) : super(message, cause: cause);
}

/// Thrown when the native SDK fails to log the patient out.
final class MediquoDeauthenticationException extends MediquoException {
  /// Creates a [MediquoDeauthenticationException].
  const MediquoDeauthenticationException({
    String message = 'Failed to log the patient out.',
    Object? cause,
  }) : super(message, cause: cause);
}

/// Thrown when the native SDK fails to register a push token.
final class MediquoPushRegistrationException extends MediquoException {
  /// Creates a [MediquoPushRegistrationException].
  const MediquoPushRegistrationException({
    String message = 'Failed to register the push token.',
    Object? cause,
  }) : super(message, cause: cause);
}

/// Thrown when an operation requires a prior initialise or authenticate step
/// that has not yet completed.
///
/// Examples: authenticating before the SDK is initialised, or opening the
/// professional list before a patient is authenticated.
final class MediquoNotInitializedException extends MediquoException {
  /// Creates a [MediquoNotInitializedException].
  const MediquoNotInitializedException({
    String message = 'The MediQuo SDK is not ready for this operation yet.',
    Object? cause,
  }) : super(message, cause: cause);
}

/// Thrown for platform errors that do not map to a more specific subtype.
final class MediquoPlatformException extends MediquoException {
  /// Creates a [MediquoPlatformException] carrying the original platform
  /// [code].
  const MediquoPlatformException({
    required String message,
    required this.code,
    Object? cause,
  }) : super(message, cause: cause);

  /// The original platform error code.
  final String code;
}
