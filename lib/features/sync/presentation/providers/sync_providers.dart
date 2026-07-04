import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync_manager.dart';
import '../../../task/providers/notes_providers.dart';

/// Singleton [Connectivity] instance. Cheap to construct but kept here
/// so tests can override.
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// App-wide [SyncManager]. The first read wires up the connectivity
/// stream subscription; later reads reuse the same instance.
final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(
    local: ref.watch(taskLocalDataSourceProvider),
    remote: ref.watch(taskRemoteDataSourceProvider),
    connectivity: ref.watch(connectivityProvider),
  );
  ref.onDispose(manager.dispose);
  // Kick off the connectivity listener eagerly so the first read of
  // `online$` already has the correct cached value.
  unawaited(manager.start());
  return manager;
});

/// Public stream of online state for any UI that wants to react.
final onlineStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(syncManagerProvider).online$;
});

/// One-shot stream that fires every time connectivity returns. Drives
/// the "Synced N pending changes" snackbar.
final connectivityEdgeProvider = StreamProvider<bool>((ref) {
  return ref.watch(syncManagerProvider).onlineEdge$;
});