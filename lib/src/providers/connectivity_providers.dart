import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_offline_sync/src/connectivity/connectivity_monitor.dart';

final connectivityMonitorProvider =
    Provider<ConnectivityMonitor>((ref) {
  final monitor = ConnectivityMonitor();

  ref.onDispose(() {
    monitor.dispose();
  });

  monitor.initialize();
  return monitor;
});

final connectivityStatusProvider =
    StreamProvider<bool>((ref) {
  final monitor = ref.watch(connectivityMonitorProvider);
  return monitor.onConnectivityChanged;
});

final isConnectedProvider = Provider<bool>((ref) {
  final monitor = ref.watch(connectivityMonitorProvider);
  return monitor.isConnected;
});
