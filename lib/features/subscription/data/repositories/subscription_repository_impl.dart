import '../../domain/entities/otp_request.dart';
import '../../domain/entities/otp_verification.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/entities/unsubscribe_result.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_datasource.dart';

/// Thin pass-through that maps remote DTOs into domain entities.
///
/// We could collapse this into the use-cases, but keeping the
/// `Repository` ↔ `UseCase` separation means future caching,
/// offline-first behaviour, or a mock backend can be dropped in
/// without touching either layer.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({required SubscriptionRemoteDataSource remote})
      : _remote = remote;

  final SubscriptionRemoteDataSource _remote;

  @override
  Future<SubscriptionStatus> checkSubscription(String mobileNumber) async {
    final model = await _remote.checkSubscription(mobileNumber);
    return model.toEntity();
  }

  @override
  Future<OtpRequest> sendOtp(String mobileNumber) async {
    final model = await _remote.sendOtp(mobileNumber);
    return model.toEntity();
  }

  @override
  Future<OtpVerification> verifyOtp({
    required String mobileNumber,
    required String otp,
    required String referenceNo,
  }) async {
    final model = await _remote.verifyOtp(
      mobileNumber: mobileNumber,
      otp: otp,
      referenceNo: referenceNo,
    );
    return model.toEntity();
  }

  @override
  Future<UnsubscribeResult> unsubscribe(String mobileNumber) async {
    final model = await _remote.unsubscribe(mobileNumber);
    return model.toEntity();
  }
}
