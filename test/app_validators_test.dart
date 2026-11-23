import 'package:flutter_test/flutter_test.dart';
import 'package:lifelink/Manob/app_validators.dart';

void main() {
  group('AppValidators - Name & Patient Name Validation', () {
    test('Valid names pass', () {
      expect(AppValidators.validateName('Pratik Nakum'), isNull);
      expect(AppValidators.validateName('John Doe'), isNull);
      expect(AppValidators.validatePatientName('Jane Smith'), isNull);
      expect(AppValidators.validateName('A. B. Sen'), isNull);
    });

    test('Short, whitespace-only, or empty names are rejected', () {
      expect(AppValidators.validateName(''), 'Full Name is required');
      expect(AppValidators.validateName('   '), 'Full Name is required');
      expect(AppValidators.validateName(null), 'Full Name is required');
      expect(
        AppValidators.validateName('Al'),
        'Full Name must be at least 3 characters',
      );
      expect(
        AppValidators.validateName('  ab  '),
        'Full Name must be at least 3 characters',
      );
    });

    test('Names with digits or disallowed symbols are rejected', () {
      expect(
        AppValidators.validateName('User123'),
        'Full Name can only contain letters and spaces',
      );
      expect(
        AppValidators.validatePatientName('Patient #4'),
        'Patient Name can only contain letters and spaces',
      );
    });

    test('Names exceeding maximum length are rejected', () {
      final longName = 'A' * 51;
      expect(
        AppValidators.validateName(longName),
        'Full Name cannot exceed 50 characters',
      );
    });
  });

  group('AppValidators - Email Validation', () {
    test('Allowed domains pass', () {
      expect(AppValidators.validateEmail('donor@gmail.com'), isNull);
      expect(AppValidators.validateEmail('student@rku.ac.in'), isNull);
    });

    test('Disallowed domains or invalid syntax fail', () {
      expect(
        AppValidators.validateEmail('user@yahoo.com'),
        'Only @gmail.com and @rku.ac.in emails are allowed',
      );
      expect(
        AppValidators.validateEmail('invalid'),
        'Enter a valid email address',
      );
      expect(AppValidators.validateEmail(''), 'Email is required');
    });
  });

  group('AppValidators - Password Validation', () {
    test(
      'New password requires at least 8 characters and both letters and numbers',
      () {
        expect(
          AppValidators.validatePassword('Pass1234', isNewPassword: true),
          isNull,
        );
        expect(
          AppValidators.validatePassword('Short1', isNewPassword: true),
          'Password must be at least 8 characters long',
        );
        expect(
          AppValidators.validatePassword('onlyletters', isNewPassword: true),
          'Password must include both letters and numbers',
        );
        expect(
          AppValidators.validatePassword('12345678', isNewPassword: true),
          'Password must include both letters and numbers',
        );
      },
    );

    test(
      'Login password allows usable historical passwords without unnecessary lockout',
      () {
        expect(
          AppValidators.validatePassword('123456', isNewPassword: false),
          isNull,
        );
        expect(
          AppValidators.validatePassword('12345', isNewPassword: false),
          'Password must be at least 6 characters',
        );
        expect(
          AppValidators.validatePassword('', isNewPassword: false),
          'Password is required',
        );
      },
    );

    test('Confirm password matching', () {
      expect(
        AppValidators.validateConfirmPassword('Secret12', 'Secret12'),
        isNull,
      );
      expect(
        AppValidators.validateConfirmPassword('Mismatch', 'Secret12'),
        'Passwords do not match',
      );
      expect(
        AppValidators.validateConfirmPassword('', 'Secret12'),
        'Please confirm your password',
      );
    });
  });

  group('AppValidators - Indian Phone Validation', () {
    test('Valid 10-digit Indian mobile numbers pass', () {
      expect(AppValidators.validateIndianPhone('9876543210'), isNull);
      expect(AppValidators.validateIndianPhone('8765432109'), isNull);
      expect(AppValidators.validateIndianPhone('7654321098'), isNull);
      expect(AppValidators.validateIndianPhone('6543210987'), isNull);
      expect(
        AppValidators.validateIndianPhone('98765 43210'),
        isNull,
      ); // whitespace normalized
    });

    test('Invalid mobile numbers fail', () {
      expect(
        AppValidators.validateIndianPhone('5555555555'),
        'Enter a valid 10-digit mobile number (e.g., 9876543210)',
      );
      expect(
        AppValidators.validateIndianPhone('98765'),
        'Enter a valid 10-digit mobile number (e.g., 9876543210)',
      );
      expect(
        AppValidators.validateIndianPhone('987654321012'),
        'Enter a valid 10-digit mobile number (e.g., 9876543210)',
      );
      expect(AppValidators.validateIndianPhone(''), 'Phone Number is required');
      expect(
        AppValidators.validateIndianPhone(null),
        'Phone Number is required',
      );
    });
  });

  group('AppValidators - Address & City Validation', () {
    test('Valid addresses pass', () {
      expect(AppValidators.validateAddress('Kalawad Road, Rajkot'), isNull);
      expect(
        AppValidators.validateAddressOrText(
          'Civil Hospital',
          fieldName: 'Hospital name',
        ),
        isNull,
      );
    });

    test('Short or empty addresses fail', () {
      expect(AppValidators.validateAddress(''), 'Address is required');
      expect(AppValidators.validateAddress('   '), 'Address is required');
      expect(
        AppValidators.validateAddress('ab'),
        'Address must be at least 3 characters',
      );
    });

    test(
      'Default city resolves to Rajkot when empty or null, preserves existing non-empty values',
      () {
        expect(AppValidators.resolveCity(null), 'Rajkot');
        expect(AppValidators.resolveCity(''), 'Rajkot');
        expect(AppValidators.resolveCity('   '), 'Rajkot');
        expect(AppValidators.resolveCity('Ahmedabad'), 'Ahmedabad');
        expect(AppValidators.resolveCity('Surat'), 'Surat');
      },
    );
  });

  group('AppValidators - Units & Blood Group Validation', () {
    test('Units validation restricts to 1-10 positive integer units', () {
      expect(AppValidators.validateUnits(1), isNull);
      expect(AppValidators.validateUnits(5), isNull);
      expect(AppValidators.validateUnits('10'), isNull);
      expect(
        AppValidators.validateUnits(0),
        'Enter a valid number of units (minimum 1)',
      );
      expect(
        AppValidators.validateUnits(-1),
        'Enter a valid number of units (minimum 1)',
      );
      expect(
        AppValidators.validateUnits(11),
        'Maximum 10 units permitted per request',
      );
      expect(AppValidators.validateUnits(''), 'Units required is required');
      expect(AppValidators.validateUnits(null), 'Units required is required');
    });

    test('Blood group validation accepts only supported blood groups', () {
      for (final bg in ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']) {
        expect(AppValidators.validateBloodGroup(bg), isNull);
      }
      expect(
        AppValidators.validateBloodGroup('C+'),
        'Invalid blood group selected',
      );
      expect(
        AppValidators.validateBloodGroup(''),
        'Please select a blood group',
      );
      expect(
        AppValidators.validateBloodGroup(null),
        'Please select a blood group',
      );
    });
  });
}
