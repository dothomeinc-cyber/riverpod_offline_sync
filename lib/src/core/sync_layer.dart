// lib/src/core/sync_layer.dart
import 'dart:async';
import 'package:riverpod_offline_sync/riverpod_offline_sync.dart';
import 'package:synchronized/synchronized.dart';
import 'package:riverpod_offline_sync/src/queue/queue_manager.dart';
import 'package:riverpod_offline_sync/src/connectivity/connectivity_monitor.dart';
import 'package:riverpod_offline_sync/src/core/sync_config.dart';
import 'package:riverpod_offline_sync/src/core/sync_metrics.dart';
import 'package:riverpod_offline_sync/src/core/sync_progress.dart';
import 'package:riverpod_offline_sync/src/core/sync_state_machine.dart';
import 'package:riverpod_offline_sync/src/conflict/conflict_resolver.dart';
import 'package:riverpod_offline_sync/src/utils/idempotency_key.dart';
import 'package:riverpod_offline_sync/src/utils/logger.dart';

// Import the observer from a separate file to avoid duplication
// If you haven't created the separate file yet, we'll define it conditionally
export 'sync_observer.dart';

enum SyncStateType { idle, syncing, completed, failed }

enum SyncStrategyType {
  auto,
  manual,
  background,
  pushOnly,
  pullOnly
}

class OfflineSyncLayer {
  static final OfflineSyncLayer _instance =
      OfflineSyncLayer._internal();
  static OfflineSyncLayer get instance => _instance;

  late QueueManager _queueManager;
  late ConnectivityMonitor _connectivityMonitor;
  late ConflictResolver _conflictResolver;
  late SyncConfig _config;
  late SyncMetrics _metrics;
  late SyncStateMachine _stateMachine;

  // Add observer manager
  late SyncObserverManager _observerManager;

  final _syncStateController =
      StreamController<SyncStateType>.broadcast();
  final _syncProgressController =
      StreamController<SyncProgress>.broadcast();

  bool _isInitialized = false;
  bool _isSyncing = false;
  final Lock _syncMutex = Lock();
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _autoSyncTimer;

  OfflineSyncLayer._internal();

  Future<void> initialize({SyncConfig? config}) async {
    if (_isInitialized) return;

    _config = config ?? SyncConfig.defaultConfig();
    _queueManager = QueueManager.instance;
    _connectivityMonitor = ConnectivityMonitor();
    _conflictResolver = ConflictResolver();
    _metrics = SyncMetrics();
    _stateMachine = SyncStateMachine();
    _observerManager =
        SyncObserverManager(); // Initialize observer manager

    await _queueManager.initialize(
        maxQueueSize: _config.maxQueueSize);
    await _connectivityMonitor.initialize();
    await _metrics.init();

    _setupListeners();
    _isInitialized = true;
    OfflineLogger.info(
        'OfflineSyncLayer initialized with config: ${_config.toJson()}');
  }

  // Observer management methods
  void addObserver(SyncObserver observer) {
    _observerManager.addObserver(observer);
  }

  void removeObserver(SyncObserver observer) {
    _observerManager.removeObserver(observer);
  }

  void _setupListeners() {
    _connectivitySubscription = _connectivityMonitor
        .onConnectivityChanged
        .listen((isConnected) {
      if (isConnected && _config.autoSyncOnReconnect) {
        sync();
      }
    });

    if (_config.autoSyncInterval != null) {
      _autoSyncTimer =
          Timer.periodic(_config.autoSyncInterval!, (_) {
        if (_connectivityMonitor.isConnected) {
          sync();
        }
      });
    }
  }

  Future<bool> _shouldSyncBasedOnWiFi() async {
    if (_config.syncOnWiFiOnly) {
      final isWifi =
          await _connectivityMonitor.isWifiConnected;
      if (!isWifi) {
        OfflineLogger.debug(
            'Sync skipped - WiFi only mode and not on WiFi');
        return false;
      }
    }
    return true;
  }

  Future<void> sync(
      {SyncStrategyType strategy =
          SyncStrategyType.auto}) async {
    if (!_isInitialized) {
      throw Exception('Sync layer not initialized');
    }

    if (!await _shouldSyncBasedOnWiFi()) return;

    await _syncMutex.synchronized(() async {
      if (_isSyncing) return;

      _isSyncing = true;
      _observerManager
          .notifySyncStarted(); // Notify observers
      _stateMachine.transitionTo(SyncMachineState.checking);
      _syncStateController.add(SyncStateType.syncing);

      try {
        // Push phase
        if (strategy != SyncStrategyType.pullOnly) {
          _stateMachine
              .transitionTo(SyncMachineState.pushing);
          await _pushChanges();
        }

        // Pull phase
        if (strategy != SyncStrategyType.pushOnly) {
          _stateMachine
              .transitionTo(SyncMachineState.pulling);
          await _pullChanges();
        }

        // Complete
        _stateMachine
            .transitionTo(SyncMachineState.completing);
        _syncStateController.add(SyncStateType.completed);
        _metrics.recordSuccess();
        _stateMachine.transitionTo(SyncMachineState.idle);
        _observerManager
            .notifySyncCompleted(); // Notify observers
        OfflineLogger.info('Sync completed successfully');
      } catch (e) {
        _stateMachine.transitionTo(SyncMachineState.failed);
        _syncStateController.add(SyncStateType.failed);
        _metrics.recordFailure(e.toString());
        _observerManager
            .notifySyncFailed(e); // Notify observers
        OfflineLogger.error('Sync failed', error: e);
      } finally {
        _isSyncing = false;
      }
    });
  }

  Future<void> _pushChanges() async {
    final pendingCount =
        await _queueManager.getPendingCount();

    OfflineLogger.debug(
        'Pushing local changes to server...');
    _syncProgressController.add(SyncProgress(
      current: 0,
      total: pendingCount,
      currentOperation: 'Pushing local changes...',
    ));
    _observerManager.notifyProgressChanged(
        0, pendingCount); // Notify observers

    if (pendingCount > 0) {
      await _queueManager.processQueue(
          maxConcurrent: _config.maxConcurrentOperations);
    }

    _observerManager.notifyProgressChanged(
        pendingCount, pendingCount); // Notify observers
    OfflineLogger.debug('Push completed');
  }

  Future<void> _pullChanges() async {
    final lastSyncTime = _metrics.lastSyncTime ??
        DateTime.now().subtract(const Duration(days: 1));

    _syncProgressController.add(SyncProgress(
      current: 0,
      total: 0,
      currentOperation: 'Checking for remote changes...',
    ));

    OfflineLogger.debug(
        'Pulling remote changes since $lastSyncTime');

    // Fetch remote changes from your API
    final remoteChanges =
        await _fetchRemoteChanges(lastSyncTime);

    if (remoteChanges.isEmpty) {
      _syncProgressController.add(SyncProgress(
        current: 1,
        total: 1,
        currentOperation: 'No changes to pull',
      ));
      OfflineLogger.debug('No remote changes found');
      return;
    }

    final total = remoteChanges.length;
    var current = 0;

    for (final change in remoteChanges) {
      current++;
      _syncProgressController.add(SyncProgress(
        current: current,
        total: total,
        currentOperation:
            'Syncing ${change['id'] ?? 'item'}',
      ));
      _observerManager.notifyProgressChanged(
          current, total); // Notify observers

      // Get local version
      final localData = await _getLocalData(
          change['collection'], change['id']);

      if (localData != null) {
        // Resolve conflicts
        OfflineLogger.debug(
            'Conflict detected for ${change['id']}, resolving...');
        final resolved = await _conflictResolver.resolve(
          local: localData,
          remote: change['data'],
          strategy: _config.conflictStrategy ??
              ConflictStrategy.lastWriteWins,
          localTimestamp: localData['updatedAt'] != null
              ? DateTime.tryParse(localData['updatedAt'])
              : null,
          remoteTimestamp:
              change['data']['updatedAt'] != null
                  ? DateTime.tryParse(
                      change['data']['updatedAt'])
                  : null,
        );

        await _applyRemoteData(
            change['collection'], change['id'], resolved);
        _observerManager.notifyItemProcessed(
            change['id'], true); // Notify observers
      } else {
        // No conflict, just apply
        await _applyRemoteData(change['collection'],
            change['id'], change['data']);
        _observerManager.notifyItemProcessed(
            change['id'], true); // Notify observers
      }
    }

    OfflineLogger.debug(
        'Pull completed, synced $total items');
  }

  // Override these methods based on your backend implementation

  Future<List<Map<String, dynamic>>> _fetchRemoteChanges(
      DateTime since) async {
    // TODO: Implement actual API call to fetch changes since timestamp
    return [];
  }

  Future<Map<String, dynamic>?> _getLocalData(
      String collection, String id) async {
    // TODO: Implement local data retrieval
    return null;
  }

  Future<void> _applyRemoteData(String collection,
      String id, Map<String, dynamic> data) async {
    // TODO: Implement data application logic
  }

  Future<void> submitOperation({
    required String category,
    required int priority,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) async {
    if (!_isInitialized) {
      throw Exception('Sync layer not initialized');
    }

    await _queueManager.enqueue(
      category: category,
      priority: priority,
      data: data,
      idempotencyKey:
          idempotencyKey ?? IdempotencyKey.generate(),
    );

    OfflineLogger.info(
        'Operation enqueued: $category (priority: $priority)');

    if (_connectivityMonitor.isConnected &&
        _config.syncImmediately) {
      await _shouldSyncBasedOnWiFi();
      unawaited(sync());
    }
  }

  void registerOperationHandler(String category,
      Future<void> Function(Map<String, dynamic>) handler) {
    _queueManager.registerHandler(category, handler);
    OfflineLogger.info(
        'Handler registered for category: $category');
  }

  Future<List<Map<String, dynamic>>>
      getPendingOperations() async {
    final items = await _queueManager.getPendingItems();
    return items.map((e) => e.toJson()).toList();
  }

  Future<int> getPendingCount() async {
    return await _queueManager.getPendingCount();
  }

  Future<void> clearQueue() async {
    await _queueManager.clearQueue();
    OfflineLogger.info('Queue cleared');
  }

  Future<void> retryFailedOperation(String id) async {
    await _queueManager.retryFailed(id);
    OfflineLogger.info('Retrying operation: $id');
  }

  Stream<SyncStateType> get syncState =>
      _syncStateController.stream;
  Stream<SyncProgress> get syncProgress =>
      _syncProgressController.stream;
  bool get isSyncing => _isSyncing;
  bool get isInitialized => _isInitialized;
  QueueManager get queueManager => _queueManager;
  SyncMetrics get metrics => _metrics;
  SyncStateMachine get stateMachine => _stateMachine;
  ConnectivityMonitor get connectivityMonitor =>
      _connectivityMonitor;
  SyncConfig get config => _config;

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _autoSyncTimer?.cancel();
    await _syncStateController.close();
    await _syncProgressController.close();
    await _queueManager.dispose();
    _connectivityMonitor.dispose();
    _metrics.dispose();
    _stateMachine.dispose();
    OfflineLogger.info('OfflineSyncLayer disposed');
  }
}
