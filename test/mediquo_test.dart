import 'package:flutter_test/flutter_test.dart';
import 'package:mediquo_flutter/mediquo_flutter.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlatform extends Mock implements MediquoFlutterPlatform {}

void main() {
  group('Mediquo', () {
    late MediquoFlutterPlatform platform;
    late Mediquo mediquo;

    const configuration = MediquoConfiguration(
      apiKey: 'api-key',
      clientCode: '12345678901',
    );
    const token = MediquoPushToken.fcm('tok');

    setUp(() {
      platform = _MockPlatform();
      mediquo = Mediquo(platform: platform);
    });

    test('initialize delegates to the platform', () async {
      when(() => platform.initialize(any())).thenAnswer((_) async {});

      await mediquo.initialize('api-key');

      verify(() => platform.initialize('api-key')).called(1);
    });

    test('authenticate delegates to the platform', () async {
      when(() => platform.authenticate(any())).thenAnswer((_) async {});

      await mediquo.authenticate('12345678901');

      verify(() => platform.authenticate('12345678901')).called(1);
    });

    test('startSession initialises then authenticates in order', () async {
      when(() => platform.initialize(any())).thenAnswer((_) async {});
      when(() => platform.authenticate(any())).thenAnswer((_) async {});

      await mediquo.startSession(configuration);

      verifyInOrder([
        () => platform.initialize('api-key'),
        () => platform.authenticate('12345678901'),
      ]);
    });

    test('startSession does not authenticate when initialize fails', () async {
      when(
        () => platform.initialize(any()),
      ).thenThrow(const MediquoInitializationException());

      await expectLater(
        mediquo.startSession(configuration),
        throwsA(isA<MediquoInitializationException>()),
      );
      verifyNever(() => platform.authenticate(any()));
    });

    test('openProfessionalList delegates to the platform', () async {
      when(() => platform.openProfessionalList()).thenAnswer((_) async {});

      await mediquo.openProfessionalList();

      verify(() => platform.openProfessionalList()).called(1);
    });

    test('openFromNotification delegates with the payload', () async {
      const payload = <String, Object?>{'conversation_id': '42'};
      when(
        () => platform.openFromRemoteNotification(payload),
      ).thenAnswer((_) async {});

      await mediquo.openFromNotification(payload);

      verify(() => platform.openFromRemoteNotification(payload)).called(1);
    });

    test('registerPushToken delegates to the platform', () async {
      when(() => platform.registerPushToken(token)).thenAnswer((_) async {});

      await mediquo.registerPushToken(token);

      verify(() => platform.registerPushToken(token)).called(1);
    });

    test('logout delegates to deauthenticate', () async {
      when(() => platform.deauthenticate()).thenAnswer((_) async {});

      await mediquo.logout();

      verify(() => platform.deauthenticate()).called(1);
    });

    test('uses the default platform instance when none is provided', () {
      expect(Mediquo.new, returnsNormally);
    });
  });
}
