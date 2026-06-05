// sync_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_offline_sync/riverpod_offline_sync.dart';
import 'package:riverpod_offline_sync/src/core/sync_layer.dart';
import 'package:riverpod_offline_sync/src/core/sync_metrics.dart';
import 'package:riverpod_offline_sync/src/core/sync_progress.dart';
import 'package:riverpod_offline_sync/src/utils/riverpod_extensions.dart';

final offlineSyncLayerProvider =
    Provider<OfflineSyncLayer>((ref) {
  return OfflineSyncLayer.instance;
});

final syncStateProvider =
    StreamProvider<SyncStateType>((ref) {
  final syncLayer = ref.watch(offlineSyncLayerProvider);
  return syncLayer.syncState;
});

final syncProgressProvider =
    StreamProvider<SyncProgress?>((ref) {
  final syncLayer = ref.watch(offlineSyncLayerProvider);
  return syncLayer.syncProgress;
});

final isSyncingProvider = Provider<bool>((ref) {
  final syncLayer = ref.watch(offlineSyncLayerProvider);
  return syncLayer.isSyncing;
});

final syncMetricsProvider = Provider<SyncMetrics>((ref) {
  final syncLayer = ref.watch(offlineSyncLayerProvider);
  return syncLayer.metrics;
});

final syncStatusTextProvider = Provider<String>((ref) {
  final syncState = ref.watch(syncStateProvider);
  final syncStateValue = syncState.valueOrNull; // Built-in
  if (syncStateValue == SyncStateType.syncing) {
    return 'Syncing...';
  }
  if (syncStateValue == SyncStateType.completed) {
    return 'Sync Complete';
  }
  if (syncStateValue == SyncStateType.failed) {
    return 'Sync Failed';
  }
  return 'Idle';
});
