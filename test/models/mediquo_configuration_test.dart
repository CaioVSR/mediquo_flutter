import 'package:flutter_test/flutter_test.dart';
import 'package:mediquo_flutter/mediquo_flutter.dart';

void main() {
  group('MediquoConfiguration', () {
    test('stores the values passed to the default constructor', () {
      const configuration = MediquoConfiguration(
        apiKey: 'api-key',
        clientCode: '12345678901',
      );

      expect(configuration.apiKey, 'api-key');
      expect(configuration.clientCode, '12345678901');
    });

    test('supports value equality', () {
      const a = MediquoConfiguration(apiKey: 'k', clientCode: '1');
      const b = MediquoConfiguration(apiKey: 'k', clientCode: '1');
      const c = MediquoConfiguration(apiKey: 'k', clientCode: '2');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('equal configurations share a hash code', () {
      final validated = MediquoConfiguration.validated(
        apiKey: 'k',
        clientCode: '1',
      );

      expect(
        validated.hashCode,
        const MediquoConfiguration(apiKey: 'k', clientCode: '1').hashCode,
      );
    });

    group('validated', () {
      test('trims surrounding whitespace from both values', () {
        final configuration = MediquoConfiguration.validated(
          apiKey: '  api-key  ',
          clientCode: '  12345678901  ',
        );

        expect(configuration.apiKey, 'api-key');
        expect(configuration.clientCode, '12345678901');
      });

      test('throws when the api key is empty', () {
        expect(
          () => MediquoConfiguration.validated(
            apiKey: '   ',
            clientCode: '12345678901',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws when the client code is empty', () {
        expect(
          () => MediquoConfiguration.validated(
            apiKey: 'api-key',
            clientCode: '   ',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws when the client code is not digits only', () {
        expect(
          () => MediquoConfiguration.validated(
            apiKey: 'api-key',
            clientCode: '123.456.789-01',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('returns a configuration for valid input', () {
        final configuration = MediquoConfiguration.validated(
          apiKey: 'api-key',
          clientCode: '12345678901',
        );

        expect(
          configuration,
          const MediquoConfiguration(
            apiKey: 'api-key',
            clientCode: '12345678901',
          ),
        );
      });
    });
  });
}
