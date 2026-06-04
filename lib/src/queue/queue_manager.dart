// lib/src/queue/queue_manager.dart
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'queue_item.dart';
import 'queue_stats.dart';
import 'hive_registry.dart';
import 'retry_strategy.dart';
import '../utils/logger.dart';

typedef OperationHandler = Future<void> Function(
    Map<String, dynamic> data);

class QueueManager {
  static final QueueManager _instance =
      QueueManager._internal();
  static QueueManager get instance => _instance;

  QueueManager._internal();

  static const String _boxName = 'offline_queue';
  late Box<QueueItem> _box;
  bool _isProcessing = false;
  bool _isInitialized = false;
  final _queueStreamController =
      StreamController<List<QueueItem>>.broadcast();
  final Map<String, OperationHandler> _handlers = {};
  final RetryStrategy _retryStrategy =
      const RetryStrategy();
  int _maxQueueSize = 1000;

  Future<void> initialize({int maxQueueSize = 1000}) async {
    if (_isInitialized) return;

    _maxQueueSize = maxQueueSize;
    await Hive.initFlutter();
    HiveRegistry.ensureRegistered();
    _box = await Hive.openBox<QueueItem>(_boxName);
    _isInitialized = true;
    OfflineLogger.info(
        'QueueManager initialized with max size: $_maxQueueSize');
  }

  void registerHandler(
      String category, OperationHandler handler) {
    _handlers[category] = handler;
    OfflineLogger.debug(
        'Handler registered for: $category');
  }

  Future<void> enqueue({
    required String category,
    required int priority,
    required Map<String, dynamic> data,
    required String idempotencyKey,
  }) async {
    if (!_isInitialized) {
      throw Exception('QueueManager not initialized');
    }

    if (_box.length >= _maxQueueSize) {
      OfflineLogger.warning(
          'Queue full, dropping oldest items');
      await _trimQueue();
    }

    final existing =
        await _findByIdempotencyKey(idempotencyKey);
    if (existing != null) {
      OfflineLogger.debug(
          'Duplicate operation prevented: $idempotencyKey');
      return;
    }

    // Use the create factory method from QueueItem
    final item = QueueItem.create(
      category: category,
      priority: priority,
      data: data,
      idempotencyKey: idempotencyKey,
    );

    await _box.put(item.id, item);
    _queueStreamController.add(await getPendingItems());
    OfflineLogger.debug(
        'Item enqueued: ${item.id} (${item.category})');
  }

  // UPDATED: Better trimming logic
  Future<void> _trimQueue() async {
    final items = _box.values.toList();
    if (items.length >= _maxQueueSize) {
      // Sort by priority (lower number = higher priority) and then by creation time
      items.sort((a, b) {
        final priorityCompare =
            a.priority.compareTo(b.priority);
        if (priorityCompare != 0) return priorityCompare;
        return a.createdAt.compareTo(b.createdAt);
      });

      // Keep higher priority items (first half), remove lower priority ones (second half)
      final toRemove = items.sublist(_maxQueueSize ~/ 2);
      for (final item in toRemove) {
        await _box.delete(item.id);
        OfflineLogger.warning(
            'Dropped item: ${item.id} due to queue full');
      }
    }
  }

  Future<QueueItem?> _findByIdempotencyKey(
      String key) async {
    for (var item in _box.values) {
      if (item.idempotencyKey == key) {
        return item;
      }
    }
    return null;
  }

  Future<List<QueueItem>> getPendingItems() async {
    if (!_isInitialized) return [];

    final items = _box.values.toList();

    final readyItems = items.where((item) {
      if (item.nextRetryAt == null) return true;
      return item.nextRetryAt!.isBefore(DateTime.now());
    }).toList();

    readyItems.sort((a, b) {
      final priorityCompare =
          a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.createdAt.compareTo(b.createdAt);
    });
    return readyItems;
  }

  Future<int> getPendingCount() async {
    final items = await getPendingItems();
    return items.length;
  }

  // NEW: Get queue statistics
  Future<QueueStats> getQueueStats() async {
    final items = _box.values.toList();
    final now = DateTime.now();

    int failedCount = 0;
    int retryingCount = 0;
    DateTime? oldestCreatedAt;
    final categoryBreakdown = <String, int>{};
    final priorityBreakdown = <int, int>{};

    for (final item in items) {
      // Count failed (retryCount > 0 and no nextRetryAt means failed)
      if (item.retryCount > 0 && item.nextRetryAt == null) {
        failedCount++;
      }
      // Count retrying
      if (item.nextRetryAt != null &&
          item.nextRetryAt!.isAfter(now)) {
        retryingCount++;
      }
      // Track oldest
      if (oldestCreatedAt == null ||
          item.createdAt.isBefore(oldestCreatedAt)) {
        oldestCreatedAt = item.createdAt;
      }
      // Breakdown by category
      categoryBreakdown[item.category] =
          (categoryBreakdown[item.category] ?? 0) + 1;
      // Breakdown by priority
      priorityBreakdown[item.priority] =
          (priorityBreakdown[item.priority] ?? 0) + 1;
    }

    return QueueStats(
      pendingCount: items.length,
      failedCount: failedCount,
      retryingCount: retryingCount,
      oldestItemAge: oldestCreatedAt != null
          ? now.difference(oldestCreatedAt)
          : Duration.zero,
      categoryBreakdown: categoryBreakdown,
      priorityBreakdown: priorityBreakdown,
    );
  }

  Future<void> processQueue({int maxConcurrent = 3}) async {
    if (!_isInitialized) {
      throw Exception('QueueManager not initialized');
    }
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      final items = await getPendingItems();
      final batches = <List<QueueItem>>[];
      for (var i = 0;
          i < items.length;
          i += maxConcurrent) {
        batches.add(items.sublist(
            i,
            i + maxConcurrent > items.length
                ? items.length
                : i + maxConcurrent));
      }

      for (final batch in batches) {
        await Future.wait(
            batch.map((item) => processItem(item)));
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> processItem(QueueItem item) async {
    try {
      final handler = _handlers[item.category];
      if (handler == null) {
        throw Exception(
            'No handler registered for category: ${item.category}');
      }

      await handler(item.data);
      await _box.delete(item.id);
      _queueStreamController.add(await getPendingItems());
      OfflineLogger.debug(
          'Item processed successfully: ${item.id}');
    } catch (e) {
      item.retryCount++;
      item.lastError = e.toString();

      final shouldRetry = _retryStrategy.shouldRetry(
          item.retryCount, e, null);
      if (shouldRetry) {
        final delay =
            _retryStrategy.getDelay(item.retryCount);
        item.nextRetryAt = DateTime.now().add(delay);
        await _box.put(item.id, item);
        OfflineLogger.warning(
            'Item ${item.id} failed, retry ${item.retryCount} scheduled in ${delay.inSeconds}s');
      } else {
        await _box.delete(item.id);
        OfflineLogger.error(
            'Item ${item.id} dropped after ${item.retryCount} retries',
            error: e);
      }

      rethrow;
    }
  }

  Future<void> retryFailed(String id) async {
    final item = _box.get(id);
    if (item != null) {
      item.retryCount = 0;
      item.nextRetryAt = null;
      await _box.put(id, item);
      await processItem(item);
    }
  }

  Future<void> clearQueue() async {
    await _box.clear();
    _queueStreamController.add([]);
    OfflineLogger.info('Queue cleared');
  }

  Stream<List<QueueItem>> get queueStream =>
      _queueStreamController.stream;
  int get queueSize => _box.length;
  bool get isInitialized => _isInitialized;

  Future<void> dispose() async {
    await _queueStreamController.close();
    await _box.close();
  }
}
