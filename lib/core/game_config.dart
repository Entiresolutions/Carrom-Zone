import 'vector2.dart';

class GameConfig {
  // Virtual board dimension (400x400 playing field)
  static const double boardSize = 400.0;
  static const double halfBoard = boardSize / 2.0;
  static const double frameWidth = 35.0;

  // Radii
  static const double pieceRadius = 12.0;
  static const double strikerRadius = 16.0;
  static const double queenRadius = 12.0;
  static const double pocketRadius = 19.0;

  // Physics settings
  static const double friction = 0.026;
  static const double frictionAir = 0.013;
  static const double restitution = 0.86; // Elasticity
  static const double strikerMaxPower = 22.0;
  static const double velocityStopThreshold = 0.08;

  // Mass ratios
  static const double pieceMass = 1.0;
  static const double strikerMass = 2.8;

  // Freestyle Points Mode configuration
  static const int freestyleWhitePoints = 20;
  static const int freestyleBlackPoints = 10;
  static const int freestyleQueenPoints = 50;
  static const int freestyleFoulPenalty = 10;
  static const int freestyleTargetScore = 160;

  // Turn Countdown Timer configuration (Ludo Star-style)
  static const double defaultTurnDurationSeconds = 20.0;
  static const double turnWarningThresholdSeconds = 5.0;

  // Baselines (in virtual coordinates, center is 0,0)
  static const double baselineYWhite = 142.0;
  static const double baselineYBlack = -142.0;
  static const double baselineHalfWidth = 85.0; // Distance to red circle centers
  static const double baselineStrikerInset = 0.0; // Striker can reach and cover the red circles
  static const double strikerMinX = -baselineHalfWidth; // -85.0 (up to on top of left red circle)
  static const double strikerMaxX = baselineHalfWidth;  // 85.0 (up to on top of right red circle)

  /// Validates that a striker position is within legal board boundaries and does not overlap pockets.
  static bool isStrikerPositionWithinBounds(Vector2 pos) {
    if (pos.x < strikerMinX - 0.5 || pos.x > strikerMaxX + 0.5) return false;
    // Cushion wall bounds check (striker body must stay strictly inside playing field)
    const double halfPlay = halfBoard - 16.0; // 184.0
    if (pos.x.abs() + strikerRadius > halfPlay) return false;
    // Pocket clearance check (striker must never overlap any pocket hole or outer trim)
    const double minPocketClearance = strikerRadius + pocketRadius + 6.5; // 41.5
    for (final pocket in pockets) {
      if (pos.distanceTo(pocket) < minPocketClearance) return false;
    }
    return true;
  }

  // Corner Pocket positions (in virtual coordinates where center is 0,0)
  static const double pocketOffset = halfBoard - 22.0;
  static const List<Vector2> pockets = [
    Vector2(-pocketOffset, -pocketOffset), // Top-Left
    Vector2(pocketOffset, -pocketOffset),  // Top-Right
    Vector2(-pocketOffset, pocketOffset),  // Bottom-Left
    Vector2(pocketOffset, pocketOffset),   // Bottom-Right
  ];

  // Initial piece positions in flower pattern
  static const Vector2 queenInitialPos = Vector2.zero;

  static const List<Map<String, dynamic>> innerRingPieces = [
    {'pos': Vector2(0.0, -26.0), 'isWhite': true},
    {'pos': Vector2(22.5, -13.0), 'isWhite': false},
    {'pos': Vector2(22.5, 13.0), 'isWhite': true},
    {'pos': Vector2(0.0, 26.0), 'isWhite': false},
    {'pos': Vector2(-22.5, 13.0), 'isWhite': true},
    {'pos': Vector2(-22.5, -13.0), 'isWhite': false},
  ];

  static const List<Map<String, dynamic>> outerRingPieces = [
    {'pos': Vector2(0.0, -52.0), 'isWhite': true},
    {'pos': Vector2(26.0, -45.0), 'isWhite': false},
    {'pos': Vector2(45.0, -26.0), 'isWhite': true},
    {'pos': Vector2(52.0, 0.0), 'isWhite': false},
    {'pos': Vector2(45.0, 26.0), 'isWhite': true},
    {'pos': Vector2(26.0, 45.0), 'isWhite': false},
    {'pos': Vector2(0.0, 52.0), 'isWhite': true},
    {'pos': Vector2(-26.0, 45.0), 'isWhite': false},
    {'pos': Vector2(-45.0, 26.0), 'isWhite': true},
    {'pos': Vector2(-52.0, 0.0), 'isWhite': false},
    {'pos': Vector2(-45.0, -26.0), 'isWhite': true},
    {'pos': Vector2(-26.0, -45.0), 'isWhite': false},
  ];
}
