import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Aliased import — the old provider is named `authNotifierProvider`
// too, so we need a prefix to disambiguate.
import '../../../authentication/presentation/providers/auth_providers.dart'
    as google_auth;
import '../../core/validators.dart';
import '../../domain/entities/mobile_session.dart';
import '../../domain/services/session_manager.dart';
import 'auth_state.dart';
import 'subscription_providers.dart';

/// Central ViewModel for the new mobile-first auth flow.
///
/// The state machine walks the user through:
///
///   1. `checkSubscription(mobile)` — if `isSubscribed`, mark
///      mobile-verified and skip OTP.
///   2. `sendOtp(mobile)`           — only if step 1 returned false.
///      Persists a **pending** OTP session (no auth flags).
///   3. `verifyOtp(mobile, otp)`    — confirm OTP. On success AND
///      `isSubscribed`, mark mobile-verified.
///   4. `signInWithGoogle()`        — Firebase/Google; persist Google.
///   5. `unsubscribeAndLogout()`    — wipes everything.
///
/// ## Auth-flag invariants
/// `isMobileLoggedIn` and `isSubscribed` are **only** flipped to
/// `true` in two places — both at the bottom of this file:
///
///   * `submitMobileNumber` when `check_subscription.php` says
///     `isSubscribed`.
///   * `verifyOtp` when `verify_otp.php` says success AND
///     `isSubscribed`.
///
/// Sending an OTP — even successfully, even when the API returns a
/// `referenceNo` — does NOT set these flags. A wrong OTP must NOT
/// leave any persistent trace of "the user has logged in".
class AuthNotifier extends Notifier<AuthState> {
  late final SessionManager _session;
  late final GoogleSignIn _google;
  late final fb.FirebaseAuth _firebase;

  /// Cached mobile session — kept in memory so screens can read it
  /// without round-tripping through SharedPreferences on every build.
  MobileSession? _mobileSession;

  /// Reference number from `send_otp.php`. Needed by `verify_otp.php`.
  String? _referenceNo;

  @override
  AuthState build() {
    _session = ref.read(sessionManagerProvider);
    _google = GoogleSignIn();
    _firebase = fb.FirebaseAuth.instance;
    return const AuthInitial();
  }

  // ─── Read accessors ────────────────────────────────────────────

  MobileSession? get currentSession => _mobileSession;

  String? get referenceNo => _referenceNo;

  // ─── Boot (splash) ─────────────────────────────────────────────

  /// Called by the splash screen. Loads the persisted session and
  /// returns it so the splash can route based on **persisted auth
  /// flags only** — never on in-flight data like a pending
  /// `referenceNo`.
  Future<MobileSession> loadSession() async {
    _mobileSession = await _session.loadSession();
    return _mobileSession!;
  }

  // ─── Step 1: check subscription ────────────────────────────────

  /// Drives the [AuthCheckingSubscription] → [AuthAlreadySubscribed]
  /// | [AuthSendingOtp] → [AuthOtpSent] | [AuthError] transition.
  ///
  /// The caller passes a **local** mobile number (e.g. `01712345678`).
  /// We translate it to the API format (`8801712345678`) at the
  /// edge so the rest of the app never has to know about the wire
  /// format.
  ///
  /// Persistence rules:
  ///
  /// * If the carrier says `isSubscribed == true` we mark the user
  ///   as mobile-verified (`isMobileLoggedIn=true`) — this is one of
  ///   the only two places that flips the flag.
  /// * If the carrier says NOT subscribed, we send an OTP. The
  ///   resulting `referenceNo` is stored in **pending** state
  ///   (`savePendingOtpSession`) — `isMobileLoggedIn` is NOT set.
  ///   A wrong OTP therefore leaves no persistent auth trace.
  Future<void> submitMobileNumber(String localMobile) async {
    final validation = Validators.mobileNumber(localMobile);
    if (validation != null) {
      state = AuthError(validation);
      return;
    }

    final apiMobile = Validators.toApiMobile(localMobile);
    state = const AuthCheckingSubscription();

    try {
      final useCase = ref.read(checkSubscriptionUseCaseProvider);
      final status = await useCase(apiMobile);

      if (status.isOk && status.isSubscribed) {
        // The carrier already confirms this number is subscribed.
        // Flip the auth flags and route to the Google login.
        _mobileSession = await _session.markAlreadySubscribed(
          mobileNumber: apiMobile,
          subscriberId: status.subscriberId,
          subscriptionStatus: status.subscriptionStatus,
        );
        state = const AuthAlreadySubscribed();
        return;
      }

      // Not subscribed (or unknown). Fall through to OTP.
      state = const AuthSendingOtp();
      final sendOtp = ref.read(sendOtpUseCaseProvider);
      final otpResponse = await sendOtp(apiMobile);

      // The API has three possible outcomes for `send_otp.php`:
      //
      //   1. `success=true` with a `referenceNo`  — new user. We use
      //      that reference number to verify the OTP.
      //
      //   2. `E1351` "user already registered"   — the carrier already
      //      has this number. The server does NOT return a fresh
      //      `referenceNo`, but the `subscriberId` doubles as one for
      //      `verify_otp.php` (the API accepts it as the reference).
      //      We still proceed to the OTP screen so the user can
      //      complete their verification.
      //
      //   3. Any other error                      — surface the server
      //      message as a user-friendly snackbar.
      //
      // In **both** successful cases we persist a *pending* OTP
      // session. `isMobileLoggedIn` is NOT touched.
      if (otpResponse.isAlreadyRegistered &&
          otpResponse.subscriberId.isNotEmpty) {
        // Extract the bare number from the `tel:8801828931039` prefix
        // and use it as the reference number. The carrier's
        // `verify_otp.php` accepts this value in the `referenceNo`
        // field for already-registered users.
        final refFromSub = otpResponse.subscriberId.startsWith('tel:')
            ? otpResponse.subscriberId.substring(4)
            : otpResponse.subscriberId;
        _referenceNo = refFromSub;
        _mobileSession = await _session.savePendingOtpSession(
          mobileNumber: apiMobile,
          referenceNo: refFromSub,
          subscriberId: otpResponse.subscriberId,
          subscriptionStatus: 'ALREADY REGISTERED',
        );
        developer.log(
          'sendOtp(E1351) → using subscriberId as referenceNo=$refFromSub '
          '(pending; isMobileLoggedIn NOT set)',
          name: 'Auth',
        );
        state = const AuthOtpSent();
        return;
      }

      // Standard success path: the server gave us a fresh reference
      // number. Save it (in memory + prefs) and route to the OTP
      // screen.
      if (otpResponse.success && otpResponse.referenceNo != null) {
        _referenceNo = otpResponse.referenceNo;
        _mobileSession = await _session.savePendingOtpSession(
          mobileNumber: apiMobile,
          referenceNo: _referenceNo!,
          subscriberId: otpResponse.subscriberId,
          subscriptionStatus: 'PENDING OTP',
        );
        developer.log(
          'sendOtp(ok) → referenceNo=$_referenceNo '
          '(pending; isMobileLoggedIn NOT set)',
          name: 'Auth',
        );
        state = const AuthOtpSent();
        return;
      }

      // The server returned a structured error that we couldn't
      // recover from. Surface its message verbatim.
      state = AuthError(
        otpResponse.message.isNotEmpty
            ? otpResponse.message
            : 'Could not send OTP. Please try again.',
      );
    } catch (e) {
      state = AuthError(_friendly(e));
    }
  }

  // ─── Step 2: verify OTP ────────────────────────────────────────

  Future<void> verifyOtp(String localMobile, String otp) async {
    // In-memory reference is the source of truth, but if the user
    // hot-restarted the app between sending and verifying the OTP
    // we may have lost it. Fall back to the persisted pending
    // session in that case so they don't have to re-enter their
    // number. **Important**: a non-null `referenceNo` here is *in
    // flight*, not authenticated — we never set `isMobileLoggedIn`
    // based on it.
    var referenceNo = _referenceNo;
    if (referenceNo == null) {
      final session = _mobileSession ?? await _session.loadSession();
      referenceNo = session.referenceNo;
      if (referenceNo != null) {
        _referenceNo = referenceNo;
      }
    }

    if (referenceNo == null) {
      state = const AuthError(
        'No OTP request in progress. Please restart the login.',
      );
      return;
    }

    final validation = Validators.otp(otp);
    if (validation != null) {
      state = AuthError(validation);
      return;
    }

    final apiMobile = Validators.toApiMobile(localMobile);
    state = const AuthVerifyingOtp();

    // Debug trail — handy when the server complains. We log the
    // OTP length and a masked reference number rather than the raw
    // values, so a leaked logcat/console never exposes a usable
    // verification code.
    developer.log(
      'verifyOtp → mobile=$apiMobile otp.len=${otp.length} '
      'refNo=${_maskRef(referenceNo)}',
      name: 'Auth',
    );

    try {
      final useCase = ref.read(verifyOtpUseCaseProvider);
      final result = await useCase(
        mobileNumber: apiMobile,
        otp: otp,
        referenceNo: referenceNo,
      );

      developer.log(
        'verifyOtp ← statusCode=${result.statusCode} '
        'statusDetail=${result.statusDetail} '
        'subscriptionStatus=${result.subscriptionStatus} '
        'subscriberId=${_maskSub(result.subscriberId)} '
        'isSubscribed=${result.isSubscribed}',
        name: 'Auth',
      );

      if (!result.isOk) {
        // Wrong / expired OTP. Do NOT touch any auth flag — just
        // surface the error so the OTP screen can keep the user on
        // the OTP screen.
        state = AuthError(
          result.statusDetail.isNotEmpty
              ? result.statusDetail
              : 'Invalid OTP. Please try again.',
        );
        return;
      }

      // After OTP verification, the carrier returns an `isSubscribed`
      // flag. When true the user is fully subscribed and we flip
      // the auth flags. When false we surface a friendly error and
      // leave the auth flags alone.
      if (!result.isSubscribed) {
        developer.log(
          'verifyOtp → isSubscribed=false after OTP, blocking flow',
          name: 'Auth',
        );
        state = const AuthError(
          'Subscription is not active. Please retry the verification.',
        );
        return;
      }

      // SUCCESS — this is the **only** place in the OTP flow that
      // sets `isMobileLoggedIn = true`. Persisting auth flags here
      // means a wrong OTP cannot leave a persistent auth trace.
      _mobileSession = await _session.markMobileVerified(
        mobileNumber: apiMobile,
        subscriberId: result.subscriberId,
        subscriptionStatus: result.subscriptionStatus,
      );
      _referenceNo = null; // consumed
      state = const AuthOtpVerified();
    } catch (e) {
      state = AuthError(_friendly(e));
    }
  }

  /// Re-issues an OTP using the cached reference number. The mobile
  /// number is required because the API takes it as a field; we read
  /// it from the persisted session.
  ///
  /// Like `submitMobileNumber`, this only persists *pending* data —
  /// it never touches the auth flags.
  Future<void> resendOtp() async {
    final session = _mobileSession ?? await _session.loadSession();
    final mobile = session.mobileNumber;
    if (mobile == null) {
      state = const AuthError('Missing mobile number. Please re-enter.');
      return;
    }
    state = const AuthSendingOtp();
    try {
      final useCase = ref.read(sendOtpUseCaseProvider);
      final response = await useCase(mobile);
      if (!response.success || response.referenceNo == null) {
        state = AuthError(
          response.message.isNotEmpty
              ? response.message
              : 'Could not resend OTP. Please try again.',
        );
        return;
      }
      _referenceNo = response.referenceNo;
      await _session.saveReferenceNo(_referenceNo!);
      state = const AuthOtpSent();
    } catch (e) {
      state = AuthError(_friendly(e));
    }
  }

  // ─── Step 3: Google sign-in (only after mobile success) ────────

  /// Reuses the existing Firebase/Google implementation. We don't
  /// touch `AuthRemoteDataSource.signInWithGoogle` directly — we go
  /// through the notifier in `auth_providers.dart` so the rest of
  /// the app keeps its single source of truth for the Google user.
  ///
  /// Pre-condition: by the time the user reaches this screen the
  /// mobile-session auth flags are already `true` (either via
  /// `check_subscription.php` → `markAlreadySubscribed` or via
  /// `verify_otp.php` → `markMobileVerified`). We only persist the
  /// Google side here.
  Future<void> signInWithGoogle() async {
    state = const AuthGoogleSigningIn();
    try {
      await ref
          .read(google_auth.authNotifierProvider.notifier)
          .signInWithGoogle();
      final googleUser =
          ref.read(google_auth.authNotifierProvider).value;
      if (googleUser == null) {
        state = const AuthError('Google sign-in was cancelled.');
        return;
      }
      // Persist the Google side of the session.
      _mobileSession = await _session.saveGoogleSession(
        firebaseUid: googleUser.uid,
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );
      state = const AuthAuthenticated();
    } catch (e) {
      // Google sign-in failures — including user cancellation — come
      // back as [AuthFailure]. We surface a friendly message.
      state = AuthError(_friendly(e));
    }
  }

  // ─── Step 4: unsubscribe + logout ──────────────────────────────

  /// Calls `unsubscribe.php`, then wipes the local session, then
  /// signs out of Firebase + Google, then asks the caller to route
  /// back to the splash.
  ///
  /// The "regardless of the server response, we always clear the
  /// local session" rule is enforced here. The unsubscribe endpoint
  /// is idempotent — even when it returns "already unregistered" we
  /// still log the user out.
  Future<void> unsubscribeAndLogout() async {
    state = const AuthUnsubscribing();
    final session = _mobileSession ?? await _session.loadSession();
    final mobile = session.mobileNumber;

    if (mobile != null) {
      try {
        await ref.read(unsubscribeUseCaseProvider)(mobile);
      } catch (_) {
        // Swallow — we'll clear the local session regardless.
      }
    }

    // Best-effort Firebase + Google sign-out.
    try {
      await _google.signOut();
      await _google.disconnect();
    } catch (_) {/* ignore */}
    try {
      await _firebase.signOut();
    } catch (_) {/* ignore */}

    // Also clear the cached Google-side AuthUser so the rest of the
    // app (HomeScreen, ProfileScreen) reacts immediately.
    try {
      await ref
          .read(google_auth.authNotifierProvider.notifier)
          .signOut();
    } catch (_) {/* ignore */}

    await _session.clearSession();
    _mobileSession = null;
    _referenceNo = null;
    state = const AuthLoggedOut();
  }

  // ─── Misc ──────────────────────────────────────────────────────

  /// Re-runs `loadSession()` after logout. Used by the splash screen
  /// so it can re-route from `AuthLoggedOut` straight to Onboarding.
  Future<MobileSession> refreshSession() async {
    _mobileSession = await _session.loadSession();
    return _mobileSession!;
  }

  /// Manually resets the in-memory state to [AuthInitial]. Useful
  /// when the UI wants to clear an error banner without firing a
  /// network call.
  void reset() {
    state = const AuthInitial();
  }

  /// Drops the cached mobile-auth flags (**isMobileLoggedIn**,
  /// **isSubscribed**) without touching the Google or onboarding
  /// flags, and without contacting the carrier. Used by the splash
  /// screen when `check_subscription.php` reports the subscription
  /// is no longer active. The user is then routed to the Mobile
  /// Login screen so they can re-verify.
  ///
  /// We deliberately keep the user's `mobileNumber` and
  /// `subscriberId` in prefs so the verifier can pre-fill the field
  /// on the next login attempt.
  Future<void> clearMobileAuth() async {
    final current = _mobileSession ?? await _session.loadSession();
    final next = MobileSession(
      isMobileLoggedIn: false,
      isGoogleLoggedIn: current.isGoogleLoggedIn,
      isOnboardingCompleted: current.isOnboardingCompleted,
      isSubscribed: false,
      mobileNumber: current.mobileNumber,
      subscriberId: current.subscriberId,
      subscriptionStatus: current.subscriptionStatus,
      firebaseUid: current.firebaseUid,
      email: current.email,
      displayName: current.displayName,
      photoUrl: current.photoUrl,
      loginDate: current.loginDate,
      referenceNo: null,
    );
    await _session.saveMobileOffline(next);
    _mobileSession = await _session.loadSession();
  }

  String _friendly(Object error) {
    return ref.read(friendlyErrorMapperProvider).map(error);
  }

  /// Mask a carrier `referenceNo` for logging. The full value is
  /// only ever needed by `verify_otp.php` over HTTPS — leaking it to
  /// logs would let a developer with logcat access replay the
  /// verification step. We keep the first two and last two chars.
  static String _maskRef(String ref) {
    if (ref.length <= 6) return '•••';
    return '${ref.substring(0, 2)}•••${ref.substring(ref.length - 2)}';
  }

  /// Mask a `subscriberId` (which is itself a `tel:880XXXXXXXXX`
  /// string) for logging. Logs frequently capture build numbers and
  /// error tags, so it's worth keeping the carrier prefix out of
  /// them too.
  static String _maskSub(String sub) {
    if (sub.isEmpty) return '';
    if (sub.length <= 6) return '•••';
    return '${sub.substring(0, 4)}•••${sub.substring(sub.length - 3)}';
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Public alias used by other modules (e.g. the splash, profile, and
/// the OTP screen) so we don't collide with the existing Google-auth
/// `authNotifierProvider` exported from
/// `package:notely/features/authentication/presentation/providers/auth_providers.dart`.
final subscriptionAuthNotifierProvider = authNotifierProvider;