/// Result of `send_otp.php`. The `referenceNo` is what the client
/// must send back to `verify_otp.php` — without it the verification
/// call will fail.
class OtpRequest {
  const OtpRequest({
    required this.success,
    required this.message,
    required this.referenceNo,
    required this.statusCode,
    required this.statusDetail,
    required this.subscriberId,
  });

  final bool success;
  final String message;
  final String? referenceNo;
  final String statusCode;
  final String statusDetail;
  final String subscriberId;

  /// The server treats some cases (e.g. E1351) as "the user is
  /// already registered" — in that scenario the API still returns
  /// success=false but the caller should keep going as if the
  /// subscription check had succeeded.
  bool get isAlreadyRegistered => statusCode == 'E1351';
}
