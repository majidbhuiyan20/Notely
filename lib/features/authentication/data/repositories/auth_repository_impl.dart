import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_user_model.dart';

/// Composes the local cache and the Firebase/Google datasources into the
/// single [AuthRepository] interface used by the presentation layer.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<AuthUser?> getSavedUser() async {
    // 1. The local cache is the source of truth for "do we need to ask
    //    the user to sign in again". Once they've completed Google
    //    Sign-In once, this is set and they skip the Login screen.
    final cached = await _local.readUser();
    if (cached != null && cached.uid.isNotEmpty) return cached;

    // 2. Fallback: Firebase might still have a live session even if the
    //    cache was wiped (e.g. after reinstall on iOS).
    final fresh = _remote.currentUser();
    if (fresh != null) {
      await _local.writeUser(AuthUserModel.fromEntity(fresh));
      return fresh;
    }
    return null;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final user = await _remote.signInWithGoogle();
    // Persist the user locally so the next launch can skip the Login
    // screen entirely (see [getSavedUser]).
    await _local.writeUser(AuthUserModel.fromEntity(user));
    return user;
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final user = await _remote.signInAnonymously();
    await _local.writeUser(AuthUserModel.fromEntity(user));
    return user;
  }

  @override
  Future<void> signOut() async {
    await _remote.signOut();
    await _local.clearUser();
  }

  @override
  Future<bool> isOnboardingComplete() => _local.isOnboardingComplete();

  @override
  Future<void> markOnboardingComplete() => _local.markOnboardingComplete();
}