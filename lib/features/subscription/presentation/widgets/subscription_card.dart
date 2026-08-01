import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/mobile_session.dart';

/// Profile-screen card that shows the mobile-subscription info and a
/// single "Unsubscribe & Logout" CTA.
///
/// The card itself is **stateless** — it gets a [MobileSession] from
/// the parent and renders accordingly. The parent owns the loading
/// state and the confirmation dialog.
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    super.key,
    required this.session,
    required this.onUnsubscribe,
    this.isBusy = false,
  });

  final MobileSession session;
  final Future<void> Function() onUnsubscribe;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final mobile = session.mobileNumber;
    final subscriberId = session.subscriberId;
    final subStatus = session.subscriptionStatus;
    final email = session.email;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.cardShadow,
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.brandGradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sim_card_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'Subscription',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (subStatus != null && subStatus.isNotEmpty)
                _StatusPill(status: subStatus),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.phone_iphone_rounded,
            label: 'Mobile Number',
            value: mobile != null
                ? '+${mobile.startsWith('880') ? mobile : '880$mobile'}'
                : '—',
          ),
          if (subscriberId != null && subscriberId.isNotEmpty)
            _DetailRow(
              icon: Icons.fingerprint_rounded,
              label: 'Subscriber ID',
              value: subscriberId,
              monospaced: true,
            ),
          if (email != null && email.isNotEmpty)
            _DetailRow(
              icon: Icons.alternate_email_rounded,
              label: 'Google Email',
              value: email,
            ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.divider,
                  AppColors.divider.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _UnsubscribeButton(isBusy: isBusy, onPressed: onUnsubscribe),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospaced = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool monospaced;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: monospaced ? 'monospace' : null,
                    letterSpacing: monospaced ? 0.2 : -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final isActive = lower.contains('active') || lower.contains('subscribed');
    final isPending =
        lower.contains('pending') || lower.contains('charging');
    final color = isActive
        ? AppColors.success
        : isPending
            ? AppColors.warning
            : AppColors.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _UnsubscribeButton extends StatelessWidget {
  const _UnsubscribeButton({required this.isBusy, required this.onPressed});

  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isBusy ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isBusy
                    ? const SizedBox(
                        key: ValueKey('spinner'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.error,
                          ),
                        ),
                      )
                    : const Icon(
                        key: ValueKey('icon'),
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  isBusy ? 'Unsubscribing…' : 'Unsubscribe & Logout',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Icon(
                isBusy
                    ? Icons.hourglass_top_rounded
                    : Icons.chevron_right_rounded,
                color: AppColors.error.withValues(alpha: 0.6),
                size: isBusy ? 16 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
