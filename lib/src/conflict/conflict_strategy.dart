enum ConflictStrategy {
  serverWins,
  clientWins,
  merge,
  lastWriteWins,
  manualResolve,
}

extension ConflictStrategyExtension on ConflictStrategy {
  String get label {
    switch (this) {
      case ConflictStrategy.serverWins:
        return 'Server Wins';
      case ConflictStrategy.clientWins:
        return 'Client Wins';
      case ConflictStrategy.merge:
        return 'Merge';
      case ConflictStrategy.lastWriteWins:
        return 'Last Write Wins';
      case ConflictStrategy.manualResolve:
        return 'Manual Resolve';
    }
  }
}
