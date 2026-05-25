import 'dart:async';
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
  // ignore: unused_field
  late ConflictResolver _conflictResolver;
  late SyncConfig _config;
  late SyncMetrics _metrics;
  late SyncStateMachine _stateMachine;

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
    _queueManager = QueueManager();
    _connectivityMonitor = ConnectivityMonitor();
    _conflictResolver = ConflictResolver();
    _metrics = SyncMetrics();
    _stateMachine = SyncStateMachine();

    await _queueManager.initialize(
        maxQueueSize: _config.maxQueueSize);
    await _connectivityMonitor.initialize();
    await _metrics.init();

    _setupListeners();
    _isInitialized = true;
    OfflineLogger.info('OfflineSyncLayer initialized');
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
        OfflineLogger.debug('Sync skipped - WiFi only');
        return false;
      }
    }
    return true;
  }

  Future<void> sync(
      {SyncStrategyType strategy =
          SyncStrategyType.auto}) async {
    if (!_isInitialized)
      throw Exception('Sync layer not initialized');
    if (!await _shouldSyncBasedOnWiFi()) return;

    await _syncMutex.synchronized(() async {
      if (_isSyncing) return;

      _isSyncing = true;
      _stateMachine.transitionTo(SyncMachineState.checking);
      _syncStateController.add(SyncStateType.syncing);

      try {
        _stateMachine
            .transitionTo(SyncMachineState.pulling);
        await _pushChanges();

        if (strategy != SyncStrategyType.pushOnly) {
          _stateMachine
              .transitionTo(SyncMachineState.pushing);
          await _pullChanges();
        }

        _stateMachine
            .transitionTo(SyncMachineState.completing);
        _syncStateController.add(SyncStateType.completed);
        _metrics.recordSuccess();
        _stateMachine.transitionTo(SyncMachineState.idle);
        OfflineLogger.info('Sync completed');
      } catch (e) {
        _stateMachine.transitionTo(SyncMachineState.failed);
        _syncStateController.add(SyncStateType.failed);
        _metrics.recordFailure(e.toString());
        OfflineLogger.error('Sync failed', error: e);
      } finally {
        _isSyncing = false;
      }
    });
  }

  Future<void> _pushChanges() async {
    await _queueManager.processQueue(
        maxConcurrent: _config.maxConcurrentOperations);
  }

  Future<void> _pullChanges() async {
    _syncProgressController.add(SyncProgress(
      current: 0,
      total: 0,
      currentOperation: 'Pulling latest data...',
    ));
    await Future.delayed(Duration(milliseconds: 500));
  }

  Future<void> submitOperation({
    required String category,
    required int priority,
    required Map<String, dynamic> data,
    String? idempotencyKey,
  }) async {
    if (!_isInitialized)
      throw Exception('Sync layer not initialized');

    await _queueManager.enqueue(
      category: category,
      priority: priority,
      data: data,
      idempotencyKey:
          idempotencyKey ?? IdempotencyKey.generate(),
    );

    OfflineLogger.info('Operation enqueued: $category');

    if (_connectivityMonitor.isConnected &&
        _config.syncImmediately) {
      sync();
    }
  }

  void registerOperationHandler(String category,
      Future<void> Function(Map<String, dynamic>) handler) {
    _queueManager.registerHandler(category, handler);
    OfflineLogger.info('Handler registered: $category');
  }

  Future<List<Map<String, dynamic>>>
      getPendingOperations() async {
    final items = await _queueManager.getPendingItems();
    return items.map((e) => e.toJson()).toList();
  }

  Future<int> getPendingCount() async {
    final items = await _queueManager.getPendingItems();
    return items.length;
  }

  Future<void> clearQueue() async {
    await _queueManager.clearQueue();
    OfflineLogger.info('Queue cleared');
  }

  Future<void> retryFailedOperation(String id) async {
    await _queueManager.retryFailed(id);
    OfflineLogger.info('Retrying: $id');
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
