class SyncConfig {
  final bool autoSyncOnReconnect;
  final bool syncImmediately;
  final Duration? autoSyncInterval;
  final int maxRetries;
  final Duration initialRetryDelay;
  final int maxConcurrentOperations;
  final bool enableMetrics;
  final bool enableDebugLogging;
  final bool syncOnWiFiOnly;
  final int maxQueueSize;

  const SyncConfig({
    this.autoSyncOnReconnect = true,
    this.syncImmediately = true,
    this.autoSyncInterval,
    this.maxRetries = 5,
    this.initialRetryDelay = const Duration(seconds: 2),
    this.maxConcurrentOperations = 3,
    this.enableMetrics = true,
    this.enableDebugLogging = false,
    this.syncOnWiFiOnly = false,
    this.maxQueueSize = 1000,
  });

  factory SyncConfig.defaultConfig() => const SyncConfig();

  factory SyncConfig.aggressive() => const SyncConfig(
        syncImmediately: true,
        autoSyncOnReconnect: true,
        maxRetries: 10,
        initialRetryDelay: Duration(seconds: 1),
        maxConcurrentOperations: 5,
      );

  factory SyncConfig.batteryFriendly() => const SyncConfig(
        autoSyncOnReconnect: true,
        syncImmediately: false,
        autoSyncInterval: Duration(minutes: 30),
        maxRetries: 3,
        initialRetryDelay: Duration(seconds: 5),
        maxConcurrentOperations: 1,
      );

  factory SyncConfig.wifiOnly() => const SyncConfig(
        syncOnWiFiOnly: true,
        autoSyncOnReconnect: true,
        syncImmediately: false,
        autoSyncInterval: Duration(minutes: 15),
      );

  SyncConfig copyWith({
    bool? autoSyncOnReconnect,
    bool? syncImmediately,
    Duration? autoSyncInterval,
    int? maxRetries,
    Duration? initialRetryDelay,
    int? maxConcurrentOperations,
    bool? enableMetrics,
    bool? enableDebugLogging,
    bool? syncOnWiFiOnly,
    int? maxQueueSize,
  }) {
    return SyncConfig(
      autoSyncOnReconnect:
          autoSyncOnReconnect ?? this.autoSyncOnReconnect,
      syncImmediately:
          syncImmediately ?? this.syncImmediately,
      autoSyncInterval:
          autoSyncInterval ?? this.autoSyncInterval,
      maxRetries: maxRetries ?? this.maxRetries,
      initialRetryDelay:
          initialRetryDelay ?? this.initialRetryDelay,
      maxConcurrentOperations: maxConcurrentOperations ??
          this.maxConcurrentOperations,
      enableMetrics: enableMetrics ?? this.enableMetrics,
      enableDebugLogging:
          enableDebugLogging ?? this.enableDebugLogging,
      syncOnWiFiOnly: syncOnWiFiOnly ?? this.syncOnWiFiOnly,
      maxQueueSize: maxQueueSize ?? this.maxQueueSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'autoSyncOnReconnect': autoSyncOnReconnect,
        'syncImmediately': syncImmediately,
        'autoSyncInterval': autoSyncInterval?.inSeconds,
        'maxRetries': maxRetries,
        'initialRetryDelayMs':
            initialRetryDelay.inMilliseconds,
        'maxConcurrentOperations': maxConcurrentOperations,
        'enableMetrics': enableMetrics,
        'enableDebugLogging': enableDebugLogging,
        'syncOnWiFiOnly': syncOnWiFiOnly,
        'maxQueueSize': maxQueueSize,
      };
}
