import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_offline_sync/src/connectivity/connectivity_monitor.dart';
import 'sync_providers.dart';

// FIX: Read from sync layer instead of creating new instance
final connectivityMonitorProvider =
    Provider<ConnectivityMonitor>((ref) {
  final syncLayer = ref.watch(offlineSyncLayerProvider);
  return syncLayer.connectivityMonitor;
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
