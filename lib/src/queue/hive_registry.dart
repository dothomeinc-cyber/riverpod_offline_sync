import 'package:hive/hive.dart';
import 'queue_item_adapter.dart';

class HiveRegistry {
  static bool _isRegistered = false;

  static void ensureRegistered() {
    if (!_isRegistered) {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(QueueItemAdapter());
      }
      _isRegistered = true;
    }
  }
}
