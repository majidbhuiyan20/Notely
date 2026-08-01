import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around [Connectivity] that returns a single boolean
/// describing "can we talk to the network right now?".
///
/// Kept as a class (not a function) so it can be dependency-injected
/// in tests with a fake.
class InternetChecker {
  InternetChecker({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// `true` when the device reports at least one non-`none` interface.
  Future<bool> isOnline() async {
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
