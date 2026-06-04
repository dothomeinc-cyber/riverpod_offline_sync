import 'package:riverpod_offline_sync/riverpod_offline_sync.dart';

class OfflineSyncInitializer {
  static bool _isInitialized = false;

  static Future<void> initialize(
      {SyncConfig? config}) async {
    if (_isInitialized) return;

    // Enable logging in debug mode
    OfflineLogger.isEnabled = true;

    await OfflineSyncLayer.instance
        .initialize(config: config);
    _isInitialized = true;
    OfflineLogger.info('OfflineSyncInitializer completed');
  }

  static bool get isInitialized => _isInitialized;

  static Future<void> reset() async {
    if (_isInitialized) {
      await OfflineSyncLayer.instance.dispose();
      _isInitialized = false;
    }
  }
}
