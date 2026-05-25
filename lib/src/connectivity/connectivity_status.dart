enum ConnectivityStatus {
  connected,
  disconnected,
  unknown,
}

extension ConnectivityStatusExtension
    on ConnectivityStatus {
  bool get isConnected =>
      this == ConnectivityStatus.connected;
  bool get isDisconnected =>
      this == ConnectivityStatus.disconnected;

  String get label {
    switch (this) {
      case ConnectivityStatus.connected:
        return 'Connected';
      case ConnectivityStatus.disconnected:
        return 'Disconnected';
      case ConnectivityStatus.unknown:
        return 'Unknown';
    }
  }
}
