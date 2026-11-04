import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/core/vector2.dart';
import 'package:carrom_master/models/piece_model.dart';
import 'package:carrom_master/physics/carrom_physics.dart';

void main() {
  group('CarromPhysics Reliability Test Suite', () {
    test('1. Multi-FPS determinism: Identical seeded shots at 30, 60, and 120 FPS', () {
      CarromPhysics createWorld() {
        final queen = PieceModel(
          id: 1,
          type: PieceType.queen,
          position: GameConfig.queenInitialPos,
          radius: GameConfig.queenRadius,
          mass: GameConfig.pieceMass,
        );

        final target = PieceModel(
          id: 2,
          type: PieceType.white,
          position: const Vector2(0.0, 50.0),
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        );

        final striker = PieceModel(
          id: 0,
          type: PieceType.striker,
          position: const Vector2(0.0, 142.0),
          velocity: const Vector2(2.5, -20.0),
          radius: GameConfig.strikerRadius,
          mass: GameConfig.strikerMass,
        );

        return CarromPhysics(
          pieces: [queen, target],
          striker: striker,
        );
      }

      // Simulate 2.0 seconds at 30 FPS (60 ticks, dt = 1/30)
      final world30 = createWorld();
      for (int i = 0; i < 60; i++) {
        world30.update(1.0 / 30.0);
      }

      // Simulate 2.0 seconds at 60 FPS (120 ticks, dt = 1/60)
      final world60 = createWorld();
      for (int i = 0; i < 120; i++) {
        world60.update(1.0 / 60.0);
      }

      // Simulate 2.0 seconds at 120 FPS (240 ticks, dt = 1/120)
      final world120 = createWorld();
      for (int i = 0; i < 240; i++) {
        world120.update(1.0 / 120.0);
      }

      // Verify that all worlds execute identical fixed steps and arrive at identical states
      for (int i = 0; i < world60.pieces.length; i++) {
        final p30 = world30.pieces[i];
        final p60 = world60.pieces[i];
        final p120 = world120.pieces[i];

        expect(
          p30.position.distanceTo(p60.position),
          lessThan(1e-4),
          reason: 'Piece $i position diverged between 30 FPS and 60 FPS',
        );
        expect(
          p60.position.distanceTo(p120.position),
          lessThan(1e-4),
          reason: 'Piece $i position diverged between 60 FPS and 120 FPS',
        );

        expect(
          p30.velocity.distanceTo(p60.velocity),
          lessThan(1e-4),
          reason: 'Piece $i velocity diverged between 30 FPS and 60 FPS',
        );
        expect(
          p60.velocity.distanceTo(p120.velocity),
          lessThan(1e-4),
          reason: 'Piece $i velocity diverged between 60 FPS and 120 FPS',
        );
      }

      expect(
        world30.striker.position.distanceTo(world60.striker.position),
        lessThan(1e-4),
        reason: 'Striker position diverged between 30 FPS and 60 FPS',
      );
      expect(
        world60.striker.position.distanceTo(world120.striker.position),
        lessThan(1e-4),
        reason: 'Striker position diverged between 60 FPS and 120 FPS',
      );
    });

    test('2. High-power direct cushion impact: No tunneling, valid finite vectors', () {
      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, 0.0),
        velocity: const Vector2(GameConfig.strikerMaxPower, 0.0), // 22.0 straight right
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      bool wallHitTriggered = false;
      final physics = CarromPhysics(
        pieces: [],
        striker: striker,
        onWallCollision: () => wallHitTriggered = true,
      );

      const double halfPlay = GameConfig.halfBoard - 16.0; // 184.0

      // Step physics for 1.0 second
      for (int i = 0; i < 60; i++) {
        physics.update(1.0 / 60.0);
        // Striker must never penetrate past the right cushion boundary
        expect(
          striker.position.x + striker.radius,
          lessThanOrEqualTo(halfPlay + 0.01),
          reason: 'Striker tunneled through right cushion!',
        );
        expect(striker.position.isValid, isTrue);
        expect(striker.velocity.isValid, isTrue);
      }

      expect(wallHitTriggered, isTrue, reason: 'Wall collision callback was not triggered');
      // Velocity should have reversed along x
      expect(striker.velocity.x, lessThanOrEqualTo(0.0));
    });

    test('3. High-power piece-to-piece impact: Momentum transfer and penetration prevention', () {
      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, 60.0),
        velocity: const Vector2(0.0, -22.0),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final target = PieceModel(
        id: 1,
        type: PieceType.white,
        position: const Vector2(0.0, 0.0),
        velocity: Vector2.zero,
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      double maxImpulse = 0.0;
      Vector2 targetVelAtImpact = Vector2.zero;
      final physics = CarromPhysics(
        pieces: [target],
        striker: striker,
        onPieceCollision: (impulse) {
          if (impulse > maxImpulse) {
            maxImpulse = impulse;
            targetVelAtImpact = target.velocity;
          }
        },
      );

      for (int i = 0; i < 30; i++) {
        physics.update(1.0 / 60.0);
        expect(striker.position.isValid, isTrue);
        expect(target.position.isValid, isTrue);
      }

      expect(maxImpulse, greaterThan(1.0), reason: 'Collision impulse was not registered');
      // Target piece should have absorbed forward momentum immediately at impact
      expect(targetVelAtImpact.y, lessThan(0.0), reason: 'Target piece did not receive forward velocity at impact');
      // Striker should have decelerated or rebounded
      expect(striker.velocity.y.abs(), lessThan(22.0));
    });

    test('4. Corner pocket overshoot/near-miss: Strict boundary containment', () {
      // Piece placed in corner heading outward at high velocity
      final piece = PieceModel(
        id: 1,
        type: PieceType.white,
        position: const Vector2(195.0, 195.0),
        velocity: const Vector2(20.0, 20.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, 142.0),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final physics = CarromPhysics(pieces: [piece], striker: striker);

      const double maxOuterBound = GameConfig.halfBoard - 4.0; // 196.0

      for (int i = 0; i < 60; i++) {
        physics.update(1.0 / 60.0);
        // Piece must NEVER escape beyond outer frame boundary
        expect(
          piece.position.x.abs() + piece.radius,
          lessThanOrEqualTo(maxOuterBound + 0.1),
          reason: 'Piece escaped board horizontally in corner zone: ${piece.position}',
        );
        expect(
          piece.position.y.abs() + piece.radius,
          lessThanOrEqualTo(maxOuterBound + 0.1),
          reason: 'Piece escaped board vertically in corner zone: ${piece.position}',
        );
        expect(piece.position.isValid, isTrue);
        expect(piece.velocity.isValid, isTrue);
      }
    });

    test('5. Overlapping pieces at zero distance: Smooth separation without sticking or NaNs', () {
      final p1 = PieceModel(
        id: 1,
        type: PieceType.white,
        position: const Vector2(0.0, 0.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final p2 = PieceModel(
        id: 2,
        type: PieceType.black,
        position: const Vector2(0.0, 0.0), // Exact same coordinate
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, 142.0),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final physics = CarromPhysics(pieces: [p1, p2], striker: striker);

      // Run 6 frames (36 substeps)
      for (int i = 0; i < 6; i++) {
        physics.update(1.0 / 60.0);
      }

      final double finalDist = p1.position.distanceTo(p2.position);
      final double minAllowedDist = p1.radius + p2.radius;

      expect(p1.position.isValid, isTrue);
      expect(p2.position.isValid, isTrue);
      expect(finalDist, greaterThan(0.0), reason: 'Pieces remained stuck at distance 0');
      expect(
        finalDist,
        greaterThanOrEqualTo(minAllowedDist - 0.5),
        reason: 'Pieces did not separate to their combined radii',
      );
    });

    test('6. Pocket suction and capture: Single callback and velocity zeroing', () {
      // Piece placed in top-right pocket suction threshold (33.0)
      // Pocket is at (178.0, -178.0)
      final piece = PieceModel(
        id: 1,
        type: PieceType.white,
        position: const Vector2(165.0, -165.0), // dist ~ 18.38 (< 21.0 drop radius)
        velocity: const Vector2(1.0, -1.0),
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, 142.0),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      int pocketCallbackCount = 0;
      final physics = CarromPhysics(
        pieces: [piece],
        striker: striker,
        onPocket: (p, pocket) {
          pocketCallbackCount++;
        },
      );

      for (int i = 0; i < 30; i++) {
        physics.update(1.0 / 60.0);
      }

      expect(pocketCallbackCount, equals(1), reason: 'onPocket should fire exactly once per piece');
      expect(piece.isPocketed, isTrue);
      expect(piece.velocity, equals(Vector2.zero));
      expect(piece.pocketProgress, equals(1.0));
    });

    test('7. Delta spike bounding: Prevents spiral of death under sudden lag spikes', () {
      final striker = PieceModel(
        id: 0,
        type: PieceType.striker,
        position: const Vector2(0.0, 142.0),
        velocity: const Vector2(0.0, -10.0),
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final physics = CarromPhysics(pieces: [], striker: striker);

      // Simulate a massive 5.0 second freeze (e.g. App suspended or heavy blocking task)
      physics.update(5.0);

      // maxAccumulatedTime is 0.1s (at most 6 fixed steps of 1/60s)
      // Striker should have stepped at most 6 times (moving ~54 units from 142 down to ~88)
      expect(striker.position.y, greaterThan(70.0), reason: 'Lag spike caused uncontrolled runaway physics!');
      expect(striker.position.y, lessThan(142.0));
      expect(striker.position.isValid, isTrue);
      expect(physics.accumulator, lessThanOrEqualTo(CarromPhysics.fixedTimeStep));
    });
  });
}
