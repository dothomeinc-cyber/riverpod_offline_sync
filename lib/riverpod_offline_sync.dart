library;

// Core
export 'src/core/sync_layer.dart';
export 'src/core/sync_config.dart';
export 'src/core/sync_metrics.dart';
export 'src/core/sync_progress.dart';
export 'src/core/sync_state_machine.dart';
export 'src/core/sync_observer.dart';
export 'src/core/offline_sync_scope.dart';

// Queue
export 'src/queue/queue_manager.dart';
export 'src/queue/queue_item.dart';
export 'src/queue/queue_priority.dart';
export 'src/queue/queue_category.dart';
export 'src/queue/retry_strategy.dart';
export 'src/queue/hive_registry.dart';
export 'src/queue/queue_item_adapter.dart';
export 'src/queue/queue_stats.dart';

// Connectivity
export 'src/connectivity/connectivity_monitor.dart';
export 'src/connectivity/connectivity_status.dart';

// Conflict
export 'src/conflict/conflict_resolver.dart';
export 'src/conflict/conflict_strategy.dart';
export 'src/conflict/conflict_detector.dart';

// Firebase
export 'src/firebase/firestore_sync.dart';
export 'src/firebase/storage_queue.dart';
export 'src/firebase/auth_persistence.dart';

// Providers
export 'src/providers/sync_providers.dart';
export 'src/providers/queue_providers.dart';
export 'src/providers/connectivity_providers.dart';

// UI Components
export 'src/ui/connectivity_banner.dart';
export 'src/ui/sync_status_indicator.dart';
export 'src/ui/sync_progress_bar.dart';
export 'src/ui/offline_toast.dart';
export 'src/ui/auth_theme.dart';
export 'src/ui/debug_panel.dart';

// Mixins
export 'src/mixins/sync_aware_mixin.dart';

// Utils (no riverpod_extensions.dart)
export 'src/utils/backoff_calculator.dart';
export 'src/utils/idempotency_key.dart';
export 'src/utils/logger.dart';

// Initializer
export 'src/offline_sync_initializer.dart';
