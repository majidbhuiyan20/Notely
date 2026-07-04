import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../task/model/note_data.dart';
import '../task/providers/notes_providers.dart';
import 'app_snackbar.dart';

/// Modal bottom sheet that exposes the common actions on a note:
/// Pin / Unpin, Edit, Delete. Caller passes the note; we resolve the
/// notifier from Riverpod and persist via [TasksNotifier].
Future<void> showNoteActionsSheet(BuildContext context, NoteData note) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _NoteActionsSheet(note: note),
  );
}

class _NoteActionsSheet extends ConsumerWidget {
  const _NoteActionsSheet({required this.note});
  final NoteData note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: note.categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(note.categoryIcon,
                        size: 20, color: note.categoryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          note.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            _ActionTile(
              icon: note.isPinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              color: AppColors.royalBlue,
              label: note.isPinned ? 'Unpin from top' : 'Pin to top',
              onTap: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                final updated =
                    await ref.read(tasksProvider.notifier).togglePin(note.id);
                if (updated == null) return;
                AppSnackbar.showInfo(
                  messenger,
                  updated.isPinned ? 'Pinned to top' : 'Unpinned',
                );
              },
            ),
            _ActionTile(
              icon: Icons.edit_outlined,
              color: AppColors.royalBlue,
              label: 'Edit',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(
                  // Use the root navigator so we pop the sheet first.
                  '/editTask',
                  arguments: note.id,
                );
              },
            ),
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              color: AppColors.error,
              label: 'Delete',
              onTap: () async {
                Navigator.of(context).pop();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Text('Delete note?'),
                    content: Text(
                      '"${note.title}" will be permanently deleted '
                      'from this device and from your cloud backup.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dctx).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                await ref.read(tasksProvider.notifier).delete(note.id);
                if (!context.mounted) return;
                AppSnackbar.success(context, 'Note deleted');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}