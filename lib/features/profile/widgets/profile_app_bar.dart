import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../task/model/note_data.dart';
import '../../task/providers/notes_providers.dart';

/// Hero header for the profile screen. Pinned SliverAppBar with a
/// royalBlue→violet gradient, parallax avatar, and a "streak / total"
/// pill under the email. Avatar shrinks slightly on collapse so the
/// name + email stay readable while scrolling.
class ProfileAppBar extends ConsumerWidget {
  const ProfileAppBar({
    super.key,
    required this.name,
    required this.email,
    required this.imageUrl,
  });

  final String name;
  final String email;
  final String imageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesListProvider);
    final completed = notes
        .where((n) => n.status == NoteStatus.completed)
        .length;
    final streak = _streakDays(notes);

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.royalBlue,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.royalBlue,
                    Color(0xFF6A5AE0),
                    Color(0xFF8B5CF6),
                  ],
                ),
              ),
            ),
            // Soft radial highlight — adds depth without visual noise.
            Positioned(
              left: -80,
              top: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -60,
              bottom: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final shrink = 1 -
                    (constraints.biggest.height - kToolbarHeight) /
                        (240 - kToolbarHeight);
                final avatar = (64 - shrink * 14).clamp(40.0, 64.0);
                return Padding(
                  padding: EdgeInsets.only(top: kToolbarHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _AvatarRing(
                        size: avatar,
                        imageUrl: imageUrl,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22 - shrink * 4,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 12),
                      _StreakPill(
                        streak: streak,
                        completed: completed,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Consecutive days (ending today or yesterday) where the user
  /// completed at least one note. Returns 0 when there's no streak.
  static int _streakDays(List<NoteData> notes) {
    if (notes.isEmpty) return 0;
    final completedDays = <DateTime>{};
    for (final n in notes) {
      if (n.status != NoteStatus.completed) continue;
      final iso = n.dueDateIso;
      if (iso == null) continue;
      final dt = DateTime.tryParse(iso);
      if (dt == null) continue;
      completedDays.add(DateTime(dt.year, dt.month, dt.day));
    }
    if (completedDays.isEmpty) return 0;

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    var cursor = todayKey;
    var streak = 0;
    // Allow today to be empty — streak still counts if yesterday had one.
    if (!completedDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (completedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.size, required this.imageUrl});
  final double size;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
          // Subtle coloured glow tying the avatar to the brand palette.
          BoxShadow(
            color: AppColors.brandSecondary.withValues(alpha: 0.55),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak, required this.completed});
  final int streak;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFFD27A),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            streak == 0
                ? 'Start a streak today'
                : '$streak day${streak == 1 ? '' : 's'} streak',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '$completed done',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}