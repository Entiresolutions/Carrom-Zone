/// Discrete operational states for the Carrom Master game lifecycle.
enum GameState {
  /// Waiting for active player to position the striker on the baseline or initiate aim.
  placingStriker,

  /// Active player is touching and dragging the board to aim and set shot power.
  aiming,

  /// Striker has been fired; physics engine is simulating piece motions.
  simulating,

  /// Physics motion has stopped; evaluating pocketed pieces, fouls, and scores.
  evaluating,

  /// Returning foul or illegal pieces back to the board with deterministic clearance.
  respotting,

  /// AI opponent is calculating trajectory, positioning striker, and preparing shot.
  cpuThinking,

  /// Gameplay is paused via user modal or application lifecycle backgrounding.
  paused,

  /// Win condition met or match terminated; game over screen is displayed.
  gameOver,
}

