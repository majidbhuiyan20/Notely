/// Snapshot of the user's mobile-subscription session. Persisted by
/// [SessionManager] and rehydrated at app launch.
///
/// `isMobileLoggedIn` and `isGoogleLoggedIn` are tracked separately
/// so we can tell "mobile is fine, just re-do Google" apart from
/// "everything is gone, restart from onboarding".
///
/// IMPORTANT — these flags are **only** set after the user has
/// successfully completed the relevant verification step:
///
///   * `isMobileLoggedIn` — set only after `verify_otp.php` succeeds
///     with `isSubscribed == true`. Sending an OTP (or having a
///     pending referenceNo) does NOT set this flag.
///   * `isSubscribed`     — set at the same time as
///     `isMobileLoggedIn`. Stays true after logout so the user can
///     still be distinguished from a first-launch user.
///   * `isGoogleLoggedIn` — set only after Firebase/Google sign-in
///     returns a real user.
///
/// `referenceNo` and `mobileNumber` may be populated while the user
/// is mid-flow (e.g. on the OTP screen) but they are NOT
/// authentication flags — the splash must never route on them.
class MobileSession {
  const MobileSession({
    required this.isMobileLoggedIn,
    required this.isGoogleLoggedIn,
    required this.isOnboardingCompleted,
    this.isSubscribed = false,
    this.mobileNumber,
    this.subscriberId,
    this.subscriptionStatus,
    this.firebaseUid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.loginDate,
    this.referenceNo,
  });

  final bool isMobileLoggedIn;
  final bool isGoogleLoggedIn;
  final bool isOnboardingCompleted;

  /// True when the carrier has confirmed (either via
  /// `check_subscription.php` or after a successful
  /// `verify_otp.php`) that the mobile number is subscribed. Always
  /// false in [MobileSession.empty]. Persists across logout so the
  /// splash can route correctly.
  final bool isSubscribed;

  /// The mobile number the user last entered. May be populated while
  /// the user is mid-OTP, but is NOT an authentication flag on its
  /// own.
  final String? mobileNumber;
  final String? subscriberId;
  final String? subscriptionStatus;
  final String? firebaseUid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? loginDate;

  /// Carrier-side reference number for an in-flight OTP request. Set
  /// after `send_otp.php` returns a `referenceNo` (or after the
  /// E1351 fallback). Persisted so a hot-restart on the OTP screen
  /// can rehydrate the right reference. NEVER set
  /// `isMobileLoggedIn` based on this — see the class doc.
  final String? referenceNo;

  /// An empty session used as a default before any prefs are read.
  static const MobileSession empty = MobileSession(
    isMobileLoggedIn: false,
    isGoogleLoggedIn: false,
    isOnboardingCompleted: false,
    isSubscribed: false,
  );

  /// True when the carrier has confirmed the subscription but the
  /// user has not yet completed Google sign-in. The splash uses this
  /// to skip OTP entirely and route straight to the Google login.
  bool get isMobileVerifiedAndSubscribed => isMobileLoggedIn && isSubscribed;

  MobileSession copyWith({
    bool? isMobileLoggedIn,
    bool? isGoogleLoggedIn,
    bool? isOnboardingCompleted,
    bool? isSubscribed,
    String? mobileNumber,
    String? subscriberId,
    String? subscriptionStatus,
    String? firebaseUid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? loginDate,
    String? referenceNo,
  }) {
    return MobileSession(
      isMobileLoggedIn: isMobileLoggedIn ?? this.isMobileLoggedIn,
      isGoogleLoggedIn: isGoogleLoggedIn ?? this.isGoogleLoggedIn,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      subscriberId: subscriberId ?? this.subscriberId,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      loginDate: loginDate ?? this.loginDate,
      referenceNo: referenceNo ?? this.referenceNo,
    );
  }
}