import 'package:flutter/material.dart';
import '../core/sync_layer.dart';
import '../queue/queue_category.dart';
import '../queue/queue_priority.dart';
import '../utils/logger.dart';

mixin SyncAwareMixin<T extends StatefulWidget> on State<T> {
  late OfflineSyncLayer syncLayer;

  @override
  void initState() {
    super.initState();
    syncLayer = OfflineSyncLayer.instance;
  }

  Future<void> submitOffline({
    required String category,
    required int priority,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) async {
    try {
      await syncLayer.submitOperation(
        category: category,
        priority: priority,
        data: data,
        idempotencyKey: idempotencyKey,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Saved offline. Will sync when online.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      OfflineLogger.error('Failed to submit operation',
          error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> submitOrder(
      Map<String, dynamic> orderData) async {
    await submitOffline(
      category: QueueCategory.orders.label,
      priority: QueuePriority.high.value,
      data: orderData,
    );
  }

  Future<void> uploadFile(
      Map<String, dynamic> fileData) async {
    await submitOffline(
      category: QueueCategory.uploads.label,
      priority: QueuePriority.normal.value,
      data: fileData,
    );
  }

  Future<void> sendMessage(
      Map<String, dynamic> messageData) async {
    await submitOffline(
      category: QueueCategory.messages.label,
      priority: QueuePriority.high.value,
      data: messageData,
    );
  }

  Future<void> trackAnalytics(
      Map<String, dynamic> analyticsData) async {
    await submitOffline(
      category: QueueCategory.analytics.label,
      priority: QueuePriority.low.value,
      data: analyticsData,
    );
  }

  Future<void> triggerSync() async {
    await syncLayer.sync();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync triggered'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>>
      getPendingOperations() async {
    return await syncLayer.getPendingOperations();
  }

  Future<int> getPendingCount() async {
    return await syncLayer.getPendingCount();
  }

  Future<void> clearQueue() async {
    await syncLayer.clearQueue();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Queue cleared'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  bool get isSyncing => syncLayer.isSyncing;
  bool get isInitialized => syncLayer.isInitialized;
  bool get isConnected =>
      syncLayer.connectivityMonitor.isConnected;
}
