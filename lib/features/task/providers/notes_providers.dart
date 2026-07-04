import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/note_data.dart';
import '../model/notes_repository.dart';

/// DI seam for the in-memory notes repository. Tests can override this
/// with a fake or in-memory implementation without touching UI code.
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository.instance;
});

/// Live list of notes, rebuilt whenever the repository emits a change.
/// Home, Calendar, and any other future feature should depend on this
/// rather than calling the singleton directly.
class NotesNotifier extends Notifier<List<NoteData>> {
  late final NotesRepository _repo;
  late final VoidCallback _listener;

  @override
  List<NoteData> build() {
    _repo = ref.read(notesRepositoryProvider);
    _listener = () {
      // New list reference so Riverpod sees the change.
      state = List<NoteData>.unmodifiable(_repo.notes);
    };
    _repo.addListener(_listener);
    ref.onDispose(() => _repo.removeListener(_listener));
    return List<NoteData>.unmodifiable(_repo.notes);
  }
}

final notesProvider =
    NotifierProvider<NotesNotifier, List<NoteData>>(NotesNotifier.new);