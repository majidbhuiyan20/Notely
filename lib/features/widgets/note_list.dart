import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/route/app_route.dart';
import '../task/model/notes_repository.dart';

/// Tile representing a single note in any list. Used on the home screen
/// for "Pinned Note" and "All Notes" sections. Reads its data from the
/// [NotesRepository] singleton.
class NoteList extends StatelessWidget {
  const NoteList({super.key, this.noteId, this.titleOverride, this.timeOverride});

  final String? noteId;
  final String? titleOverride;
  final String? timeOverride;

  @override
  Widget build(BuildContext context) {
    final repo = NotesRepository.instance;
    // Pick a note — first if not specified.
    final note = (noteId != null
            ? repo.noteById(noteId!)
            : (repo.notes.isNotEmpty ? repo.notes.first : null)) ??
        (repo.notes.isNotEmpty ? repo.notes.first : null);

    final title = titleOverride ?? note?.title ?? 'No notes yet';
    final time = timeOverride ?? 'Recently';
    final accent = note?.categoryColor ?? AppColors.royalBlue;
    final categoryName = note?.category ?? 'Notes';
    final id = note?.id;

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 1,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return InkWell(
          onTap: id == null
              ? null
              : () {
                  Navigator.pushNamed(
                    context,
                    Routes.taskRoute,
                    arguments: id,
                  );
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.1), width: 1),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: accent.withOpacity(0.2), width: 1),
                    ),
                    child: Icon(
                      note?.categoryIcon ?? Icons.person_outline,
                      color: accent,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: accent.withOpacity(0.2), width: 1),
                  ),
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 14,
                      color: accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}