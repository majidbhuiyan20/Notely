import '../entities/otp_request.dart';
import '../entities/otp_verification.dart';
import '../entities/subscription_status.dart';
import '../entities/unsubscribe_result.dart';

/// Contract implemented by the data layer. The presentation layer
/// depends on this interface only — never on Dio or any remote
/// package — so the underlying transport can be swapped (or mocked
/// in tests) without touching UI code.
abstract class SubscriptionRepository {
  /// Hits `check_subscription.php`. The result tells the caller
  /// whether they can skip the OTP flow.
  Future<SubscriptionStatus> checkSubscription(String mobileNumber);

  /// Hits `send_otp.php`. Returns the reference number needed to
  /// verify the OTP.
  Future<OtpRequest> sendOtp(String mobileNumber);

  /// Hits `verify_otp.php`. Returns success/failure along with the
  /// updated subscription status.
  Future<OtpVerification> verifyOtp({
    required String mobileNumber,
    required String otp,
    required String referenceNo,
  });

  /// Hits `unsubscribe.php`. The endpoint is idempotent — the caller
  /// should always clear the local session regardless of the result.
  Future<UnsubscribeResult> unsubscribe(String mobileNumber);
}
