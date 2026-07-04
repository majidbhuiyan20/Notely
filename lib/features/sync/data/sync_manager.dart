import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../task/data/datasources/task_local_datasource.dart';
import '../../task/data/datasources/task_remote_datasource.dart';

/// Drains the offline-write outbox to Firestore.
///
/// Every local `upsert` / `delete` is marked `is_dirty = 1` (or
/// tombstoned) in sqflite before its best-effort `_remote` push. If the
/// push fails (offline, throttled, server error) the row stays dirty.
/// [SyncManager] re-attempts those pushes whenever connectivity returns
/// or the app resumes.
///
/// The drain is idempotent — calling it twice without any new offline
/// writes is a no-op. Callers should drive drains from:
///   * [onlineEdge$] (one event per offline → online transition), and
///   * app foreground (`AppLifecycleState.resumed`).
class SyncManager {
  SyncManager({
    required TaskLocalDataSource local,
    required TaskRemoteDataSource remote,
    required Connectivity connectivity,
  })  : _local = local,
        _remote = remote,
        _connectivity = connectivity;

  final TaskLocalDataSource _local;
  final TaskRemoteDataSource _remote;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _onlineEdgeController =
      StreamController<bool>.broadcast();
  bool _isOnline = true;
  bool _started = false;

  /// Hot stream of online state. `true` means connectivity is NOT `none`.
  Stream<bool> get online$ => _onlineController.stream;

  /// One event per offline → online transition. Use this to drive a
  /// drain + snackbar in the UI shell.
  Stream<bool> get onlineEdge$ => _onlineEdgeController.stream;

  bool get isOnline => _isOnline;

  /// Wires up the connectivity listener. Safe to call multiple times.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    final initial = await _connectivity.checkConnectivity();
    _isOnline = _isOnlineFromConnectivity(initial);
    _onlineController.add(_isOnline);
    _connectivitySub = _connectivity.onConnectivityChanged.listen((events) {
      final next = _isOnlineFromConnectivity(events);
      final wasOffline = !_isOnline;
      _isOnline = next;
      _onlineController.add(next);
      if (next && wasOffline) {
        _onlineEdgeController.add(true);
      }
    });
  }

  bool _isOnlineFromConnectivity(List<ConnectivityResult> r) {
    if (r.isEmpty) return false;
    return !r.every((e) => e == ConnectivityResult.none);
  }

  /// Total unsynced work for [uid]: dirty rows + tombstones.
  Future<int> pendingCount(String uid) async {
    final dirty = await _local.countDirtyForUser(uid);
    final tombstones = await _local.countTombstonesForUser(uid);
    return dirty + tombstones;
  }

  /// Drains pending writes for [uid]. Returns the number of operations
  /// successfully pushed. Safe to call concurrently — operations
  /// themselves are idempotent (upserts overwrite, deletes are unique
  /// by id) but callers should ideally serialize via the `onlineEdge$`
  /// / lifecycle signals to avoid wasted work.
  Future<int> drain(String uid) async {
    var pushed = 0;

    // Tombstones first so any pending upsert for a deleted note is
    // overridden by the subsequent remote delete.
    final tombstones = await _local.readTombstonesForUser(uid);
    for (final t in tombstones) {
      try {
        await _remote.delete(uid, t.id);
        await _local.removeTombstone(uid, t.id);
        pushed++;
      } catch (_) {
        // Stay tombstoned; will retry next drain.
      }
    }

    final dirty = await _local.readDirtyForUser(uid);
    for (final row in dirty) {
      try {
        await _remote.upsert(uid, row.toNote());
        await _local.markClean(uid, row.id);
        pushed++;
      } catch (_) {
        // Stay dirty; will retry next drain.
      }
    }

    return pushed;
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    await _onlineController.close();
    await _onlineEdgeController.close();
  }
}