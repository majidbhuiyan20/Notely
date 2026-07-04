import 'dart:async';

import '../../model/note_data.dart';
import '../datasources/task_local_datasource.dart';
import '../datasources/task_remote_datasource.dart';
import '../models/task_row.dart';
import '../../domain/repositories/task_repository.dart';

/// Local-first implementation of [TaskRepository]. Every write hits sqflite
/// immediately (so the UI is responsive and offline-safe) and is flagged
/// `is_dirty = 1` so the [SyncManager] can drain it to Firestore later.
/// Reads return whatever is in sqflite; callers can call
/// [refreshFromRemote] to pull down cloud changes (which clears all dirty
/// flags because the cloud copy is now authoritative).
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({
    required TaskLocalDataSource local,
    required TaskRemoteDataSource remote,
  })  : _local = local,
        _remote = remote;

  final TaskLocalDataSource _local;
  final TaskRemoteDataSource _remote;

  @override
  Future<List<NoteData>> getTasks(String uid) async {
    final rows = await _local.readAllForUser(uid);
    return rows.map((r) => r.toNote()).toList(growable: false);
  }

  @override
  Future<List<NoteData>> refreshFromRemote(String uid) async {
    final remote = await _remote.fetchAllForUser(uid);
    if (remote.isEmpty) return getTasks(uid);

    // Replace the local cache with the cloud copy. Newest-write-wins
    // because Firestore server-timestamps the write. The replacement
    // rows are NOT dirty — they came straight from the cloud.
    await _local.deleteAllForUser(uid);
    for (final row in remote) {
      await _local.upsert(row);
    }
    return getTasks(uid);
  }

  @override
  Future<NoteData> upsertNote(String uid, NoteData note) async {
    final row = TaskRow.fromNote(uid: uid, note: note, isDirty: true);
    await _local.upsert(row);

    // Best-effort immediate push. If this fails the row stays dirty
    // and SyncManager will retry on reconnect / app resume.
    unawaited(_pushAndMarkClean(uid, note));

    return note;
  }

  Future<void> _pushAndMarkClean(String uid, NoteData note) async {
    try {
      await _remote.upsert(uid, note);
      await _local.markClean(uid, note.id);
    } catch (_) {
      // Remote datasource already logs the failure; row stays dirty
      // and will be retried by SyncManager.drain later.
    }
  }

  @override
  Future<void> deleteNote(String uid, String id) async {
    // Remove locally + leave a tombstone so the SyncManager can
    // replay the remote delete when connectivity returns.
    await _local.markDeleted(uid, id);
    unawaited(_pushDeleteAndRemoveTombstone(uid, id));
  }

  Future<void> _pushDeleteAndRemoveTombstone(String uid, String id) async {
    try {
      await _remote.delete(uid, id);
      await _local.removeTombstone(uid, id);
    } catch (_) {
      // Remote datasource logs the failure; tombstone stays and the
      // SyncManager will retry later.
    }
  }

  @override
  Future<NoteData?> getNote(String uid, String id) async {
    final row = await _local.readOne(uid, id);
    return row?.toNote();
  }
}