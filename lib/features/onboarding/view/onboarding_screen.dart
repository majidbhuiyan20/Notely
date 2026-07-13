import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/route/app_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../authentication/presentation/providers/auth_providers.dart';

/// First screen a new user sees after the splash. Premium onboarding —
/// gradient backdrop, soft shadows, animated gradient button.
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF6F7FB),
              Color(0xFFEDE9FE),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: AppElevation.cardShadow,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/onboarding_one.png',
                    fit: BoxFit.contain,
                    height: 240,
                  ),
                ),
                const SizedBox(height: 36),
                ShaderMask(
                  shaderCallback: (rect) =>
                      kHeroGradient.createShader(rect),
                  child: const Text(
                    "Notely",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your premium space for ideas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Write, organise and store every thought with beautiful attachments, '
                  'smart categories and offline-first sync.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                ValueListenableBuilder<bool>(
                  valueListenable: _busy,
                  builder: (context, busy, _) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.brandGradient,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        boxShadow: AppElevation.brandGlow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          onTap: busy ? null : _onGetStarted,
                          child: SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: Center(
                              child: busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'GET STARTED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                            ),
                          ),
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
      ),
    );
  }
}
