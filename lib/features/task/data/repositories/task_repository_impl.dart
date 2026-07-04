import 'dart:async';

import '../../model/note_data.dart';
import '../datasources/task_local_datasource.dart';
import '../datasources/task_remote_datasource.dart';
import '../models/task_row.dart';
import '../../domain/repositories/task_repository.dart';

/// Local-first implementation of [TaskRepository]. Every write hits sqflite
/// immediately (so the UI is responsive and offline-safe) and then pushes
/// to Firestore in the background. Reads return whatever is in sqflite;
/// callers can call [refreshFromRemote] to pull down cloud changes.
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
    // because Firestore server-timestamps the write.
    await _local.deleteAllForUser(uid);
    for (final row in remote) {
      await _local.upsert(row);
    }
    return getTasks(uid);
  }

  @override
  Future<NoteData> upsertNote(String uid, NoteData note) async {
    final row = TaskRow.fromNote(uid: uid, note: note);
    await _local.upsert(row);
    // Fire-and-forget cloud sync. The local copy is authoritative.
    unawaited(_remote.upsert(uid, note));
    return note;
  }

  @override
  Future<void> deleteNote(String uid, String id) async {
    await _local.delete(uid, id);
    unawaited(_remote.delete(uid, id));
  }

  @override
  Future<NoteData?> getNote(String uid, String id) async {
    final row = await _local.readOne(uid, id);
    return row?.toNote();
  }
}