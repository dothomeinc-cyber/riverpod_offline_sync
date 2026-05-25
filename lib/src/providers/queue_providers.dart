import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_offline_sync/src/queue/queue_manager.dart';
import 'package:riverpod_offline_sync/src/queue/queue_item.dart';
import 'package:riverpod_offline_sync/src/utils/riverpod_extensions.dart';

final queueManagerProvider = Provider<QueueManager>((ref) {
  final manager = QueueManager();
  manager.initialize();
  return manager;
});

final pendingItemsProvider =
    StreamProvider<List<QueueItem>>((ref) {
  final manager = ref.watch(queueManagerProvider);
  return manager.queueStream;
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
