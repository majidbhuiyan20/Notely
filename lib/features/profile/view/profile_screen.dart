import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/providers/auth_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/route/app_route.dart';
import '../widgets/category_progress_list.dart';
import '../widgets/profile_app_bar.dart';
import '../widgets/profile_section_header.dart';
import '../widgets/stats_grid.dart';
import '../widgets/weekly_sparkline_card.dart';

/// Premium Profile tab. Reads from [notesListProvider] (in-memory
/// cache) so it stays fast offline. Layout:
///
///   1. ProfileAppBar — gradient hero with parallax avatar + streak pill.
///   2. StatsGrid     — Today / Week / Month / Total glass cards.
///   3. WeeklySparklineCard — 7-bar activity chart.
///   4. Category Progress   — restyled category breakdown.
///   5. Account tile        — sign-out, restyled.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    final name = user?.displayName ?? 'Notely User';
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl ?? 'https://picsum.photos/200';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          ProfileAppBar(
            name: name,
            email: email,
            imageUrl: photoUrl,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StatsGrid(),
                  const SizedBox(height: AppSpacing.xl),
                  const WeeklySparklineCard(),
                  const SizedBox(height: AppSpacing.xl),
                  const ProfileSectionHeader(title: 'Category Progress'),
                  const SizedBox(height: AppSpacing.md),
                  const CategoryProgressList(),
                  const SizedBox(height: AppSpacing.xl),
                  const ProfileSectionHeader(title: 'Account'),
                  const SizedBox(height: AppSpacing.md),
                  _AccountCard(
                    email: email,
                    onSignOut: () async {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .signOut();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        Routes.loginRoute,
                        (_) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Account row containing the user's email and a destructive
/// sign-out action. Restyled with frosted card surface + gradient
/// icon to match the rest of the screen.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.email, required this.onSignOut});
  final String email;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.cardShadow,
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        children: [
          if (email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.brandGradient,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.alternate_email_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Signed in as',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (email.isNotEmpty)
            Container(
              height: 1,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.divider,
                    AppColors.divider.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onSignOut,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Text(
                        'Sign out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.error,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}