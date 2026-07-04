import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/route/app_route.dart';
import '../../authentication/presentation/providers/auth_providers.dart';

/// First screen a new user sees after the splash. Once they tap "Get
/// Started" we mark onboarding as completed (so it won't show again) and
/// navigate to the Login screen.
///
/// [_busy] is a local UI-only flag (spinner vs button label) — we keep
/// it in a [ValueNotifier] rather than calling `setState` so toggling
/// it doesn't trigger a full widget rebuild and can't race with parent
/// rebuilds.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final ValueNotifier<bool> _busy = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _busy.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    if (_busy.value) return;
    _busy.value = true;
    try {
      await ref.read(authRepositoryProvider).markOnboardingComplete();
      if (!mounted) return;
      // Drop the splash + onboarding from the back-stack so the user
      // can't pop back into them.
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.loginRoute,
        (route) => route.isFirst,
      );
    } finally {
      if (mounted) _busy.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/onboarding_one.png',
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 48),
              const Text(
                'World’s Safest And Largest Digital Notebook',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Notely is the world’s safest and largest digital notebook, providing you with a space to write and store all your notes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              ValueListenableBuilder<bool>(
                valueListenable: _busy,
                builder: (context, busy, _) {
                  return ElevatedButton(
                    onPressed: busy ? null : _onGetStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD9E9FF),
                      foregroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text(
                            'GET STARTED',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}