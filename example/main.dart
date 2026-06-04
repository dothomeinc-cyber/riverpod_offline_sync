import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_offline_sync/riverpod_offline_sync.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline sync
  await OfflineSyncInitializer.initialize(
    config: SyncConfig.aggressive(),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Offline Sync Demo',
        theme: authTheme(),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final isConnected = ref.watch(isConnectedProvider);
    // ignore: unused_local_variable
    final pendingCount =
        ref.watch(pendingItemsCountProvider);

    return Scaffold(
      body: ConnectivityBanner(
        child: Stack(
          children: [
            // Your app content here
            const Center(child: Text('Your App Content')),

            // Status indicators
            Positioned(
              top: 10,
              right: 10,
              child: SyncStatusIndicator(),
            ),

            // Debug panel button (only in debug mode)
            if (kDebugMode)
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.small(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const DebugPanel(),
                    );
                  },
                  child: const Icon(Icons.bug_report),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget? ConnectivityBanner({required Stack child}) {
    return null;
  }
}
