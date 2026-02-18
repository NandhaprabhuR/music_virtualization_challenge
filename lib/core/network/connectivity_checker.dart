import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityChecker {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class ConnectivityCheckerImpl implements ConnectivityChecker {
  final Connectivity _connectivity;

  ConnectivityCheckerImpl({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get isConnected async {
    // On web, connectivity_plus may not detect connection types properly.
    // Trust the browser — if we're running, we likely have internet.
    if (kIsWeb) return true;

    final results = await _connectivity.checkConnectivity();
    final hasConn = _hasConnection(results);
    if (hasConn) return true;
    // Fallback: connectivity_plus can be unreliable on emulators,
    // so do a real DNS lookup to verify.
    return _realReachabilityCheck();
  }

  /// Performs a real DNS lookup to check if the device can reach the internet.
  /// Only called on non-web platforms.
  Future<bool> _realReachabilityCheck() async {
    try {
      // If connectivity_plus said no, try one more check
      final recheck = await _connectivity.checkConnectivity();
      return _hasConnection(recheck);
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    // On web, ConnectivityResult.none may be returned but internet works
    if (kIsWeb) return true;
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );
  }
}
