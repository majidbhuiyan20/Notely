import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/route/app_route.dart';
import '../../task/model/note_data.dart';
import '../../task/model/notes_repository.dart';
import '../../task/providers/notes_providers.dart';

/// Lists notes whose [NoteData.dueDateIso] equals today. If there are no
/// dated tasks, shows a small empty-state banner instead.
class TodaySection extends ConsumerWidget {
  const TodaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final todayIso = _todayIso();
    final todayNotes = notes
        .where((n) => n.dueDateIso == todayIso)
        .toList(growable: false)
      ..sort((a, b) => comparePriority(a.priority, b.priority));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'TODAY',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF1E1E1E),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const Spacer(),
            Text(
              '${todayNotes.length}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (todayNotes.isEmpty)
          _EmptyTodayBanner()
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: todayNotes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) =>
                  _TodayNoteCard(note: todayNotes[i]),
            ),
          ),
      ],
    );
  }

  String _todayIso() {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

class _EmptyTodayBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.beach_access_rounded,
              color: AppColors.royalBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Inbox zero for today',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                Text(
                  'Nothing scheduled — great job!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
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

class _TodayNoteCard extends StatelessWidget {
  const _TodayNoteCard({required this.note});
  final NoteData note;

  @override
  Widget build(BuildContext context) {
    final accent = note.categoryColor;
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.pushNamed(
              context,
              Routes.taskRoute,
              arguments: note.id,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(note.categoryIcon, size: 18, color: accent),
                ),
                const Spacer(),
                Text(
                  note.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E1E),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        note.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}