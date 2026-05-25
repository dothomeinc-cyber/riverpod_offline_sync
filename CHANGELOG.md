## 1.0.2

### 🚀 New Features
- Added `OfflineSyncInitializer` for safe, race-condition-free initialization
- Added `syncStatusTextProvider` for UI-friendly sync status text
- Added `AsyncValue` extensions:
  - `valueOrNull`
  - `isLoading`
  - `hasError`
  - `errorValue`
- Added `SyncMachineState` helper getters:
  - `isPulling`
  - `isPushing`
- Added `OfflineLogger` for structured logging
- Added deep merge conflict resolution for nested maps and lists
- Added queue concurrency support with `maxConcurrentOperations`
- Added WiFi-only synchronization mode
- Added queue size limiting with automatic trimming
- Added upload lifecycle controls:
  - pause
  - resume
  - cancel
- Added real-time sync progress streams
- Added queue breakdown metrics for debugging
- Added provider disposal cleanup using `ref.onDispose`
- Added improved debug tooling and inspection utilities

### 🐛 Bug Fixes
- Fixed race condition in provider initialization (`QueueManager`, `ConnectivityMonitor`)
- Fixed duplicate listener registration in `OfflineToast`
- Fixed `DebugPanel` extension misuse error
- Fixed `IdempotencyKey.isValid()` to support UUID and composite keys
- Fixed `SyncStateMachine` transition order
- Fixed `FirestoreSync` using `print()` instead of `OfflineLogger`
- Fixed memory leaks in providers and stream subscriptions
- Fixed queue retry scheduling edge cases
- Fixed adapter re-registration issues in Hive
- Fixed connectivity stream handling for latest `connectivity_plus`
- Fixed duplicate operation handling during retries
- Fixed queue persistence restoration after app restart

### 🔧 Improvements
- Replaced `print()` statements with `OfflineLogger`
- Improved retry orchestration and exponential backoff handling
- Improved queue batching and concurrent processing
- Improved sync lifecycle orchestration
- Improved Riverpod integration and provider ergonomics
- Improved error messages and debugging output
- Improved metrics persistence and reporting
- Improved upload tracking and progress monitoring
- Improved connectivity-aware synchronization
- Improved conflict merge logic with recursive resolution
- Improved offline UI components and developer experience
- Improved sync metrics visualization in `DebugPanel`

### ⚠️ Breaking Changes
- Removed `riverpod_offline_sync_base.dart`
  - Use `OfflineSyncInitializer` instead
- Removed `QueueStore`
  - Functionality merged into `QueueManager`
- `queueManagerProvider` now uses `FutureProvider`
- `connectivityMonitorProvider` now uses `FutureProvider`
- `OfflineSyncInitializer.initialize()` must be called before `runApp()`

### 📦 Dependencies
- Added `uuid: ^4.2.0`
- Added `synchronized: ^3.1.0`
- Updated `connectivity_plus`
- Updated Firebase dependencies
- Updated minimum Flutter SDK to `>=3.0.0`

### 📚 Documentation
- Added complete API documentation
- Added detailed README with examples
- Added troubleshooting guide
- Added architecture overview
- Added usage examples in `/example`
- Added migration notes
- Added provider documentation
- Added Firebase integration examples

### 🧪 Testing
- Added unit tests for `IdempotencyKey`
- Added unit tests for `QueueManager`
- Added unit tests for `ConflictResolver`
- Added retry handling tests
- Added queue persistence tests
- Added sync lifecycle tests

---

## 1.0.0

### Initial Release
- 🚀 Offline-first sync engine for Flutter
- 📦 Queue management with priorities
- 🔄 Bi-directional synchronization
- 📱 Riverpod integration
- 🔌 Connectivity monitoring
- ⚡ Smart retry with exponential backoff
- 🎯 Idempotency key support
- 💾 Persistent queue using Hive
- 🎨 Built-in offline UI components
- 🔥 Firebase integration
- ⚔️ Conflict resolution strategies
- 🧩 `SyncAwareMixin`
- 📊 Sync metrics and monitoring
- 🔍 Debug tools and inspection utilities