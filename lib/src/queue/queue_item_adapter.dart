import 'package:hive/hive.dart';
import 'queue_item.dart';

class QueueItemAdapter extends TypeAdapter<QueueItem> {
  @override
  final int typeId = 0;

  @override
  QueueItem read(BinaryReader reader) {
    final id = reader.readString();
    final category = reader.readString();
    final priority = reader.readInt();
    final data = reader.readMap();
    final idempotencyKey = reader.readString();
    final createdAt = DateTime.parse(reader.readString());
    final retryCount = reader.readInt();
    final hasNextRetry = reader.readBool();
    DateTime? nextRetryAt;
    if (hasNextRetry) {
      nextRetryAt = DateTime.parse(reader.readString());
    }
    final hasLastError = reader.readBool();
    String? lastError;
    if (hasLastError) {
      lastError = reader.readString();
    }

    return QueueItem(
      id: id,
      category: category,
      priority: priority,
      data: Map<String, dynamic>.from(data),
      idempotencyKey: idempotencyKey,
      createdAt: createdAt,
      retryCount: retryCount,
      nextRetryAt: nextRetryAt,
      lastError: lastError,
    );
  }

  @override
  void write(BinaryWriter writer, QueueItem obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.category);
    writer.writeInt(obj.priority);
    writer.writeMap(obj.data);
    writer.writeString(obj.idempotencyKey);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeInt(obj.retryCount);
    writer.writeBool(obj.nextRetryAt != null);
    if (obj.nextRetryAt != null) {
      writer
          .writeString(obj.nextRetryAt!.toIso8601String());
    }
    writer.writeBool(obj.lastError != null);
    if (obj.lastError != null) {
      writer.writeString(obj.lastError!);
    }
  }
}
