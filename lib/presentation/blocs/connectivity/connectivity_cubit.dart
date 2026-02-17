import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled1/core/network/connectivity_checker.dart';

/// Cubit that monitors internet connectivity status.
/// Emits true when connected, false when disconnected.
class ConnectivityCubit extends Cubit<bool> {
  final ConnectivityChecker connectivityChecker;
  StreamSubscription<bool>? _subscription;

  ConnectivityCubit({required this.connectivityChecker}) : super(true) {
    _init();
  }

  Future<void> _init() async {
    // Check initial status
    final isConnected = await connectivityChecker.isConnected;
    emit(isConnected);

    // Listen for changes
    _subscription = connectivityChecker.onConnectivityChanged.listen(
      (isConnected) => emit(isConnected),
    );
  }

  Future<void> checkConnectivity() async {
    final isConnected = await connectivityChecker.isConnected;
    emit(isConnected);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
