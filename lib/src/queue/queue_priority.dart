enum QueuePriority {
  critical,
  high,
  normal,
  low,
  background,
}

extension QueuePriorityExtension on QueuePriority {
  int get value {
    switch (this) {
      case QueuePriority.critical:
        return 0;
      case QueuePriority.high:
        return 1;
      case QueuePriority.normal:
        return 2;
      case QueuePriority.low:
        return 3;
      case QueuePriority.background:
        return 4;
    }
  }

  String get label {
    switch (this) {
      case QueuePriority.critical:
        return 'Critical';
      case QueuePriority.high:
        return 'High';
      case QueuePriority.normal:
        return 'Normal';
      case QueuePriority.low:
        return 'Low';
      case QueuePriority.background:
        return 'Background';
    }
  }
}
