import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/route/app_route.dart';
import '../../../widgets/app_snackbar.dart';
import '../../core/subscription_constants.dart';
import '../../core/validators.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

/// First mobile-auth screen. Material 3, light/dark, premium feel.
///
/// UX:
///   * app logo
///   * welcome text
///   * country code (+880) + 11-digit input
///   * "Continue" CTA (gradient, with spinner when busy)
///   * live inline validation
///   * error snackbar for API failures
class MobileLoginScreen extends ConsumerStatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  ConsumerState<MobileLoginScreen> createState() =>
      _MobileLoginScreenState();
}

class _MobileLoginScreenState extends ConsumerState<MobileLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_navigated) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    HapticFeedback.selectionClick();
    await ref
        .read(authNotifierProvider.notifier)
        .submitMobileNumber(_controller.text.trim());
  }

  void _onStateChange(AuthState next) {
    if (_navigated || !mounted) return;
    next.when(
      initial: () {},
      loading: () {},
      checkingSubscription: () {},
      alreadySubscribed: () {
        _navigated = true;
        Navigator.pushNamed(context, Routes.googleLoginRoute);
      },
      sendingOtp: () {},
      otpSent: () {
        _navigated = true;
        Navigator.pushNamed(
          context,
          Routes.otpRoute,
          arguments: _controller.text.trim(),
        );
      },
      verifyingOtp: () {},
      otpVerified: () {
        _navigated = true;
        Navigator.pushNamed(context, Routes.googleLoginRoute);
      },
      googleSigningIn: () {},
      authenticated: () {},
      unsubscribing: () {},
      loggedOut: () {},
      error: (msg) {
        AppSnackbar.error(context, msg);
        ref.read(authNotifierProvider.notifier).reset();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (prev, next) => _onStateChange(next));

    final state = ref.watch(authNotifierProvider);
    final isBusy = state.isLoading;

    return Scaffold(
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical -
                      48,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 1),
                        const _BrandHeader(),
                        const Spacer(flex: 2),
                        _MobileInputField(
                          controller: _controller,
                          focusNode: _focusNode,
                          enabled: !isBusy,
                          onSubmit: _onContinue,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _ContinueButton(
                          isLoading: isBusy,
                          onPressed: _onContinue,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const _LegalFooter(),
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Backdrop ─────────────────────────────────────────────────────

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
            color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.35 : 0.18),
          ),
        ),
        Positioned(
          top: 80,
          right: -100,
          child: _Blob(
            size: 220,
            color: AppColors.brandSecondary.withValues(alpha: isDark ? 0.32 : 0.22),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -60,
          child: _Blob(
            size: 320,
            color: AppColors.brandPrimary.withValues(alpha: isDark ? 0.25 : 0.14),
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
          padding: const EdgeInsets.all(16),
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
        const SizedBox(height: 24),
        const Text(
          'Sign in to Notely',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Enter your Airtel or Robi number to continue. '
            'We\'ll verify your subscription before linking your account.',
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

// ─── Mobile input ─────────────────────────────────────────────────

class _MobileInputField extends StatelessWidget {
  const _MobileInputField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      maxLength: SubscriptionConstants.mobileLength,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.6,
      ),
      onFieldSubmitted: (_) => onSubmit(),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(
          SubscriptionConstants.mobileLength,
        ),
      ],
      decoration: InputDecoration(
        counterText: '',
        hintText: '1XXXXXXXXX',
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🇧🇩',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  SubscriptionConstants.countryCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.brandPrimary,
            width: 1.6,
          ),
        ),
      ),
      validator: Validators.mobileNumber,
    );
  }
}

// ─── Continue button ──────────────────────────────────────────────

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradient,
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppElevation.brandGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: isLoading ? null : onPressed,
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Legal footer ─────────────────────────────────────────────────

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    return Text(
      'By continuing you agree to our Terms & Privacy Policy. '
      'Carrier charges may apply.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }
}

// ─── `when` helper ────────────────────────────────────────────────

extension on AuthState {
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function() checkingSubscription,
    required R Function() alreadySubscribed,
    required R Function() sendingOtp,
    required R Function() otpSent,
    required R Function() verifyingOtp,
    required R Function() otpVerified,
    required R Function() googleSigningIn,
    required R Function() authenticated,
    required R Function() unsubscribing,
    required R Function() loggedOut,
    required R Function(String message) error,
  }) {
    return switch (this) {
      AuthInitial() => initial(),
      AuthLoading() => loading(),
      AuthCheckingSubscription() => checkingSubscription(),
      AuthAlreadySubscribed() => alreadySubscribed(),
      AuthSendingOtp() => sendingOtp(),
      AuthOtpSent() => otpSent(),
      AuthVerifyingOtp() => verifyingOtp(),
      AuthOtpVerified() => otpVerified(),
      AuthGoogleSigningIn() => googleSigningIn(),
      AuthAuthenticated() => authenticated(),
      AuthUnsubscribing() => unsubscribing(),
      AuthLoggedOut() => loggedOut(),
      AuthError(:final errorMessage) => error(errorMessage),
    };
  }
}
