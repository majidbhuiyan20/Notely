// Tests for the auth-flag invariants on [SessionManager].
//
// The whole point of the bug-fix in this file is: a wrong OTP, a
// pending OTP request, or any other mid-flow state MUST NOT set
// `isMobileLoggedIn = true`. The only paths that flip that flag are
// `markAlreadySubscribed` and `markMobileVerified`, and only after a
// successful API response.
import 'package:flutter_test/flutter_test.dart';
import 'package:notely/features/subscription/data/datasources/session_local_datasource.dart';
import 'package:notely/features/subscription/domain/entities/mobile_session.dart';
import 'package:notely/features/subscription/domain/services/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SessionManager session;
  late SessionLocalDataSource local;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    local = SessionLocalDataSource();
    session = SessionManager(local);
  });

  group('Auth-flag invariants', () {
    test('empty session starts with all flags false', () async {
      final s = await session.loadSession();
      expect(s.isMobileLoggedIn, isFalse);
      expect(s.isGoogleLoggedIn, isFalse);
      expect(s.isOnboardingCompleted, isFalse);
      expect(s.isSubscribed, isFalse);
    });

    test('savePendingOtpSession does NOT set isMobileLoggedIn', () async {
      await session.savePendingOtpSession(
        mobileNumber: '8801712345678',
        referenceNo: 'REF123',
        subscriberId: 'tel:8801712345678',
        subscriptionStatus: 'PENDING OTP',
      );

      final s = await session.loadSession();
      expect(s.referenceNo, 'REF123');
      expect(s.mobileNumber, '8801712345678');
      // Crucial: user is NOT marked as logged in.
      expect(s.isMobileLoggedIn, isFalse);
      expect(s.isSubscribed, isFalse);
    });

    test('saveReferenceNo preserves isMobileLoggedIn if previously set',
        () async {
      // Simulate a previously-completed login (e.g. a returning user
      // whose session was wiped by resend). Then verify a saveReferenceNo
      // does not clobber the auth flag.
      await session.markMobileVerified(
        mobileNumber: '8801712345678',
        subscriberId: 'tel:8801712345678',
        subscriptionStatus: 'ACTIVE',
      );

      await session.saveReferenceNo('REFRESHED_REF');

      final s = await session.loadSession();
      expect(s.isMobileLoggedIn, isTrue);
      expect(s.isSubscribed, isTrue);
      expect(s.referenceNo, 'REFRESHED_REF');
    });

    test('markMobileVerified flips BOTH isMobileLoggedIn and isSubscribed',
        () async {
      await session.markMobileVerified(
        mobileNumber: '8801712345678',
        subscriberId: 'tel:8801712345678',
        subscriptionStatus: 'ACTIVE',
      );

      final s = await session.loadSession();
      expect(s.isMobileLoggedIn, isTrue);
      expect(s.isSubscribed, isTrue);
      expect(s.mobileNumber, '8801712345678');
      expect(s.subscriberId, 'tel:8801712345678');
      // referenceNo is cleared on success — we no longer need it.
      expect(s.referenceNo, isNull);
    });

    test('markAlreadySubscribed flips BOTH isMobileLoggedIn and isSubscribed',
        () async {
      await session.markAlreadySubscribed(
        mobileNumber: '8801712345678',
        subscriberId: 'tel:8801712345678',
        subscriptionStatus: 'ACTIVE',
      );

      final s = await session.loadSession();
      expect(s.isMobileLoggedIn, isTrue);
      expect(s.isSubscribed, isTrue);
    });

    test('clearPendingOtpSession preserves isMobileLoggedIn', () async {
      await session.markMobileVerified(
        mobileNumber: '8801712345678',
        subscriberId: 'tel:8801712345678',
        subscriptionStatus: 'ACTIVE',
      );
      await session.saveReferenceNo('LEFTOVER_REF');
      await session.clearPendingOtpSession();

      final s = await session.loadSession();
      expect(s.isMobileLoggedIn, isTrue);
      expect(s.isSubscribed, isTrue);
      expect(s.referenceNo, isNull);
    });

    test('clearSession wipes every flag and in-flight field', () async {
      await session.markMobileVerified(
        mobileNumber: '8801712345678',
        subscriberId: 'tel:8801712345678',
        subscriptionStatus: 'ACTIVE',
      );

      await session.clearSession();

      final s = await session.loadSession();
      expect(s.isMobileLoggedIn, isFalse);
      expect(s.isSubscribed, isFalse);
      expect(s.isGoogleLoggedIn, isFalse);
      expect(s.isOnboardingCompleted, isFalse);
      expect(s.mobileNumber, isNull);
      expect(s.subscriberId, isNull);
      expect(s.referenceNo, isNull);
    });

    test('MobileSession.empty has all flags false', () {
      expect(MobileSession.empty.isMobileLoggedIn, isFalse);
      expect(MobileSession.empty.isGoogleLoggedIn, isFalse);
      expect(MobileSession.empty.isOnboardingCompleted, isFalse);
      expect(MobileSession.empty.isSubscribed, isFalse);
    });

    test('isMobileVerifiedAndSubscribed is true only when BOTH flags are set',
        () {
      const a = MobileSession(
        isMobileLoggedIn: true,
        isGoogleLoggedIn: false,
        isOnboardingCompleted: true,
        isSubscribed: true,
      );
      const b = MobileSession(
        isMobileLoggedIn: false,
        isGoogleLoggedIn: false,
        isOnboardingCompleted: true,
        isSubscribed: true,
      );
      const c = MobileSession(
        isMobileLoggedIn: true,
        isGoogleLoggedIn: false,
        isOnboardingCompleted: true,
        isSubscribed: false,
      );
      expect(a.isMobileVerifiedAndSubscribed, isTrue);
      expect(b.isMobileVerifiedAndSubscribed, isFalse);
      expect(c.isMobileVerifiedAndSubscribed, isFalse);
    });

    test('saveMobileOffline preserves every supplied field verbatim',
        () async {
      // The splash uses saveMobileOffline after re-validating
      // subscription status — the caller hands us a fully-formed
      // session and we MUST persist it exactly as-is.
      const fresh = MobileSession(
        isMobileLoggedIn: false,
        isGoogleLoggedIn: true,
        isOnboardingCompleted: true,
        isSubscribed: false,
        mobileNumber: '8801712345678',
        subscriberId: 'tel:8801712345678',
      );
      final result = await session.saveMobileOffline(fresh);
      expect(result.isGoogleLoggedIn, isTrue);
      expect(result.isMobileLoggedIn, isFalse);
      expect(result.isSubscribed, isFalse);
      expect(result.mobileNumber, '8801712345678');

      final reread = await session.loadSession();
      expect(reread.isGoogleLoggedIn, isTrue);
      expect(reread.mobileNumber, '8801712345678');
    });
  });
}