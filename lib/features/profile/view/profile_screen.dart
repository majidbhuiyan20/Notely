import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/providers/auth_providers.dart'
    as google_auth;
import '../../../core/constants/app_colors.dart';
import '../../../core/route/app_route.dart';
import '../../subscription/presentation/providers/auth_notifier.dart';
import '../../subscription/presentation/providers/subscription_providers.dart';
import '../../subscription/presentation/widgets/subscription_card.dart';
import '../../widgets/app_snackbar.dart';
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
///   5. Account tile        — sign-out with confirmation + loading state.
///
/// Sign-out is wired reactively: tapping the row triggers a
/// confirmation dialog, then awaits the auth notifier. Errors are
/// surfaced via [AppSnackbar]. Navigation to the Login screen happens
/// whenever the auth state flips to signed-out (handled by a
/// [ref.listen] in [_ProfileScaffold], not by the button callback) so
/// the user can't end up stranded on Profile if the sign-out finishes
/// faster than the navigation call.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(google_auth.authNotifierProvider).value;
    final name = user?.displayName ?? 'Notely User';
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl ?? 'https://picsum.photos/200';

    return _ProfileScaffold(
      name: name,
      email: email,
      photoUrl: photoUrl,
    );
  }
}

/// Wraps the entire profile content in a [ConsumerStatefulWidget] so
/// we can mount a [ref.listen] on the auth state without rebuilding
/// the whole screen on every auth tick.
class _ProfileScaffold extends ConsumerStatefulWidget {
  const _ProfileScaffold({
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  final String name;
  final String email;
  final String photoUrl;

  @override
  ConsumerState<_ProfileScaffold> createState() => _ProfileScaffoldState();
}

class _ProfileScaffoldState extends ConsumerState<_ProfileScaffold> {
  @override
  Widget build(BuildContext context) {
    // Sign-out is driven explicitly from [_confirmAndSignOut] below
    // (because the user's tap is the explicit intent), not from a
    // Riverpod listener. We still want a safety net for users on
    // Home/Calendar/Insights if the session expires mid-use — that's
    // handled by the listener on [_MainScreenState] in main_screen.dart.

    final session = ref.watch(subscriptionSessionProvider);
    final authState = ref.watch(subscriptionAuthNotifierProvider);
    final isUnsubBusy = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          ProfileAppBar(
            name: widget.name,
            email: widget.email,
            imageUrl: widget.photoUrl,
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
                  const ProfileSectionHeader(title: 'Subscription'),
                  const SizedBox(height: AppSpacing.md),
                  SubscriptionCard(
                    session: session,
                    isBusy: isUnsubBusy,
                    onUnsubscribe: _confirmUnsubscribeAndLogout,
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

  /// Shows a confirmation dialog, then triggers the Unsubscribe &
  /// Logout flow. On success, the local session is wiped, Firebase is
  /// signed out, and the user is routed back to the splash.
  Future<void> _confirmUnsubscribeAndLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Unsubscribe & Logout?'),
        content: const Text(
          'This will cancel your mobile subscription, sign you out of '
          'Notely, and clear all local data. You\'ll need to verify '
          'your number again to come back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Unsubscribe & Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(subscriptionAuthNotifierProvider.notifier)
          .unsubscribeAndLogout();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Could not unsubscribe: $e');
      return;
    }

    if (!mounted) return;
    AppSnackbar.info(context, 'You\'ve been unsubscribed.');

    // Force a re-route via the root navigator so the user lands on
    // the splash (which will then route them through the new flow).
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      Routes.splashRoute,
      (_) => false,
    );
  }
}