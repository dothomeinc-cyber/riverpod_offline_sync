class ConflictDetector {
  List<String> detectConflicts(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final conflicts = <String>[];

    for (final key in local.keys) {
      if (remote.containsKey(key) &&
          local[key] != remote[key]) {
        if (_isConflict(local[key], remote[key])) {
          conflicts.add(key);
        }
      }
    }

    return conflicts;
  }

  bool _isConflict(
      dynamic localValue, dynamic remoteValue) {
    if (localValue.runtimeType != remoteValue.runtimeType) {
      return true;
    }

    if (localValue is Map<String, dynamic> &&
        remoteValue is Map<String, dynamic>) {
      return detectConflicts(localValue, remoteValue)
          .isNotEmpty;
    }

    if (localValue is List && remoteValue is List) {
      if (localValue.length != remoteValue.length) {
        return true;
      }
      for (int i = 0; i < localValue.length; i++) {
        if (localValue[i] != remoteValue[i]) return true;
      }
      return false;
    }

    return localValue != remoteValue;
  }
}
