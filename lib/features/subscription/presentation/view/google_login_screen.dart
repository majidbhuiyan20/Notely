import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/route/app_route.dart';
import '../../../widgets/app_snackbar.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

/// Wraps the existing Firebase/Google Sign-In flow with mobile-flow
/// glue. We don't change how Google Sign-In itself works — the only
/// new thing this screen does is route the user to Home on success
/// and surface any mobile-session errors that bubble up.
class GoogleLoginScreen extends ConsumerStatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  ConsumerState<GoogleLoginScreen> createState() =>
      _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends ConsumerState<GoogleLoginScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // If we already have a saved Google user (returning user), bounce
    // them straight to Home without another tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(authNotifierProvider.notifier).currentSession;
      if (session?.isGoogleLoggedIn == true && !_navigated) {
        _navigated = true;
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.mainRoute,
          (_) => false,
        );
      }
    });
  }

  void _onStateChange(AuthState next) {
    if (_navigated || !mounted) return;
    if (next is AuthAuthenticated) {
      _navigated = true;
      AppSnackbar.success(context, 'You\'re all set. Welcome back!');
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.mainRoute,
        (_) => false,
      );
    } else if (next is AuthError) {
      AppSnackbar.error(context, next.errorMessage);
      ref.read(authNotifierProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (prev, next) => _onStateChange(next));

    final state = ref.watch(authNotifierProvider);
    final isSigningIn = state.isLoading;
    final session = ref.watch(authNotifierProvider.notifier).currentSession;
    final masked = session?.mobileNumber != null
        ? _mask(session!.mobileNumber!)
        : null;

    return Scaffold(
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          const _BrandHeader(),
                          const Spacer(flex: 1),
                          if (masked != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppElevation.cardShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.success
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.success,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Mobile verified',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          '+880$masked',
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          _PrimaryGoogleButton(
                            isLoading: isSigningIn,
                            onPressed: () => ref
                                .read(authNotifierProvider.notifier)
                                .signInWithGoogle(),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: isSigningIn
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                      context,
                                      Routes.mobileLoginRoute,
                                    );
                                  },
                            child: const Text('Use a different number'),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'By continuing you agree to our Terms & Privacy Policy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _mask(String local) {
    if (local.length < 5) return local;
    final start = local.substring(0, 3);
    final end = local.substring(local.length - 2);
    return '$start••••$end';
  }
}

// ─── Brand header ─────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 116,
          height: 116,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withValues(alpha: 0.18),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 12),
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
        const SizedBox(height: 22),
        const Text(
          'One last step',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Link your Notely account with Google to sync your notes '
            'across all your devices.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: AppColors.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Google button ────────────────────────────────────────────────

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
          shadowColor: AppColors.brandPrimary.withValues(alpha: 0.35),
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
                    AppColors.brandPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _GoogleGlyph(),
                  SizedBox(width: 14),
                  Text(
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

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: isDark ? const Color(0xFF0B0D1F) : const Color(0xFFF6F8FF)),
        Positioned(
          top: -120,
          left: -80,
          child: _Blob(
            size: 280,
            color: AppColors.brandPrimary.withValues(alpha: 0.18),
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
            color: AppColors.brandPrimary.withValues(alpha: 0.14),
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
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
