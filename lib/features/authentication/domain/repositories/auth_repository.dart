import '../entities/auth_user.dart';

/// Contract implemented by the data layer. The presentation layer depends
/// only on this interface, so the underlying auth provider (Google, Apple,
/// anonymous, etc.) can be swapped without touching UI code.
abstract class AuthRepository {
  /// Returns the persisted user profile (locally cached), or `null` when
  /// the user has never signed in or has been signed out. This is what is
  /// used at app startup to decide whether to show the Login screen.
  Future<AuthUser?> getSavedUser();

  /// Triggers a Google Sign-In flow. On success returns the authenticated
  /// user and (as a side-effect) persists the profile locally so future
  /// launches can skip the login screen. Throws [AuthFailure] on failure.
  Future<AuthUser> signInWithGoogle();

  /// Signs in anonymously (no email/profile). The returned user has a
  /// real Firebase uid so notes stay scoped per-device, but the account
  /// can be upgraded later via a provider link.
  Future<AuthUser> signInAnonymously();

  /// Clears the persisted user and signs out from any underlying providers.
  Future<void> signOut();

  /// Whether the user has previously completed the onboarding carousel.
  /// Used by the splash flow to decide between Onboarding → Login and
  /// Login-only entry points.
  Future<bool> isOnboardingComplete();

  /// Marks the onboarding carousel as completed so it won't be shown
  /// again on subsequent app launches.
  Future<void> markOnboardingComplete();
}