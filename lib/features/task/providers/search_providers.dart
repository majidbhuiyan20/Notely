import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/note_data.dart';
import 'notes_providers.dart' show notesListProvider;

/// Free-text search query shared across screens (Home, Category details).
/// A simple [Notifier] over `String`. Using the Riverpod 3.x [Notifier]
/// API (rather than the legacy [StateProvider] which is not exported by
/// `flutter_riverpod` 3.3) gives us a typed notifier with a clean
/// `notifier.state = ...` setter.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  /// Updates the query. Callers can keep using
  /// `ref.read(searchQueryProvider.notifier).state = 'foo'`.
  // ignore: use_setters_to_change_properties
  void set(String value) => state = value;

  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Derived list: notes matching [searchQueryProvider] (case-insensitive
/// substring on title + description + category). Returns `null` when the
/// query is empty so consumers can short-circuit and render the unfiltered
/// list (cheaper, and avoids unnecessary allocations on the home screen).
final filteredNotesProvider = Provider<List<NoteData>?>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final notes = ref.watch(notesListProvider);
  if (query.isEmpty) return null;
  return notes.where((n) {
    return n.title.toLowerCase().contains(query) ||
        n.description.toLowerCase().contains(query) ||
        n.category.toLowerCase().contains(query);
  }).toList(growable: false);
});