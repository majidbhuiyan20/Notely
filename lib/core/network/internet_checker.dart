import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around [Connectivity] that returns a single boolean
/// describing "can we talk to the network right now?".
///
/// Kept as a class (not a function) so it can be dependency-injected
/// in tests with a fake.
class InternetChecker {
  InternetChecker({Connectivity? connectivity, Future<bool> Function()? override})
      : _connectivity = connectivity ?? Connectivity(),
        _override = override;

  final Connectivity _connectivity;

  /// When set, this function is consulted instead of the
  /// `Connectivity` plugin. Useful for unit tests that need to
  /// force a deterministic online/offline answer.
  final Future<bool> Function()? _override;

  /// `true` when the device reports at least one non-`none` interface.
  Future<bool> isOnline() async {
    final override = _override;
    if (override != null) {
      try {
        return await override();
      } catch (_) {
        return false;
      }
    }
    try {
      final result = await _connectivity.checkConnectivity();
      return _isOnlineFrom(result);
    } catch (_) {
      // `connectivity_plus` occasionally throws on iOS during fast
      // app launches. Treat the failure as "offline" — the request
      // will then produce a proper [NoInternetException] downstream.
      return false;
    }
  }

  bool _isOnlineFrom(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }
}