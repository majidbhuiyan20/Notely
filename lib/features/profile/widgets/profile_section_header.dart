import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Premium section header used by the profile screen. Shows an
/// uppercase tracking-wide label plus an optional thin coloured accent
/// rule underneath. Keeps the typographic rhythm consistent across
/// every section on the screen.
class ProfileSectionHeader extends StatelessWidget {
  const ProfileSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.brandPrimary.withValues(alpha: 0.25),
                  AppColors.brandPrimary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
