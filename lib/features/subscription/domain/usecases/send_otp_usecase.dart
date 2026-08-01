import '../entities/otp_request.dart';
import '../repositories/subscription_repository.dart';

class SendOtpUseCase {
  const SendOtpUseCase(this._repository);
  final SubscriptionRepository _repository;

  Future<OtpRequest> call(String mobileNumber) {
    return _repository.sendOtp(mobileNumber);
  }
}
