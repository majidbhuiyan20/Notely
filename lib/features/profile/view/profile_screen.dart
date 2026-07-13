import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/providers/auth_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/route/app_route.dart';
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
    final user = ref.watch(authNotifierProvider).value;
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
                  const ProfileSectionHeader(title: 'Account'),
                  const SizedBox(height: AppSpacing.md),
                  AccountCard(
                    email: widget.email,
                    onConfirmSignOut: _confirmAndSignOut,
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

  /// Shows a confirmation dialog, then triggers sign-out. Errors are
  /// surfaced via a snackbar instead of being swallowed. On success we
  /// navigate to the Login screen directly here (not via a listener)
  /// because the user's tap is the explicit intent.
  Future<void> _confirmAndSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Sign out?'),
        content: const Text(
          'You\'ll need to sign in again to view your notes. Your local '
          'notes will be kept for next time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(authNotifierProvider.notifier).signOut();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Sign out failed: $e');
      return;
    }

    if (!mounted) return;

    // Push the Login screen and pop every route below it (which is
    // MainScreen). Use the root navigator explicitly so this works
    // even though the trigger originates inside an IndexedStack tab.
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pushNamedAndRemoveUntil(
      Routes.loginRoute,
      (_) => false,
    );
  }
}

/// Account row containing the user's email and a destructive
/// sign-out action. Stateful so it can show a spinner while sign-out
/// is in flight and disable the tap to prevent double-fires.
///
/// Exposed (not private) so it can be exported as `AccountCard` if
/// other screens ever want to reuse it.
class AccountCard extends StatefulWidget {
  const AccountCard({
    super.key,
    required this.email,
    required this.onConfirmSignOut,
  });

  final String email;

  /// Called when the user confirms they want to sign out. The card
  /// owns its own loading state and disables taps while this future
  /// is pending — but it does NOT trigger navigation itself.
  final Future<void> Function() onConfirmSignOut;

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  bool _signingOut = false;

  Future<void> _handleTap() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await widget.onConfirmSignOut();
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSignOut = widget.email.isNotEmpty;
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
          if (canSignOut)
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
                          widget.email,
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
          if (canSignOut)
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
              onTap: canSignOut && !_signingOut ? _handleTap : null,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(scale: anim, child: child),
                      ),
                      child: _signingOut
                          ? Container(
                              key: const ValueKey('spinner'),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.error,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              key: const ValueKey('icon'),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _signingOut ? 'Signing out…' : 'Sign out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _signingOut
                              ? AppColors.textSecondary
                              : AppColors.error,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    Icon(
                      _signingOut
                          ? Icons.hourglass_top_rounded
                          : Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                      size: _signingOut ? 16 : 24,
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