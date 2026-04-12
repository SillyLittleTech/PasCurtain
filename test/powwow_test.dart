import 'package:flutter_test/flutter_test.dart';

import 'package:pas_curtain/services/password_generator.dart';
import 'package:pas_curtain/services/pwned_api_service.dart';
import 'package:pas_curtain/models/breach_result.dart';

void main() {
  group('PasswordGenerator', () {
    test('generates the requested number of passwords', () {
      final gen = PasswordGenerator(length: 20);
      final passwords = gen.generate(count: 3);
      expect(passwords.length, 3);
    });

    test('generated passwords meet minimum length', () {
      final gen = PasswordGenerator(length: 16);
      for (final p in gen.generate(count: 5)) {
        expect(p.length, greaterThanOrEqualTo(16));
      }
    });

    test('generated passwords contain mixed character types', () {
      final gen = PasswordGenerator(length: 20);
      for (final p in gen.generate(count: 10)) {
        final hasUpper = p.contains(RegExp(r'[A-Z]'));
        final hasLower = p.contains(RegExp(r'[a-z]'));
        final hasDigit = p.contains(RegExp(r'[0-9]'));
        // At least three of the four classes should be present
        final classCount = [hasUpper, hasLower, hasDigit].where((b) => b).length;
        expect(classCount, greaterThanOrEqualTo(2));
      }
    });

    test('generatePassphrase produces a non-empty string', () {
      final passphrase = PasswordGenerator.generatePassphrase(wordCount: 4);
      expect(passphrase.isNotEmpty, isTrue);
    });

    test('generatePassphrase contains word separators', () {
      final passphrase = PasswordGenerator.generatePassphrase(wordCount: 4);
      expect(passphrase.contains('-'), isTrue);
    });
  });

  group('PwnedApiService - input validation', () {
    test('checkPassword returns error for empty input', () async {
      final service = PwnedApiService();
      final result = await service.checkPassword('');
      expect(result.hasError, isTrue);
      expect(result.checkType, CheckType.password);
    });

    test('checkEmail returns error for empty input', () async {
      final service = PwnedApiService();
      final result = await service.checkEmail('');
      expect(result.hasError, isTrue);
      expect(result.checkType, CheckType.email);
    });

    test('checkEmail returns error when no API key is set', () async {
      final service = PwnedApiService();
      final result = await service.checkEmail('test@example.com');
      expect(result.hasError, isTrue);
      expect(result.errorMessage, contains('API key'));
    });
  });

  group('BreachResult', () {
    test('hasError is false when errorMessage is null', () {
      const result = BreachResult(
        input: 'test',
        checkType: CheckType.password,
        isPwned: false,
      );
      expect(result.hasError, isFalse);
    });

    test('hasError is true when errorMessage is set', () {
      const result = BreachResult(
        input: 'test',
        checkType: CheckType.password,
        isPwned: false,
        errorMessage: 'Something went wrong',
      );
      expect(result.hasError, isTrue);
    });
  });
}
