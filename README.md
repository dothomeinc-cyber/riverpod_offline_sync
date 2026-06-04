# 📦 riverpod_offline_sync

A production-ready offline-first sync engine for Flutter with Riverpod state management, queue orchestration, conflict resolution, Firebase integration, retry handling, connectivity monitoring, and built-in offline UI components.

[![pub version](https://img.shields.io/badge/pub-v1.0.0-blue)](https://pub.dev)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)](https://flutter.dev)

---

## Table of Contents

- [Features](#-features)
- [What's New in v1.0.0](#-whats-new-in-v100)
- [Dependencies](#dependencies)
- [Quick Start with Firebase](#quick-start-with-firebase)
  - [1. Complete Setup in main()](#1-complete-setup-in-main)
  - [2. Register All Operation Handlers](#2-register-all-operation-handlers)
  - [3. Wrap Your App](#3-wrap-your-app)
  - [4. Submit Offline Operations](#4-submit-offline-operations)
- [Complete Firebase Integration](#complete-firebase-integration)
  - [Firestore Operations](#firestore-operations)
  - [Firebase Storage Uploads](#firebase-storage-uploads)
  - [Firebase Auth Persistence](#firebase-auth-persistence)
  - [Real-time Firestore + Offline Queue](#real-time-firestore--offline-queue)
- [New in v1.0.0](#new-in-v100)
  - [Queue Statistics API](#queue-statistics-api)
  - [Sync Observer System](#sync-observer-system)
  - [OfflineSyncScope Widget](#offlinesyncscope-widget)
- [Complete Service Class Example](#complete-service-class-example)
- [Complete Todo App Example](#complete-todo-app-example)
- [Architecture](#️-architecture)
- [Core Concepts](#core-concepts)
  - [Queue Priorities](#queue-priorities)
  - [Queue Categories](#queue-categories)
  - [Sync Strategies](#sync-strategies)
  - [Conflict Resolution](#conflict-resolution)
- [Providers](#providers)
- [Methods](#methods)
- [UI Components](#ui-components)
- [Configuration](#configuration)
- [Metrics & Analytics](#metrics--analytics)
- [Retry System](#retry-system)
- [Connectivity Monitoring](#connectivity-monitoring)
- [Utilities](#utilities)
- [Examples](#examples)
- [Debugging](#debugging)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [License](#license)

---

## ✨ Features

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
- 🔥 Full Firebase integrations (Firestore, Storage, Auth)
- 🧩 Riverpod integration
- 📱 Offline-first architecture
- 🚀 Queue survives app restarts
- 🎯 Upload pause / resume / cancel
- 📈 Real-time sync progress streams
- 🔒 Production-ready sync orchestration

---

## 🆕 What's New in v1.0.0

- 📊 **Queue Statistics API** — Get detailed queue insights (pending/failed/retrying counts, age, breakdowns)
- 👁️ **Sync Observer System** — Listen to sync events for analytics and monitoring
- 🎯 **OfflineSyncScope Widget** — Simplified initialization with loading states
- 🔧 **Improved Queue Trimming** — Smart priority-based queue management
- 🆔 **UUID-based IDs** — Better collision prevention for queue items
- 📈 **Enhanced Progress Tracking** — Percentage-based upload progress
- 🔌 **Better Connectivity Handling** — Safe disposal and improved WiFi detection
- 🛡️ **Conflict Detector Ignored Fields** — Skip timestamp fields in conflict detection

---

## Dependencies

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  riverpod_offline_sync: ^1.0.0
  flutter_riverpod: ^2.5.0
  firebase_core: ^2.24.0
  cloud_firestore: ^4.17.0
  firebase_storage: ^11.6.0
  firebase_auth: ^4.17.0
  hive_flutter: ^1.1.0
  connectivity_plus: ^5.0.0
  synchronized: ^3.1.0
  http: ^1.1.0
```

Then run:

```bash
flutter pub get
```

---

## Quick Start with Firebase

### 1. Complete Setup in main()

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_offline_sync/riverpod_offline_sync.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Enable Firestore native offline persistence
  await FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  // Initialize offline sync layer
  await OfflineSyncLayer.instance.initialize(
    config: const SyncConfig(
      autoSyncOnReconnect: true,
      syncImmediately: true,
      maxConcurrentOperations: 3,
      enableMetrics: true,
      enableDebugLogging: false,
    ),
  );

  // Register ALL operation handlers
  _registerHandlers();

  runApp(const ProviderScope(child: MyApp()));
}
```

---

### 2. Register All Operation Handlers

```dart
void _registerHandlers() {
  final sync = OfflineSyncLayer.instance;

  // ✅ CREATE / SET document handler
  sync.registerOperationHandler('firestore_set', (data) async {
    await FirebaseFirestore.instance
        .collection(data['collection'])
        .doc(data['docId'])
        .set(Map<String, dynamic>.from(data['payload']));
  });

  // ✅ UPDATE document handler
  sync.registerOperationHandler('firestore_update', (data) async {
    await FirebaseFirestore.instance
        .collection(data['collection'])
        .doc(data['docId'])
        .update(Map<String, dynamic>.from(data['payload']));
  });

  // ✅ DELETE document handler
  sync.registerOperationHandler('firestore_delete', (data) async {
    await FirebaseFirestore.instance
        .collection(data['collection'])
        .doc(data['docId'])
        .delete();
  });

  // ✅ Batch write handler
  sync.registerOperationHandler('firestore_batch', (data) async {
    final batch = FirebaseFirestore.instance.batch();
    final writes = List<Map<String, dynamic>>.from(data['writes']);

    for (final write in writes) {
      final docRef = FirebaseFirestore.instance
          .collection(write['collection'])
          .doc(write['docId']);

      switch (write['type']) {
        case 'set':
          batch.set(docRef, write['data']);
          break;
        case 'update':
          batch.update(docRef, write['data']);
          break;
        case 'delete':
          batch.delete(docRef);
          break;
      }
    }

    await batch.commit();
  });

  // ✅ Custom REST API handler
  sync.registerOperationHandler('api_request', (data) async {
    final response = await http.post(
      Uri.parse(data['url']),
      body: data['body'],
      headers: data['headers'],
    );

    if (response.statusCode != 200) {
      throw Exception('API request failed: ${response.statusCode}');
    }

    return response.body;
  });

  // ✅ Analytics handler (low priority)
  sync.registerOperationHandler('analytics', (data) async {
    await AnalyticsService.trackEvent(
      data['event_name'],
      properties: data['properties'],
    );
  });
}
```

---

### 3. Wrap Your App

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline-First App',
      home: ConnectivityBanner(
        child: OfflineToast(
          child: HomePage(),
        ),
      ),
    );
  }
}
```

---

### 4. Submit Offline Operations

```dart
// ✅ CREATE document (works offline)
Future<void> createUser(String userId, String name, String email) async {
  await OfflineSyncLayer.instance.submitOperation(
    category: 'firestore_set',
    priority: QueuePriority.high.value,
    idempotencyKey: 'set_user_${userId}_${DateTime.now().millisecondsSinceEpoch}',
    data: {
      'collection': 'users',
      'docId': userId,
      'payload': {
        'name': name,
        'email': email,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    },
  );
}

// ✅ UPDATE document (works offline)
Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
  await OfflineSyncLayer.instance.submitOperation(
    category: 'firestore_update',
    priority: QueuePriority.normal.value,
    idempotencyKey: IdempotencyKey.generate(),
    data: {
      'collection': 'users',
      'docId': userId,
      'payload': {
        ...updates,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    },
  );
}

// ✅ DELETE document (works offline)
Future<void> deleteUser(String userId) async {
  await OfflineSyncLayer.instance.submitOperation(
    category: 'firestore_delete',
    priority: QueuePriority.high.value,
    idempotencyKey: 'delete_user_${userId}_${DateTime.now().millisecondsSinceEpoch}',
    data: {
      'collection': 'users',
      'docId': userId,
    },
  );
}
```

---

## Complete Firebase Integration

### Firestore Operations

```dart
class OfflineFirestoreService {
  static Future<void> submitOperation({
    required String category,
    required Map<String, dynamic> data,
    QueuePriority priority = QueuePriority.normal,
    String? customIdempotencyKey,
  }) async {
    await OfflineSyncLayer.instance.submitOperation(
      category: category,
      priority: priority.value,
      idempotencyKey: customIdempotencyKey ?? IdempotencyKey.generate(),
      data: data,
    );
  }

  static Future<void> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await submitOperation(
      category: 'firestore_set',
      priority: QueuePriority.high,
      data: {'collection': collection, 'docId': docId, 'payload': data},
    );
  }

  static Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> updates,
  }) async {
    await submitOperation(
      category: 'firestore_update',
      priority: QueuePriority.normal,
      data: {'collection': collection, 'docId': docId, 'payload': updates},
    );
  }

  static Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    await submitOperation(
      category: 'firestore_delete',
      priority: QueuePriority.high,
      data: {'collection': collection, 'docId': docId},
    );
  }

  static Future<void> batchWrite({
    required List<Map<String, dynamic>> operations,
  }) async {
    await submitOperation(
      category: 'firestore_batch',
      priority: QueuePriority.high,
      data: {'writes': operations},
    );
  }
}

// Usage
await OfflineFirestoreService.setDocument(
  collection: 'products',
  docId: 'prod_001',
  data: {'name': 'Laptop', 'price': 999},
);

await OfflineFirestoreService.updateDocument(
  collection: 'products',
  docId: 'prod_001',
  updates: {'price': 899},
);

await OfflineFirestoreService.batchWrite(
  operations: [
    {'type': 'update', 'collection': 'products', 'docId': 'prod_001', 'data': {'stock': 5}},
    {'type': 'set', 'collection': 'orders', 'docId': 'order_001', 'data': {'productId': 'prod_001'}},
  ],
);
```

---

### Firebase Storage Uploads

```dart
final storageQueue = StorageQueue();

// Upload a file with full queue support
Future<void> uploadUserPhoto(File file, String userId) async {
  final idempotencyKey = IdempotencyKey.generate();

  await storageQueue.uploadFile(
    file: file,
    path: 'uploads/$userId/photo.jpg',
    idempotencyKey: idempotencyKey,
    onProgress: (percentage) {
      print('Upload progress: ${(percentage * 100).toStringAsFixed(1)}%');
    },
  );

  // Control the upload
  storageQueue.pauseUpload(idempotencyKey);
  storageQueue.resumeUpload(idempotencyKey);
  storageQueue.cancelUpload(idempotencyKey);
}

// Upload multiple files
Future<void> uploadMultipleFiles(List<File> files, String userId) async {
  for (final file in files) {
    await storageQueue.uploadFile(
      file: file,
      path: 'uploads/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg',
      idempotencyKey: IdempotencyKey.generate(),
    );
  }
}
```

---

### Firebase Auth Persistence

```dart
final auth = AuthPersistence();

// Sign in (works offline - stores credentials)
await auth.signInWithEmail('email@example.com', 'password');

// Check auth state
final user = auth.currentUser;
if (user != null) {
  print('Signed in as: ${user.email}');
}

// Set persistence type
await auth.setPersistence(AuthPersistenceType.local);   // Keep logged in
await auth.setPersistence(AuthPersistenceType.session); // Until app closes
await auth.setPersistence(AuthPersistenceType.none);    // Never persist
```

---

### Real-time Firestore + Offline Queue

```dart
// Provider for real-time Firestore data
final usersProvider = StreamProvider.autoDispose<List<User>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => User.fromFirestore(doc))
          .toList());
});

class UserListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final pendingCount = ref.watch(pendingItemsCountProvider).valueOrNull ?? 0;
    final isSyncing = ref.watch(isSyncingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
        actions: [
          if (pendingCount > 0)
            Stack(
              children: [
                Icon(Icons.sync),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$pendingCount',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          usersAsync.when(
            data: (users) => ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(users[index].name),
                  subtitle: Text(users[index].email),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      await OfflineFirestoreService.deleteDocument(
                        collection: 'users',
                        docId: users[index].id,
                      );
                    },
                  ),
                );
              },
            ),
            loading: () => Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
          if (isSyncing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await OfflineFirestoreService.setDocument(
            collection: 'users',
            docId: 'user_${DateTime.now().millisecondsSinceEpoch}',
            data: {
              'name': 'New User',
              'email': 'new@example.com',
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
        },
      ),
    );
  }
}
```

---

## New in v1.0.0

### Queue Statistics API

```dart
// Get comprehensive queue statistics
final stats = await queueManager.getQueueStats();

print('Pending: ${stats.pendingCount}');
print('Failed: ${stats.failedCount}');
print('Retrying: ${stats.retryingCount}');
print('Oldest item age: ${stats.oldestItemAge.inMinutes} minutes');
print('Category breakdown: ${stats.categoryBreakdown}');
print('Priority breakdown: ${stats.priorityBreakdown}');

// Use with providers
final statsProvider = FutureProvider<QueueStats>((ref) async {
  final manager = ref.watch(queueManagerProvider);
  return await manager.getQueueStats();
});
```

### Sync Observer System

```dart
class MySyncObserver implements SyncObserver {
  @override
  void onSyncStarted() {
    print('Sync started at ${DateTime.now()}');
  }

  @override
  void onSyncCompleted() {
    print('Sync completed successfully');
  }

  @override
  void onSyncFailed(Object error) {
    print('Sync failed: $error');
    // Send to analytics
    Analytics.track('sync_failed', {'error': error.toString()});
  }

  @override
  void onProgressChanged(int current, int total) {
    print('Progress: $current/$total');
    // Update UI progress bar
  }

  @override
  void onItemProcessed(String itemId, bool success) {
    print('Item $itemId processed: ${success ? "success" : "failed"}');
  }
}

// Register observer
final observer = MySyncObserver();
OfflineSyncLayer.instance.addObserver(observer);

// Don't forget to remove when done
OfflineSyncLayer.instance.removeObserver(observer);

// Analytics observer example
class AnalyticsSyncObserver implements SyncObserver {
  @override
  void onSyncStarted() {
    Analytics.trackEvent('sync_started');
  }

  @override
  void onSyncCompleted() {
    Analytics.trackEvent('sync_completed');
  }

  @override
  void onSyncFailed(Object error) {
    Analytics.trackEvent('sync_failed', properties: {
      'error': error.toString(),
    });
  }

  @override
  void onProgressChanged(int current, int total) {
    final percentage = (current / total * 100).toStringAsFixed(1);
    Analytics.trackEvent('sync_progress', properties: {
      'percentage': percentage,
      'current': current,
      'total': total,
    });
  }
}
```

### OfflineSyncScope Widget

```dart
void main() {
  runApp(
    ProviderScope(
      child: OfflineSyncScope(
        config: SyncConfig.defaultConfig(),
        loadingWidget: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing offline sync...'),
              ],
            ),
          ),
        ),
        onInitialized: () {
          print('Offline sync ready!');
          // Register handlers after initialization
          _registerHandlers();
        },
        child: MyApp(),
      ),
    ),
  );
}
```

---

## Complete Service Class Example

```dart
class OfflineSyncService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    await FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: true);

    await OfflineSyncLayer.instance.initialize(
      config: SyncConfig.defaultConfig(),
    );

    _registerHandlers();
  }

  static void _registerHandlers() {
    final sync = OfflineSyncLayer.instance;

    sync.registerOperationHandler('firestore_set', (data) async {
      await FirebaseFirestore.instance
          .collection(data['collection'])
          .doc(data['docId'])
          .set(data['payload']);
    });

    sync.registerOperationHandler('firestore_update', (data) async {
      await FirebaseFirestore.instance
          .collection(data['collection'])
          .doc(data['docId'])
          .update(data['payload']);
    });

    sync.registerOperationHandler('firestore_delete', (data) async {
      await FirebaseFirestore.instance
          .collection(data['collection'])
          .doc(data['docId'])
          .delete();
    });
  }

  static Future<void> create(String collection, String id, Map<String, dynamic> data) async {
    await OfflineSyncLayer.instance.submitOperation(
      category: 'firestore_set',
      priority: QueuePriority.high.value,
      idempotencyKey: IdempotencyKey.generate(),
      data: {'collection': collection, 'docId': id, 'payload': data},
    );
  }

  static Future<void> update(String collection, String id, Map<String, dynamic> updates) async {
    await OfflineSyncLayer.instance.submitOperation(
      category: 'firestore_update',
      priority: QueuePriority.normal.value,
      idempotencyKey: IdempotencyKey.generate(),
      data: {'collection': collection, 'docId': id, 'payload': updates},
    );
  }

  static Future<void> delete(String collection, String id) async {
    await OfflineSyncLayer.instance.submitOperation(
      category: 'firestore_delete',
      priority: QueuePriority.high.value,
      idempotencyKey: IdempotencyKey.generate(),
      data: {'collection': collection, 'docId': id},
    );
  }

  static Future<void> forceSync() async => OfflineSyncLayer.instance.sync();

  static Future<int> getPendingCount() async {
    final pending = await OfflineSyncLayer.instance.getPendingOperations();
    return pending.length;
  }

  static Future<QueueStats> getQueueStats() async {
    return await OfflineSyncLayer.instance.queueManager.getQueueStats();
  }

  static Future<void> clearQueue() async => OfflineSyncLayer.instance.clearQueue();

  static Future<void> retryFailed(String id) async =>
      OfflineSyncLayer.instance.retryFailedOperation(id);
}
```

---

## Complete Todo App Example

### Todo Model

```dart
class Todo {
  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Todo({
    required this.id,
    required this.title,
    this.completed = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'],
    title: json['title'],
    completed: json['completed'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
  );

  factory Todo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Todo(
      id: doc.id,
      title: data['title'],
      completed: data['completed'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Todo copyWith({String? title, bool? completed}) => Todo(
    id: id,
    title: title ?? this.title,
    completed: completed ?? this.completed,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}
```

### Todo Service

```dart
class TodoService {
  static Future<void> addTodo(Todo todo) async {
    await OfflineSyncLayer.instance.submitOperation(
      category: 'firestore_set',
      priority: QueuePriority.high.value,
      idempotencyKey: 'todo_${todo.id}_${DateTime.now().millisecondsSinceEpoch}',
      data: {
        'collection': 'todos',
        'docId': todo.id,
        'payload': todo.toJson(),
      },
    );
  }

  static Future<void> updateTodo(Todo todo) async {
    await OfflineSyncLayer.instance.submitOperation(
      category: 'firestore_update',
      priority: QueuePriority.normal.value,
      idempotencyKey: IdempotencyKey.generate(),
      data: {
        'collection': 'todos',
        'docId': todo.id,
        'payload': {
          'completed': todo.completed,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      },
    );
  }

  static Future<void> deleteTodo(String todoId) async {
    await OfflineSyncLayer.instance.submitOperation(
      category: 'firestore_delete',
      priority: QueuePriority.high.value,
      idempotencyKey: 'delete_todo_${todoId}_${DateTime.now().millisecondsSinceEpoch}',
      data: {
        'collection': 'todos',
        'docId': todoId,
      },
    );
  }

  static Stream<List<Todo>> streamTodos() {
    return FirebaseFirestore.instance
        .collection('todos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Todo.fromFirestore(doc))
            .toList());
  }

  static Future<void> forceSync() async => OfflineSyncLayer.instance.sync();
}
```

### Todo List Page

```dart
final todoListProvider = StreamProvider.autoDispose<List<Todo>>((ref) {
  return TodoService.streamTodos();
});

class TodoListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todoListProvider);
    final pendingCount = ref.watch(pendingItemsCountProvider).valueOrNull ?? 0;
    final isSyncing = ref.watch(isSyncingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Offline Todo'),
        actions: [
          if (pendingCount > 0 || isSyncing)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Row(
                  children: [
                    if (isSyncing)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (pendingCount > 0)
                      Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text('$pendingCount'),
                      ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () async {
              await TodoService.forceSync();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Syncing...')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          todosAsync.when(
            data: (todos) {
              if (todos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No todos yet', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Add your first todo!', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return CheckboxListTile(
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    value: todo.completed,
                    onChanged: (completed) async {
                      await TodoService.updateTodo(todo.copyWith(completed: completed));
                    },
                    secondary: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async => TodoService.deleteTodo(todo.id),
                    ),
                  );
                },
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error loading todos: $err'),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(todoListProvider),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          if (isSyncing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final newTodo = Todo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'New Task ${DateTime.now().hour}:${DateTime.now().minute}',
            completed: false,
            createdAt: DateTime.now(),
          );
          await TodoService.addTodo(newTodo);
        },
      ),
    );
  }
}
```

---

## 🏗️ Architecture

```
UI Widgets
    ↓
Riverpod Providers (Real-time data)
    ↓
OfflineSyncLayer (Queue management)
    ↓
QueueManager (Orchestration)
    ↓
Retry / Conflict / Connectivity Systems
    ↓
Persistence Layer (Hive for queue + Firestore for data)
    ↓
Backend APIs / Firebase
```

---

## 📂 Package Structure

```
lib/
 ├── core/
 │   ├── sync_layer.dart
 │   ├── sync_config.dart
 │   ├── sync_metrics.dart
 │   ├── sync_progress.dart
 │   ├── sync_state_machine.dart
 │   ├── sync_observer.dart        (NEW in v1.0.0)
 │   └── offline_sync_scope.dart   (NEW in v1.0.0)
 ├── queue/
 │   ├── queue_manager.dart
 │   ├── queue_item.dart
 │   ├── queue_priority.dart
 │   ├── queue_category.dart
 │   ├── retry_strategy.dart
 │   ├── hive_registry.dart
 │   ├── queue_item_adapter.dart
 │   └── queue_stats.dart          (NEW in v1.0.0)
 ├── connectivity/
 ├── conflict/
 ├── firebase/
 │   ├── firestore_service.dart
 │   ├── storage_queue.dart
 │   └── auth_persistence.dart
 ├── providers/
 ├── ui/
 ├── mixins/
 ├── utils/
 └── riverpod_offline_sync.dart
```

---

## Core Concepts

### Queue Priorities

| Priority | Value | Use Cases |
|---|---|---|
| critical | 0 | Payments, KYC |
| high | 1 | Orders, Messages |
| normal | 2 | Profile updates |
| low | 3 | Analytics |
| background | 4 | Cache refresh |

---

### Queue Categories

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

### Sync Strategies

| Strategy | Description |
|---|---|
| auto | Automatic synchronization |
| manual | Manual user-triggered sync |
| background | Silent sync |
| pushOnly | Push local changes only |
| pullOnly | Pull remote changes only |

---

### Conflict Resolution

```dart
ConflictStrategy.serverWins
ConflictStrategy.clientWins
ConflictStrategy.merge
ConflictStrategy.lastWriteWins
ConflictStrategy.manualResolve
```

**Example:**

```dart
final resolver = ConflictResolver();

final resolved = await resolver.resolve(
  local: localData,
  remote: remoteData,
  strategy: ConflictStrategy.merge,
);
```

**Features:**
- Deep merge support
- Nested map resolution
- List merging
- Duplicate removal
- Timestamp-based conflict handling
- Ignored fields support (NEW in v1.0.0)

---

## Providers

### Sync Providers

```dart
final offlineSyncLayerProvider
final syncStateProvider
final syncProgressProvider
final syncMetricsProvider
final isSyncingProvider
final syncStatusTextProvider
```

### Queue Providers

```dart
final queueManagerProvider
final pendingItemsProvider
final pendingItemsCountProvider
final queueBreakdownProvider
```

### Connectivity Providers

```dart
final connectivityMonitorProvider
final connectivityStatusProvider
final isConnectedProvider
```

---

## Methods

### OfflineSyncLayer

```dart
// Initialize
await OfflineSyncLayer.instance.initialize();

// Submit operation
await OfflineSyncLayer.instance.submitOperation(
  category: 'orders',
  priority: 1,
  idempotencyKey: IdempotencyKey.generate(),
  data: {'key': 'value'},
);

// Manual sync
await OfflineSyncLayer.instance.sync();

// Clear queue
await OfflineSyncLayer.instance.clearQueue();

// Get pending operations
final pending = await OfflineSyncLayer.instance.getPendingOperations();

// Retry failed operation
await OfflineSyncLayer.instance.retryFailedOperation('item_id');

// Check initialization
if (OfflineSyncLayer.instance.isInitialized) {
  // Safe to use
}

// Observer management (NEW in v1.0.0)
OfflineSyncLayer.instance.addObserver(myObserver);
OfflineSyncLayer.instance.removeObserver(myObserver);

// Dispose
await OfflineSyncLayer.instance.dispose();
```

### QueueManager

```dart
final manager = QueueManager();

await manager.initialize();

await manager.enqueue(
  category: 'orders',
  priority: 1,
  data: {},
);

await manager.processQueue(maxConcurrent: 3);

await manager.retryFailed('item_id');

// Get queue statistics (NEW in v1.0.0)
final stats = await manager.getQueueStats();
print('Failed items: ${stats.failedCount}');
print('Retrying items: ${stats.retryingCount}');
```

### StorageQueue

```dart
final storageQueue = StorageQueue();

// Upload file with progress (NEW in v1.0.0)
await storageQueue.uploadFile(
  file: file,
  path: 'uploads/image.jpg',
  idempotencyKey: IdempotencyKey.generate(),
  onProgress: (percentage) {
    print('Progress: ${(percentage * 100).toStringAsFixed(1)}%');
  },
);

// Control upload
storageQueue.pauseUpload('key');
storageQueue.resumeUpload('key');
storageQueue.cancelUpload('key');
```

---

## UI Components

### ConnectivityBanner

```dart
ConnectivityBanner(
  child: HomePage(),
)
```

### SyncStatusIndicator

```dart
SyncStatusIndicator(
  showAsFloatingAction: true,
)
```

### SyncProgressBar

```dart
SyncProgressBar(
  showDetails: true,
)
```

### OfflineToast

```dart
OfflineToast(
  child: HomePage(),
)
```

### DebugPanel

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => const DebugPanel(),
);
```

**Features:** Queue inspection, sync metrics, connectivity status, retry operations, queue breakdown, manual sync controls.

---

## Configuration

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
  conflictStrategy: ConflictStrategy.merge, // NEW in v1.0.0
);
```

**Predefined Configurations:**

```dart
SyncConfig.defaultConfig()      // Balanced
SyncConfig.aggressive()         // Fast sync, more battery
SyncConfig.batteryFriendly()    // Less frequent sync
SyncConfig.wifiOnly()           // Only sync on WiFi
```

---

## Metrics & Analytics

```dart
final metrics = OfflineSyncLayer.instance.metrics;

print('Success rate: ${metrics.successRatePercentage}%');
print('Total syncs: ${metrics.totalSyncs}');
print('Failed syncs: ${metrics.failedSyncs}');
print('Avg duration: ${metrics.averageSyncDuration}');
```

---

## Retry System

```dart
final delay = BackoffCalculator.calculateNextRetry(attempt: 3);
// Returns: Duration(seconds: 8) for attempt 3 with base delay 2
```

**Features:** Exponential backoff, delayed retry scheduling, retry tracking, configurable retry count.

---

## Connectivity Monitoring

```dart
final connected = OfflineSyncLayer.instance.connectivityMonitor.isConnected;
final isWifi = await OfflineSyncLayer.instance.connectivityMonitor.isWifiConnected;

// Listen to changes
OfflineSyncLayer.instance.connectivityMonitor.onConnectivityChanged.listen((status) {
  print('Connectivity: $status');
});
```

---

## Utilities

### Idempotency Keys

```dart
// Auto-generate
final key = IdempotencyKey.generate();

// Custom key
final customKey = 'user_${userId}_action_${timestamp}';
```

### Logger

```dart
OfflineLogger.isEnabled = true;

OfflineLogger.info('Sync started');
OfflineLogger.error('Sync failed: $error');
OfflineLogger.debug('Queue processed: ${items.length} items');
```

### Backoff Calculator

```dart
final delay = BackoffCalculator.calculateNextRetry(3);
// Exponential backoff: 2^3 = 8 seconds
```

---

## Examples

### Offline Orders

```dart
await OfflineSyncLayer.instance.submitOperation(
  category: QueueCategory.orders.label,
  priority: QueuePriority.high.value,
  idempotencyKey: IdempotencyKey.generate(),
  data: {
    'product': 'Laptop',
    'quantity': 1,
    'price': 999.99,
    'userId': currentUser.id,
  },
);
```

### Chat Messages

```dart
await OfflineSyncLayer.instance.submitOperation(
  category: QueueCategory.messages.label,
  priority: QueuePriority.high.value,
  idempotencyKey: IdempotencyKey.generate(),
  data: {
    'message': 'Hello!',
    'recipientId': 'user456',
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

### Analytics Tracking

```dart
await OfflineSyncLayer.instance.submitOperation(
  category: 'analytics',
  priority: QueuePriority.low.value,
  idempotencyKey: IdempotencyKey.generate(),
  data: {
    'event_name': 'button_click',
    'properties': {
      'button': 'add_todo',
      'screen': 'home',
    },
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

---

## Debugging

### Enable Debug Logging

```dart
OfflineLogger.isEnabled = true;
```

### Show Debug Panel

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (BuildContext context) => const DebugPanel(),
);
```

### Manual Inspection

```dart
// Get pending operations
final operations = await OfflineSyncLayer.instance.getPendingOperations();
print('Pending: ${operations.length}');

// Get queue statistics (NEW in v1.0.0)
final stats = await OfflineSyncLayer.instance.queueManager.getQueueStats();
print('Failed: ${stats.failedCount}');
print('Retrying: ${stats.retryingCount}');

// Get metrics
final metrics = OfflineSyncLayer.instance.metrics;
print('Success rate: ${metrics.successRatePercentage}%');

// Check connectivity
final isConnected = OfflineSyncLayer.instance.connectivityMonitor.isConnected;
print('Connected: $isConnected');

// Check initialization
final isInitialized = OfflineSyncLayer.instance.isInitialized;
print('Initialized: $isInitialized');
```

---

## Troubleshooting

**❌ `HiveError: A Hive box with name 'offline_queue' already exists`**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await OfflineSyncLayer.instance.initialize();
  runApp(const ProviderScope(child: MyApp()));
}
```

**❌ `Hive has not been initialized`**

```dart
await Hive.initFlutter();
await OfflineSyncLayer.instance.initialize();
```

**❌ `No Firebase App '[DEFAULT]' has been created`**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize first
  await OfflineSyncLayer.instance.initialize();
  runApp(const ProviderScope(child: MyApp()));
}
```

**❌ `Firestore persistence enabled too late`**

```dart
await Firebase.initializeApp();
await FirebaseFirestore.instance.settings =
    const Settings(persistenceEnabled: true); // Before sync layer
await OfflineSyncLayer.instance.initialize();
```

**❌ Queue Stuck Processing**

```dart
// 1. Force sync
await OfflineSyncLayer.instance.sync();

// 2. Verify handler is registered
OfflineSyncLayer.instance.registerOperationHandler('your_category', ...);

// 3. Check WiFi-only mode
if (syncConfig.syncOnWiFiOnly) {
  final isWifi = await OfflineSyncLayer.instance.connectivityMonitor.isWifiConnected;
  if (!isWifi) print('WiFi-only mode active');
}

// 4. Retry manually
await OfflineSyncLayer.instance.retryFailedOperation('item_id');
```

**❌ Duplicate Operations**

```dart
await OfflineSyncLayer.instance.submitOperation(
  category: 'orders',
  priority: 1,
  data: orderData,
  idempotencyKey: 'unique_order_${orderData['id']}', // Custom key
);
```

**❌ `OfflineSyncLayer not initialized`**

```dart
if (OfflineSyncLayer.instance.isInitialized) {
  await OfflineSyncLayer.instance.submitOperation(...);
} else {
  print('Sync layer not ready yet');
}
```

**✅ Queue Statistics Not Updating (NEW in v1.0.0)**

```dart
// Force refresh stats
final stats = await OfflineSyncLayer.instance.queueManager.getQueueStats();

// Or invalidate provider
ref.invalidate(pendingItemsCountProvider);
```

**✅ Observer Not Receiving Events (NEW in v1.0.0)**

```dart
// Ensure observer is added after initialization
await OfflineSyncLayer.instance.initialize();
OfflineSyncLayer.instance.addObserver(myObserver);
```

### Debug Checklist

- [ ] `OfflineSyncLayer.instance.isInitialized` is `true`
- [ ] Handlers registered for all categories
- [ ] Firebase initialized before sync layer
- [ ] Firestore persistence enabled before sync layer
- [ ] Connectivity monitor working
- [ ] Queue has items
- [ ] No console errors
- [ ] Hive initialized
- [ ] Unique idempotency keys used
- [ ] WiFi-only mode not blocking (if enabled)

---

## FAQ

**Q: Does it work offline?**
A: Yes. Queue operations persist locally using Hive and sync automatically when online.

**Q: What happens if the app restarts?**
A: Queue data persists using Hive and resumes automatically.

**Q: Does it support Firebase?**
A: Yes. Full Firestore, Storage, and Auth integrations are included.

**Q: Can I use custom backends?**
A: Yes. Works with REST APIs, GraphQL, or any backend.

**Q: How are duplicates prevented?**
A: Idempotency keys prevent duplicate operations.

**Q: Does it support large uploads?**
A: Yes. Includes pause, resume, cancel, and progress tracking.

**Q: Is it Riverpod-only?**
A: Core sync system works independently, but Riverpod integration is included.

**Q: Do I need Firestore persistence enabled?**
A: Recommended for a complete offline-first experience. It works alongside `riverpod_offline_sync`.

**Q: How does this compare to Firebase's offline?**
A: Firebase handles query caching; `riverpod_offline_sync` handles operation queuing with retries, conflict resolution, and full control.

**Q: Can I use both together?**
A: Yes! Use Firestore native offline for reads and `riverpod_offline_sync` for critical writes needing control.

**Q: What's new in v1.0.0?**
A: Queue statistics API, sync observer system, OfflineSyncScope widget, improved queue trimming, UUID-based IDs, enhanced progress tracking, and better connectivity handling.

---

## 🎯 Handler Registration Checklist

**Required handlers to register in `main()`:**
- ✅ `firestore_set` — For create/set operations
- ✅ `firestore_update` — For update operations
- ✅ `firestore_delete` — For delete operations
- ✅ `firestore_batch` — For batch writes (optional)
- ✅ `api_request` — For custom API endpoints
- ✅ `analytics` — For analytics tracking

**No handler needed for:**
- ✅ Firebase Storage uploads (uses `StorageQueue`)
- ✅ Firestore real-time listeners (native)

---

## 📊 Package Comparison

| Feature | Firebase Only | With riverpod_offline_sync |
|---|---|---|
| Offline reads | ✅ Yes (cached queries) | ✅ Yes (via Firestore) |
| Offline writes | ✅ Basic queue | ✅ **Full queue control** |
| Pause/Resume operations | ❌ No | ✅ **Yes** |
| Conflict resolution | ❌ Last write wins | ✅ **Multiple strategies** |
| Retry logic | ✅ Basic | ✅ **Customizable** |
| Queue inspection | ❌ No | ✅ **Debug panel + metrics** |
| Queue Statistics | ❌ No | ✅ **Yes (v1.0.0)** |
| Sync Observers | ❌ No | ✅ **Yes (v1.0.0)** |
| Idempotency | ❌ Manual | ✅ **Built-in** |
| Progress tracking | ❌ No | ✅ **Real-time streams** |
| Upload control | ❌ No | ✅ **Pause/Resume/Cancel** |

---

## License

MIT License — see [LICENSE](LICENSE) file for details.

---

## ❤️ Built For Offline-First Flutter Apps

Reliable synchronization for super apps, delivery apps, chat apps, POS systems, CRM apps, warehouse systems, social apps, field-service apps, and media upload apps.

**Perfect for Firebase offline-first development! 🚀**