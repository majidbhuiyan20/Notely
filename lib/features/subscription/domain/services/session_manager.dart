import '../entities/mobile_session.dart';
import '../../data/datasources/session_local_datasource.dart';

/// Singleton-ish facade over the auth-related SharedPreferences.
///
/// API exposed to the rest of the app:
///
///   * `loadSession()`         — rehydrate on splash.
///   * `saveMobileSession()`   — after OTP success.
///   * `saveGoogleSession()`   — after Firebase/Google sign-in.
///   * `markOnboardingComplete()`  — once the user finishes onboarding.
///   * `isMobileLoggedIn()`     — quick boolean read.
///   * `isGoogleLoggedIn()`     — quick boolean read.
///   * `isOnboardingCompleted()`   — quick boolean read.
///   * `getSession()`           — for screens that need the full blob.
///   * `clearSession()`         — logout (no unsubscribe).
///   * `logout()`               — alias of clearSession().
class SessionManager {
  SessionManager(this._local);

  final SessionLocalDataSource _local;

  // --- Reads ---

  Future<MobileSession> loadSession() => _local.read();

  Future<MobileSession> getSession() => _local.read();

  Future<bool> isMobileLoggedIn() async {
    return (await _local.read()).isMobileLoggedIn;
  }

  Future<bool> isGoogleLoggedIn() async {
    return (await _local.read()).isGoogleLoggedIn;
  }

  Future<bool> isOnboardingCompleted() async {
    return (await _local.read()).isOnboardingCompleted;
  }

  // --- Writes ---

  Future<MobileSession> saveMobileSession({
    required String mobileNumber,
    required String subscriberId,
    required String subscriptionStatus,
    String? referenceNo,
  }) async {
    final current = await _local.read();
    final next = current.copyWith(
      isMobileLoggedIn: true,
      mobileNumber: mobileNumber,
      subscriberId: subscriberId,
      subscriptionStatus: subscriptionStatus,
      referenceNo: referenceNo,
      loginDate: DateTime.now(),
    );
    await _local.write(next);
    return next;
  }

  Future<MobileSession> saveGoogleSession({
    required String firebaseUid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final current = await _local.read();
    final next = current.copyWith(
      isGoogleLoggedIn: true,
      firebaseUid: firebaseUid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      loginDate: DateTime.now(),
    );
    await _local.write(next);
    return next;
  }

  Future<MobileSession> markOnboardingComplete() async {
    final current = await _local.read();
    final next = current.copyWith(isOnboardingCompleted: true);
    await _local.write(next);
    return next;
  }

  /// Stores the reference number while the user is on the OTP screen
  /// (so a re-build of the OTP screen can rehydrate the right
  /// reference even after a network drop).
  Future<MobileSession> saveReferenceNo(String referenceNo) async {
    final current = await _local.read();
    final next = current.copyWith(referenceNo: referenceNo);
    await _local.write(next);
    return next;
  }

  // --- Logout / clear ---

  Future<void> clearSession() => _local.wipe();

  /// Alias of [clearSession]. Kept as a separate method so call
  /// sites read like English ("session.logout()").
  Future<void> logout() => _local.wipe();

  /// Called during the Unsubscribe & Logout flow. Same effect as
  /// [clearSession] — the function name documents intent at the
  /// call site.
  Future<void> unsubscribe() => _local.wipe();
}
