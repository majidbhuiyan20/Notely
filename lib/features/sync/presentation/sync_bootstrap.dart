import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../task/providers/notes_providers.dart';
import '../../widgets/app_snackbar.dart';
import 'providers/sync_providers.dart';

/// Wraps the app so that:
///   1. The [SyncManager] lifecycle + connectivity listeners are started.
///   2. App foreground transitions (`AppLifecycleState.resumed`) trigger
///      a drain of pending writes for the current user.
///   3. Whenever connectivity returns (`onlineEdge$`), we drain + show a
///      single `AppSnackbar.showSuccess` if any work was actually done.
///
/// Render this widget ABOVE the [MaterialApp] so the snackbar context
/// is always available, but BELOW anything that depends on
/// `currentUidProvider` (which it reads).
class SyncBootstrap extends ConsumerStatefulWidget {
  const SyncBootstrap({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SyncBootstrap> createState() => _SyncBootstrapState();
}

class _SyncBootstrapState extends ConsumerState<SyncBootstrap>
    with WidgetsBindingObserver {
  StreamSubscription<bool>? _edgeSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Touch the sync manager so it starts listening.
    final manager = ref.read(syncManagerProvider);
    _edgeSub = manager.onlineEdge$.listen((_) => _drainAndSnackbar());
  }

  @override
  void dispose() {
    _edgeSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Foregrounded — drain pending writes.
      _drainAndSnackbar();
    }
  }

  Future<void> _drainAndSnackbar() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final manager = ref.read(syncManagerProvider);
    final pushed = await manager.drain(uid);
    if (pushed <= 0 || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final label = pushed == 1
        ? 'Synced 1 pending change'
        : 'Synced $pushed pending changes';
    AppSnackbar.showSuccess(messenger, label);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}