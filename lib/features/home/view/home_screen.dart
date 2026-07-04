import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/route/app_route.dart';
import '../../category/model/category_model.dart';
import '../../task/model/note_data.dart';
import '../../task/providers/notes_providers.dart';
import '../../task/providers/search_providers.dart';
import '../../widgets/category_card.dart';
import '../../widgets/note_list.dart';
import '../../widgets/search_field.dart';
import '../../widgets/title_section.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/recent_notes_row.dart';
import '../widgets/today_section.dart';

/// Rebuilt home screen. Reads from [notesProvider] and the auth notifier
/// instead of using the repository singleton directly. The search field
/// at the top drives [searchQueryProvider]; the lists below auto-filter
/// via [filteredNotesProvider].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allNotes = ref.watch(notesProvider);
    // When the search field is non-empty, swap to the filtered list for
    // category counts + the section titles. When empty, keep the full
    // list (cheaper + matches user expectation of "see everything").
    final filtered = ref.watch(filteredNotesProvider);
    final notes = filtered ?? allNotes;
    final hasQuery = ref.watch(
      searchQueryProvider.select((s) => s.trim().isNotEmpty),
    );
    final categories = _categoriesWithCounts(notes);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            const GreetingHeader(),
            const SizedBox(height: 16),
            const SearchField(),
            const SizedBox(height: 16),
            const QuickStatsRow(),
            const SizedBox(height: 24),
            const TodaySection(),
            const SizedBox(height: 24),
            TitleSection(
              title: 'Categories',
              onTap: () {
                Navigator.pushNamed(context, Routes.categoryRoute);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final category = categories[i];
                  return SizedBox(
                    width: 160,
                    child: CategoryCard(
                      icon: category.icon,
                      title: category.title,
                      count: category.count,
                      color: category.color,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Routes.categoryDetailsRoute,
                          arguments: category.title,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // When the user has typed a query we collapse the home
            // view into a single "Search results" section. Less noise.
            if (hasQuery) ...[
              TitleSection(
                title: 'Search results',
                showSeeAll: false,
              ),
              const SizedBox(height: 12),
              const NoteList(pinned: false),
            ] else ...[
              TitleSection(
                title: 'Pinned Notes',
                showSeeAll: false,
              ),
              const SizedBox(height: 12),
              const NoteList(pinned: true),
              const SizedBox(height: 24),
              const RecentNotesRow(),
              const SizedBox(height: 24),
              TitleSection(
                title: 'All Notes',
                showSeeAll: false,
              ),
              const SizedBox(height: 12),
              const NoteList(pinned: false),
            ],
          ],
        ),
      ),
    );
  }

  /// Combines the static [CategoryModel.all] list with real-time counts
  /// from [notesProvider]. Falls back to the seeded counts when there are
  /// no notes yet (cold start).
  List<CategoryModel> _categoriesWithCounts(List<NoteData> notes) {
    if (notes.isEmpty) return CategoryModel.all;
    final counts = <String, int>{};
    for (final n in notes) {
      counts[n.category] = (counts[n.category] ?? 0) + 1;
    }
    return CategoryModel.all
        .map(
          (c) => CategoryModel(
            title: c.title,
            icon: c.icon,
            color: c.color,
            count: c.title == 'All Notes' ? notes.length : (counts[c.title] ?? 0),
          ),
        )
        .toList(growable: false);
  }
}