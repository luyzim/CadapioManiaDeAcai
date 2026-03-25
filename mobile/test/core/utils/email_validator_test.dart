import 'package:flutter_test/flutter_test.dart';
import 'package:mania_de_acai/core/utils/email_validator.dart';

void main() {
  group('EmailValidator', () {
    test('accepts well-formed email addresses', () {
      expect(EmailValidator.isValid('cliente@email.com'), isTrue);
      expect(EmailValidator.isValid('nome.sobrenome+app@empresa.com.br'), isTrue);
      expect(EmailValidator.isValid('USER@EXAMPLE.COM'), isTrue);
    });

    test('rejects malformed email addresses', () {
      expect(EmailValidator.isValid(''), isFalse);
      expect(EmailValidator.isValid('sem-arroba.com'), isFalse);
      expect(EmailValidator.isValid('cliente@dominio'), isFalse);
      expect(EmailValidator.isValid('.cliente@email.com'), isFalse);
      expect(EmailValidator.isValid('cliente..teste@email.com'), isFalse);
      expect(EmailValidator.isValid('cliente@-dominio.com'), isFalse);
      expect(EmailValidator.isValid('cliente@dominio..com'), isFalse);
      expect(EmailValidator.isValid('cliente@dominio.c'), isFalse);
    });
  });
}
