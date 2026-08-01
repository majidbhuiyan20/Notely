import '../entities/unsubscribe_result.dart';
import '../repositories/subscription_repository.dart';

class UnsubscribeUseCase {
  const UnsubscribeUseCase(this._repository);
  final SubscriptionRepository _repository;

  Future<UnsubscribeResult> call(String mobileNumber) {
    return _repository.unsubscribe(mobileNumber);
  }
}
