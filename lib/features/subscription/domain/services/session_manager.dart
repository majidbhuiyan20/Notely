import '../entities/mobile_session.dart';
import '../../data/datasources/session_local_datasource.dart';

/// Singleton-ish facade over the auth-related SharedPreferences.
///
/// ## Auth-flag rules (read carefully)
/// **Never** call `saveMobileSession(...)` until the user has
/// successfully verified their OTP AND `isSubscribed == true`. That
/// is the **only** place in the flow that writes
/// `isMobileLoggedIn = true`. Sending an OTP, receiving a
/// `referenceNo`, or even getting back an E1351 ("already
/// registered") does NOT mark the user as logged in.
///
/// For mid-flow data (mobile number while the user is on the OTP
/// screen, or the carrier `referenceNo`), use the dedicated
/// in-flight writers — they **never** touch the auth flags:
///
///   * [savePendingOtpSession] — remember the mobile + reference
///     between screens. Splash ignores this for routing.
///   * [saveReferenceNo]       — narrower version used by resend.
///
/// ## API
/// Reads:
///   * [loadSession], [getSession]
///   * [isMobileLoggedIn], [isGoogleLoggedIn], [isOnboardingCompleted]
///
/// Writes (auth flags):
///   * [markMobileVerified]    — only after OTP+subscription succeed.
///   * [saveGoogleSession]     — only after Firebase/Google succeeds.
///   * [markOnboardingComplete]
///
/// Writes (in-flight, never touches auth flags):
///   * [savePendingOtpSession]
///   * [saveReferenceNo]
///
/// Logout / clear:
///   * [clearSession], [logout], [unsubscribe]
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

  // --- Writes (auth flags) ---

  /// Called **only** after `verify_otp.php` returns `S1000` AND the
  /// user is subscribed. This is the single point in the codebase
  /// that flips `isMobileLoggedIn` to `true`.
  ///
  /// Persists:
  ///   * `isMobileLoggedIn = true`
  ///   * `isSubscribed = true`
  ///   * `mobileNumber`, `subscriberId`, `subscriptionStatus`
  ///   * `referenceNo` is cleared (no longer needed).
  Future<MobileSession> markMobileVerified({
    required String mobileNumber,
    required String subscriberId,
    required String subscriptionStatus,
  }) async {
    final current = await _local.read();
    final next = MobileSession(
      // Preserve Google + onboarding flags, flip the mobile-related ones.
      isMobileLoggedIn: true,
      isGoogleLoggedIn: current.isGoogleLoggedIn,
      isOnboardingCompleted: current.isOnboardingCompleted,
      isSubscribed: true,
      mobileNumber: mobileNumber,
      subscriberId: subscriberId,
      subscriptionStatus: subscriptionStatus,
      firebaseUid: current.firebaseUid,
      email: current.email,
      displayName: current.displayName,
      photoUrl: current.photoUrl,
      loginDate: DateTime.now(),
      // Auth flags are set — drop any in-flight referenceNo so the
      // splash doesn't try to resume a stale OTP request.
      referenceNo: null,
    );
    await _local.write(next);
    return next;
  }

  /// Same as [markMobileVerified] but for users that already had an
  /// active subscription when [AuthNotifier] called
  /// `check_subscription.php`. Skips the OTP step entirely.
  Future<MobileSession> markAlreadySubscribed({
    required String mobileNumber,
    required String subscriberId,
    required String subscriptionStatus,
  }) async {
    final current = await _local.read();
    final next = MobileSession(
      isMobileLoggedIn: true,
      isGoogleLoggedIn: current.isGoogleLoggedIn,
      isOnboardingCompleted: current.isOnboardingCompleted,
      isSubscribed: true,
      mobileNumber: mobileNumber,
      subscriberId: subscriberId,
      subscriptionStatus: subscriptionStatus,
      firebaseUid: current.firebaseUid,
      email: current.email,
      displayName: current.displayName,
      photoUrl: current.photoUrl,
      loginDate: DateTime.now(),
      referenceNo: null,
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
    final next = MobileSession(
      isMobileLoggedIn: current.isMobileLoggedIn,
      isGoogleLoggedIn: true,
      isOnboardingCompleted: current.isOnboardingCompleted,
      isSubscribed: current.isSubscribed,
      mobileNumber: current.mobileNumber,
      subscriberId: current.subscriberId,
      subscriptionStatus: current.subscriptionStatus,
      firebaseUid: firebaseUid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      loginDate: DateTime.now(),
      referenceNo: current.referenceNo,
    );
    await _local.write(next);
    return next;
  }

  Future<MobileSession> markOnboardingComplete() async {
    final current = await _local.read();
    final next = MobileSession(
      isMobileLoggedIn: current.isMobileLoggedIn,
      isGoogleLoggedIn: current.isGoogleLoggedIn,
      isOnboardingCompleted: true,
      isSubscribed: current.isSubscribed,
      mobileNumber: current.mobileNumber,
      subscriberId: current.subscriberId,
      subscriptionStatus: current.subscriptionStatus,
      firebaseUid: current.firebaseUid,
      email: current.email,
      displayName: current.displayName,
      photoUrl: current.photoUrl,
      loginDate: current.loginDate,
      referenceNo: current.referenceNo,
    );
    await _local.write(next);
    return next;
  }

  // --- Writes (in-flight data — auth flags are untouched) ---

  /// Stores the mobile number + carrier `referenceNo` while the user
  /// is on the OTP screen. Crucially this does **not** set
  /// `isMobileLoggedIn` — the splash must not route to Google Login
  /// just because we remembered an OTP request.
  ///
  /// When the API returns E1351 ("already registered") the carrier
  /// has no `referenceNo` for us, but the `subscriberId` doubles as
  /// one for `verify_otp.php`. Pass the resolved reference in
  /// [referenceNo] (the notifier extracts the bare number from the
  /// `tel:...` prefix before calling this).
  Future<MobileSession> savePendingOtpSession({
    required String mobileNumber,
    required String referenceNo,
    String? subscriberId,
    String? subscriptionStatus,
  }) async {
    final current = await _local.read();
    final next = MobileSession(
      // IMPORTANT: do NOT set isMobileLoggedIn here.
      isMobileLoggedIn: current.isMobileLoggedIn,
      isGoogleLoggedIn: current.isGoogleLoggedIn,
      isOnboardingCompleted: current.isOnboardingCompleted,
      isSubscribed: current.isSubscribed,
      mobileNumber: mobileNumber,
      subscriberId: subscriberId ?? current.subscriberId,
      subscriptionStatus: subscriptionStatus ?? current.subscriptionStatus,
      firebaseUid: current.firebaseUid,
      email: current.email,
      displayName: current.displayName,
      photoUrl: current.photoUrl,
      loginDate: current.loginDate,
      referenceNo: referenceNo,
    );
    await _local.write(next);
    return next;
  }

  /// Stores only the carrier `referenceNo`. Used when resending an
  /// OTP — the mobile number is already in prefs from the initial
  /// `savePendingOtpSession`. Auth flags are explicitly preserved.
  Future<MobileSession> saveReferenceNo(String referenceNo) async {
    final current = await _local.read();
    final next = MobileSession(
      isMobileLoggedIn: current.isMobileLoggedIn,
      isGoogleLoggedIn: current.isGoogleLoggedIn,
      isOnboardingCompleted: current.isOnboardingCompleted,
      isSubscribed: current.isSubscribed,
      mobileNumber: current.mobileNumber,
      subscriberId: current.subscriberId,
      subscriptionStatus: current.subscriptionStatus,
      firebaseUid: current.firebaseUid,
      email: current.email,
      displayName: current.displayName,
      photoUrl: current.photoUrl,
      loginDate: current.loginDate,
      referenceNo: referenceNo,
    );
    await _local.write(next);
    return next;
  }

  /// Clears any in-flight OTP data — used when the user explicitly
  /// navigates back to the mobile-number screen, or when an
  /// unhandled error occurs mid-flow. Auth flags that were already
  /// set (e.g. `isMobileLoggedIn` from a previous successful login)
  /// are preserved.
  ///
  /// We can't use `copyWith(referenceNo: null)` because the entity
  /// treats `null` as "leave unchanged" (the canonical Dart pattern
  /// for `copyWith`). Instead we build a fresh `MobileSession` that
  /// copies the auth flags verbatim and zeroes the `referenceNo`.
  Future<MobileSession> clearPendingOtpSession() async {
    final current = await _local.read();
    final next = MobileSession(
      // Preserve every auth flag — this is only clearing in-flight data.
      isMobileLoggedIn: current.isMobileLoggedIn,
      isGoogleLoggedIn: current.isGoogleLoggedIn,
      isOnboardingCompleted: current.isOnboardingCompleted,
      isSubscribed: current.isSubscribed,
      // Keep identity fields, drop only the in-flight referenceNo.
      mobileNumber: current.mobileNumber,
      subscriberId: current.subscriberId,
      subscriptionStatus: current.subscriptionStatus,
      firebaseUid: current.firebaseUid,
      email: current.email,
      displayName: current.displayName,
      photoUrl: current.photoUrl,
      loginDate: current.loginDate,
      referenceNo: null,
    );
    await _local.write(next);
    return next;
  }

  // --- Logout / clear ---

  /// Low-level write used by `AuthNotifier.clearMobileAuth`. Unlike
  /// the auth-flag methods above, this is intentionally non-prescriptive
  /// — the caller chooses what stays and what goes. We persist the
  /// supplied session as-is so the splash can rely on it being
  /// exactly what the caller asked for.
  Future<MobileSession> saveMobileOffline(MobileSession session) async {
    await _local.write(session);
    return session;
  }

  Future<void> clearSession() => _local.wipe();

  /// Alias of [clearSession]. Kept as a separate method so call
  /// sites read like English ("session.logout()").
  Future<void> logout() => _local.wipe();

  /// Called during the Unsubscribe & Logout flow. Same effect as
  /// [clearSession] — the function name documents intent at the
  /// call site.
  Future<void> unsubscribe() => _local.wipe();
}