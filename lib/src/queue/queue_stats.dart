// lib/src/queue/queue_stats.dart
class QueueStats {
  final int pendingCount;
  final int failedCount;
  final int retryingCount;
  final Duration oldestItemAge;
  final Map<String, int> categoryBreakdown;
  final Map<int, int> priorityBreakdown;

  const QueueStats({
    required this.pendingCount,
    required this.failedCount,
    required this.retryingCount,
    required this.oldestItemAge,
    required this.categoryBreakdown,
    required this.priorityBreakdown,
  });

  Map<String, dynamic> toJson() => {
        'pendingCount': pendingCount,
        'failedCount': failedCount,
        'retryingCount': retryingCount,
        'oldestItemAgeMs': oldestItemAge.inMilliseconds,
        'categoryBreakdown': categoryBreakdown,
        'priorityBreakdown': priorityBreakdown,
      };

  @override
  String toString() {
    return 'QueueStats(pending: $pendingCount, failed: $failedCount, retrying: $retryingCount)';
  }
}
