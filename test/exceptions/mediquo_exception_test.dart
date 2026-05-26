import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediquo_flutter/mediquo_flutter.dart';

void main() {
  group('MediquoException', () {
    test('toString includes the runtime type and the message', () {
      const exception = MediquoInitializationException(message: 'boom');

      expect(
        exception.toString(),
        'MediquoInitializationException: boom',
      );
    });

    test('every subtype exposes a sensible default message', () {
      final defaults = <MediquoException Function(), String>{
        MediquoInitializationException.new:
            'Failed to initialise the MediQuo SDK.',
        MediquoAuthenticationException.new:
            'Failed to authenticate the patient.',
        MediquoOpenException.new: 'Failed to open the professional list.',
        MediquoDeauthenticationException.new: 'Failed to log the patient out.',
        MediquoPushRegistrationException.new:
            'Failed to register the push token.',
        MediquoNotInitializedException.new:
            'The MediQuo SDK is not ready for this operation yet.',
      };

      for (final entry in defaults.entries) {
        expect(entry.key().message, entry.value);
      }
    });

    group('fromPlatformException', () {
      void expectMapping<T extends MediquoException>(String code) {
        final platformException = PlatformException(code: code, message: 'msg');
        final exception = MediquoException.fromPlatformException(
          platformException,
        );

        expect(exception, isA<T>());
        expect(exception.message, 'msg');
        expect(exception.cause, same(platformException));
      }

      test('maps the initialization code', () {
        expectMapping<MediquoInitializationException>(
          MediquoErrorCode.initializationFailed,
        );
      });

      test('maps the authentication code', () {
        expectMapping<MediquoAuthenticationException>(
          MediquoErrorCode.authenticationFailed,
        );
      });

      test('maps the open code', () {
        expectMapping<MediquoOpenException>(MediquoErrorCode.openFailed);
      });

      test('maps the deauthentication code', () {
        expectMapping<MediquoDeauthenticationException>(
          MediquoErrorCode.deauthenticationFailed,
        );
      });

      test('maps the push registration code', () {
        expectMapping<MediquoPushRegistrationException>(
          MediquoErrorCode.pushRegistrationFailed,
        );
      });

      test('maps the not initialized code', () {
        expectMapping<MediquoNotInitializedException>(
          MediquoErrorCode.notInitialized,
        );
      });

      test('falls back to MediquoPlatformException for unknown codes', () {
        final exception = MediquoException.fromPlatformException(
          PlatformException(code: 'something_else', message: 'msg'),
        );

        expect(exception, isA<MediquoPlatformException>());
        expect(
          (exception as MediquoPlatformException).code,
          'something_else',
        );
      });

      test('uses a default message when the platform message is null', () {
        final exception = MediquoException.fromPlatformException(
          PlatformException(code: MediquoErrorCode.openFailed),
        );

        expect(exception.message, 'Unknown MediQuo platform error.');
      });
    });
  });
}
