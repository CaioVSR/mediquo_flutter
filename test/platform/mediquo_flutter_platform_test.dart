import 'package:flutter_test/flutter_test.dart';
import 'package:mediquo_flutter/mediquo_flutter.dart';
import 'package:mediquo_flutter/src/platform/mediquo_flutter_method_channel.dart';
import 'package:mocktail/mocktail.dart';

class _BarePlatform extends MediquoFlutterPlatform {}

class _ImplementsPlatform extends Mock implements MediquoFlutterPlatform {}

void main() {
  group('MediquoFlutterPlatform', () {
    test('default instance is the method channel implementation', () {
      expect(
        MediquoFlutterPlatform.instance,
        isA<MediquoFlutterMethodChannel>(),
      );
    });

    test('accepts an implementation that extends the interface', () {
      final original = MediquoFlutterPlatform.instance;
      addTearDown(() => MediquoFlutterPlatform.instance = original);

      final replacement = _BarePlatform();
      MediquoFlutterPlatform.instance = replacement;

      expect(MediquoFlutterPlatform.instance, same(replacement));
    });

    test('rejects an implementation that only implements the interface', () {
      expect(
        () => MediquoFlutterPlatform.instance = _ImplementsPlatform(),
        throwsA(isA<AssertionError>()),
      );
    });

    group('default methods throw UnimplementedError', () {
      final platform = _BarePlatform();

      test('initialize', () {
        expect(
          () => platform.initialize('k'),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('authenticate', () {
        expect(
          () => platform.authenticate('c'),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('openProfessionalList', () {
        expect(
          platform.openProfessionalList,
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('deauthenticate', () {
        expect(
          platform.deauthenticate,
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('registerPushToken', () {
        expect(
          () => platform.registerPushToken(const MediquoPushToken.fcm('t')),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('openFromRemoteNotification', () {
        expect(
          () => platform.openFromRemoteNotification(const {}),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });
  });
}
