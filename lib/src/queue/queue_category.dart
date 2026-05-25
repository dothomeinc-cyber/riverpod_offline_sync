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

extension QueueCategoryExtension on QueueCategory {
  String get label {
    switch (this) {
      case QueueCategory.uploads:
        return 'Uploads';
      case QueueCategory.orders:
        return 'Orders';
      case QueueCategory.messages:
        return 'Messages';
      case QueueCategory.payments:
        return 'Payments';
      case QueueCategory.sync:
        return 'Sync';
      case QueueCategory.analytics:
        return 'Analytics';
      case QueueCategory.media:
        return 'Media';
      case QueueCategory.documents:
        return 'Documents';
      case QueueCategory.background:
        return 'Background';
    }
  }

  String get icon {
    switch (this) {
      case QueueCategory.uploads:
        return '📤';
      case QueueCategory.orders:
        return '📦';
      case QueueCategory.messages:
        return '💬';
      case QueueCategory.payments:
        return '💰';
      case QueueCategory.sync:
        return '🔄';
      case QueueCategory.analytics:
        return '📊';
      case QueueCategory.media:
        return '🎬';
      case QueueCategory.documents:
        return '📄';
      case QueueCategory.background:
        return '⚙️';
    }
  }
}
