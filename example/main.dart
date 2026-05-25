import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_offline_sync/riverpod_offline_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize BEFORE app starts - Fixes race condition
  await OfflineSyncInitializer.initialize(
    config: const SyncConfig(
      autoSyncOnReconnect: true,
      syncImmediately: true,
      maxConcurrentOperations: 3,
    ),
  );

  // Register handlers
  OfflineSyncLayer.instance
      .registerOperationHandler('orders', (data) async {
    print('Processing order: $data');
  });

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Sync Demo',
      home: ConnectivityBanner(
        child: OfflineToast(
          child: Scaffold(
            appBar: AppBar(
                title: const Text('Offline Sync Demo')),
            body: const Center(
              child: Text('Ready'),
            ),
          ),
        ),
      ),
    );
  }
}
