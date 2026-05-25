import 'package:uuid/uuid.dart';

class IdempotencyKey {
  static const Uuid _uuid = Uuid();

  static String generate() {
    return _uuid.v4();
  }

  static String fromData(Map<String, dynamic> data,
      {List<String>? fields}) {
    final keys = fields ?? ['id', 'timestamp', 'userId'];
    final buffer = StringBuffer();
    for (final key in keys) {
      if (data.containsKey(key)) {
        buffer.write('${data[key]}_');
      }
    }
    buffer.write(_uuid.v4());
    return buffer.toString();
  }

  static bool isValid(String key) {
    return key.isNotEmpty && key.length == 36;
  }
}
