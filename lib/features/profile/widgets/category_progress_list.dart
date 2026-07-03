import 'package:flutter/material.dart';
import '../../task/model/notes_repository.dart';

/// Single-row progress card used inside the profile screen.
class CategoryProgressTile extends StatelessWidget {
  const CategoryProgressTile({
    super.key,
    required this.name,
    required this.color,
    required this.icon,
    required this.progress,
  });

  final String name;
  final Color color;
  final IconData icon;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade50,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
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

/// Full list of category tiles driven by [NotesRepository].
class CategoryProgressList extends StatelessWidget {
  const CategoryProgressList({super.key});

  static const List<({String name, IconData icon, Color color})> _shown = [
    (name: 'Work', icon: Icons.work_outline, color: Color(0xFFFF9500)),
    (name: 'Personal', icon: Icons.person_outline, color: Color(0xFF34C759)),
    (name: 'Ideas', icon: Icons.lightbulb_outline, color: Color(0xFFAF52DE)),
    (name: 'Health', icon: Icons.favorite_border, color: Color(0xFFFF3B30)),
  ];

  @override
  Widget build(BuildContext context) {
    final repo = NotesRepository.instance;

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _shown.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final cat = _shown[index];
        return CategoryProgressTile(
          name: cat.name,
          icon: cat.icon,
          color: cat.color,
          progress: repo.progressFor(cat.name),
        );
      },
    );
  }
}