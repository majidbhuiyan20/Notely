import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/route/app_route.dart';
import '../../task/model/note_data.dart';
import '../../task/providers/notes_providers.dart';
import '../../widgets/back_button.dart';
import '../model/category_model.dart';
import '../widgets/category_grid_card.dart';

/// Eye-catching 2-column grid of category cards. Counts and completion
/// rings are computed live from [notesProvider] — empty categories still
/// show, but at 0 / 0%.
class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final stats = _statsFor(notes);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: false,
            titleSpacing: 0,
            leading: const RoundedBackButton(),
            title: const Text(
              'Categories',
              style: TextStyle(
                color: Color(0xFF1E1E1E),
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.4,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(96),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage your thoughts'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.royalBlue.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${stats.length}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E1E1E),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'categories',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7A8194),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${stats.totalNotes} notes',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A8194),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final c = CategoryModel.all[index];
                  final s = stats.byCategory[c.title] ?? const _Stat.zero();
                  return CategoryGridCard(
                    title: c.title,
                    icon: c.icon,
                    color: c.color,
                    count: s.total,
                    completed: s.completed,
                    onTap: () => Navigator.pushNamed(
                      context,
                      Routes.categoryDetailsRoute,
                      arguments: c.title,
                    ),
                  );
                },
                childCount: CategoryModel.all.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _CategoryStats _statsFor(List<NoteData> notes) {
    final byCategory = <String, _Stat>{};
    var total = 0;
    for (final n in notes) {
      final cur = byCategory[n.category] ?? const _Stat.zero();
      byCategory[n.category] = _Stat(
        total: cur.total + 1,
        completed: cur.completed +
            (n.status == NoteStatus.completed ? 1 : 0),
      );
      total++;
    }
    return _CategoryStats(
      byCategory: byCategory,
      length: CategoryModel.all.length,
      totalNotes: total,
    );
  }
}

class _Stat {
  const _Stat({required this.total, required this.completed});
  const _Stat.zero()
      : total = 0,
        completed = 0;
  final int total;
  final int completed;
}

class _CategoryStats {
  const _CategoryStats({
    required this.byCategory,
    required this.length,
    required this.totalNotes,
  });
  final Map<String, _Stat> byCategory;
  final int length;
  final int totalNotes;
}