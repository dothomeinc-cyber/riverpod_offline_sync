import 'dart:async';

enum SyncMachineState {
  idle,
  checking,
  pulling,
  pushing,
  completing,
  failed,
  cancelled,
}

class SyncStateMachine {
  SyncMachineState _currentState = SyncMachineState.idle;
  final _stateController =
      StreamController<SyncMachineState>.broadcast();

  SyncMachineState get currentState => _currentState;
  Stream<SyncMachineState> get onStateChanged =>
      _stateController.stream;

  void transitionTo(SyncMachineState newState) {
    if (_canTransition(_currentState, newState)) {
      _currentState = newState;
      _stateController.add(_currentState);
    }
  }

  bool _canTransition(
      SyncMachineState from, SyncMachineState to) {
    switch (from) {
      case SyncMachineState.idle:
        return to == SyncMachineState.checking;

      case SyncMachineState.checking:
        return to == SyncMachineState.pushing ||
            to == SyncMachineState.pulling ||
            to == SyncMachineState.failed;

      case SyncMachineState.pushing:
        return to == SyncMachineState.pulling ||
            to == SyncMachineState.completing ||
            to == SyncMachineState.failed;

      case SyncMachineState.pulling:
        return to == SyncMachineState.completing ||
            to == SyncMachineState.failed;

      case SyncMachineState.completing:
        return to == SyncMachineState.idle;

      case SyncMachineState.failed:
        return to == SyncMachineState.idle ||
            to == SyncMachineState.checking;

      case SyncMachineState.cancelled:
        return to == SyncMachineState.idle;
    }
  }

  void reset() {
    _currentState = SyncMachineState.idle;
    _stateController.add(_currentState);
  }

  bool get isIdle => _currentState == SyncMachineState.idle;
  bool get isSyncing =>
      _currentState != SyncMachineState.idle &&
      _currentState != SyncMachineState.failed &&
      _currentState != SyncMachineState.cancelled;
  bool get hasFailed =>
      _currentState == SyncMachineState.failed;

  void dispose() {
    _stateController.close();
  }
}
