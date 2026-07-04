import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/route/app_route.dart';
import '../../../widgets/app_snackbar.dart';
import '../providers/auth_providers.dart';

/// First screen an unauthenticated user sees. Offers Google Sign-In and,
/// after a successful sign-in, transitions to the main app with a green
/// "Signed in" snackbar.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user == null) return;
          // Show a green success snackbar, then push the main app and
          // wipe the back-stack so the user can't pop back into Login.
          AppSnackbar.success(
            context,
            'Signed in as ${user.firstName}',
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.mainRoute,
            (_) => false,
          );
        },
        error: (err, _) {
          AppSnackbar.error(context, err.toString());
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Center(child: _BrandMark()),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Notely',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1E1E),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "The world's safest place to write and store all your notes.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              _GoogleSignInButton(
                isLoading: isLoading,
                onPressed: () => ref
                    .read(authNotifierProvider.notifier)
                    .signInWithGoogle(),
              ),
              const SizedBox(height: 12),
              Text(
                'By continuing you agree to our Terms & Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.royalBlue, Color(0xFF7B91FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withOpacity(0.35),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.note_alt_rounded,
        color: Colors.white,
        size: 48,
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.isLoading, required this.onPressed});
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF1F3F4),
          foregroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}