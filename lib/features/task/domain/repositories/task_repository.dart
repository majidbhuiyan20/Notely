import '../../model/note_data.dart';

/// Tasks are stored locally in sqflite and mirrored to Firestore. The
/// repository is responsible for keeping both sides in sync. Local-first
/// means: every mutation writes to sqflite synchronously, then pushes to
/// Firestore in the background; reads return whatever sqflite has right
/// now, optionally refreshed from the cloud first.
abstract class TaskRepository {
  /// Returns every task for [uid], ordered by most recently updated.
  Future<List<NoteData>> getTasks(String uid);

  /// Replaces the local cache for [uid] with what Firestore has, then
  /// returns the merged list. Best-effort: a network failure does not
  /// throw — the caller still gets the local copy.
  Future<List<NoteData>> refreshFromRemote(String uid);

  /// Saves [note] to local + remote and returns the persisted copy.
  Future<NoteData> upsertNote(String uid, NoteData note);

  /// Deletes [id] from local + remote.
  Future<void> deleteNote(String uid, String id);

  /// Returns a single note or `null` if it doesn't exist.
  Future<NoteData?> getNote(String uid, String id);
}