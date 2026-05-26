import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediquo_flutter/mediquo_flutter.dart';
import 'package:mediquo_flutter/src/messages.g.dart';
import 'package:mediquo_flutter/src/platform/mediquo_flutter_method_channel.dart';
import 'package:mocktail/mocktail.dart';

class _MockMediquoHostApi extends Mock implements MediquoHostApi {}

void main() {
  group('MediquoFlutterMethodChannel', () {
    late _MockMediquoHostApi hostApi;
    late MediquoFlutterMethodChannel channel;

    setUp(() {
      hostApi = _MockMediquoHostApi();
      channel = MediquoFlutterMethodChannel(hostApi: hostApi);
    });

    group('delegation', () {
      test('initialize forwards the api key', () async {
        when(() => hostApi.initialize(any())).thenAnswer((_) async {});

        await channel.initialize('api-key');

        verify(() => hostApi.initialize('api-key')).called(1);
      });

      test('authenticate forwards the client code', () async {
        when(() => hostApi.authenticate(any())).thenAnswer((_) async {});

        await channel.authenticate('12345678901');

        verify(() => hostApi.authenticate('12345678901')).called(1);
      });

      test('openProfessionalList forwards the call', () async {
        when(() => hostApi.openProfessionalList()).thenAnswer((_) async {});

        await channel.openProfessionalList();

        verify(() => hostApi.openProfessionalList()).called(1);
      });

      test('deauthenticate forwards the call', () async {
        when(() => hostApi.deauthenticate()).thenAnswer((_) async {});

        await channel.deauthenticate();

        verify(() => hostApi.deauthenticate()).called(1);
      });

      test('registerPushToken maps an fcm token', () async {
        when(
          () => hostApi.registerPushToken('tok', PushTokenType.fcm),
        ).thenAnswer((_) async {});

        await channel.registerPushToken(const MediquoPushToken.fcm('tok'));

        verify(
          () => hostApi.registerPushToken('tok', PushTokenType.fcm),
        ).called(1);
      });

      test('registerPushToken maps an apns token', () async {
        when(
          () => hostApi.registerPushToken('tok', PushTokenType.apns),
        ).thenAnswer((_) async {});

        await channel.registerPushToken(const MediquoPushToken.apns('tok'));

        verify(
          () => hostApi.registerPushToken('tok', PushTokenType.apns),
        ).called(1);
      });

      test('openFromRemoteNotification forwards the payload', () async {
        const payload = <String, Object?>{'conversation_id': '42'};
        when(
          () => hostApi.openFromRemoteNotification(payload),
        ).thenAnswer((_) async {});

        await channel.openFromRemoteNotification(payload);

        verify(
          () => hostApi.openFromRemoteNotification(payload),
        ).called(1);
      });
    });

    group('error translation', () {
      test('maps a typed platform code to its MediquoException', () async {
        when(() => hostApi.initialize(any())).thenThrow(
          PlatformException(code: MediquoErrorCode.initializationFailed),
        );

        await expectLater(
          () => channel.initialize('k'),
          throwsA(isA<MediquoInitializationException>()),
        );
      });

      test('maps an unknown code to MediquoPlatformException', () async {
        when(
          () => hostApi.deauthenticate(),
        ).thenThrow(PlatformException(code: 'unexpected'));

        await expectLater(
          channel.deauthenticate(),
          throwsA(isA<MediquoPlatformException>()),
        );
      });
    });
  });
}
