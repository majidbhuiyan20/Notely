/// Result of `verify_otp.php`. The interesting field is [statusCode]:
/// `S1000` means the OTP was accepted.
class OtpVerification {
  const OtpVerification({
    required this.statusCode,
    required this.statusDetail,
    required this.subscriptionStatus,
    required this.subscriberId,
  });

  final String statusCode;
  final String statusDetail;
  final String subscriptionStatus;
  final String subscriberId;

  bool get isOk => statusCode == 'S1000';
}
