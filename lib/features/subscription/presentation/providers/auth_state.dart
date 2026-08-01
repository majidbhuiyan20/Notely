/// The exhaustive set of high-level UI states for the mobile-then-
/// google auth flow.
///
/// Modeled as a sealed class so the [AuthNotifier] can expose a
/// single, type-safe state object and screens can pattern-match on
/// it. This is what we render in the UI — it deliberately hides the
/// lower-level state machine (subscription status, reference number,
/// etc.) which lives inside the notifier.
sealed class AuthState {
  const AuthState();

  /// Convenience getters so screens don't have to do `is AuthAuthenticated`
  /// checks for the common cases.
  bool get isLoading => false;
  bool get isError => false;
  String? get errorMessage => null;
  bool get isAuthenticated => false;
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
  @override
  bool get isLoading => true;
}

class AuthCheckingSubscription extends AuthState {
  const AuthCheckingSubscription();
  @override
  bool get isLoading => true;
}

class AuthAlreadySubscribed extends AuthState {
  const AuthAlreadySubscribed();
}

class AuthSendingOtp extends AuthState {
  const AuthSendingOtp();
  @override
  bool get isLoading => true;
}

class AuthOtpSent extends AuthState {
  const AuthOtpSent();
}

class AuthVerifyingOtp extends AuthState {
  const AuthVerifyingOtp();
  @override
  bool get isLoading => true;
}

class AuthOtpVerified extends AuthState {
  const AuthOtpVerified();
}

class AuthGoogleSigningIn extends AuthState {
  const AuthGoogleSigningIn();
  @override
  bool get isLoading => true;
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
  @override
  bool get isAuthenticated => true;
}

class AuthUnsubscribing extends AuthState {
  const AuthUnsubscribing();
  @override
  bool get isLoading => true;
}

class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}

class AuthError extends AuthState {
  const AuthError(this.errorMessage);
  @override
  bool get isError => true;
  @override
  final String errorMessage;
}
