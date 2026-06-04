// lib/src/core/sync_observer.dart
// import 'sync_layer.dart';

/// Observer interface for sync events
abstract class SyncObserver {
  void onSyncStarted() {}
  void onSyncCompleted() {}
  void onSyncFailed(Object error) {}
  void onProgressChanged(int current, int total) {}
  void onItemProcessed(String itemId, bool success) {}
}

/// Manages sync observers
class SyncObserverManager {
  final List<SyncObserver> _observers = [];

  void addObserver(SyncObserver observer) {
    _observers.add(observer);
  }

  void removeObserver(SyncObserver observer) {
    _observers.remove(observer);
  }

  void notifySyncStarted() {
    for (final observer in _observers) {
      observer.onSyncStarted();
    }
  }

  void notifySyncCompleted() {
    for (final observer in _observers) {
      observer.onSyncCompleted();
    }
  }

  void notifySyncFailed(Object error) {
    for (final observer in _observers) {
      observer.onSyncFailed(error);
    }
  }

  void notifyProgressChanged(int current, int total) {
    for (final observer in _observers) {
      observer.onProgressChanged(current, total);
    }
  }

  void notifyItemProcessed(String itemId, bool success) {
    for (final observer in _observers) {
      observer.onItemProcessed(itemId, success);
    }
  }
}
