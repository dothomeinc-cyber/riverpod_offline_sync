import 'conflict_strategy.dart';
import 'conflict_detector.dart';

class ConflictResolver {
  final ConflictDetector _detector = ConflictDetector();

  Future<Map<String, dynamic>> resolve({
    required Map<String, dynamic> local,
    required Map<String, dynamic> remote,
    required ConflictStrategy strategy,
    DateTime? localTimestamp,
    DateTime? remoteTimestamp,
  }) async {
    final conflicts =
        _detector.detectConflicts(local, remote);

    if (conflicts.isEmpty) {
      return remote;
    }

    switch (strategy) {
      case ConflictStrategy.serverWins:
        return remote;

      case ConflictStrategy.clientWins:
        return local;

      case ConflictStrategy.merge:
        return _deepMerge(local, remote);

      case ConflictStrategy.lastWriteWins:
        if (localTimestamp != null &&
            remoteTimestamp != null) {
          return localTimestamp.isAfter(remoteTimestamp)
              ? local
              : remote;
        }
        return remote;

      case ConflictStrategy.manualResolve:
        throw Exception(
            'Manual resolution required for conflicts: $conflicts');
    }
  }

  Map<String, dynamic> _deepMerge(
      Map<String, dynamic> local,
      Map<String, dynamic> remote) {
    final result = Map<String, dynamic>.from(remote);

    for (final key in local.keys) {
      if (!remote.containsKey(key)) {
        result[key] = local[key];
      } else if (local[key] is Map<String, dynamic> &&
          remote[key] is Map<String, dynamic>) {
        result[key] = _deepMerge(
            local[key] as Map<String, dynamic>,
            remote[key] as Map<String, dynamic>);
      } else if (local[key] is List &&
          remote[key] is List) {
        final merged = [
          ...local[key] as List,
          ...remote[key] as List
        ];
        result[key] = merged.toSet().toList();
      } else {
        // For primitive types, prefer remote value
        result[key] = remote[key];
      }
    }

    return result;
  }
}
