# Changelog

## 1.0.5

### 🚀 New Features

#### Queue Statistics API
- Added `QueueStats` class with comprehensive queue metrics:
  - `pendingCount` - Total pending operations
  - `failedCount` - Permanently failed operations
  - `retryingCount` - Operations scheduled for retry
  - `oldestItemAge` - Age of oldest queue item
  - `categoryBreakdown` - Count by queue category
  - `priorityBreakdown` - Count by priority level
- Added `getQueueStats()` method to `QueueManager` for real-time statistics
- Added queue statistics provider for Riverpod integration
- Added statistics display in DebugPanel

#### Sync Observer System
- Added `SyncObserver` abstract class with lifecycle callbacks:
  - `onSyncStarted()` - Sync begins
  - `onSyncCompleted()` - Sync finishes successfully
  - `onSyncFailed(Object error)` - Sync fails with error
  - `onProgressChanged(int current, int total)` - Real-time progress
  - `onItemProcessed(String itemId, bool success)` - Individual item status
- Added `SyncObserverManager` for observer registration and notification
- Added observer support to `OfflineSyncLayer`
- Added analytics integration example

#### OfflineSyncScope Widget
- Added `OfflineSyncScope` widget for simplified initialization:
  - Automatic initialization with loading state
  - Error handling with retry UI
  - Custom loading widget support
  - Initialization callback
  - Proper disposal management
- Reduced boilerplate code in `main()`
- Improved user experience during sync layer initialization

#### Enhanced Conflict Resolution
- Added ignored fields support to `ConflictDetector`:
  - Skip timestamp fields (`updatedAt`, `lastSeen`, etc.)
  - Skip version control fields (`syncVersion`, `_localId`)
  - Skip cache metadata (`cachedAt`)
- Configurable ignored fields list
- Improved performance for large documents
- Reduced false conflict detections

#### Improved Queue Item Identification
- Replaced timestamp-based IDs with UUID v4:
  - Better collision prevention
  - True unique identifiers across devices
  - No duplicate IDs even in same millisecond
  - Improved debugging with random IDs
- Added `QueueItem.create()` factory constructor
- Backward compatible with existing queue items

#### Enhanced Upload Progress Tracking
- Changed progress callback from `VoidCallback` to `ValueChanged<double>`:
  - Receive actual percentage (0.0 to 1.0)
  - Calculate bytes uploaded from percentage
  - Better UI progress bars with exact values
  - Support for multiple concurrent uploads
- Added progress stream to `StorageQueue`
- Added upload speed estimation helpers

#### Improved Queue Trimming Logic
- Smart priority-based queue trimming:
  - Sorts by priority (critical → background)
  - Keeps higher priority items
  - Drops oldest low-priority items first
  - Prevents accidental deletion of important operations
- Configurable max queue size (default: 1000)
- Warning logs when items are dropped

#### Safe Connectivity Disposal
- Fixed memory leaks in `ConnectivityMonitor`:
  - Made subscription nullable
  - Safe cancellation on dispose
  - No errors if dispose called before initialize
  - Proper cleanup of resources
- Added dispose safety checks throughout

### 🐛 Bug Fixes

#### Compilation and Build Issues
- Fixed `DebugPanel` compile error with `AsyncValueExtensions`
- Removed incorrect wrapper class usage
- Fixed direct extension method access
- Resolved all analysis warnings

#### Queue Processing Issues
- Fixed queue trimming deleting important items unexpectedly
- Improved priority-based sorting algorithm
- Fixed race condition in queue size checking
- Fixed queue recovery after app crash

#### Conflict Resolution Issues
- Fixed false conflict detection on timestamp fields
- Added proper DateTime comparison handling
- Fixed nested map conflict detection
- Improved list comparison performance

#### UI Component Issues
- Fixed `DebugPanel` crash on empty queue
- Fixed progress bar percentage calculation
- Fixed connectivity banner update frequency
- Fixed sync status indicator positioning

#### Provider Issues
- Fixed `pendingItemsCountProvider` returning stale data
- Fixed memory leak in queue stream providers
- Fixed provider disposal order
- Improved provider state consistency

### 🔧 Improvements

#### Documentation Overhaul (Complete)
- Added comprehensive README with Firebase-first approach:
  - Firebase quick start guide
  - Complete Firestore integration examples
  - Storage upload with pause/resume/cancel
  - Auth persistence setup
  - Real-time Firestore + offline queue
- Added v1.0.5 new features section:
  - Queue Statistics API documentation
  - Sync Observer System guide
  - OfflineSyncScope widget usage
- Added complete service class examples:
  - `OfflineFirestoreService`
  - `OfflineSyncService`
- Added production-ready Todo app example:
  - Full offline CRUD operations
  - Riverpod integration
  - Real-time sync indicators
  - Error handling and retry UI
- Added troubleshooting section with 10+ common issues
- Added debug checklist for systematic debugging
- Added package comparison table
- Added architecture diagram
- Added FAQ section

#### Code Quality
- Added comprehensive code comments
- Improved type safety across all methods
- Added input validation for public APIs
- Standardized error messages
- Added documentation for all public APIs

#### Developer Experience
- Improved initialization error messages
- Added initialization state validation
- Added handler registration verification
- Added debug logging improvements
- Added queue inspection utilities
- Added statistics helpers

#### Performance
- Optimized queue sorting algorithm
- Reduced memory allocation in hot paths
- Improved conflict detection performance
- Optimized stream subscriptions
- Reduced unnecessary rebuilds

### 📚 Examples Added

#### Complete Firestore Integration
```dart
// Full CRUD operations with offline support
await OfflineFirestoreService.setDocument(
  collection: 'users',
  docId: 'user123',
  data: {'name': 'John', 'email': 'john@example.com'},
);

await OfflineFirestoreService.updateDocument(
  collection: 'users',
  docId: 'user123',
  updates: {'email': 'john.doe@example.com'},
);

await OfflineFirestoreService.deleteDocument(
  collection: 'users',
  docId: 'user123',
);