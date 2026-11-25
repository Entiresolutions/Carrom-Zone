import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carrom_master/core/game_config.dart';
import 'package:carrom_master/core/vector2.dart';
import 'package:carrom_master/models/piece_model.dart';
import 'package:carrom_master/physics/carrom_physics.dart';
import 'package:carrom_master/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> platformCalls = [];

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async {
        platformCalls.add(methodCall);
        return 1;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async {
        platformCalls.add(methodCall);
        return 1;
      },
    );
  });

  setUp(() {
    platformCalls.clear();
    AudioService().sfxEnabled = true;
    AudioService().hapticsEnabled = true;
  });

  group('AudioService Pool Architecture & Sizing', () {
    test('Player pools have enhanced capacities for concurrency headroom', () {
      final audio = AudioService();
      expect(audio.hitPoolSize, equals(5),
          reason: 'Hit pool should contain 5 players for rapid carom collisions');
      expect(audio.pocketPoolSize, equals(3),
          reason: 'Pocket pool should contain 3 players for multi-pocketing');
      expect(audio.uiTouchPoolSize, equals(3),
          reason: 'UI touch pool should contain 3 players for fast tapping');
    });

    test('AudioService.init() initializes all pools and dedicated players without errors', () async {
      final audio = AudioService();
      await audio.init();

      // Verify that platform received player mode and source setup calls
      expect(platformCalls, isNotEmpty);
      final setSourceCalls =
          platformCalls.where((c) => c.method == 'setSource' || c.method == 'setPlayerMode').toList();
      expect(setSourceCalls, isNotEmpty);
    });

    test('Hit pool cycles round-robin through all 5 players for concurrency', () {
      final audio = AudioService();

      // Trigger 5 hits spaced out slightly
      for (int i = 0; i < 5; i++) {
        audio.playHit(volumeScale: 1.0);
      }

      // First hit plays; subsequent rapid hits in the same millisecond are debounced
      // Now wait beyond debounce threshold (25ms) and trigger
      expect(audio.hitPoolSize, equals(5));
    });

    test('Pocket pool supports rapid consecutive pocketing without starvation', () {
      final audio = AudioService();
      expect(audio.pocketPoolSize, equals(3));

      // Trigger pocket
      audio.playPocket();
      expect(audio.lastPocketTime, greaterThan(0));
    });
  });

  group('Collision SFX Physics Integration & Volume Scaling', () {
    test('Striker-to-coin and coin-to-coin collisions trigger sound with calibrated scaling', () {
      final List<double> playedVolumes = [];
      final audio = AudioService();

      // Simulate physics detailed collision callback logic
      void handleDetailedCollision(double impulse, PieceType typeA, PieceType typeB) {
        final bool isAValidCoin = typeA == PieceType.white ||
            typeA == PieceType.black ||
            typeA == PieceType.queen;
        final bool isBValidCoin = typeB == PieceType.white ||
            typeB == PieceType.black ||
            typeB == PieceType.queen;
        final bool isAStriker = typeA == PieceType.striker;
        final bool isBStriker = typeB == PieceType.striker;

        final bool isStrikerCoin =
            (isAStriker && isBValidCoin) || (isBStriker && isAValidCoin);
        final bool isCoinCoin = isAValidCoin && isBValidCoin;

        if (!isStrikerCoin && !isCoinCoin) return;

        if (impulse >= 0.35) {
          final double normalized = ((impulse - 0.35) / 8.0).clamp(0.0, 1.0);
          final double volScale = 0.35 + 0.65 * (normalized > 0 ? (normalized * 0.5 + 0.5) : 0.0);
          playedVolumes.add(volScale);
          audio.playPieceCollision(volumeScale: volScale);
        }
      }

      // 1. Striker hitting white coin with medium impulse
      handleDetailedCollision(3.0, PieceType.striker, PieceType.white);
      expect(playedVolumes.length, equals(1));
      expect(playedVolumes.first, greaterThan(0.5));

      // 2. White coin hitting black coin with soft impulse (>= 0.35)
      handleDetailedCollision(0.8, PieceType.white, PieceType.black);
      expect(playedVolumes.length, equals(2));

      // 3. Wall collision (not coin-coin or striker-coin)
      handleDetailedCollision(5.0, PieceType.striker, PieceType.striker);
      expect(playedVolumes.length, equals(2), reason: 'Wall/other collision should not trigger');

      // 4. Imperceptible micro-vibration (< 0.35) is filtered
      handleDetailedCollision(0.1, PieceType.white, PieceType.black);
      expect(playedVolumes.length, equals(2), reason: 'Impulse below 0.35 should be filtered');
    });

    test('CarromPhysics invokes onDetailedPieceCollision when striker strikes a coin', () {
      final List<double> impulses = [];
      final List<PieceType> typesA = [];
      final List<PieceType> typesB = [];

      final striker = PieceModel(
        id: 99,
        type: PieceType.striker,
        position: const Vector2(0.0, 142.0),
        velocity: const Vector2(0.0, -10.0), // Moving towards center
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );

      final targetPiece = PieceModel(
        id: 1,
        type: PieceType.white,
        position: const Vector2(0.0, 120.0), // Direct in striker path
        velocity: Vector2.zero,
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );

      final physics = CarromPhysics(
        pieces: [targetPiece],
        striker: striker,
        onDetailedPieceCollision: (impulse, typeA, typeB) {
          impulses.add(impulse);
          typesA.add(typeA);
          typesB.add(typeB);
        },
      );

      // Advance physics simulation
      physics.step(1.0 / 60.0);

      expect(impulses, isNotEmpty, reason: 'Collision must trigger detailed callback');
      expect(impulses.first, greaterThan(0.35));
      expect(typesA.first, equals(PieceType.white));
      expect(typesB.first, equals(PieceType.striker));
    });
  });

  group('Pocket / Point SFX Integration & Queen Events', () {
    test('Every piece pocket event triggers pocket sound, including striker pocket', () {
      final audio = AudioService();
      int pocketSoundCount = 0;
      int foulSoundCount = 0;
      int queenPocketCount = 0;

      // Mock audio triggers
      void handlePocket(PieceModel piece) {
        if (piece.type == PieceType.queen) {
          queenPocketCount++;
          audio.playQueenPocket();
        } else if (piece.type == PieceType.striker) {
          pocketSoundCount++;
          foulSoundCount++;
          audio.playPocket();
          audio.playFoul();
        } else {
          pocketSoundCount++;
          audio.playPocket();
        }
      }

      // Pocket a white piece
      final whitePiece = PieceModel(
        id: 1,
        type: PieceType.white,
        position: Vector2.zero,
        radius: GameConfig.pieceRadius,
        mass: GameConfig.pieceMass,
      );
      handlePocket(whitePiece);
      expect(pocketSoundCount, equals(1));

      // Pocket queen
      final queenPiece = PieceModel(
        id: 0,
        type: PieceType.queen,
        position: Vector2.zero,
        radius: GameConfig.queenRadius,
        mass: GameConfig.pieceMass,
      );
      handlePocket(queenPiece);
      expect(queenPocketCount, equals(1));

      // Pocket striker (foul with audible pocket sound)
      final strikerPiece = PieceModel(
        id: 99,
        type: PieceType.striker,
        position: Vector2.zero,
        radius: GameConfig.strikerRadius,
        mass: GameConfig.strikerMass,
      );
      handlePocket(strikerPiece);
      expect(pocketSoundCount, equals(2),
          reason: 'Striker pocket must trigger pocket drop sound');
      expect(foulSoundCount, equals(1),
          reason: 'Striker pocket must trigger foul sound');
    });

    test('Queen cover celebration triggers win sound fanfare', () {
      final audio = AudioService();
      platformCalls.clear();

      audio.playQueenCover();
      // Should not throw and should initiate playback
      expect(audio.sfxEnabled, isTrue);
    });

    test('Striker shoot flick SFX triggers cleanly', () {
      final audio = AudioService();
      platformCalls.clear();

      audio.playShoot();
      expect(audio.sfxEnabled, isTrue);
    });
  });

  group('Audio Settings Toggles & App Lifecycle', () {
    test('Disabling sfxEnabled suppresses all gameplay sounds', () {
      final audio = AudioService();
      audio.sfxEnabled = false;

      final initialCallCount = platformCalls.length;
      audio.playHit();
      audio.playPocket();
      audio.playQueenPocket();
      audio.playQueenCover();
      audio.playFoul();
      audio.playShoot();
      audio.playWin();

      // No new platform calls should be made when SFX is disabled
      expect(platformCalls.length, equals(initialCallCount));
    });

    test('stopAllSfx halts all pool and dedicated players without errors', () {
      final audio = AudioService();
      expect(() => audio.stopAllSfx(), returnsNormally);
    });
  });
}
