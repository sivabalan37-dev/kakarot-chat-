import 'package:flutter_test/flutter_test.dart';
import 'package:kakarot_chat/core/validators/password_validator.dart';
import 'package:kakarot_chat/core/validators/username_validator.dart';

void main() {
  group('UsernameValidator', () {
    test('normalizes names case-insensitively', () {
      expect(UsernameValidator.normalize('Rahul'), 'rahul');
      expect(UsernameValidator.normalize('RAHUL'), 'rahul');
    });

    test('accepts valid usernames', () {
      expect(UsernameValidator.validate('rahul_01'), isNull);
      expect(UsernameValidator.validate('siva.balan'), isNull);
    });

    test('rejects invalid lengths and characters', () {
      expect(UsernameValidator.validate('ab'), isNotNull);
      expect(UsernameValidator.validate('a' * 21), isNotNull);
      expect(UsernameValidator.validate('.rahul'), isNotNull);
      expect(UsernameValidator.validate('rahul_'), isNotNull);
      expect(UsernameValidator.validate('rahul name'), isNotNull);
    });

    test('rejects reserved usernames case-insensitively', () {
      expect(UsernameValidator.validate('ADMIN'), isNotNull);
      expect(UsernameValidator.validate('Kakarot'), isNotNull);
    });
  });

  test('password strength checks all five requirements', () {
    expect(PasswordValidator.isStrong('Kakarot@123'), isTrue);
    expect(PasswordValidator.isStrong('kakarot123'), isFalse);
  });
}
