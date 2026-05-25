import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

class SyncMetrics {
  static const String _metricsBox = 'sync_metrics';
  late Box _box;

  int totalSyncs = 0;
  int successfulSyncs = 0;
  int failedSyncs = 0;
  String? lastError;
  DateTime? lastSyncTime;
  DateTime? firstSyncTime;
  Duration averageSyncDuration = Duration.zero;
  final List<Duration> _syncDurations = [];
  final _syncEventsController =
      StreamController<SyncEvent>.broadcast();

  Future<void> init() async {
    _box = await Hive.openBox(_metricsBox);
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    totalSyncs = _box.get('totalSyncs', defaultValue: 0);
    successfulSyncs =
        _box.get('successfulSyncs', defaultValue: 0);
    failedSyncs = _box.get('failedSyncs', defaultValue: 0);
    lastError = _box.get('lastError');
    final lastSyncTimeStr = _box.get('lastSyncTime');
    lastSyncTime = lastSyncTimeStr != null
        ? DateTime.parse(lastSyncTimeStr)
        : null;
    final firstSyncTimeStr = _box.get('firstSyncTime');
    firstSyncTime = firstSyncTimeStr != null
        ? DateTime.parse(firstSyncTimeStr)
        : null;
  }

  Future<void> _saveToStorage() async {
    await _box.put('totalSyncs', totalSyncs);
    await _box.put('successfulSyncs', successfulSyncs);
    await _box.put('failedSyncs', failedSyncs);
    await _box.put('lastError', lastError);
    await _box.put(
        'lastSyncTime', lastSyncTime?.toIso8601String());
    await _box.put(
        'firstSyncTime', firstSyncTime?.toIso8601String());
  }

  void recordSuccess() {
    totalSyncs++;
    successfulSyncs++;
    lastSyncTime = DateTime.now();
    firstSyncTime ??= lastSyncTime;
    _syncEventsController.add(SyncEvent.success);
    _saveToStorage();
  }

  void recordFailure(String error) {
    totalSyncs++;
    failedSyncs++;
    lastError = error;
    lastSyncTime = DateTime.now();
    firstSyncTime ??= lastSyncTime;
    _syncEventsController.add(SyncEvent.failure);
    _saveToStorage();
  }

  void recordDuration(Duration duration) {
    _syncDurations.add(duration);
    if (_syncDurations.length > 10) {
      _syncDurations.removeAt(0);
    }
    if (_syncDurations.isNotEmpty) {
      averageSyncDuration =
          _syncDurations.reduce((a, b) => a + b) ~/
              _syncDurations.length;
    }
  }

  void reset() {
    totalSyncs = 0;
    successfulSyncs = 0;
    failedSyncs = 0;
    lastError = null;
    lastSyncTime = null;
    firstSyncTime = null;
    averageSyncDuration = Duration.zero;
    _syncDurations.clear();
    _saveToStorage();
  }

  double get successRate {
    if (totalSyncs == 0) return 0.0;
    return successfulSyncs / totalSyncs;
  }

  String get successRatePercentage =>
      '${(successRate * 100).toStringAsFixed(1)}%';

  Stream<SyncEvent> get syncEvents =>
      _syncEventsController.stream;

  Map<String, dynamic> toJson() => {
        'totalSyncs': totalSyncs,
        'successfulSyncs': successfulSyncs,
        'failedSyncs': failedSyncs,
        'lastError': lastError,
        'lastSyncTime': lastSyncTime?.toIso8601String(),
        'firstSyncTime': firstSyncTime?.toIso8601String(),
        'averageSyncDurationMs':
            averageSyncDuration.inMilliseconds,
        'successRate': successRate,
        'successRatePercentage': successRatePercentage,
      };

  void dispose() {
    _syncEventsController.close();
  }
}

enum SyncEvent { success, failure }

extension SyncEventExtension on SyncEvent {
  String get label {
    switch (this) {
      case SyncEvent.success:
        return 'Success';
      case SyncEvent.failure:
        return 'Failure';
    }
  }

  bool get isSuccess => this == SyncEvent.success;
  bool get isFailure => this == SyncEvent.failure;

  String get icon {
    switch (this) {
      case SyncEvent.success:
        return '✅';
      case SyncEvent.failure:
        return '❌';
    }
  }
}
