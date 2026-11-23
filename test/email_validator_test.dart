import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink/Manob/email_validator.dart';

void main() {
  group('EmailValidator tests', () {
    test('Accepted domains: @gmail.com and @rku.ac.in', () {
      expect(EmailValidator.isValid('student@gmail.com'), isTrue);
      expect(EmailValidator.isValid('student@rku.ac.in'), isTrue);
      expect(EmailValidator.isValid('john.doe+filter@gmail.com'), isTrue);
      expect(EmailValidator.isValid('pratik.nakum@rku.ac.in'), isTrue);
      expect(EmailValidator.isValid('UPPERCASE@GMAIL.COM'), isTrue);
      expect(EmailValidator.isValid('UPPERCASE@RKU.AC.IN'), isTrue);
    });

    test('Rejected domains', () {
      expect(EmailValidator.isValid('student@yahoo.com'), isFalse);
      expect(EmailValidator.isValid('student@outlook.com'), isFalse);
      expect(EmailValidator.isValid('student@otheruniversity.edu'), isFalse);
      expect(EmailValidator.isValid('student@rku.ac.in.example.com'), isFalse);
      expect(EmailValidator.isValid('student@gmail.com.co'), isFalse);
      expect(EmailValidator.isValid(''), isFalse);
      expect(EmailValidator.isValid(null), isFalse);
      expect(EmailValidator.isValid('not-an-email'), isFalse);
      expect(EmailValidator.isValid('@gmail.com'), isFalse);
      expect(EmailValidator.isValid('student@'), isFalse);
    });

    test('Validation error messages', () {
      expect(EmailValidator.validate(null), 'Email is required');
      expect(EmailValidator.validate(''), 'Email is required');
      expect(EmailValidator.validate('invalid'), 'Enter a valid email address');
      expect(
        EmailValidator.validate('user@yahoo.com'),
        'Only @gmail.com and @rku.ac.in emails are allowed',
      );
      expect(EmailValidator.validate('user@gmail.com'), isNull);
      expect(EmailValidator.validate('user@rku.ac.in'), isNull);
    });

    test('Normalization works properly', () {
      expect(
        EmailValidator.normalize('  Student@GMAIL.COM  '),
        'student@gmail.com',
      );
      expect(
        EmailValidator.normalize('Faculty@RKU.AC.IN'),
        'faculty@rku.ac.in',
      );
    });
  });
}
