import '../../task/model/note_data.dart';
import '../../task/providers/notes_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin lookup layer for date-keyed queries used by the calendar UI.
/// Keeps the calendar feature decoupled from the [NotesRepository] type:
/// everything is keyed off [notesProvider].
class CalendarRepository {
  CalendarRepository(this._ref);
  final Ref _ref;

  /// All notes whose [NoteData.dueDateIso] equals the given ISO date
  /// (yyyy-MM-dd). Live – re-runs whenever [notesProvider] changes.
  List<NoteData> notesOnDate(String isoDate) {
    final notes = _ref.watch(notesProvider);
    return notes.where((n) => n.dueDateIso == isoDate).toList(growable: false);
  }

  /// Returns a map keyed by ISO date -> number of notes due that day.
  /// Used to render dot indicators in the month grid.
  Map<String, int> countsByDate() {
    final notes = _ref.watch(notesProvider);
    final map = <String, int>{};
    for (final n in notes) {
      final iso = n.dueDateIso;
      if (iso == null) continue;
      map[iso] = (map[iso] ?? 0) + 1;
    }
    return map;
  }
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(ref);
});