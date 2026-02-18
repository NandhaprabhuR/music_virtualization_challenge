import 'dart:io';

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
    final results = await _connectivity.checkConnectivity();
    final hasConn = _hasConnection(results);
    if (hasConn) return true;
    // Fallback: connectivity_plus can be unreliable on emulators,
    // so do a real DNS lookup to verify.
    return _realReachabilityCheck();
  }

  /// Performs a real DNS lookup to check if the device can reach the internet.
  Future<bool> _realReachabilityCheck() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );
  }
}
