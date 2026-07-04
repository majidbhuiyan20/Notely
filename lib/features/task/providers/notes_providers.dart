import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/providers/auth_providers.dart';
import '../data/datasources/task_local_datasource.dart';
import '../data/datasources/task_remote_datasource.dart';
import '../data/repositories/task_repository_impl.dart';
import '../domain/repositories/task_repository.dart';
import '../model/note_data.dart';
import '../model/notes_repository.dart';

// --- DI ------------------------------------------------------------

final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>((ref) {
  final ds = TaskLocalDataSource();
  ref.onDispose(ds.close);
  return ds;
});

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSource();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(
    local: ref.watch(taskLocalDataSourceProvider),
    remote: ref.watch(taskRemoteDataSourceProvider),
  );
});

/// The currently signed-in user's uid, or `null` when no user is logged
/// in. Most task providers watch this and re-load when it changes (e.g.
/// after sign-out + sign-in as a different account).
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).value?.uid;
});

// --- Live task list ------------------------------------------------

/// How long the in-memory cache stays warm. Once the user lands on Home,
/// subsequent tab switches (Calendar / Analytics / Profile) read from
/// this cache instead of hitting sqflite again.
const _cacheTtl = Duration(seconds: 60);

/// The full list of tasks for the current user. Watches [currentUidProvider]
/// so signing in as a different account automatically reloads. Reads come
/// from sqflite — never from Firestore — so list screens stay fast even
/// offline.
class TasksNotifier extends AsyncNotifier<List<NoteData>> {
  String? _uid;
  String? _cachedForUid;
  DateTime? _cachedAt;

  @override
  Future<List<NoteData>> build() async {
    final uid = ref.watch(currentUidProvider);
    _uid = uid;
    if (uid == null) {
      _cachedForUid = null;
      _cachedAt = null;
      return const [];
    }

    // In-memory cache short-circuit: if we just loaded this uid, return
    // the same list reference. This is what keeps tab switches snappy.
    if (_cachedForUid == uid &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheTtl) {
      return NotesRepository.instance.notes;
    }

    final repo = ref.read(taskRepositoryProvider);
    final tasks = await repo.getTasks(uid);
    // Mirror into the in-memory singleton so existing screens (home,
    // calendar, category, profile) keep working without changes.
    NotesRepository.instance.replaceAll(tasks);
    _cachedForUid = uid;
    _cachedAt = DateTime.now();
    return tasks;
  }

  /// Pulls from Firestore and replaces the local copy. Intended to be
  /// called exactly once per sign-in by [AuthNotifier]. The local cache
  /// is the source of truth for everything else.
  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(taskRepositoryProvider);
      final tasks = await repo.refreshFromRemote(uid);
      NotesRepository.instance.replaceAll(tasks);
      _cachedForUid = uid;
      _cachedAt = DateTime.now();
      return tasks;
    });
  }

  /// Create or update a note. Re-reads the mirror afterwards so the
  /// Riverpod state stays in sync with whatever the in-memory singleton
  /// exposes to the rest of the app (home, calendar, etc.).
  Future<NoteData> upsert(NoteData note) async {
    final uid = _uid;
    if (uid == null) throw StateError('Cannot save a task when signed out.');
    final repo = ref.read(taskRepositoryProvider);
    final saved = await repo.upsertNote(uid, note);
    NotesRepository.instance.addOrUpdate(saved);
    state = AsyncValue.data(NotesRepository.instance.notes);
    return saved;
  }

  /// Toggles the `isPinned` flag on a note. Cheap because it goes through
  /// the same code path as [upsert] — local write first, remote push in
  /// the background.
  Future<NoteData?> togglePin(String id) async {
    final list = state.value ?? NotesRepository.instance.notes;
    final note = list.cast<NoteData?>().firstWhere(
          (n) => n?.id == id,
          orElse: () => null,
        );
    if (note == null) return null;
    note.isPinned = !note.isPinned;
    return upsert(note);
  }

  Future<void> delete(String id) async {
    final uid = _uid;
    if (uid == null) return;
    final repo = ref.read(taskRepositoryProvider);
    await repo.deleteNote(uid, id);
    NotesRepository.instance.remove(id);
    state = AsyncValue.data(NotesRepository.instance.notes);
  }

  /// Drops the in-memory mirror and the provider state. Local sqflite
  /// rows are intentionally kept on disk so the next sign-in can restore
  /// them via [refresh].
  void clearLocal() {
    NotesRepository.instance.replaceAll(const []);
    _cachedForUid = null;
    _cachedAt = null;
    state = const AsyncValue.data([]);
  }
}

final tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<NoteData>>(TasksNotifier.new);

/// Convenience accessor for screens that only need to read the current
/// list synchronously. Falls back to an empty list while loading.
final notesListProvider = Provider<List<NoteData>>((ref) {
  return ref.watch(tasksProvider).value ?? const [];
});

/// All notes the user has pinned. Derived from [notesListProvider] so it
/// stays in sync with the underlying notifier.
final pinnedNotesProvider = Provider<List<NoteData>>((ref) {
  final notes = ref.watch(notesListProvider);
  final pinned = notes.where((n) => n.isPinned).toList()
    ..sort((a, b) => comparePriority(a.priority, b.priority));
  return pinned;
});

/// Backwards-compatible alias. Existing screens call
/// `ref.watch(notesProvider)` and treat the result as a `List<NoteData>`.
/// This keeps that contract intact while the underlying implementation is
/// backed by sqflite + Firestore.
final notesProvider = notesListProvider;

/// Legacy alias for the singleton notes repository (kept around so
/// tests/overrides that previously targeted [notesRepositoryProvider]
/// still work). New code should depend on [tasksProvider] directly.
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository.instance;
});