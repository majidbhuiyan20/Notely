/// Snapshot of the user's mobile-subscription session. Persisted by
/// [SessionManager] and rehydrated at app launch.
///
/// `isMobileLoggedIn` and `isGoogleLoggedIn` are tracked separately
/// so we can tell "mobile is fine, just re-do Google" apart from
/// "everything is gone, restart from onboarding".
class MobileSession {
  const MobileSession({
    required this.isMobileLoggedIn,
    required this.isGoogleLoggedIn,
    required this.isOnboardingCompleted,
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
  final String? mobileNumber;
  final String? subscriberId;
  final String? subscriptionStatus;
  final String? firebaseUid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? loginDate;
  final String? referenceNo;

  /// An empty session used as a default before any prefs are read.
  static const MobileSession empty = MobileSession(
    isMobileLoggedIn: false,
    isGoogleLoggedIn: false,
    isOnboardingCompleted: false,
  );

  MobileSession copyWith({
    bool? isMobileLoggedIn,
    bool? isGoogleLoggedIn,
    bool? isOnboardingCompleted,
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
