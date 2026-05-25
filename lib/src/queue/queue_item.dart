import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class QueueItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final int priority;

  @HiveField(3)
  final Map<String, dynamic> data;

  @HiveField(4)
  final String idempotencyKey;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  int retryCount;

  @HiveField(7)
  DateTime? nextRetryAt;

  @HiveField(8)
  String? lastError;

  QueueItem({
    required this.id,
    required this.category,
    required this.priority,
    required this.data,
    required this.idempotencyKey,
    required this.createdAt,
    this.retryCount = 0,
    this.nextRetryAt,
    this.lastError,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'priority': priority,
        'data': data,
        'idempotencyKey': idempotencyKey,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'nextRetryAt': nextRetryAt?.toIso8601String(),
        'lastError': lastError,
      };

  factory QueueItem.fromJson(Map<String, dynamic> json) =>
      QueueItem(
        id: json['id'],
        category: json['category'],
        priority: json['priority'],
        data: Map<String, dynamic>.from(json['data']),
        idempotencyKey: json['idempotencyKey'],
        createdAt: DateTime.parse(json['createdAt']),
        retryCount: json['retryCount'],
        nextRetryAt: json['nextRetryAt'] != null
            ? DateTime.parse(json['nextRetryAt'])
            : null,
        lastError: json['lastError'],
      );
}
