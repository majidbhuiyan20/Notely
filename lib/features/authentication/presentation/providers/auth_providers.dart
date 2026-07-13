import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../task/providers/notes_providers.dart';

/// DI providers for the authentication feature. The data sources are
/// kept as separate providers so tests (and the override in `main.dart`)
/// can swap them out.

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
  );
});

/// Holds the currently authenticated user, or `null` when signed out.
/// Exposed as [AsyncValue] so the UI can react to loading and error
/// states consistently.
class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final repo = ref.read(authRepositoryProvider);
    return repo.getSavedUser();
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithGoogle();
      state = AsyncValue.data(user);
      // Pull the user's tasks from Firestore and replace the local cache
      // so the rest of the app sees their data immediately. We use a
      // microtask + ignore so this never re-enters the auth provider's
      // call stack (which would form a circular dependency, since
      // tasksProvider → currentUidProvider → authNotifierProvider).
      Future.microtask(() async {
        try {
          await ref.read(tasksProvider.notifier).refresh();
        } catch (_) {
          // Refresh failure is non-fatal for sign-in. The next
          // connectivity edge or app foreground will retry the drain.
        }
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    // Setting `state` to `data(null)` makes `currentUidProvider` flip to
    // null, which causes `TasksNotifier.build()` to re-run and clear its
    // in-memory mirror itself (see the `uid == null` branch in
    // notes_providers.dart). We MUST NOT call
    // `ref.read(tasksProvider.notifier).clearLocal()` here — that would
    // form a circular dependency (authNotifierProvider →
    // tasksProvider → currentUidProvider → authNotifierProvider) and
    // throw a `CircularDependencyError` mid-sign-out.
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUser?>(AuthNotifier.new);

/// One-shot bootstrap state used by the splash screen to decide what to
/// show next: the main app, onboarding, or the login screen.
class BootState {
  const BootState({required this.user, required this.onboardingComplete});

  final AuthUser? user;
  final bool onboardingComplete;

  bool get isAuthenticated => user != null;
}

final bootStateProvider = FutureProvider<BootState>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  // Run the two reads in parallel since they touch independent prefs keys.
  final results = await Future.wait([
    repo.getSavedUser(),
    repo.isOnboardingComplete(),
  ]);
  return BootState(
    user: results[0] as AuthUser?,
    onboardingComplete: results[1] as bool,
  );
});