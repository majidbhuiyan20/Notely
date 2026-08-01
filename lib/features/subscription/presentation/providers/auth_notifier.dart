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
///   1. `checkSubscription(mobile)` — if `isSubscribed`, skip OTP.
///   2. `sendOtp(mobile)`           — only if step 1 returned false.
///   3. `verifyOtp(mobile, otp, refNo)` — confirm OTP, store session.
///   4. `signInWithGoogle()`        — Firebase/Google; store session.
///   5. `unsubscribeAndLogout()`    — wipes everything.
///
/// All persistence flows through [SessionManager]. All API calls
/// flow through the use-case providers. The notifier itself never
/// touches Dio, Firebase, or SharedPreferences directly — that's the
/// whole point of Clean Architecture.
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
  /// returns a suggested initial state — UI then navigates.
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
        // Persist mobile-side session now — the user has proven they
        // own the number, and we want to keep the subscriberId around
        // for the Google step and the Profile screen.
        _mobileSession = await _session.saveMobileSession(
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
        _mobileSession = await _session.saveMobileSession(
          mobileNumber: apiMobile,
          subscriberId: otpResponse.subscriberId,
          subscriptionStatus: 'ALREADY REGISTERED',
          referenceNo: refFromSub,
        );
        developer.log(
          'sendOtp(E1351) → using subscriberId as referenceNo=$refFromSub',
          name: 'Auth',
        );
        // Still navigate to the OTP screen so the user can verify.
        state = const AuthOtpSent();
        return;
      }

      // Standard success path: the server gave us a fresh reference
      // number. Save it (in memory + prefs) and route to the OTP
      // screen.
      if (otpResponse.success && otpResponse.referenceNo != null) {
        _referenceNo = otpResponse.referenceNo;
        // Persist the full mobile-session atomically: the reference
        // number, the mobile, and the subscriberId all together. This
        // avoids the "wipe referenceNo" race that would happen if we
        // called `saveReferenceNo` followed by `saveMobileSession`
        // (the latter would overwrite `referenceNo: null`).
        _mobileSession = await _session.saveMobileSession(
          mobileNumber: apiMobile,
          subscriberId: otpResponse.subscriberId,
          subscriptionStatus: 'PENDING OTP',
          referenceNo: _referenceNo,
        );
        developer.log(
          'sendOtp(ok) → referenceNo=$_referenceNo',
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
    // we may have lost it. Fall back to the persisted session in
    // that case so they don't have to re-enter their number.
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

    // Debug trail — handy when the server complains. The fields
    // here are exactly the ones the API expects in the request body.
    developer.log(
      'verifyOtp → mobile=$apiMobile otp=$otp refNo=$referenceNo',
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
        'subscriberId=${result.subscriberId}',
        name: 'Auth',
      );

      if (!result.isOk) {
        state = AuthError(
          result.statusDetail.isNotEmpty
              ? result.statusDetail
              : 'Invalid OTP. Please try again.',
        );
        return;
      }

      _mobileSession = await _session.saveMobileSession(
        mobileNumber: apiMobile,
        subscriberId: result.subscriberId,
        subscriptionStatus: result.subscriptionStatus,
        referenceNo: referenceNo,
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

  String _friendly(Object error) {
    return ref.read(friendlyErrorMapperProvider).map(error);
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Public alias used by other modules (e.g. the splash, profile, and
/// the OTP screen) so we don't collide with the existing Google-auth
/// `authNotifierProvider` exported from
/// `package:notely/features/authentication/presentation/providers/auth_providers.dart`.
final subscriptionAuthNotifierProvider = authNotifierProvider;
