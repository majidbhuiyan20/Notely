import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/route/app_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../subscription/domain/entities/mobile_session.dart';
import '../../subscription/presentation/providers/auth_notifier.dart';
import '../../subscription/presentation/providers/subscription_providers.dart';

/// Brand splash. Waits for the persisted mobile-then-google
/// session to load, then routes to the right destination.
///
/// ## Routing invariants
/// Routing is driven **exclusively** by persisted auth flags —
/// never by in-flight data:
///
/// * `isMobileLoggedIn` + `isGoogleLoggedIn` → Main
/// * `isMobileLoggedIn` + `isSubscribed` + !`isGoogleLoggedIn` →
///   Google Login (skip OTP — the user already verified mobile)
/// * `isOnboardingCompleted` + no mobile login → Mobile Login
/// * Otherwise → Onboarding
///
/// The splash **must not** route to the Google Login screen based on
/// non-auth fields like `referenceNo` (a stale in-flight OTP) or
/// `mobileNumber` (typed in but never verified). Only auth flags
/// persisted by `SessionManager.markMobileVerified` /
/// `markAlreadySubscribed` count.
///
/// ## Subscription re-validation
/// The carrier can deactivate a subscription at any time (user
/// cancels via USSD, billing failure, etc.). When the splash starts
/// and we already have a mobile-validated session, we re-run
/// `check_subscription.php` against the carrier. If the carrier
/// reports the subscription is no longer active we clear the
/// `isMobileLoggedIn` flag and route to the Mobile Login screen —
/// without this check, a long-time user whose subscription silently
/// expired would land on the Google Login screen with an invalid
/// backend state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _boot();
    });
  }

  Future<void> _boot() async {
    // Touch the new auth notifier so it loads the persisted mobile
    // session into memory before the splash decides where to route.
    final MobileSession session = await ref
        .read(subscriptionAuthNotifierProvider.notifier)
        .loadSession();

    if (!mounted) return;

    // If the persisted session claims a mobile-verified user, ask
    // the carrier to confirm the subscription is still active
    // before we trust the cached flag. This is the only place in
    // the app where we re-validate on every cold start.
    if (session.isMobileLoggedIn && session.mobileNumber != null) {
      await _revalidateSubscription(session);
      if (!mounted) return;
    }

    _route(session);
  }

  /// Re-runs `check_subscription.php`. If the carrier says the user
  /// is no longer subscribed, we drop the auth flags so the splash
  /// routes to the Mobile Login screen instead of the Google Login
  /// screen. We collect and ignore any errors — if the network is
  /// down at startup we fall back to the cached flags rather than
  /// locking the user out.
  Future<void> _revalidateSubscription(MobileSession session) async {
    final notifier = ref.read(subscriptionAuthNotifierProvider.notifier);
    final useCase = ref.read(checkSubscriptionUseCaseProvider);
    try {
      final status = await useCase(session.mobileNumber!);
      if (!status.isOk || !status.isSubscribed) {
        // Subscription no longer active — clear the cached auth
        // flags so the splash routes to Mobile Login.
        await notifier.clearMobileAuth();
      }
    } catch (_) {
      // Network error during cold start — keep the cached session
      // so the user isn't locked out of a working app.
    }
  }

  void _route(MobileSession originalSession) {
    if (_navigated || !mounted) return;
    _navigated = true;

    // After re-validation the session in the notifier may have been
    // cleared. Re-read it so we route based on the up-to-date flags.
    final session = ref
            .read(subscriptionAuthNotifierProvider.notifier)
            .currentSession ??
        originalSession;

    // 1. Fully authenticated → Home.
    if (session.isMobileLoggedIn && session.isGoogleLoggedIn) {
      Navigator.pushReplacementNamed(context, Routes.mainRoute);
      return;
    }

    // 2. Mobile verified & subscribed but Google not yet done →
    //    Google Login (skip OTP entirely).
    if (session.isMobileLoggedIn && session.isSubscribed) {
      Navigator.pushReplacementNamed(context, Routes.googleLoginRoute);
      return;
    }

    // 3. Onboarding complete but mobile not verified → Mobile Login.
    if (session.isOnboardingCompleted) {
      Navigator.pushReplacementNamed(context, Routes.mobileLoginRoute);
      return;
    }

    // 4. First launch → Onboarding.
    Navigator.pushReplacementNamed(context, Routes.onboardingRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kHeroGradient),
        child: const Center(
          child: _SplashHero(),
        ),
      ),
    );
  }
}

class _SplashHero extends StatefulWidget {
  const _SplashHero();

  @override
  State<_SplashHero> createState() => _SplashHeroState();
}

class _SplashHeroState extends State<_SplashHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _scale = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
    );
    _opacity = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 124,
              height: 124,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Notely',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your space to think',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}