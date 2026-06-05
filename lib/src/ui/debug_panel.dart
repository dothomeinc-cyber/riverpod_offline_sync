import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/queue_providers.dart';
import '../providers/sync_providers.dart';
import '../providers/connectivity_providers.dart';
import 'auth_theme.dart';

class DebugPanel extends ConsumerStatefulWidget {
  const DebugPanel({super.key});

  @override
  ConsumerState<DebugPanel> createState() =>
      _DebugPanelState();
}

class _DebugPanelState extends ConsumerState<DebugPanel> {
  @override
  Widget build(BuildContext context) {
    final pendingItemsAsync =
        ref.watch(pendingItemsProvider);
    final queueBreakdown =
        ref.watch(queueBreakdownProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final metrics = ref.watch(syncMetricsProvider);
    final syncStatus = ref.watch(syncStatusTextProvider);
    final isConnected = ref.watch(isConnectedProvider);

    final pendingItems = pendingItemsAsync.maybeWhen(
      data: (items) => items,
      orElse: () => [],
    );

    final pendingCount = pendingItems.length;

    final isLoading = pendingItemsAsync.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    final errorValue = pendingItemsAsync.maybeWhen(
      error: (error, stackTrace) => error,
      orElse: () => null,
    );

    final hasError = errorValue != null;

    final hasQueueBreakdown = queueBreakdown.isNotEmpty;
    final breakdownEntries = queueBreakdown.entries;

    return Container(
      decoration: BoxDecoration(
        color: AuthColors.black.withAlpha(230),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AuthColors.black,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12.r),
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🔧 Debug Panel',
                  style: TextStyle(
                    color: AuthColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AuthColors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Connection Status'),
                  _buildInfoRow(
                    'Network Status',
                    isConnected
                        ? '🟢 Connected'
                        : '🔴 Disconnected',
                  ),
                  _buildInfoRow('Sync Status', syncStatus),
                  SizedBox(height: 8.h),
                  _buildSectionHeader('Queue Status'),
                  _buildInfoRow(
                      'Queue Size', '$pendingCount'),
                  _buildInfoRow('Is Syncing',
                      isSyncing ? 'Yes' : 'No'),
                  if (isLoading)
                    _buildInfoRow(
                        'Loading', 'Fetching items...'),
                  if (hasError)
                    _buildInfoRow(
                      'Error',
                      '$errorValue',
                      isError: true,
                    ),
                  SizedBox(height: 8.h),
                  if (hasQueueBreakdown) ...[
                    _buildSectionHeader('Queue Breakdown'),
                    ...breakdownEntries.map(
                      (e) => _buildInfoRow(
                          '  ${e.key}', '${e.value}'),
                    ),
                    SizedBox(height: 8.h),
                  ],
                  _buildSectionHeader('Sync Metrics'),
                  _buildInfoRow('Total Syncs',
                      '${metrics.totalSyncs}'),
                  _buildInfoRow('Successful',
                      '${metrics.successfulSyncs}'),
                  _buildInfoRow(
                      'Failed', '${metrics.failedSyncs}'),
                  _buildInfoRow(
                    'Success Rate',
                    metrics.successRatePercentage,
                  ),
                  if (metrics.lastError != null)
                    _buildInfoRow(
                      'Last Error',
                      '${metrics.lastError}',
                      isError: true,
                    ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await ref
                                .read(
                                    offlineSyncLayerProvider)
                                .clearQueue();

                            ref.invalidate(
                                pendingItemsProvider);
                            ref.invalidate(
                                queueBreakdownProvider);

                            if (mounted) setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Clear Queue'),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await ref
                                .read(
                                    offlineSyncLayerProvider)
                                .sync();

                            if (mounted) setState(() {});
                          },
                          child: const Text('Force Sync'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            ref.invalidate(
                                pendingItemsProvider);
                            ref.invalidate(
                                queueBreakdownProvider);
                            ref.invalidate(
                                pendingItemsCountProvider);
                            ref.invalidate(
                                syncMetricsProvider);

                            if (mounted) setState(() {});

                            final count = await ref
                                .read(
                                    offlineSyncLayerProvider)
                                .getPendingCount();

                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Refreshed. Pending items: $count',
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('Refresh'),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          color: AuthColors.yellow,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isError = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.sp,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError
                    ? AuthColors.error
                    : Colors.white,
                fontWeight: isError
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
