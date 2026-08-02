/// Result of `verify_otp.php`. The interesting field is [statusCode]:
/// `S1000` means the OTP was accepted.
class OtpVerification {
  const OtpVerification({
    required this.statusCode,
    required this.statusDetail,
    required this.subscriptionStatus,
    required this.subscriberId,
    this.isSubscribed = false,
  });

  final String statusCode;
  final String statusDetail;
  final String subscriptionStatus;
  final String subscriberId;

  /// Some `verify_otp.php` responses include an `isSubscribed` flag —
  /// true when the OTP step completed and the user is now active on
  /// the carrier. When true the caller can route straight to Google
  /// Sign-In without re-running `check_subscription.php`.
  final bool isSubscribed;

  bool get isOk => statusCode == 'S1000';
}