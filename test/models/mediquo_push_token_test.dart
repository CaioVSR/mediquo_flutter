import 'package:flutter_test/flutter_test.dart';
import 'package:mediquo_flutter/mediquo_flutter.dart';

MediquoPushToken _fcm(String value) => MediquoPushToken.fcm(value);

void main() {
  group('MediquoPushToken', () {
    test('fcm constructor sets the value and the fcm type', () {
      const token = MediquoPushToken.fcm('fcm-token');

      expect(token.value, 'fcm-token');
      expect(token.type, MediquoPushTokenType.fcm);
    });

    test('apns constructor sets the value and the apns type', () {
      const token = MediquoPushToken.apns('apns-token');

      expect(token.value, 'apns-token');
      expect(token.type, MediquoPushTokenType.apns);
    });

    test('supports value equality', () {
      expect(
        const MediquoPushToken.fcm('t'),
        equals(const MediquoPushToken.fcm('t')),
      );
      expect(
        const MediquoPushToken.fcm('t'),
        isNot(equals(const MediquoPushToken.apns('t'))),
      );
      expect(
        const MediquoPushToken.fcm('a'),
        isNot(equals(const MediquoPushToken.fcm('b'))),
      );
    });

    test('equal tokens share a hash code', () {
      expect(_fcm('t').hashCode, _fcm('t').hashCode);
    });
  });
}
