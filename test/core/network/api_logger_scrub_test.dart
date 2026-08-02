// Tests for the ApiLogger scrubbing logic. The interceptor masks
// sensitive fields (`otp`, `referenceNo`, `subscriberId`,
// `userMobile`) in any logged body so a leaked logcat cannot let
// someone replay the verification step.
import 'package:flutter_test/flutter_test.dart';
import 'package:notely/core/network/api_logger.dart';

void main() {
  group('ApiLogger.scrubMap', () {
    test('masks sensitive keys and leaves others untouched', () {
      final scrubbed = ApiLogger.scrubMap({
        'user_mobile': '01712345678',
        'otp': '123456',
        'referenceNo': 'REF-SECRET-123',
        'subscriberId': 'tel:8801712345678',
      });
      expect(scrubbed, contains('otp: ***'));
      expect(scrubbed, contains('referenceNo: ***'));
      expect(scrubbed, contains('subscriberId: ***'));
      expect(scrubbed, contains('user_mobile: ***'));
    });

    test('is case-insensitive on keys', () {
      final scrubbed = ApiLogger.scrubMap({
        'OTP': '999999',
        'ReferenceNo': 'whatever',
      });
      expect(scrubbed, contains('OTP: ***'));
      expect(scrubbed, contains('ReferenceNo: ***'));
    });
  });

  group('ApiLogger.scrubString', () {
    test('masks JSON form (`"key":"value"`)', () {
      final result = ApiLogger.scrubString(
        '{"otp":"123456","referenceNo":"REF-SECRET","statusCode":"S1000"}',
      );
      expect(result, contains('"otp":"***"'));
      expect(result, contains('"referenceNo":"***"'));
      expect(result, contains('"statusCode":"S1000"'));
    });

    test('masks URL-encoded form (`key=value`)', () {
      final result = ApiLogger.scrubString(
        'user_mobile=01712345678&otp=123456&referenceNo=REF-SECRET',
      );
      expect(result, contains('otp=***'));
      expect(result, contains('referenceNo=***'));
      // user_mobile is also masked because logging a plaintext
      // mobile number would be a PII leak.
      expect(result, contains('user_mobile=***'));
    });

    test('leaves non-sensitive fields untouched', () {
      final result = ApiLogger.scrubString(
        '{"statusCode":"S1000","statusDetail":"Success."}',
      );
      expect(result, contains('"statusCode":"S1000"'));
      expect(result, contains('"statusDetail":"Success."'));
    });

    test('masks the BDApps canonical `Otp` (capital O) key', () {
      // The BDApps verify_otp.php endpoint reads `$_POST['Otp']` with
      // a capital O. The scrubber must catch that variant too.
      final result = ApiLogger.scrubString(
        'Otp=123456&referenceNo=REF-SECRET',
      );
      expect(result, contains('Otp=***'));
      expect(result, contains('referenceNo=***'));
    });
  });
}