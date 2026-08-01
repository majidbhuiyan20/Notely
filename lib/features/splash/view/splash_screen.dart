import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/route/app_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../subscription/domain/entities/mobile_session.dart';
import '../../subscription/presentation/providers/auth_notifier.dart';

/// Brand splash. Waits for the mobile-then-google session to load, then
/// routes to the right destination:
///
/// * isMobileLoggedIn && isGoogleLoggedIn → Main
/// * isMobileLoggedIn && !isGoogleLoggedIn → Google Login
/// * !isMobileLoggedIn && isOnboardingCompleted → Mobile Login
/// * !isOnboardingCompleted → Onboarding
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
    _route(session);
  }

  void _route(MobileSession session) {
    if (_navigated || !mounted) return;
    _navigated = true;

    if (session.isMobileLoggedIn && session.isGoogleLoggedIn) {
      Navigator.pushReplacementNamed(context, Routes.mainRoute);
    } else if (session.isMobileLoggedIn) {
      Navigator.pushReplacementNamed(context, Routes.googleLoginRoute);
    } else if (session.isOnboardingCompleted) {
      Navigator.pushReplacementNamed(context, Routes.mobileLoginRoute);
    } else {
      Navigator.pushReplacementNamed(context, Routes.onboardingRoute);
    }
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
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 56,
                  color: Colors.white,
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
