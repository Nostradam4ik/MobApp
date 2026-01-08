import 'package:flutter_test/flutter_test.dart';
import 'package:smartspend/core/utils/validators.dart';
import 'package:smartspend/core/constants/app_constants.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('should return error for null email', () {
        expect(Validators.email(null), 'L\'email est requis');
      });

      test('should return error for empty email', () {
        expect(Validators.email(''), 'L\'email est requis');
      });

      test('should return error for invalid email format', () {
        expect(Validators.email('invalid'), 'Email invalide');
        expect(Validators.email('invalid@'), 'Email invalide');
        expect(Validators.email('@example.com'), 'Email invalide');
        expect(Validators.email('test@.com'), 'Email invalide');
      });

      test('should return null for valid email', () {
        expect(Validators.email('test@example.com'), isNull);
        expect(Validators.email('user.name@domain.org'), isNull);
        expect(Validators.email('user-name@domain.co'), isNull);
        expect(Validators.email('user_name@domain.info'), isNull);
      });
    });

    group('password', () {
      test('should return error for null password', () {
        expect(Validators.password(null), 'Le mot de passe est requis');
      });

      test('should return error for empty password', () {
        expect(Validators.password(''), 'Le mot de passe est requis');
      });

      test('should return error for too short password', () {
        final shortPassword = 'a' * (SecurityConstants.minPasswordLength - 1);
        expect(
          Validators.password(shortPassword),
          'Le mot de passe doit faire au moins ${SecurityConstants.minPasswordLength} caractères',
        );
      });

      test('should return null for valid password', () {
        final validPassword = 'a' * SecurityConstants.minPasswordLength;
        expect(Validators.password(validPassword), isNull);
      });

      test('should return null for long password', () {
        final longPassword = 'a' * 50;
        expect(Validators.password(longPassword), isNull);
      });
    });

    group('confirmPassword', () {
      test('should return error for null confirmation', () {
        expect(
          Validators.confirmPassword(null, 'password123'),
          'Veuillez confirmer le mot de passe',
        );
      });

      test('should return error for empty confirmation', () {
        expect(
          Validators.confirmPassword('', 'password123'),
          'Veuillez confirmer le mot de passe',
        );
      });

      test('should return error when passwords do not match', () {
        expect(
          Validators.confirmPassword('different', 'password123'),
          'Les mots de passe ne correspondent pas',
        );
      });

      test('should return null when passwords match', () {
        expect(Validators.confirmPassword('password123', 'password123'), isNull);
      });
    });

    group('name', () {
      test('should return error for null name', () {
        expect(Validators.name(null), 'Le nom est requis');
      });

      test('should return error for empty name', () {
        expect(Validators.name(''), 'Le nom est requis');
      });

      test('should return error for too short name', () {
        expect(Validators.name('A'), 'Le nom est trop court');
      });

      test('should return null for valid name', () {
        expect(Validators.name('AB'), isNull);
        expect(Validators.name('Jean Dupont'), isNull);
        expect(Validators.name('Marie-Claire'), isNull);
      });
    });

    group('amount', () {
      test('should return error for null amount', () {
        expect(Validators.amount(null), 'Le montant est requis');
      });

      test('should return error for empty amount', () {
        expect(Validators.amount(''), 'Le montant est requis');
      });

      test('should return error for invalid format', () {
        expect(Validators.amount('abc'), 'Montant invalide');
        expect(Validators.amount('12.34.56'), 'Montant invalide');
      });

      test('should return error for zero or negative amount', () {
        expect(Validators.amount('0'), 'Le montant doit être positif');
        expect(Validators.amount('-10'), 'Le montant doit être positif');
      });

      test('should return error for amount exceeding max', () {
        final tooHigh = (AppConstants.maxExpenseAmount + 1).toString();
        expect(Validators.amount(tooHigh), 'Le montant est trop élevé');
      });

      test('should return null for valid amount', () {
        expect(Validators.amount('100'), isNull);
        expect(Validators.amount('50.50'), isNull);
        expect(Validators.amount('0.01'), isNull);
      });

      test('should handle comma as decimal separator', () {
        expect(Validators.amount('50,50'), isNull);
        expect(Validators.amount('1000,99'), isNull);
      });
    });

    group('note', () {
      test('should return null for null note', () {
        expect(Validators.note(null), isNull);
      });

      test('should return null for empty note', () {
        expect(Validators.note(''), isNull);
      });

      test('should return null for valid note', () {
        expect(Validators.note('Achat courses'), isNull);
        expect(Validators.note('A' * 100), isNull);
      });

      test('should return error for note exceeding max length', () {
        final tooLong = 'A' * (AppConstants.maxNoteLength + 1);
        expect(Validators.note(tooLong), 'La note est trop longue');
      });

      test('should return null for note at max length', () {
        final atMax = 'A' * AppConstants.maxNoteLength;
        expect(Validators.note(atMax), isNull);
      });
    });

    group('required', () {
      test('should return error for null value', () {
        expect(Validators.required(null), 'Ce champ est requis');
      });

      test('should return error for empty value', () {
        expect(Validators.required(''), 'Ce champ est requis');
      });

      test('should return null for non-empty value', () {
        expect(Validators.required('value'), isNull);
      });

      test('should use custom field name in error', () {
        expect(
          Validators.required(null, fieldName: 'Le titre'),
          'Le titre est requis',
        );
        expect(
          Validators.required('', fieldName: 'La description'),
          'La description est requis',
        );
      });
    });
  });
}
