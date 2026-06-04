import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_offline_sync/src/queue/queue_manager.dart';
import 'package:riverpod_offline_sync/src/queue/queue_item.dart';
import 'package:riverpod_offline_sync/src/utils/riverpod_extensions.dart';
import 'sync_providers.dart';

final queueManagerProvider = Provider<QueueManager>((ref) {
  return QueueManager.instance;
});

final pendingItemsProvider =
    StreamProvider<List<QueueItem>>((ref) {
  final syncLayer = ref.watch(offlineSyncLayerProvider);
  return syncLayer.queueManager.queueStream;
});

final pendingItemsCountProvider = Provider<int>((ref) {
  final itemsAsync = ref.watch(pendingItemsProvider);
  final items = itemsAsync.valueOrNull;
  return items?.length ?? 0;
});

final queueBreakdownProvider =
    Provider<Map<String, int>>((ref) {
  final itemsAsync = ref.watch(pendingItemsProvider);
  final items = itemsAsync.valueOrNull ?? [];
  final breakdown = <String, int>{};
  for (final item in items) {
    breakdown[item.category] =
        (breakdown[item.category] ?? 0) + 1;
  }
  return breakdown;
});
