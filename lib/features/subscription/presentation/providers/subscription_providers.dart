import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/friendly_error_mapper.dart';
import '../../data/datasources/session_local_datasource.dart';
import '../../data/datasources/subscription_remote_datasource.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/entities/mobile_session.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/services/session_manager.dart';
import '../../domain/usecases/check_subscription_usecase.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/unsubscribe_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'auth_notifier.dart';

// ─── Core networking ──────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final friendlyErrorMapperProvider = Provider<FriendlyErrorMapper>((ref) {
  return const FriendlyErrorMapper();
});

// ─── Data sources ─────────────────────────────────────────────────

final subscriptionRemoteDataSourceProvider =
    Provider<SubscriptionRemoteDataSource>((ref) {
  return SubscriptionRemoteDataSource(
    client: ref.watch(apiClientProvider),
  );
});

final sessionLocalDataSourceProvider =
    Provider<SessionLocalDataSource>((ref) {
  return SessionLocalDataSource();
});

// ─── Repository ───────────────────────────────────────────────────

final subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl(
    remote: ref.watch(subscriptionRemoteDataSourceProvider),
  );
});

// ─── Use cases ────────────────────────────────────────────────────

final checkSubscriptionUseCaseProvider =
    Provider<CheckSubscriptionUseCase>((ref) {
  return CheckSubscriptionUseCase(
    ref.watch(subscriptionRepositoryProvider),
  );
});

final sendOtpUseCaseProvider = Provider<SendOtpUseCase>((ref) {
  return SendOtpUseCase(ref.watch(subscriptionRepositoryProvider));
});

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>((ref) {
  return VerifyOtpUseCase(ref.watch(subscriptionRepositoryProvider));
});

final unsubscribeUseCaseProvider = Provider<UnsubscribeUseCase>((ref) {
  return UnsubscribeUseCase(ref.watch(subscriptionRepositoryProvider));
});

// ─── Session manager ──────────────────────────────────────────────

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return SessionManager(ref.watch(sessionLocalDataSourceProvider));
});

/// Convenience provider for screens that only need the current
/// session as a synchronous read. Falls back to [MobileSession.empty]
/// while loading. The actual session is loaded by the splash screen
/// on app launch; subsequent reads come from the in-memory copy
/// maintained by [AuthNotifier].
final subscriptionSessionProvider = Provider<MobileSession>((ref) {
  // Watch the notifier so the UI rebuilds when the session changes
  // (e.g. after Unsubscribe & Logout).
  ref.watch(authNotifierProvider);
  return ref.read(authNotifierProvider.notifier).currentSession ??
      MobileSession.empty;
});
