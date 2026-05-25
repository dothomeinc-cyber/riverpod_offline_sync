import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityMonitor {
  final Connectivity _connectivity = Connectivity();
  final _connectivityController =
      StreamController<bool>.broadcast();
  bool _isConnected = true;
  late StreamSubscription<List<ConnectivityResult>>
      _subscription;

  Future<void> initialize() async {
    _subscription = _connectivity.onConnectivityChanged
        .listen(_handleConnectivityChange);
    await _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final result = await _connectivity.checkConnectivity();
    _isConnected = result.isNotEmpty &&
        result.first != ConnectivityResult.none;
    _connectivityController.add(_isConnected);
  }

  void _handleConnectivityChange(
      List<ConnectivityResult> results) {
    _isConnected = results.isNotEmpty &&
        results.first != ConnectivityResult.none;
    _connectivityController.add(_isConnected);
  }

  Stream<bool> get onConnectivityChanged =>
      _connectivityController.stream;
  bool get isConnected => _isConnected;

  Future<bool> get isWifiConnected async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.wifi);
  }

  void dispose() {
    _subscription.cancel();
    _connectivityController.close();
  }
}
