import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/presentation/providers/auth_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/route/app_route.dart';
import '../widgets/category_progress_list.dart';
import '../widgets/overall_progress_card.dart';
import '../widgets/profile_app_bar.dart';

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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OverallProgressCard(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Category Progress'),
                  const SizedBox(height: 14),
                  const CategoryProgressList(),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Account'),
                  const SizedBox(height: 12),
                  _SignOutTile(
                    onTap: () async {
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
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E1E1E),
        letterSpacing: -0.4,
      ),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sign out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
