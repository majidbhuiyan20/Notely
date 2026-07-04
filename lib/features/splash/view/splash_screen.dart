import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/route/app_route.dart';
import '../../authentication/presentation/providers/auth_providers.dart';

/// Brand splash. Waits for the bootstrap state (cached auth user +
/// onboarding completion flag) to load, then routes to the right
/// destination:
///
/// * Authenticated user             → Main
/// * New user (no onboarding yet)   → Onboarding
/// * Returning, not signed in user  → Login
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  ProviderSubscription<AsyncValue<BootState>>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sub = ref.listenManual<AsyncValue<BootState>>(
        bootStateProvider,
        (prev, next) {
          if (!mounted) return;
          // Wait until the future resolves successfully; loading/error
          // states are handled by the global error widget for now.
          if (!next.hasValue) return;
          _sub?.close();
          _route(next.requireValue);
        },
        fireImmediately: true,
      );
    });
  }

  void _route(BootState boot) {
    if (boot.isAuthenticated) {
      Navigator.pushReplacementNamed(context, Routes.mainRoute);
    } else if (!boot.onboardingComplete) {
      Navigator.pushReplacementNamed(context, Routes.onboardingRoute);
    } else {
      Navigator.pushReplacementNamed(context, Routes.loginRoute);
    }
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 250,
          height: 250,
        ),
      ),
    );
  }
}