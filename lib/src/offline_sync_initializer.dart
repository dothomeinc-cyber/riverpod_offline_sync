import 'package:riverpod_offline_sync/riverpod_offline_sync.dart';

class OfflineSyncInitializer {
  static bool _isInitialized = false;

  static Future<void> initialize(
      {SyncConfig? config}) async {
    if (_isInitialized) return;
    await OfflineSyncLayer.instance
        .initialize(config: config);
    _isInitialized = true;
    OfflineLogger.info('OfflineSyncInitializer completed');
  }

  static bool get isInitialized => _isInitialized;
}
