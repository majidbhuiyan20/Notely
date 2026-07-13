import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/route/app_route.dart';
import '../../../widgets/app_snackbar.dart';
import '../../domain/entities/auth_user.dart';
import '../providers/auth_providers.dart';

/// Sign-in screen. Shows the Notely brand mark (loaded from the
/// `assets/images/` folder), a premium gradient backdrop and a single,
/// large Google Sign-In CTA. After a successful sign-in we
/// push the main app and pop the back-stack so the user can't return to
/// the login screen with the system back gesture.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// `true` once we've pushed the Main screen. Used to suppress any
  /// late-arriving auth-state updates from re-triggering navigation or
  /// showing duplicate snackbars while the route transition is in
  /// flight.
  bool _navigated = false;

  /// `true` while a Google sign-in tap is being processed. Used to
  /// suppress error snackbars from incidental `AsyncNotifier` rebuilds
  /// (e.g. `build()` re-running because a dependency was invalidated).
  /// The user only sees an error snackbar if an error fires *during*
  /// the active sign-in window.
  bool _signInInFlight = false;

  @override
  Widget build(BuildContext context) {
    // Watched solely to trigger rebuilds when auth state changes; the
    // actual state is consumed via [ref.listen] below.
    ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      if (_navigated) return;

      // Track whether a sign-in attempt is currently in flight so we
      // only show an error snackbar when the failure is actually caused
      // by the user's tap. Otherwise, an AsyncNotifier rebuild could
      // produce a transient `error` state that has nothing to do with
      // the user's sign-in flow (e.g. plugins not yet initialised).
      final wasLoading = previous?.isLoading ?? false;
      final isLoading = next.isLoading;
      final hasError = next.hasError;
      if (isLoading && !wasLoading) {
        _signInInFlight = true;
      } else if (!isLoading && wasLoading) {
        // Sign-in attempt just finished — handle the result below.
      } else if (!isLoading && !hasError) {
        // Steady-state, not loading. Reset the in-flight flag.
        _signInInFlight = false;
      }

      next.whenOrNull(
        data: (user) {
          if (user == null) return;
          _navigated = true;
          AppSnackbar.success(context, 'Signed in as ${user.firstName}');
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.mainRoute,
            (_) => false,
          );
        },
        error: (err, _) {
          // Only surface sign-in errors. A stray `error` state from the
          // notifier's `build()` (e.g. shared_preferences not ready yet
          // at cold start) shouldn't show "could not sign in" — it has
          // nothing to do with the user's action.
          if (!_signInInFlight) return;
          _signInInFlight = false;
          AppSnackbar.error(context, _friendlyAuthError(err));
        },
      );
    });

    return Scaffold(
      body: Stack(
        children: const [
          _Backdrop(),
          SafeArea(child: _LoginBody()),
        ],
      ),
    );
  }
}

/// Big soft gradient blobs in the background — gives the screen a
/// premium, editorial feel without any extra assets.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFF6F8FF)),
        Positioned(
          top: -120,
          left: -80,
          child: _Blob(
            size: 280,
            color: AppColors.royalBlue.withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          top: 60,
          right: -100,
          child: _Blob(
            size: 220,
            color: const Color(0xFF7B91FF).withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -60,
          child: _Blob(
            size: 320,
            color: AppColors.royalBlue.withValues(alpha: 0.14),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _LoginBody extends ConsumerWidget {
  const _LoginBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          const _BrandHeader(),
          const Spacer(flex: 3),
          _PrimaryGoogleButton(
            isLoading: isLoading,
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signInWithGoogle(),
          ),
          const SizedBox(height: 14),
          const _LegalFooter(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// The big rounded app-logo card at the top of the screen. We load the
/// real `assets/images/logo.png` and frame it on a soft white surface
/// with a subtle shadow + gradient so it feels like a real product.
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 132,
          height: 132,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: AppColors.royalBlue.withValues(alpha: 0.18),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Welcome to Notely',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B1F3A),
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "The safest place to write, organise and store all your notes — "
            "synced across your devices, always within reach.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Premium pill-shaped Google button. Matches the Google brand
/// guideline (white background, dark text, G glyph in the correct blue)
/// but with extra rounding + shadow to read as "premium".
class _PrimaryGoogleButton extends StatelessWidget {
  const _PrimaryGoogleButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1B1F3A),
          elevation: 0,
          shadowColor: AppColors.royalBlue.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.royalBlue,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleGlyph(),
                  const SizedBox(width: 14),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Multi-coloured "G" — proper Google brand colors. We draw it from
/// scratch (a white circle + a coloured text glyph + a coloured quarter
/// arc) so we don't need any extra assets.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blue quarter (top-right). Real Google brand has 4 colours
          // blended, but a stylised stack reads cleanly at this size.
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4285F4),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF34A853),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFBBC05),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEA4335),
              ),
            ),
          ),
          const Text(
            'G',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    return Text(
      'By continuing you agree to our Terms & Privacy Policy.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Returns a user-friendly error string for the snackbar. We unwrap our
/// own [AuthFailure] (whose message is already user-friendly) and fall
/// back to a generic message for anything else.
String _friendlyAuthError(Object err) {
  if (err is AuthFailure) return err.message;
  return 'Could not sign you in. Please try again in a moment.';
}