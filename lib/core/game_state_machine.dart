import 'package:flutter/foundation.dart';
import '../models/game_state.dart';

/// Central state machine governing turn lifecycle, physics simulation,
/// and input gating for Carrom Master.
class GameStateMachine extends ChangeNotifier {
  GameState _currentState;
  GameState? _previousState;

  GameStateMachine([GameState initial = GameState.placingStriker])
      : _currentState = initial;

  /// The active operational state of the game.
  GameState get currentState => _currentState;

  /// The operational state immediately preceding the current state.
  GameState? get previousState => _previousState;

  /// Whether user interaction (striker positioning, aim initiation) is permitted.
  bool get isInteractive => _currentState == GameState.placingStriker;

  /// Whether physics simulation is currently active.
  bool get isSimulating => _currentState == GameState.simulating;

  /// Whether the user is actively aiming a shot with an ongoing drag gesture.
  bool get isAiming => _currentState == GameState.aiming;

  /// Whether gameplay is currently paused.
  bool get isPaused => _currentState == GameState.paused;

  /// Whether the AI opponent is currently thinking or animating its shot.
  bool get isCpuThinking => _currentState == GameState.cpuThinking;

  /// Whether the match has concluded.
  bool get isGameOver => _currentState == GameState.gameOver;

  /// Verifies whether transitioning from [_currentState] to [next] is legally valid.
  bool canTransitionTo(GameState next) {
    if (_currentState == next) return false;

    switch (_currentState) {
      case GameState.placingStriker:
        return next == GameState.aiming ||
            next == GameState.cpuThinking ||
            next == GameState.paused ||
            next == GameState.gameOver;

      case GameState.aiming:
        return next == GameState.simulating ||
            next == GameState.placingStriker ||
            next == GameState.paused;

      case GameState.simulating:
        return next == GameState.evaluating ||
            next == GameState.paused;

      case GameState.evaluating:
        return next == GameState.respotting ||
            next == GameState.placingStriker ||
            next == GameState.cpuThinking ||
            next == GameState.gameOver ||
            next == GameState.paused;

      case GameState.respotting:
        return next == GameState.placingStriker ||
            next == GameState.cpuThinking ||
            next == GameState.gameOver ||
            next == GameState.paused;

      case GameState.cpuThinking:
        return next == GameState.simulating ||
            next == GameState.paused ||
            next == GameState.placingStriker ||
            next == GameState.gameOver;

      case GameState.paused:
        return next == GameState.placingStriker ||
            next == GameState.cpuThinking ||
            next == GameState.simulating ||
            next == GameState.evaluating ||
            next == GameState.respotting ||
            next == GameState.gameOver;

      case GameState.gameOver:
        return next == GameState.placingStriker;
    }
  }

  /// Attempts to transition to [next]. Returns true if state changed, false if rejected or already in that state.
  bool transitionTo(GameState next) {
    if (_currentState == next) return false;

    if (!canTransitionTo(next)) {
      debugPrint(
        '⚠️ GameStateMachine: Illegal transition rejected: $_currentState -> $next',
      );
      return false;
    }

    _previousState = _currentState;
    _currentState = next;
    notifyListeners();
    return true;
  }

  /// Resolves the safe resumption state when unpausing.
  /// If the game was paused while aiming, returns [GameState.placingStriker]
  /// since touch drag events cannot be restored.
  GameState resolveResumeState() {
    if (_previousState == null || _previousState == GameState.aiming) {
      return GameState.placingStriker;
    }
    return _previousState!;
  }

  /// Resets the state machine to an initial state (defaults to [GameState.placingStriker]).
  void reset([GameState state = GameState.placingStriker]) {
    _previousState = null;
    _currentState = state;
    notifyListeners();
  }
}
