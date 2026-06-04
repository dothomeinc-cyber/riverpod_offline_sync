// lib/src/core/offline_sync_scope.dart
import 'package:flutter/material.dart';
import 'sync_layer.dart';
import 'sync_config.dart';
import '../utils/logger.dart';

class OfflineSyncScope extends StatefulWidget {
  final Widget child;
  final SyncConfig? config;
  final VoidCallback? onInitialized;
  final Widget? loadingWidget;

  const OfflineSyncScope({
    super.key,
    required this.child,
    this.config,
    this.onInitialized,
    this.loadingWidget,
  });

  @override
  State<OfflineSyncScope> createState() =>
      _OfflineSyncScopeState();
}

class _OfflineSyncScopeState
    extends State<OfflineSyncScope> {
  bool _isInitialized = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await OfflineSyncLayer.instance
          .initialize(config: widget.config);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        widget.onInitialized?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
        });
      }
      OfflineLogger.error(
          'Failed to initialize OfflineSyncScope',
          error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to initialize: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitialized = false;
                  });
                  _initialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return widget.loadingWidget ??
          const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
    }

    return widget.child;
  }
}
