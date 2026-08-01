import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/route/app_route.dart';
import '../../../widgets/app_snackbar.dart';
import '../../core/subscription_constants.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';

/// 6-digit OTP screen. Material 3, premium feel.
///
/// Built on top of the `pinput` package — it gives us auto-advance,
/// backspace handling, paste-from-SMS, focus animation, and a
/// configurable per-field theme for free.
///
/// UX:
///   * 6 pinput fields with animated focus state
///   * 60-second resend countdown
///   * "Verify & continue" CTA — gradient pill, with spinner during verify
///   * error snackbar on failure (with auto-reset to idle)
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.mobileNumber});

  /// Local mobile number (`017...`). We re-display it to the user
  /// and pass it back to the notifier on verify.
  final String mobileNumber;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  Timer? _timer;
  int _secondsLeft = 60;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 0) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  /// Called by pinput on every keystroke. Auto-submits once the user
  /// has entered all 6 digits.
  void _onOtpChanged(String value) {
    if (value.length == SubscriptionConstants.otpLength) {
      _onVerify(value);
    }
  }

  Future<void> _onVerify(String otp) async {
    if (otp.length != SubscriptionConstants.otpLength) {
      AppSnackbar.error(context, 'Please enter the full 6-digit code.');
      return;
    }
    HapticFeedback.selectionClick();
    // Use the route arg first, but fall back to the cached session
    // mobile number so verify still works after a hot restart.
    final session =
        ref.read(subscriptionAuthNotifierProvider.notifier).currentSession;
    final localMobile = widget.mobileNumber.isNotEmpty
        ? widget.mobileNumber
        : (session?.mobileNumber ?? '');
    await ref
        .read(authNotifierProvider.notifier)
        .verifyOtp(localMobile, otp);
  }

  Future<void> _onResend() async {
    if (_secondsLeft > 0) return;
    HapticFeedback.lightImpact();
    await ref.read(authNotifierProvider.notifier).resendOtp();
    _startTimer();
  }

  void _onStateChange(AuthState next) {
    if (_navigated || !mounted) return;
    if (next is AuthOtpVerified) {
      _navigated = true;
      Navigator.pushReplacementNamed(context, Routes.googleLoginRoute);
    } else if (next is AuthError) {
      AppSnackbar.error(context, next.errorMessage);
      ref.read(authNotifierProvider.notifier).reset();
      // Wipe whatever the user typed so they can try again, and
      // re-focus the first field.
      _pinController.clear();
      _pinFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (prev, next) => _onStateChange(next));

    final state = ref.watch(authNotifierProvider);
    final isVerifying = state.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Prefer the route argument; fall back to the cached session
    // mobile number so the "code sent to ..." footer is always
    // populated even after a hot restart.
    final session =
        ref.read(subscriptionAuthNotifierProvider.notifier).currentSession;
    final mobileForMask =
        widget.mobileNumber.isNotEmpty ? widget.mobileNumber : (session?.mobileNumber ?? '');
    final masked = _mask(mobileForMask);

    return Scaffold(
      body: Stack(
        children: [
          const _OtpBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 36,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BackButton(onTap: () => Navigator.pop(context)),
                        const SizedBox(height: 24),
                        const _OtpHeader(),
                        const SizedBox(height: 28),
                        Pinput(
                          controller: _pinController,
                          focusNode: _pinFocusNode,
                          length: SubscriptionConstants.otpLength,
                          enabled: !isVerifying,
                          autofocus: true,
                          obscureText: false,
                          showCursor: true,
                          // Visual cursor — small brand-coloured
                          // rectangle. Pinput gives us a Widget slot
                          // here, not a `Cursor` object.
                          cursor: Container(
                            width: 1.4,
                            height: 26,
                            color: AppColors.brandPrimary,
                          ),
                          // PinPut uses an onCompleted handler for the
                          // "all 6 entered" event, but we also wire
                          // onChanged so the OTP starts verifying
                          // immediately on the 6th keystroke.
                          onChanged: _onOtpChanged,
                          onCompleted: _onVerify,
                          defaultPinTheme: _pinTheme(
                            isDark: isDark,
                            focused: false,
                          ),
                          focusedPinTheme: _pinTheme(
                            isDark: isDark,
                            focused: true,
                          ),
                          submittedPinTheme: _pinTheme(
                            isDark: isDark,
                            focused: true,
                          ),
                          // 8px gap between every field. The builder
                          // is invoked once per gap with the index
                          // — we just return a fixed `SizedBox`.
                          separatorBuilder: (index) => const SizedBox(width: 8),
                          hapticFeedbackType: HapticFeedbackType.lightImpact,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          pinputAutovalidateMode:
                              PinputAutovalidateMode.onSubmit,
                        ),
                        const SizedBox(height: 20),
                        _ResendRow(
                          secondsLeft: _secondsLeft,
                          onResend: _onResend,
                        ),
                        const SizedBox(height: 28),
                        _VerifyButton(
                          isLoading: isVerifying,
                          onPressed: () => _onVerify(_pinController.text),
                          otp: _pinController.text,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Code sent to $masked',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  // ─── PinPut theme ─────────────────────────────────────────────

  /// Builds a `PinTheme` for the OTP input. The `focused` parameter
  /// controls whether we render the "active" look (brighter border,
  /// brand-coloured shadow).
  PinTheme _pinTheme({required bool isDark, required bool focused}) {
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white;
    return PinTheme(
      width: 52,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? AppColors.brandPrimary : AppColors.divider,
          width: focused ? 1.6 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
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

// ─── Back button ──────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.white.withValues(alpha: 0.8),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────

class _OtpHeader extends StatelessWidget {
  const _OtpHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.sms_rounded,
            size: 38,
            color: AppColors.brandPrimary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Verify your number',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Enter the 6-digit code we just sent to your mobile number.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
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

// ─── Resend row ───────────────────────────────────────────────────

class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.secondsLeft, required this.onResend});

  final int secondsLeft;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final canResend = secondsLeft <= 0;
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: canResend
            ? TextButton.icon(
                key: const ValueKey('resend'),
                onPressed: onResend,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Resend code',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              )
            : Row(
                key: ValueKey(secondsLeft),
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Resend code in 0:${secondsLeft.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Verify button ────────────────────────────────────────────────

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({
    required this.isLoading,
    required this.onPressed,
    required this.otp,
  });

  final bool isLoading;
  final VoidCallback onPressed;
  final String otp;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && otp.length == SubscriptionConstants.otpLength;
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
          onTap: enabled ? onPressed : null,
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
                  : const Text(
                      'Verify & continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Backdrop ─────────────────────────────────────────────────────

class _OtpBackdrop extends StatelessWidget {
  const _OtpBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: isDark ? const Color(0xFF0B0D1F) : const Color(0xFFF6F8FF)),
        Positioned(
          top: -100,
          right: -80,
          child: _Blob(
            size: 260,
            color: AppColors.brandSecondary.withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: _Blob(
            size: 280,
            color: AppColors.brandPrimary.withValues(alpha: 0.14),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
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
