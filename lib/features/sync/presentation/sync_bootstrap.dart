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
///
/// Implementation notes:
///   * We avoid `ref.read` + `setState` patterns inside [build] — instead
///     all side-effects are wired through [ref.listen] / lifecycle hooks.
///   * Subscriptions are stored on the state so we can cancel them in
///     [dispose]. We never call `state =` directly from a stream callback
///     during widget construction (which is what was producing
///     `setState() or markNeedsBuild() called during build`).
class SyncBootstrap extends ConsumerStatefulWidget {
  const SyncBootstrap({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SyncBootstrap> createState() => _SyncBootstrapState();
}

class _SyncBootstrapState extends ConsumerState<SyncBootstrap>
    with WidgetsBindingObserver {
  StreamSubscription<bool>? _edgeSub;
  ProviderSubscription<String?>? _uidSub;
  bool _booted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Defer all provider reads + subscriptions until the next frame. We
    // cannot touch [ref] during `build`, but subscribing in `initState`
    // can also produce invalidations that race with our own build pass.
    // Post-frame is the safe option.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _wireSubs();
    });
  }

  void _wireSubs() {
    if (_booted) return;
    _booted = true;

    // Touch the sync manager so it starts listening.
    final manager = ref.read(syncManagerProvider);
    _edgeSub = manager.onlineEdge$.listen((_) => _drainAndSnackbar());

    // Whenever the signed-in user changes (sign-in / sign-out / account
    // switch) we trigger a drain. `listenManual` gives us prev+next
    // without forcing a rebuild and returns a [ProviderSubscription]
    // we can close in `dispose`.
    _uidSub = ref.listenManual<String?>(
      currentUidProvider,
      (prev, next) {
        if (next != null && next != prev) _drainAndSnackbar();
      },
    );
  }

  @override
  void dispose() {
    _edgeSub?.cancel();
    _uidSub?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Foregrounded — drain pending writes. The lifecycle observer is
      // already on the platform thread, so calling `_drainAndSnackbar`
      // here is safe (no active build phase).
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