import '../entities/subscription_status.dart';
import '../repositories/subscription_repository.dart';

/// Use case: check whether the supplied mobile number is already
/// subscribed with the carrier.
///
/// Thin wrapper today, but living in the domain layer means the
/// presentation layer depends on a verb (`checkSubscription`) rather
/// than a transport (`http.post`).
class CheckSubscriptionUseCase {
  const CheckSubscriptionUseCase(this._repository);
  final SubscriptionRepository _repository;

  Future<SubscriptionStatus> call(String mobileNumber) {
    return _repository.checkSubscription(mobileNumber);
  }
}
