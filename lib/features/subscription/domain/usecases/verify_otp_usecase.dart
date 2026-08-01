import '../entities/otp_verification.dart';
import '../repositories/subscription_repository.dart';

class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository);
  final SubscriptionRepository _repository;

  Future<OtpVerification> call({
    required String mobileNumber,
    required String otp,
    required String referenceNo,
  }) {
    return _repository.verifyOtp(
      mobileNumber: mobileNumber,
      otp: otp,
      referenceNo: referenceNo,
    );
  }
}
