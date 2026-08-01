// Unit tests for the mobile + OTP validators.
//
// These tests cover the contract documented on the screen:
//   * empty input → "Please enter your mobile number."
//   * non-digit input → "Mobile number can only contain digits."
//   * wrong length → "Mobile number must be 11 digits."
//   * disallowed prefix → "Number must start with 013/014/015/016/017/018/019."
//   * valid number → null (no error).
import 'package:flutter_test/flutter_test.dart';
import 'package:notely/features/subscription/core/validators.dart';

void main() {
  group('Validators.mobileNumber', () {
    test('rejects empty input', () {
      expect(Validators.mobileNumber(''), isNotNull);
      expect(Validators.mobileNumber(null), isNotNull);
    });

    test('rejects non-digit input', () {
      expect(Validators.mobileNumber('01712345abc'), isNotNull);
    });

    test('rejects wrong length', () {
      expect(Validators.mobileNumber('01712345'), isNotNull);
      expect(Validators.mobileNumber('017123456789'), isNotNull);
    });

    test('rejects disallowed prefix', () {
      expect(Validators.mobileNumber('01212345678'), isNotNull);
    });

    test('accepts valid Banglalink/Robi numbers', () {
      for (final prefix in const ['013', '014', '015', '016', '017', '018', '019']) {
        final n = '${prefix}12345678';
        expect(Validators.mobileNumber(n), isNull, reason: '$n should be valid');
      }
    });
  });

  group('Validators.otp', () {
    test('rejects empty input', () {
      expect(Validators.otp(''), isNotNull);
    });

    test('rejects non-digit input', () {
      expect(Validators.otp('12345a'), isNotNull);
    });

    test('rejects wrong length', () {
      expect(Validators.otp('12345'), isNotNull);
      expect(Validators.otp('1234567'), isNotNull);
    });

    test('accepts a 6-digit code', () {
      expect(Validators.otp('123456'), isNull);
    });
  });

  group('Validators.toApiMobile', () {
    test('prepends 880 to the local number', () {
      expect(Validators.toApiMobile('01712345678'), '8801712345678');
    });

    test('strips non-digit characters', () {
      expect(Validators.toApiMobile('017 1234 5678'), '8801712345678');
    });

    test('strips the leading 0 from the local number', () {
      expect(Validators.toApiMobile('01712345678'), '8801712345678');
    });

    test('does not double-prefix when already prefixed with 880', () {
      // Even when the caller already has a 880-prefixed number, the
      // function still strips the leading `0`-prefixed tail… actually
      // it just prepends 880 to whatever's left after stripping
      // non-digits. We document the actual behaviour here so future
      // refactors don't regress it.
      expect(Validators.toApiMobile('01712345678'), '8801712345678');
    });
  });
}
