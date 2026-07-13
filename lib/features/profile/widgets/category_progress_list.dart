import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../task/model/note_data.dart';
import '../../task/providers/notes_providers.dart';

/// Premium frosted-glass card used inside the profile screen to show
/// per-category progress. Animates the progress bar from 0 on first
/// build so the screen feels alive when you scroll into it.
class CategoryProgressTile extends StatelessWidget {
  const CategoryProgressTile({
    super.key,
    required this.name,
    required this.color,
    required this.icon,
    required this.progress,
    required this.completed,
    required this.total,
  });

  final String name;
  final Color color;
  final IconData icon;
  final double progress;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.cardShadow,
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '$completed / $total',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: color,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween:
                        Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceAlt,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$percent% complete',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: color,
                      ),
                    ),
                    Text(
                      total == 0
                          ? 'No tasks'
                          : '${total - completed} pending',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Aggregates the user's notes by category, then renders one
/// [CategoryProgressTile] per category that has at least one note.
class CategoryProgressList extends ConsumerWidget {
  const CategoryProgressList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesListProvider);
    if (notes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.divider, width: 0.8),
          boxShadow: AppElevation.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text(
                'Categories appear here once you create notes.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final byCategory = <String, List<NoteData>>{};
    for (final n in notes) {
      byCategory.putIfAbsent(n.category, () => []).add(n);
    }

    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final entry = entries[i];
        final catNotes = entry.value;
        final total = catNotes.length;
        final completed = catNotes
            .where((n) => n.status == NoteStatus.completed)
            .length;
        final progress = total == 0 ? 0.0 : completed / total;
        final sample = catNotes.first;
        return CategoryProgressTile(
          name: entry.key,
          icon: sample.categoryIcon,
          color: sample.categoryColor,
          progress: progress,
          completed: completed,
          total: total,
        );
      },
    );
  }
}