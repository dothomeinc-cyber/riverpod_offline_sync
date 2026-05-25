class SyncProgress {
  final int current;
  final int total;
  final String currentOperation;
  final double percentage;
  final DateTime timestamp;

  SyncProgress({
    required this.current,
    required this.total,
    required this.currentOperation,
  })  : percentage = total > 0 ? current / total : 0.0,
        timestamp = DateTime.now();

  bool get isComplete => current >= total && total > 0;
  bool get isStarted => current > 0;
  String get progressText => '$current/$total';
  int get percentageInt => (percentage * 100).toInt();

  SyncProgress copyWith({
    int? current,
    int? total,
    String? currentOperation,
  }) {
    return SyncProgress(
      current: current ?? this.current,
      total: total ?? this.total,
      currentOperation:
          currentOperation ?? this.currentOperation,
    );
  }

  Map<String, dynamic> toJson() => {
        'current': current,
        'total': total,
        'currentOperation': currentOperation,
        'percentage': percentage,
        'timestamp': timestamp.toIso8601String(),
        'progressText': progressText,
        'percentageInt': percentageInt,
      };

  @override
  String toString() =>
      'SyncProgress($progressText - $currentOperation)';
}
