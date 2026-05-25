# Changelog

## 1.0.0

### 🚀 New Features
- Added `OfflineSyncInitializer` for safe, race-condition-free initialization
- Added `syncStatusTextProvider` for UI-friendly sync status text
- Added `valueOrNull`, `isLoading`, `hasError`, `errorValue` extensions to `AsyncValue`
- Added `SyncMachineState.isPulling` and `isPushing` getters
- Added `OfflineLogger` for production-ready logging

### 🐛 Bug Fixes
- Fixed race condition in provider initialization (QueueManager, ConnectivityMonitor)
- Fixed duplicate listener registration in `OfflineToast`
- Fixed `DebugPanel` extension constructor error (now uses properties directly)
- Fixed `IdempotencyKey.isValid()` to handle both pure UUID and composite keys
- Fixed `SyncStateMachine` state transition flow (pull → push, not push → pull)
- Fixed `FirestoreSync` to use `OfflineLogger` instead of `print()`
- Fixed memory leak by adding proper `ref.onDispose` in providers

### 🔧 Improvements
- Replaced `print()` statements with `OfflineLogger` throughout the package
- Added `maxQueueSize` enforcement with automatic queue trimming
- Added `syncOnWiFiOnly` constraint checking before sync operations
- Added `maxConcurrentOperations` support for batch queue processing
- Added deep merge for conflict resolution (nested maps and lists)
- Added pause/resume/cancel support for `StorageQueue` uploads
- Improved error messages and logging context

### ⚠️ Breaking Changes
- **Removed `riverpod_offline_sync_base.dart`** - Use `OfflineSyncInitializer` instead
- **Removed `QueueStore`** - Functionality merged into `QueueManager` (redundant)
- **Provider types changed** - `queueManagerProvider` and `connectivityMonitorProvider` now use `FutureProvider`
- **Must call `OfflineSyncInitializer.initialize()` before `runApp()`** - Required for proper initialization

### 📦 Dependencies
- Added `uuid: ^4.2.0` for better idempotency key generation
- Added `synchronized: ^3.1.0` for mutex locks
- Updated minimum Flutter SDK to `>=3.0.0`

### 📚 Documentation
- Added complete API documentation
- Added usage examples in `example/` folder
- Added migration guide from v1.0.0 to v1.0.1

### 🧪 Testing
- Added unit tests for `IdempotencyKey`
- Added unit tests for `QueueManager`
- Added unit tests for `ConflictResolver`

---

## [1.0.0] - 2024-01-01

### Initial Release
- 🚀 Offline-first sync engine for Flutter
- 📦 Queue management with priorities (critical, high, normal, low, background)
- 🔄 Bi-directional sync layer
- 📱 Riverpod integration with providers
- 🔌 Connectivity monitoring (WiFi/Cellular/Offline)
- ⚡ Smart retry with exponential backoff
- 🎯 Idempotency key support (prevents duplicates)
- 💾 Persistent queue across app restarts (Hive)
- 🎨 Ready-to-use UI components:
  - `ConnectivityBanner` - Displays offline status
  - `SyncStatusIndicator` - Shows pending operations
  - `SyncProgressBar` - Visual sync progress
  - `OfflineToast` - Toast notifications
  - `DebugPanel` - Debug and inspection tools
- 🔥 Firebase integration:
  - Firestore offline persistence
  - Storage upload queue with retry
  - Auth state persistence
- ⚔️ Conflict resolution strategies:
  - Server wins
  - Client wins
  - Merge
  - Last write wins
  - Manual resolve
- 🎨 Customizable theme support (`authTheme`)
- 🧩 `SyncAwareMixin` for easy integration
- 📊 Sync metrics and monitoring
- 🔍 Debug tools for QA/Testing