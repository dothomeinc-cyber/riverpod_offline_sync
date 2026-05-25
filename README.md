# 📦 riverpod_offline_sync

A production-ready offline-first sync engine for Flutter with Riverpod state management, queue orchestration, conflict resolution, Firebase integration, retry handling, connectivity monitoring, and built-in offline UI components.

[![pub version](https://img.shields.io/badge/pub-v0.1.0-blue)](https://pub.dev)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)](https://flutter.dev)

---

## Table of Contents

- [Features](#features)
- [Dependencies](#dependencies)
- [Quick Start](#quick-start)
  - [1. Initialize in main()](#1-initialize-in-main)
  - [2. Register Operation Handlers](#2-register-operation-handlers)
  - [3. Wrap Your App](#3-wrap-your-app)
  - [4. Submit Offline Operations](#4-submit-offline-operations)
- [Architecture](#architecture)
- [Core Concepts](#core-concepts)
  - [Queue Priorities](#queue-priorities)
  - [Queue Categories](#queue-categories)
  - [Sync Strategies](#sync-strategies)
  - [Conflict Resolution](#conflict-resolution)
- [Providers](#providers)
- [Methods](#methods)
  - [OfflineSyncLayer](#offlinesynclayer)
  - [QueueManager](#queuemanager)
  - [StorageQueue](#storagequeue)
- [UI Components](#ui-components)
  - [ConnectivityBanner](#connectivitybanner)
  - [SyncStatusIndicator](#syncstatusindicator)
  - [SyncProgressBar](#syncprogressbar)
  - [OfflineToast](#offlinetoast)
  - [DebugPanel](#debugpanel)
- [Firebase Integration](#firebase-integration)
  - [Firestore](#firestore)
  - [Firebase Storage](#firebase-storage)
  - [Firebase Auth](#firebase-auth)
- [Configuration](#configuration)
- [Metrics & Analytics](#metrics--analytics)
- [Retry System](#retry-system)
- [Connectivity Monitoring](#connectivity-monitoring)
- [Utilities](#utilities)
- [Examples](#examples)
- [Debugging](#debugging)
- [FAQ](#faq)
- [License](#license)

---

# ✨ Features

- 🔄 Bi-directional sync (push + pull)
- 📦 Persistent offline queue (Hive)
- ⚡ Concurrent queue processing
- 🔁 Smart retry with exponential backoff
- 🔌 Connectivity-aware synchronization
- 📶 WiFi-only sync mode
- 🧠 Conflict resolution strategies
- 🧾 Idempotency protection
- 📊 Sync metrics & analytics
- 🛠 Debug inspection tools
- 🎨 Built-in UI widgets
- 🔥 Firebase integrations
- 🧩 Riverpod integration
- 📱 Offline-first architecture
- 🚀 Queue survives app restarts
- 🎯 Upload pause / resume / cancel
- 📈 Real-time sync progress streams
- 🔒 Production-ready sync orchestration

---

# Dependencies

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  riverpod_offline_sync: ^0.1.0
  flutter_riverpod: ^2.5.0
  hive_flutter: ^1.1.0
  connectivity_plus: ^5.0.0
  synchronized: ^3.1.0
```

Then run:

```bash
flutter pub get
```

---

# Quick Start

## 1. Initialize in main()

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_offline_sync/riverpod_offline_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await OfflineSyncLayer.instance.initialize(
    config: const SyncConfig(
      autoSyncOnReconnect: true,
      syncImmediately: true,
      maxConcurrentOperations: 3,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}
```

---

## 2. Register Operation Handlers

```dart
OfflineSyncLayer.instance.registerOperationHandler(
  'orders',
  (data) async {
    await api.createOrder(data);
  },
);

OfflineSyncLayer.instance.registerOperationHandler(
  'messages',
  (data) async {
    await api.sendMessage(data);
  },
);
```

---

## 3. Wrap Your App

```dart
MaterialApp(
  home: ConnectivityBanner(
    child: OfflineToast(
      child: HomePage(),
    ),
  ),
)
```

---

## 4. Submit Offline Operations

```dart
await OfflineSyncLayer.instance.submitOperation(
  category: 'orders',
  priority: QueuePriority.high.value,
  data: {
    'product': 'Laptop',
    'quantity': 1,
    'price': 999.99,
  },
);
```

---

# 🏗 Architecture

```text
UI Widgets
    ↓
Riverpod Providers
    ↓
OfflineSyncLayer
    ↓
QueueManager
    ↓
Retry / Conflict / Connectivity Systems
    ↓
Persistence Layer (Hive)
    ↓
Backend APIs / Firebase / REST
```

---

# 📂 Package Structure

```text
lib/
 ├── core/
 ├── queue/
 ├── connectivity/
 ├── conflict/
 ├── firebase/
 ├── providers/
 ├── ui/
 ├── mixins/
 ├── utils/
 └── riverpod_offline_sync.dart
```

---

# Core Concepts

## Queue Priorities

| Priority | Value | Use Cases |
|---|---|---|
| critical | 0 | Payments, KYC |
| high | 1 | Orders, Messages |
| normal | 2 | Profile updates |
| low | 3 | Analytics |
| background | 4 | Cache refresh |

---

## Queue Categories

```dart
enum QueueCategory {
  uploads,
  orders,
  messages,
  payments,
  sync,
  analytics,
  media,
  documents,
  background,
}
```

---

## Sync Strategies

| Strategy | Description |
|---|---|
| auto | Automatic synchronization |
| manual | Manual user-triggered sync |
| background | Silent sync |
| pushOnly | Push local changes only |
| pullOnly | Pull remote changes only |

---

## Conflict Resolution

Supported strategies:

```dart
ConflictStrategy.serverWins
ConflictStrategy.clientWins
ConflictStrategy.merge
ConflictStrategy.lastWriteWins
ConflictStrategy.manualResolve
```

### Example

```dart
final resolver = ConflictResolver();

final resolved = await resolver.resolve(
  local: localData,
  remote: remoteData,
  strategy: ConflictStrategy.merge,
);
```

### Features

- Deep merge support
- Nested map resolution
- List merging
- Duplicate removal
- Timestamp-based conflict handling

---

# Providers

## Sync Providers

```dart
final offlineSyncLayerProvider
final syncStateProvider
final syncProgressProvider
final syncMetricsProvider
final isSyncingProvider
final syncStatusTextProvider
```

---

## Queue Providers

```dart
final queueManagerProvider
final pendingItemsProvider
final pendingItemsCountProvider
final queueBreakdownProvider
```

---

## Connectivity Providers

```dart
final connectivityMonitorProvider
final connectivityStatusProvider
final isConnectedProvider
```

---

# Methods

# OfflineSyncLayer

Main singleton for sync orchestration.

```dart
await OfflineSyncLayer.instance.initialize();

await OfflineSyncLayer.instance.submitOperation(
  category: 'orders',
  priority: 1,
  data: {'key': 'value'},
);

await OfflineSyncLayer.instance.sync();

await OfflineSyncLayer.instance.clearQueue();

final pending =
    await OfflineSyncLayer.instance.getPendingOperations();
```

---

# QueueManager

Handles queue orchestration.

```dart
final manager = QueueManager();

await manager.initialize();

await manager.enqueue(
  category: 'orders',
  priority: 1,
  data: {},
);

await manager.processQueue(
  maxConcurrent: 3,
);

await manager.retryFailed('item_id');
```

---

# StorageQueue

Queue-based Firebase Storage uploads.

```dart
final storageQueue = StorageQueue();

await storageQueue.uploadFile(
  file: file,
  path: 'uploads/image.jpg',
  idempotencyKey: IdempotencyKey.generate(),
);

storageQueue.pauseUpload('key');
storageQueue.resumeUpload('key');
storageQueue.cancelUpload('key');
```

---

# UI Components

# ConnectivityBanner

Shows offline banner automatically.

```dart
ConnectivityBanner(
  child: HomePage(),
)
```

---

# SyncStatusIndicator

Displays sync state.

```dart
SyncStatusIndicator(
  showAsFloatingAction: true,
)
```

---

# SyncProgressBar

Displays queue progress.

```dart
SyncProgressBar(
  showDetails: true,
)
```

---

# OfflineToast

Shows offline notifications.

```dart
OfflineToast(
  child: HomePage(),
)
```

---

# DebugPanel

Powerful debug and inspection tool.

```dart
showModalBottomSheet(
  context: context,
  builder: (_) => const DebugPanel(),
);
```

### Features

- Queue inspection
- Sync metrics
- Connectivity status
- Retry operations
- Queue breakdown
- Manual sync controls

---

# Firebase Integration

## Firestore

```dart
syncLayer.registerOperationHandler(
  'firestore_write',
  (data) async {
    await FirebaseFirestore.instance
        .collection('todos')
        .doc(data['id'])
        .set(data);
  },
);
```

---

## Firebase Storage

```dart
final storageQueue = StorageQueue();

await storageQueue.uploadFile(
  file: file,
  path: 'uploads/image.jpg',
  idempotencyKey: IdempotencyKey.generate(),
);
```

Supports:

- Upload queueing
- Pause uploads
- Resume uploads
- Cancel uploads
- Progress tracking

---

## Firebase Auth

```dart
final auth = AuthPersistence();

await auth.signInWithEmail(
  'email@example.com',
  'password',
);
```

---

# Configuration

```dart
const config = SyncConfig(
  autoSyncOnReconnect: true,
  syncImmediately: true,
  autoSyncInterval: Duration(minutes: 15),
  maxRetries: 5,
  initialRetryDelay: Duration(seconds: 2),
  maxConcurrentOperations: 3,
  enableMetrics: true,
  enableDebugLogging: false,
  syncOnWiFiOnly: false,
  maxQueueSize: 1000,
);
```

### Predefined Configurations

```dart
SyncConfig.defaultConfig()
SyncConfig.aggressive()
SyncConfig.batteryFriendly()
SyncConfig.wifiOnly()
```

---

# Metrics & Analytics

Track:

- Total syncs
- Successful syncs
- Failed syncs
- Average sync duration
- Last sync time
- Success rate

Example:

```dart
final metrics = OfflineSyncLayer.instance.metrics;

print(metrics.successRatePercentage);
```

---

# Retry System

Features:

- Exponential backoff
- Delayed retry scheduling
- Retry tracking
- Configurable retry count

Example:

```dart
final delay =
    BackoffCalculator.calculateNextRetry(3);
```

---

# Connectivity Monitoring

Automatically:

- Detects online/offline state
- Syncs on reconnect
- Supports WiFi-only mode
- Broadcasts connectivity changes

Example:

```dart
final connected =
    OfflineSyncLayer.instance
        .connectivityMonitor
        .isConnected;
```

---

# Utilities

## Idempotency Keys

```dart
final key = IdempotencyKey.generate();
```

---

## Logger

```dart
OfflineLogger.isEnabled = true;

OfflineLogger.info('Sync started');
OfflineLogger.error('Sync failed');
OfflineLogger.debug('Queue processed');
```

---

## Backoff Calculator

```dart
final delay =
    BackoffCalculator.calculateNextRetry(3);
```

---

# Examples

## Offline Orders

```dart
await submitOffline(
  category: QueueCategory.orders.label,
  priority: QueuePriority.high.value,
  data: {
    'product': 'Laptop',
    'quantity': 1,
  },
);
```

---

## Chat Messages

```dart
await submitOffline(
  category: QueueCategory.messages.label,
  priority: QueuePriority.high.value,
  data: {
    'message': 'Hello!',
  },
);
```

---

## Analytics Tracking

```dart
await OfflineSyncLayer.instance.submitOperation(
  category: 'analytics',
  priority: QueuePriority.low.value,
  data: {
    'event_name': 'button_click',
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

---

# Debugging

## Show Debug Panel

```dart
showModalBottomSheet(
  context: context,
  builder: (_) => const DebugPanel(),
);
```

---

## Manual Inspection

```dart
final operations =
    await OfflineSyncLayer.instance
        .getPendingOperations();

final metrics =
    OfflineSyncLayer.instance.metrics;

final isConnected =
    OfflineSyncLayer.instance
        .connectivityMonitor
        .isConnected;
```
# 🚨 Troubleshooting

Common issues and their solutions when using `riverpod_offline_sync`.

---

## 1. Hive Initialization Errors

### ❌ Error: `HiveError: A Hive box with name 'offline_queue' already exists`

### Cause
Multiple initializations or hot reload during development.

### Solution

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive before sync layer
  await Hive.initFlutter();

  // Then initialize offline sync
  await OfflineSyncLayer.instance.initialize();

  runApp(const ProviderScope(child: MyApp()));
}
```

---

### ❌ Error: `HiveError: Hive has not been initialized. Did you forget to call Hive.initFlutter()?`

### Solution

```dart
await Hive.initFlutter();

await OfflineSyncLayer.instance.initialize();
```

---

### ❌ Error: `TypeAdapter for typeId 0 is already registered`

### Solution

```dart
// The package handles this internally with HiveRegistry.ensureRegistered()
// Make sure you're not manually registering adapters
```

---

# 2. Connectivity Listener Issues

### ❌ Error: `connectivity_plus` version mismatch

### Cause
Different versions of `connectivity_plus` have different APIs.

### Solution

```yaml
dependencies:
  connectivity_plus: ^5.0.2
```

---

### ❌ Error: `StreamSubscription<ConnectivityResult>` type mismatch

### Solution

```dart
// Don't modify the connectivity_monitor.dart file
// The package handles both single and list results automatically
```

---

### ❌ Error: Connectivity changes not detected

### Solution

```dart
if (!OfflineSyncLayer.instance.connectivityMonitor.isConnected) {
  print('Not connected to network');
}

final isConnected =
    OfflineSyncLayer.instance
        .connectivityMonitor
        .isConnected;
```

---

# 3. Queue Stuck Processing

### ❌ Issue: Items in queue but never processed

## Option 1 — Check if sync is enabled

```dart
await OfflineSyncLayer.instance.sync();
```

---

## Option 2 — Check if handler is registered

```dart
OfflineSyncLayer.instance.registerOperationHandler(
  'your_category',
  (data) async {
    // Your processing logic
  },
);
```

---

## Option 3 — Check retry scheduling

```dart
await OfflineSyncLayer.instance.retryFailedOperation('item_id');
```

---

## Option 4 — Check queue size limits

```dart
SyncConfig(
  maxQueueSize: 2000,
);
```

---

## Option 5 — Check connectivity

```dart
if (syncConfig.syncOnWiFiOnly) {
  final isWifi =
      await OfflineSyncLayer.instance
          .connectivityMonitor
          .isWifiConnected;

  if (!isWifi) {
    print('WiFi-only mode enabled');
  }
}
```

---

# 4. Duplicate Operations

### ❌ Issue: Same operation submitted multiple times

## Solution 1 — Use idempotency keys

```dart
await OfflineSyncLayer.instance.submitOperation(
  category: 'orders',
  priority: 1,
  data: orderData,
  idempotencyKey:
      'unique_order_${orderData['id']}',
);
```

---

## Solution 2 — Generate UUID keys

```dart
import 'package:uuid/uuid.dart';

final idempotencyKey = const Uuid().v4();

await OfflineSyncLayer.instance.submitOperation(
  category: 'orders',
  priority: 1,
  data: orderData,
  idempotencyKey: idempotencyKey,
);
```

---

## Solution 3 — Use built-in generator

```dart
await OfflineSyncLayer.instance.submitOperation(
  category: 'orders',
  priority: 1,
  data: orderData,
  idempotencyKey: IdempotencyKey.generate(),
);
```

---

# 5. Provider Initialization Race Conditions

### ❌ Error: `Null check operator used on a null value`

### Solution

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await OfflineSyncLayer.instance.initialize();

  runApp(const ProviderScope(child: MyApp()));
}
```

---

### ❌ Error: `OfflineSyncLayer not initialized`

### Solution

```dart
if (OfflineSyncLayer.instance.isInitialized) {
  await OfflineSyncLayer.instance.submitOperation(...);
} else {
  print('Sync layer not ready yet');
}
```

---

# 6. Firebase Integration Issues

### ❌ Error: `[core/no-app] No Firebase App '[DEFAULT]' has been created`

### Solution

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await OfflineSyncLayer.instance.initialize();

  runApp(const ProviderScope(child: MyApp()));
}
```

---

### ❌ Error: `Firestore persistence enabled too late`

### Solution

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await FirebaseFirestore.instance.settings =
      const Settings(
        persistenceEnabled: true,
      );

  await OfflineSyncLayer.instance.initialize();

  runApp(const ProviderScope(child: MyApp()));
}
```

---

# 7. Memory Leaks

### ❌ Issue: StreamControllers not disposed

### Solution

```dart
await OfflineSyncLayer.instance.dispose();
```

---

# 8. Performance Issues

### ❌ Issue: Large queue affecting performance

## Solution 1 — Limit concurrent operations

```dart
SyncConfig(
  maxConcurrentOperations: 3,
  maxQueueSize: 500,
);
```

---

## Solution 2 — Use background priority

```dart
await OfflineSyncLayer.instance.submitOperation(
  category: 'analytics',
  priority: QueuePriority.background.value,
  data: analyticsData,
);
```

---

## Solution 3 — Enable WiFi-only mode

```dart
SyncConfig(
  syncOnWiFiOnly: true,
);
```

---

# 9. Debug Panel Not Showing

### ❌ Issue: Debug panel doesn't open or shows blank

### Solution

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (BuildContext context) {
    return const DebugPanel();
  },
);
```

---

# 10. Common Setup Mistakes

### ❌ Mistake: Forgetting to register handlers

### Solution

```dart
void main() async {
  await OfflineSyncLayer.instance.initialize();

  OfflineSyncLayer.instance.registerOperationHandler(
    'orders',
    (data) async {
      // Process order
    },
  );

  runApp(MyApp());
}
```

---

### ❌ Mistake: Using providers before initialization

### Solution

```dart
final pendingCountAsync =
    ref.watch(pendingItemsCountProvider);

final pendingCount =
    pendingCountAsync.valueOrNull ?? 0;
```

---

### ❌ Mistake: Not handling async initialization in Riverpod

### Solution

```dart
final pendingItems =
    ref.watch(pendingItemsProvider)
        .valueOrNull ?? [];
```

---

# 🔍 Debug Checklist

Use this checklist when troubleshooting:

- [ ] `OfflineSyncLayer.instance.isInitialized` is true
- [ ] Handlers registered for all categories
- [ ] Connectivity monitor working
- [ ] Queue has items
- [ ] No console errors
- [ ] Hive initialized
- [ ] Firebase initialized
- [ ] Permissions granted
- [ ] Not blocked by WiFi-only mode
- [ ] Unique idempotency keys used

---

# 📞 Getting Help

## Enable debug logging

```dart
OfflineLogger.isEnabled = true;
```

---

## Open debug panel

```dart
showModalBottomSheet(
  context: context,
  builder: (_) => const DebugPanel(),
);
```

---

## Inspect queue manually

```dart
final pending =
    await OfflineSyncLayer.instance
        .getPendingOperations();

print('Pending operations: $pending');
```

---

## Check sync metrics

```dart
final metrics =
    OfflineSyncLayer.instance.metrics;

print('Total syncs: ${metrics.totalSyncs}');
print('Failed syncs: ${metrics.failedSyncs}');
```

---

## Open a GitHub issue with:

- Error logs
- Steps to reproduce
- Flutter doctor output
- Package versions

---

**This troubleshooting guide covers the most common issues and their solutions! 🚀**


---

# FAQ

### Q: Does it work offline?
A: Yes. Queue operations persist locally and sync automatically later.

---

### Q: What happens if the app restarts?
A: Queue data persists using Hive and resumes automatically.

---

### Q: Does it support Firebase?
A: Yes. Firestore, Storage, and Auth integrations are included.

---

### Q: Can I use custom backends?
A: Yes. Works with REST APIs, GraphQL, Firebase, or any backend.

---

### Q: How are duplicates prevented?
A: Idempotency keys prevent duplicate operations.

---

### Q: Does it support large uploads?
A: Yes. Includes pause, resume, cancel, and progress tracking.

---

### Q: Is it Riverpod-only?
A: Core sync system works independently, but Riverpod integration is included.

---

# License

MIT License — see [LICENSE](LICENSE) file for details.

---

# ❤️ Built For Offline-First Flutter Apps

Reliable synchronization for:

- Super apps
- Delivery apps
- Chat apps
- POS systems
- CRM apps
- Warehouse systems
- Social apps
- Field-service apps
- Media upload apps

🚀