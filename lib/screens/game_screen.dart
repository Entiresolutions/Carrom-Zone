import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/design_system.dart';
import '../core/game_config.dart';
import '../core/vector2.dart';
import '../core/carrom_rule_engine.dart';
import '../core/game_state_machine.dart';
import '../core/theme_piece_style.dart';
import '../core/turn_timer_controller.dart';
import '../models/piece_model.dart';
import '../models/game_mode.dart';
import '../models/game_state.dart';
import '../models/turn_result.dart';
import '../physics/carrom_physics.dart';
import '../ai/carrom_ai.dart';
import '../painters/board_painter.dart';
import '../painters/piece_painter.dart';
import '../painters/aim_painter.dart';
import '../painters/particle_painter.dart';
import '../services/audio_service.dart';
import '../services/piece_asset_service.dart';
import '../services/storage_service.dart';
import '../services/striker_asset_service.dart';
import 'game_over_dialog.dart';
import 'settings_screen.dart';
import 'theme_collection_screen.dart';
import 'tutorial_dialog.dart';

class GameScreen extends StatefulWidget {
  final GameMode gameMode;
  final CarromRuleset ruleset;
  final int targetScore;
  final double turnDurationSeconds;
  final AiDifficulty? difficulty;

  const GameScreen({
    super.key,
    required this.gameMode,
    this.ruleset = CarromRuleset.classic,
    this.targetScore = GameConfig.freestyleTargetScore,
    this.turnDurationSeconds = GameConfig.defaultTurnDurationSeconds,
    this.difficulty,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Ticker? _gameLoopTicker;
  late AnimationController _glowController;
  Duration? _lastElapsed;

  // Board theme
  BoardThemeType _boardTheme = BoardThemeType.mahogany;

  // Game pieces & physics
  late PieceModel _striker;
  late List<PieceModel> _pieces;
  late CarromPhysics _physics;
  late CarromAI _ai;

  // Central Game State Machine & Ludo Star-style Turn Countdown Controller
  late GameStateMachine _stateMachine;
  late TurnTimerController _turnTimer;

  // CPU synchronization & lifecycle timers
  int _turnExecutionId = 0;
  Timer? _cpuThinkingTimer;
  Timer? _cpuAimTimer;
  AnimationController? _cpuAnimController;
  VoidCallback? _cpuAnimTickListener;
  Timer? _toastTimer;
  bool _isPauseDialogShowing = false;
  bool _isGameOverDialogShowing = false;
  double _simulatingDuration = 0.0;
  int _lastPowerTier = 0;

  // Game State
  PlayerColor _currentPlayer = PlayerColor.white;
  int _whiteScore = 0;
  int _blackScore = 0;
  int _whitePenaltyDue = 0;
  int _blackPenaltyDue = 0;
  bool _queenPocketed = false;
  bool _queenCovered = false;
  PlayerColor? _queenPocketedBy;
  bool _needsCover = false;
  PlayerColor? _firstClearedBy;

  Offset? _dragStart;
  Offset? _dragCurrent;

  // Striker baseline slider
  double _strikerSliderX = 0.0;
  final double _sliderMinX = GameConfig.strikerMinX;
  final double _sliderMaxX = GameConfig.strikerMaxX;

  // Turn Result Tracker
  final TurnResult _turnResult = TurnResult();

  // Notification Toast message
  String? _toastMessage;
  Color _toastColor = AppColors.ivory;

  // Pocket Celebration particles & Floating scores
  final List<PocketParticle> _particles = [];
  final List<PocketRingEffect> _rings = [];
  final List<FloatingScoreEffect> _floatingScores = [];
  final List<StrikerSparkParticle> _strikerSparks = [];
  final List<Vector2> _strikerTrail = [];

  final math.Random _random = math.Random();

  // Testing inspection hooks
  @visibleForTesting
  GameStateMachine get stateMachine => _stateMachine;
  @visibleForTesting
  TurnTimerController get turnTimer => _turnTimer;
  @visibleForTesting
  List<PieceModel> get pieces => _pieces;
  @visibleForTesting
  PlayerColor get currentPlayer => _currentPlayer;
  @visibleForTesting
  set currentPlayer(PlayerColor p) => _currentPlayer = p;
  @visibleForTesting
  int get whiteScore => _whiteScore;
  @visibleForTesting
  set whiteScore(int s) => _whiteScore = s;
  @visibleForTesting
  int get blackScore => _blackScore;
  @visibleForTesting
  set blackScore(int s) => _blackScore = s;
  @visibleForTesting
  bool get queenPocketed => _queenPocketed;
  @visibleForTesting
  set queenPocketed(bool q) => _queenPocketed = q;
  @visibleForTesting
  bool get queenCovered => _queenCovered;
  @visibleForTesting
  set queenCovered(bool q) => _queenCovered = q;
  @visibleForTesting
  bool get needsCover => _needsCover;
  @visibleForTesting
  set needsCover(bool n) => _needsCover = n;
  @visibleForTesting
  PlayerColor? get queenPocketedBy => _queenPocketedBy;
  @visibleForTesting
  set queenPocketedBy(PlayerColor? p) => _queenPocketedBy = p;
  @visibleForTesting
  double get strikerSliderX => _strikerSliderX;
  @visibleForTesting
  int get turnExecutionId => _turnExecutionId;
  @visibleForTesting
  void pauseGame({bool fromLifecycle = false}) =>
      _pauseGame(fromLifecycle: fromLifecycle);
  @visibleForTesting
  void resumeGame() => _resumeGame();
  @visibleForTesting
  void switchTurnForTesting() => _switchTurn();
  @visibleForTesting
  void scheduleCpuTurn() => _scheduleCpuTurn();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boardTheme = StorageService().getBoardTheme();
    StrikerAssetService.instance.preloadTheme(_boardTheme).then((_) {
      if (mounted) setState(() {});
    });
    PieceAssetService.instance.preloadTheme(_boardTheme).then((_) {
      if (mounted) setState(() {});
    });
    _ai = CarromAI(
      difficulty: widget.difficulty ?? StorageService().getAiDifficulty(),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _cpuAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _stateMachine = GameStateMachine(GameState.placingStriker);
    _turnTimer = TurnTimerController(
      turnDurationSeconds: widget.turnDurationSeconds,
      enabled: widget.gameMode != GameMode.practice,
      onTimeout: _handleTurnTimeout,
      onWarningTick: (_) {
        AudioService().hapticSelection();
      },
    );

    // High-precision frame-rate independent Ticker loop
    _gameLoopTicker = createTicker(_onGameTick);

    _initGame();

    _showToast(
      widget.ruleset == CarromRuleset.freestyle
          ? '🎯 Freestyle Points! First to ${widget.targetScore} pts wins.'
          : '🎯 Match Started! White to break.',
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pauseGame(fromLifecycle: true);
      AudioService().pauseBgm();
    } else if (state == AppLifecycleState.resumed) {
      if (AudioService().musicEnabled) {
        AudioService().resumeBgm();
      }
      final ModalRoute<dynamic>? route = ModalRoute.of(context);
      final bool isCurrentRoute = route?.isCurrent ?? true;
      if (!_isPauseDialogShowing &&
          _stateMachine.isPaused &&
          mounted &&
          isCurrentRoute &&
          !_stateMachine.isGameOver &&
          !_isGameOverDialogShowing) {
        _showPauseDialog();
      }
    }
  }

  void _cancelCpuActions() {
    _turnExecutionId++;
    _cpuThinkingTimer?.cancel();
    _cpuThinkingTimer = null;
    _cpuAimTimer?.cancel();
    _cpuAimTimer = null;
    if (_cpuAnimTickListener != null) {
      _cpuAnimController?.removeListener(_cpuAnimTickListener!);
      _cpuAnimTickListener = null;
    }
    _cpuAnimController?.stop();
    _cpuAnimController?.reset();
    _dragStart = null;
    _dragCurrent = null;
  }

  void _initGame() {
    _cancelCpuActions();
    _toastTimer?.cancel();
    _toastMessage = null;
    _isGameOverDialogShowing = false;
    _simulatingDuration = 0.0;
    _lastPowerTier = 0;
    _stateMachine.reset(GameState.placingStriker);
    _turnTimer.startNewTurn();
    if (_gameLoopTicker != null && !_gameLoopTicker!.isTicking) {
      _gameLoopTicker!.start();
    }

    _whiteScore = 0;
    _blackScore = 0;
    _whitePenaltyDue = 0;
    _blackPenaltyDue = 0;
    _queenPocketed = false;
    _queenCovered = false;
    _queenPocketedBy = null;
    _needsCover = false;
    _firstClearedBy = null;
    _currentPlayer = PlayerColor.white;
    _strikerSliderX = 0.0;
    _lastElapsed = null;
    _dragStart = null;
    _dragCurrent = null;
    _particles.clear();
    _rings.clear();
    _floatingScores.clear();
    _strikerSparks.clear();
    _strikerTrail.clear();
    _turnResult.reset();

    // Create Striker
    final double strikerY = GameConfig.baselineYWhite;
    _striker = PieceModel(
      id: 0,
      type: PieceType.striker,
      position: Vector2(_strikerSliderX, strikerY),
      radius: GameConfig.strikerRadius,
      mass: GameConfig.strikerMass,
    );

    // Create Queen & Carrom Pieces in classic flower arrangement
    _pieces = [];
    int idCounter = 1;

    // Queen
    _pieces.add(
      PieceModel(
        id: idCounter++,
        type: PieceType.queen,
        position: GameConfig.queenInitialPos,
        radius: GameConfig.queenRadius,
        mass: GameConfig.pieceMass,
      ),
    );

    // Inner ring (6 pieces)
    for (final p in GameConfig.innerRingPieces) {
      final Vector2 pos = p['pos'] as Vector2;
      final bool isWhite = p['isWhite'] as bool;
      _pieces.add(
        PieceModel(
          id: idCounter++,
          type: isWhite ? PieceType.white : PieceType.black,
          position: pos,
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ),
      );
    }

    // Outer ring (12 pieces)
    for (final p in GameConfig.outerRingPieces) {
      final Vector2 pos = p['pos'] as Vector2;
      final bool isWhite = p['isWhite'] as bool;
      _pieces.add(
        PieceModel(
          id: idCounter++,
          type: isWhite ? PieceType.white : PieceType.black,
          position: pos,
          radius: GameConfig.pieceRadius,
          mass: GameConfig.pieceMass,
        ),
      );
    }

    _physics = CarromPhysics(
      pieces: _pieces,
      striker: _striker,
      onPieceCollision: (impulse) {
        if (impulse > 1.8) {
          final double volScale = (impulse / 12.0).clamp(0.2, 1.0);
          AudioService().playHit(volumeScale: volScale);
        }
      },
      onWallCollision: () {
        AudioService().playWall();
      },
      onStrikerCollision: (contact, impulse, isWall) {
        if (impulse > 0.8) {
          _spawnStrikerImpactVfx(contact, impulse, isWall);
        }
      },
      onPocket: (piece, pocket) {
        _handlePocketEvent(piece, pocket);
      },
    );
    _physics.resetAccumulator();
  }

  void _handlePocketEvent(PieceModel piece, Vector2 pocket) {
    final bool isFreestyle = widget.ruleset == CarromRuleset.freestyle;
    Color particleColor;
    String scoreText;
    if (piece.type == PieceType.queen) {
      particleColor = AppColors.queenPiece;
      scoreText = isFreestyle
          ? '👑 +${GameConfig.freestyleQueenPoints} QUEEN'
          : '👑 +3 QUEEN';
      _turnResult.pocketedQueen = true;
      AudioService().playQueenPocket();
    } else if (piece.type == PieceType.striker) {
      particleColor = AppColors.accentRed;
      scoreText = isFreestyle
          ? 'FOUL -${GameConfig.freestyleFoulPenalty}'
          : 'FOUL -1';
      _turnResult.pocketedStriker = true;
      AudioService().playFoul();
      _spawnStrikerPocketFoulVfx(pocket);
    } else if (piece.type == PieceType.white) {
      particleColor = AppColors.whitePiece;
      if (isFreestyle) {
        scoreText = '+${GameConfig.freestyleWhitePoints}';
        _turnResult.pocketedOwn = true;
      } else if (_currentPlayer == PlayerColor.white) {
        scoreText = '+1';
        _turnResult.pocketedOwn = true;
      } else {
        scoreText = 'OPPONENT';
        _turnResult.pocketedOpponent = true;
      }
      AudioService().playPocket();
      AudioService().hapticMedium();
    } else if (piece.type == PieceType.black) {
      particleColor = AppColors.blackPiece;
      if (isFreestyle) {
        scoreText = '+${GameConfig.freestyleBlackPoints}';
        _turnResult.pocketedOwn = true;
      } else if (_currentPlayer == PlayerColor.black) {
        scoreText = '+1';
        _turnResult.pocketedOwn = true;
      } else {
        scoreText = 'OPPONENT';
        _turnResult.pocketedOpponent = true;
      }
      AudioService().playPocket();
      AudioService().hapticMedium();
    } else {
      // Striker
      particleColor = AppColors.accentRed;
      scoreText = isFreestyle
          ? 'FOUL -${GameConfig.freestyleFoulPenalty}'
          : 'FOUL -1';
      _turnResult.pocketedStriker = true;
      AudioService().playFoul();
      _spawnStrikerPocketFoulVfx(pocket);
    }

    if (piece.type != PieceType.striker) {
      _turnResult.piecesPocketedThisTurn.add(piece.type);
      _turnResult.pocketedPieces.add(piece);
    }

    // Add floating score badge
    _floatingScores.add(
      FloatingScoreEffect(
        origin: pocket,
        text: scoreText,
        color:
            piece.type == PieceType.black ? AppColors.goldBright : particleColor,
      ),
    );

    final int particleCount = piece.type == PieceType.queen ? 22 : 14;
    // Add celebration particles
    for (int i = 0; i < particleCount; i++) {
      final double angle =
          (i / particleCount.toDouble()) * math.pi * 2 + (_random.nextDouble() - 0.5) * 0.2;
      final double speed = 0.8 + _random.nextDouble() * 0.7;
      final Color pCol = piece.type == PieceType.queen
          ? (i % 2 == 0 ? AppColors.goldBright : AppColors.queenPiece)
          : (piece.type == PieceType.black ? AppColors.goldLight : particleColor);

      _particles.add(
        PocketParticle(
          origin: pocket,
          angle: angle,
          speed: speed,
          color: pCol,
        ),
      );
    }

    _rings.add(
      PocketRingEffect(
        origin: pocket,
        color:
            piece.type == PieceType.black ? AppColors.goldLight : particleColor,
      ),
    );
    if (piece.type == PieceType.queen) {
      _rings.add(
        PocketRingEffect(
          origin: pocket,
          color: AppColors.goldBright,
        ),
      );
    }
  }

  SparkShape _getSparkShapeForTheme(BoardThemeType theme) {
    switch (theme) {
      case BoardThemeType.sakuraStudio:
        return SparkShape.petal;
      case BoardThemeType.goldenPalace:
        return SparkShape.star;
      case BoardThemeType.cosmicElite:
        return SparkShape.diamond;
      case BoardThemeType.royalIndigo:
      case BoardThemeType.midnight:
        return SparkShape.star;
      default:
        return SparkShape.circle;
    }
  }

  void _spawnStrikerLaunchVfx(
    Vector2 origin,
    Vector2 direction,
    double power,
  ) {
    final style = ThemePieceStyle.of(_boardTheme);
    final shape = _getSparkShapeForTheme(_boardTheme);

    // Shockwave expansion ring at striker launch point
    _rings.add(
      PocketRingEffect(
        origin: Vector2(origin.x, origin.y),
        color: style.launchEffectColor,
        maxRadius: 36.0 + 16.0 * power.clamp(0.0, 1.0),
        strokeWidth: 2.4,
      ),
    );

    // Directional launch sparks/petals
    final double baseAngle = math.atan2(direction.y, direction.x);
    final int count = (6 + (power * 4).toInt()).clamp(6, 10);
    for (int i = 0; i < count; i++) {
      final double angle = baseAngle + math.pi + (_random.nextDouble() - 0.5) * 1.2;
      final double speed = 0.6 + _random.nextDouble() * 1.2 * power;
      _strikerSparks.add(
        StrikerSparkParticle(
          origin: Vector2(origin.x, origin.y),
          angle: angle,
          speed: speed,
          color: i.isEven ? style.launchEffectColor : style.strikerAccentRing,
          shape: shape,
          size: shape == SparkShape.petal ? 5.5 : 3.8,
        ),
      );
    }
  }

  void _spawnStrikerImpactVfx(
    Vector2 contact,
    double impulse,
    bool isWall,
  ) {
    final style = ThemePieceStyle.of(_boardTheme);
    final shape = _getSparkShapeForTheme(_boardTheme);
    final double clampedImpulse = impulse.clamp(0.8, 14.0);

    // Impact flash ring
    _rings.add(
      PocketRingEffect(
        origin: Vector2(contact.x, contact.y),
        color: isWall ? style.impactFlashColor.withOpacity(0.8) : style.impactFlashColor,
        maxRadius: isWall ? 18.0 + clampedImpulse * 1.2 : 14.0 + clampedImpulse * 1.0,
        strokeWidth: 2.2,
      ),
    );

    // Collision micro-sparks
    final int sparkCount = (clampedImpulse / 2.2).clamp(3, 8).toInt();
    for (int i = 0; i < sparkCount; i++) {
      final double angle = _random.nextDouble() * math.pi * 2;
      final double speed = 0.7 + _random.nextDouble() * (clampedImpulse / 8.0);
      _strikerSparks.add(
        StrikerSparkParticle(
          origin: Vector2(contact.x, contact.y),
          angle: angle,
          speed: speed,
          color: i % 2 == 0 ? style.impactFlashColor : style.strikerGlow,
          shape: shape,
          size: shape == SparkShape.star ? 4.5 : 3.4,
        ),
      );
    }
  }

  void _spawnStrikerPocketFoulVfx(Vector2 pocket) {
    final style = ThemePieceStyle.of(_boardTheme);
    final shape = _getSparkShapeForTheme(_boardTheme);

    // Concentric foul vortex shockwaves
    _rings.add(
      PocketRingEffect(
        origin: Vector2(pocket.x, pocket.y),
        color: AppColors.accentRed,
        maxRadius: 48.0,
        strokeWidth: 3.2,
      ),
    );
    _rings.add(
      PocketRingEffect(
        origin: Vector2(pocket.x, pocket.y),
        color: style.impactFlashColor,
        maxRadius: 32.0,
        strokeWidth: 2.0,
      ),
    );

    // Themed foul sparks
    for (int i = 0; i < 10; i++) {
      final double angle = (i / 10.0) * math.pi * 2 + (_random.nextDouble() - 0.5) * 0.3;
      final double speed = 0.5 + _random.nextDouble() * 0.8;
      _strikerSparks.add(
        StrikerSparkParticle(
          origin: Vector2(pocket.x, pocket.y),
          angle: angle,
          speed: speed,
          color: i.isEven ? AppColors.accentRed : style.strikerGlow,
          shape: shape,
          size: 4.0,
        ),
      );
    }
  }

  void _onGameTick(Duration elapsed) {
    if (!mounted || _stateMachine.isPaused) {
      _lastElapsed = null;
      return;
    }

    if (_lastElapsed == null) {
      _lastElapsed = elapsed;
      return;
    }

    final double dt = (elapsed - _lastElapsed!).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (dt <= 0.0 || dt.isNaN || dt.isInfinite) return;

    // Update Particles
    if (_particles.isNotEmpty) {
      for (final p in _particles) {
        p.life -= dt * 2.2;
      }
      _particles.removeWhere((p) => p.life <= 0.0);
    }

    // Update Rings
    if (_rings.isNotEmpty) {
      for (final r in _rings) {
        r.progress += dt * 2.2;
      }
      _rings.removeWhere((r) => r.progress >= 1.0);
    }

    // Update Floating Scores
    if (_floatingScores.isNotEmpty) {
      for (final fs in _floatingScores) {
        fs.progress += dt * 1.5;
      }
      _floatingScores.removeWhere((fs) => fs.progress >= 1.0);
    }

    // Update Striker Sparks
    if (_strikerSparks.isNotEmpty) {
      for (final s in _strikerSparks) {
        s.life -= dt * 2.8;
      }
      _strikerSparks.removeWhere((s) => s.life <= 0.0);
    }

    // Update Striker Motion Trail
    if (_stateMachine.isSimulating) {
      if (_striker.isMoving && !_striker.isPocketed) {
        _strikerTrail.add(Vector2(_striker.position.x, _striker.position.y));
        if (_strikerTrail.length > 8) {
          _strikerTrail.removeAt(0);
        }
      } else if (_strikerTrail.isNotEmpty) {
        _strikerTrail.removeAt(0);
      }
    } else if (_strikerTrail.isNotEmpty) {
      _strikerTrail.clear();
    }

    // Update Ludo Star-style Turn Countdown while active player is positioning/aiming/thinking
    final GameState currentState = _stateMachine.currentState;
    if (currentState == GameState.placingStriker ||
        currentState == GameState.aiming ||
        currentState == GameState.cpuThinking) {
      if (_turnTimer.tick(dt)) {
        if (mounted) {
          setState(() {});
        }
        return;
      }
    }

    // Update Physics while in simulating state and check shot completion
    if (_stateMachine.isSimulating) {
      _simulatingDuration += dt;
      _physics.update(dt);

      final bool isSimulationFinished =
          (!_physics.isAnyPieceMoving && !_physics.isAnyPiecePocketing) ||
          _simulatingDuration > 10.0;

      if (isSimulationFinished) {
        if (_simulatingDuration > 10.0) {
          // Safety watchdog: absorb micro-jitter and force stop endless physics
          for (final p in _pieces) {
            p.velocity = Vector2.zero;
          }
          _striker.velocity = Vector2.zero;
        }
        _simulatingDuration = 0.0;
        if (_stateMachine.transitionTo(GameState.evaluating)) {
          _handleTurnEnd();
        }
      }
    } else {
      _simulatingDuration = 0.0;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _handleTurnTimeout(int turnToken) {
    if (!mounted ||
        turnToken != _turnTimer.activeTurnToken ||
        _stateMachine.isPaused ||
        _stateMachine.isGameOver ||
        _stateMachine.isSimulating ||
        _stateMachine.currentState == GameState.evaluating ||
        _stateMachine.currentState == GameState.respotting) {
      return;
    }

    // Cancel any active aim drag or scheduled CPU timer
    _cancelCpuActions();
    if (_stateMachine.currentState == GameState.aiming ||
        _stateMachine.currentState == GameState.cpuThinking) {
      _stateMachine.transitionTo(GameState.placingStriker);
    }

    final timeoutEval = CarromTurnEvaluator.evaluateTimeout(
      currentPlayer: _currentPlayer,
      whiteScore: _whiteScore,
      blackScore: _blackScore,
      queenPocketed: _queenPocketed,
      queenCovered: _queenCovered,
      queenPocketedBy: _queenPocketedBy,
      needsCover: _needsCover,
      allPieces: _pieces,
      whitePenaltyDue: _whitePenaltyDue,
      blackPenaltyDue: _blackPenaltyDue,
    );

    _queenPocketed = timeoutEval.queenPocketed;
    _queenCovered = timeoutEval.queenCovered;
    _queenPocketedBy = timeoutEval.queenPocketedBy;
    _needsCover = timeoutEval.needsCover;

    for (final p in timeoutEval.piecesToRespot) {
      CarromRespotter.respotPiece(p, _pieces);
    }

    AudioService().playFoul();
    AudioService().hapticMedium();
    _turnResult.reset();

    if (_checkWinCondition(respotPieces: timeoutEval.piecesToRespot)) {
      return;
    }

    _switchTurn(fromTimeout: true, timeoutToast: timeoutEval.toastMessage);
  }

  void _handleTurnEnd() {
    _strikerTrail.clear();
    // Reset striker position to current player's baseline
    _resetStrikerPosition();

    final bool queenWasCoveredBefore = _queenCovered;

    final eval = CarromTurnEvaluator.evaluate(
      result: _turnResult,
      currentPlayer: _currentPlayer,
      whiteScore: _whiteScore,
      blackScore: _blackScore,
      queenPocketed: _queenPocketed,
      queenCovered: _queenCovered,
      queenPocketedBy: _queenPocketedBy,
      needsCover: _needsCover,
      allPieces: _pieces,
      whitePenaltyDue: _whitePenaltyDue,
      blackPenaltyDue: _blackPenaltyDue,
      ruleset: widget.ruleset,
    );

    // Apply state updates from evaluation
    _whiteScore = eval.whiteScore;
    _blackScore = eval.blackScore;
    _whitePenaltyDue = eval.whitePenaltyDue;
    _blackPenaltyDue = eval.blackPenaltyDue;
    _queenPocketed = eval.queenPocketed;
    _queenCovered = eval.queenCovered;
    _queenPocketedBy = eval.queenPocketedBy;
    _needsCover = eval.needsCover;

    // Queen Cover celebration
    if (!queenWasCoveredBefore && _queenCovered) {
      AudioService().playQueenCover();
      _rings.add(
        PocketRingEffect(
          origin: GameConfig.queenInitialPos,
          color: AppColors.goldBright,
        ),
      );
      _floatingScores.add(
        FloatingScoreEffect(
          origin: GameConfig.queenInitialPos,
          text: widget.ruleset == CarromRuleset.freestyle
              ? '👑 QUEEN COVERED! +${GameConfig.freestyleQueenPoints}'
              : '👑 QUEEN COVERED! +3',
          color: AppColors.goldBright,
        ),
      );
    }

    // Respot pieces if needed
    if (eval.piecesToRespot.isNotEmpty) {
      _stateMachine.transitionTo(GameState.respotting);
      for (final p in eval.piecesToRespot) {
        CarromRespotter.respotPiece(p, _pieces);
      }
    }

    if (eval.toastMessage.isNotEmpty) {
      Color toastCol = AppColors.ivory;
      if (eval.toastMessage.contains('⚠️') || eval.toastMessage.contains('❌')) {
        toastCol = AppColors.accentRed;
      } else if (eval.toastMessage.contains('👑')) {
        toastCol = AppColors.goldBright;
      } else if (eval.toastMessage.contains('🎯')) {
        toastCol = AppColors.accentGreen;
      } else if (eval.toastMessage.contains('Opponent')) {
        toastCol = AppColors.accentAmber;
      }
      _showToast(eval.toastMessage, toastCol);
    }

    // Check Win Condition
    if (_checkWinCondition(respotPieces: eval.piecesToRespot)) {
      _turnResult.reset();
      return;
    }

    _turnResult.reset();

    // Switch or Continue turn
    if (!eval.continuesTurn) {
      _switchTurn();
    } else {
      // Every continuation shot opportunity starts a fresh 20s countdown
      _turnTimer.startNewTurn();
      if (widget.gameMode == GameMode.vsCpu &&
          _currentPlayer == PlayerColor.black) {
        _scheduleCpuTurn();
      } else {
        _stateMachine.transitionTo(GameState.placingStriker);
      }
    }
  }

  bool _isPositionClearForStriker(Vector2 pos) {
    final double minSeparation =
        _striker.radius + GameConfig.pieceRadius - 0.5;
    for (final piece in _pieces) {
      if (!piece.isPocketed) {
        if ((piece.position - pos).length < minSeparation) {
          return false;
        }
      }
    }
    return true;
  }

  double _findValidStrikerX(double preferredX, double baselineY) {
    if (_isPositionClearForStriker(Vector2(preferredX, baselineY))) {
      return preferredX;
    }
    for (double dx = 5.0; dx <= 60.0; dx += 5.0) {
      final double rightX = preferredX + dx;
      if (rightX <= _sliderMaxX &&
          _isPositionClearForStriker(Vector2(rightX, baselineY))) {
        return rightX;
      }
      final double leftX = preferredX - dx;
      if (leftX >= _sliderMinX &&
          _isPositionClearForStriker(Vector2(leftX, baselineY))) {
        return leftX;
      }
    }
    return preferredX;
  }

  bool _isStrikerPlacementValid() {
    if (_strikerSliderX < _sliderMinX - 0.5 ||
        _strikerSliderX > _sliderMaxX + 0.5) {
      return false;
    }

    final double expectedY = _currentPlayer == PlayerColor.white
        ? GameConfig.baselineYWhite
        : GameConfig.baselineYBlack;
    if ((_striker.position.y - expectedY).abs() > 0.5) {
      return false;
    }

    return _isPositionClearForStriker(_striker.position);
  }

  void _resetStrikerPosition() {
    final double y = _currentPlayer == PlayerColor.white
        ? GameConfig.baselineYWhite
        : GameConfig.baselineYBlack;

    _striker.isPocketed = false;
    _striker.pocketProgress = 0.0;
    _striker.pocketTarget = null;
    _striker.velocity = Vector2.zero;
    _strikerSliderX = _findValidStrikerX(_strikerSliderX, y);
    _striker.position = Vector2(_strikerSliderX, y);
  }

  void _switchTurn({bool fromTimeout = false, String? timeoutToast}) {
    if (widget.gameMode == GameMode.practice) {
      _currentPlayer = PlayerColor.white;
      _resetStrikerPosition();
      _stateMachine.transitionTo(GameState.placingStriker);
      return;
    }

    _currentPlayer = _currentPlayer == PlayerColor.white
        ? PlayerColor.black
        : PlayerColor.white;
    _resetStrikerPosition();
    _turnTimer.startNewTurn();

    if (widget.gameMode == GameMode.vsCpu &&
        _currentPlayer == PlayerColor.black) {
      _scheduleCpuTurn(preserveToast: fromTimeout);
      if (fromTimeout && timeoutToast != null) {
        _showToast(timeoutToast, AppColors.accentRed);
      }
    } else {
      _stateMachine.transitionTo(GameState.placingStriker);
      if (fromTimeout && timeoutToast != null) {
        _showToast(timeoutToast, AppColors.accentRed);
      } else {
        final String name = widget.ruleset == CarromRuleset.freestyle
            ? (_currentPlayer == PlayerColor.white
                ? 'Player 1'
                : (widget.gameMode == GameMode.vsCpu ? 'CPU' : 'Player 2'))
            : (_currentPlayer == PlayerColor.white ? 'White' : 'Black');
        _showToast('🎯 $name\'s Turn');
      }
    }
  }

  Duration _getCpuThinkingDuration() {
    switch (_ai.difficulty) {
      case AiDifficulty.easy:
        // Easy: 900ms - 1500ms
        return Duration(milliseconds: 900 + _random.nextInt(601));
      case AiDifficulty.medium:
        // Medium: 600ms - 1100ms
        return Duration(milliseconds: 600 + _random.nextInt(501));
      case AiDifficulty.hard:
        // Hard: 400ms - 800ms
        return Duration(milliseconds: 400 + _random.nextInt(401));
    }
  }

  Duration _getCpuAimDwellDuration() {
    switch (_ai.difficulty) {
      case AiDifficulty.easy:
        // Easy: 500ms - 800ms
        return Duration(milliseconds: 500 + _random.nextInt(301));
      case AiDifficulty.medium:
        // Medium: 350ms - 600ms
        return Duration(milliseconds: 350 + _random.nextInt(251));
      case AiDifficulty.hard:
        // Hard: 250ms - 450ms
        return Duration(milliseconds: 250 + _random.nextInt(201));
    }
  }

  void _scheduleCpuTurn({bool preserveToast = false}) {
    if (widget.gameMode != GameMode.vsCpu ||
        _currentPlayer != PlayerColor.black) {
      return;
    }
    if (_stateMachine.currentState != GameState.cpuThinking) {
      if (!_stateMachine.transitionTo(GameState.cpuThinking)) {
        return;
      }
    }
    _cancelCpuActions();
    final int scheduledId = _turnExecutionId;
    if (!preserveToast) {
      _showToast('🤖 CPU Thinking...', AppColors.accentBlue);
    }

    final Duration thinkingDelay = _getCpuThinkingDuration();
    _cpuThinkingTimer = Timer(thinkingDelay, () {
      if (!mounted || scheduledId != _turnExecutionId) return;
      if (_stateMachine.currentState != GameState.cpuThinking) return;
      _executeCpuAim(scheduledId);
    });
  }

  void _executeCpuAim(int scheduledId) {
    if (!mounted || scheduledId != _turnExecutionId) return;
    if (_stateMachine.currentState != GameState.cpuThinking) return;

    final shot = _ai.calculateShot(
      pieces: _pieces,
      striker: _striker,
      aiColor: PlayerColor.black,
      needsQueenCover: _needsCover && _queenPocketedBy == PlayerColor.black,
      queenCovered: _queenCovered,
      whiteScore: _whiteScore,
      blackScore: _blackScore,
      queenPocketed: _queenPocketed,
      queenPocketedBy: _queenPocketedBy,
      whitePenaltyDue: _whitePenaltyDue,
      blackPenaltyDue: _blackPenaltyDue,
      ruleset: widget.ruleset,
      targetScore: widget.targetScore,
    );

    final double validStrikerX = _findValidStrikerX(
      shot.strikerX.clamp(_sliderMinX, _sliderMaxX),
      GameConfig.baselineYBlack,
    );

    // Compute visual drag vector so human player sees CPU aiming trajectory & power ring
    // In AimPainter, shotDir = -dragVector.normalized().
    // Therefore, dragVector points opposite to shot.angle.
    final double dragDist = (shot.power * 110.0).clamp(20.0, 110.0);
    final Offset dragVec = Offset(
      -math.cos(shot.angle) * dragDist,
      -math.sin(shot.angle) * dragDist,
    );

    final double startX = _strikerSliderX;
    final double targetX = validStrikerX;
    final Offset targetDrag = dragVec;

    _cpuAnimController?.stop();
    _cpuAnimController?.reset();
    if (_cpuAnimTickListener != null) {
      _cpuAnimController?.removeListener(_cpuAnimTickListener!);
      _cpuAnimTickListener = null;
    }

    _cpuAnimTickListener = () {
      if (!mounted || scheduledId != _turnExecutionId) {
        if (_cpuAnimTickListener != null) {
          _cpuAnimController?.removeListener(_cpuAnimTickListener!);
          _cpuAnimTickListener = null;
        }
        return;
      }
      if (_stateMachine.currentState != GameState.cpuThinking) {
        if (_cpuAnimTickListener != null) {
          _cpuAnimController?.removeListener(_cpuAnimTickListener!);
          _cpuAnimTickListener = null;
        }
        return;
      }
      final double t = CurvedAnimation(
        parent: _cpuAnimController!,
        curve: Curves.easeOutCubic,
      ).value;
      setState(() {
        _strikerSliderX = startX + (targetX - startX) * t;
        _striker.position = Vector2(_strikerSliderX, GameConfig.baselineYBlack);
        _dragStart = const Offset(0.0, 0.0);
        _dragCurrent = targetDrag * t;
      });
    };

    _cpuAnimController?.addListener(_cpuAnimTickListener!);

    _cpuAnimController?.forward().then((_) {
      if (_cpuAnimTickListener != null) {
        _cpuAnimController?.removeListener(_cpuAnimTickListener!);
        _cpuAnimTickListener = null;
      }
      if (!mounted || scheduledId != _turnExecutionId) return;
      if (_stateMachine.currentState != GameState.cpuThinking) return;

      final Duration aimDwell = _getCpuAimDwellDuration();
      _cpuAimTimer = Timer(aimDwell, () {
        if (!mounted || scheduledId != _turnExecutionId) return;
        if (_stateMachine.currentState != GameState.cpuThinking) return;

        _fireCpuShot(shot);
      });
    });
  }

  void _fireCpuShot(AiShotResult shot) {
    _dragStart = null;
    _dragCurrent = null;
    if (!_stateMachine.transitionTo(GameState.simulating)) return;
    _turnTimer.stop();

    final double powerMag = shot.power * GameConfig.strikerMaxPower;
    final Vector2 impulse = Vector2(
      math.cos(shot.angle) * powerMag,
      math.sin(shot.angle) * powerMag,
    );

    _physics.resetAccumulator();
    _striker.velocity = impulse;
    _turnResult.reset();
    AudioService().playShoot();
    _spawnStrikerLaunchVfx(
      _striker.position,
      Vector2(math.cos(shot.angle), math.sin(shot.angle)),
      shot.power,
    );
    setState(() {});
  }

  bool _checkWinCondition({List<PieceModel>? respotPieces}) {
    if (_stateMachine.isGameOver || _isGameOverDialogShowing) {
      return true;
    }

    int whiteLeft = _pieces
        .where((p) => p.type == PieceType.white && !p.isPocketed)
        .length;
    int blackLeft = _pieces
        .where((p) => p.type == PieceType.black && !p.isPocketed)
        .length;

    if (widget.ruleset == CarromRuleset.freestyle) {
      // Freestyle Deadlock Guard: if 0 normal coins remain while Queen is unresolved,
      // respot 1 normal coin so the Queen can always be covered.
      if (whiteLeft == 0 &&
          blackLeft == 0 &&
          (!_queenCovered || _needsCover)) {
        final PieceModel pocketedNormal = _pieces.firstWhere(
          (p) =>
              (p.type == PieceType.white || p.type == PieceType.black) &&
              p.isPocketed,
          orElse: () => PieceModel(
            id: -1,
            type: PieceType.white,
            position: Vector2.zero,
            radius: 0,
            mass: 0,
          ),
        );
        if (pocketedNormal.id != -1) {
          CarromRespotter.respotPiece(pocketedNormal, _pieces);
          if (pocketedNormal.type == PieceType.white) {
            whiteLeft = 1;
          } else {
            blackLeft = 1;
          }
          _showToast(
            '⚠️ Queen must be covered before final coin!',
            AppColors.accentRed,
          );
        }
      }

      final outcome = CarromTurnEvaluator.evaluateMatchOutcome(
        whiteScore: _whiteScore,
        blackScore: _blackScore,
        queenCovered: _queenCovered,
        needsCover: _needsCover,
        queenCoveredBy: _queenPocketedBy,
        allPieces: _pieces,
        whiteRemaining: whiteLeft,
        blackRemaining: blackLeft,
        clearingPlayer: _currentPlayer,
        turnResult: _turnResult,
        respotPieces: respotPieces,
        ruleset: CarromRuleset.freestyle,
        targetScore: widget.targetScore,
      );

      if (outcome.isMatchOver && (outcome.winner != null || outcome.isDraw)) {
        if (_stateMachine.transitionTo(GameState.gameOver)) {
          _endGame(outcome);
          return true;
        }
      }
      return false;
    }

    // Safety: If a player cleared/has 0 pieces left on board but still owes a penalty due,
    // they cannot win yet. A pocketed piece is immediately respotted to serve the penalty,
    // ensuring the game never permanently deadlocks with zero target pieces.
    if (whiteLeft == 0 && _whitePenaltyDue > 0) {
      final pocketedWhite = _pieces.firstWhere(
        (p) => p.type == PieceType.white && p.isPocketed,
        orElse: () => PieceModel(id: -1, type: PieceType.white, position: Vector2.zero, radius: 0, mass: 0),
      );
      if (pocketedWhite.id != -1) {
        _whitePenaltyDue--;
        _whiteScore = math.max(0, _whiteScore - 1);
        CarromRespotter.respotPiece(pocketedWhite, _pieces);
        _showToast('⚠️ Due Paid: White piece returned to board', AppColors.accentRed);
        whiteLeft = 1;
      }
    }

    if (blackLeft == 0 && _blackPenaltyDue > 0) {
      final pocketedBlack = _pieces.firstWhere(
        (p) => p.type == PieceType.black && p.isPocketed,
        orElse: () => PieceModel(id: -1, type: PieceType.black, position: Vector2.zero, radius: 0, mass: 0),
      );
      if (pocketedBlack.id != -1) {
        _blackPenaltyDue--;
        _blackScore = math.max(0, _blackScore - 1);
        CarromRespotter.respotPiece(pocketedBlack, _pieces);
        _showToast('⚠️ Due Paid: Black piece returned to board', AppColors.accentRed);
        blackLeft = 1;
      }
    }

    // Safety guard: If a player reaches 0 pieces on board while Queen is unresolved,
    // respot 1 piece so the match cannot end prematurely or deadlock.
    if (whiteLeft == 0 && (!_queenCovered || _needsCover)) {
      final pocketedWhite = _pieces.firstWhere(
        (p) => p.type == PieceType.white && p.isPocketed,
        orElse: () => PieceModel(id: -1, type: PieceType.white, position: Vector2.zero, radius: 0, mass: 0),
      );
      if (pocketedWhite.id != -1) {
        CarromRespotter.respotPiece(pocketedWhite, _pieces);
        whiteLeft = 1;
        final int pocketedWhiteAfterRespot = _pieces
            .where((p) => p.type == PieceType.white && p.isPocketed)
            .length;
        final int maxLegalWhiteScore = pocketedWhiteAfterRespot +
            (_queenCovered && _queenPocketedBy == PlayerColor.white ? 3 : 0);
        if (_whiteScore > maxLegalWhiteScore) {
          _whiteScore = maxLegalWhiteScore;
        }
        _showToast('⚠️ Queen must be covered before final piece!', AppColors.accentRed);
      }
    }

    if (blackLeft == 0 && (!_queenCovered || _needsCover)) {
      final pocketedBlack = _pieces.firstWhere(
        (p) => p.type == PieceType.black && p.isPocketed,
        orElse: () => PieceModel(id: -1, type: PieceType.black, position: Vector2.zero, radius: 0, mass: 0),
      );
      if (pocketedBlack.id != -1) {
        CarromRespotter.respotPiece(pocketedBlack, _pieces);
        blackLeft = 1;
        final int pocketedBlackAfterRespot = _pieces
            .where((p) => p.type == PieceType.black && p.isPocketed)
            .length;
        final int maxLegalBlackScore = pocketedBlackAfterRespot +
            (_queenCovered && _queenPocketedBy == PlayerColor.black ? 3 : 0);
        if (_blackScore > maxLegalBlackScore) {
          _blackScore = maxLegalBlackScore;
        }
        _showToast('⚠️ Queen must be covered before final piece!', AppColors.accentRed);
      }
    }

    // Invalidate _firstClearedBy if respotting or unresolved state reversed that player's clearance
    final bool queenResolvedNow = _queenCovered &&
        !_needsCover &&
        !_pieces.any((p) => p.type == PieceType.queen && !p.isPocketed);
    if (_firstClearedBy == PlayerColor.white &&
        (whiteLeft > 0 || _whitePenaltyDue > 0 || !queenResolvedNow)) {
      _firstClearedBy = null;
    } else if (_firstClearedBy == PlayerColor.black &&
        (blackLeft > 0 || _blackPenaltyDue > 0 || !queenResolvedNow)) {
      _firstClearedBy = null;
    }

    final outcome = CarromTurnEvaluator.evaluateMatchOutcome(
      whiteScore: _whiteScore,
      blackScore: _blackScore,
      queenCovered: _queenCovered,
      needsCover: _needsCover,
      queenCoveredBy: _queenPocketedBy,
      allPieces: _pieces,
      whiteRemaining: whiteLeft,
      blackRemaining: blackLeft,
      whitePenaltyDue: _whitePenaltyDue,
      blackPenaltyDue: _blackPenaltyDue,
      firstClearedBy: _firstClearedBy,
      clearingPlayer: _currentPlayer,
      turnResult: _turnResult,
      respotPieces: respotPieces,
    );

    // Assign _firstClearedBy only after legally finalized clearance (or invalidate to null)
    _firstClearedBy = outcome.firstClearedBy;

    if (outcome.isMatchOver && outcome.winner != null) {
      if (_stateMachine.transitionTo(GameState.gameOver)) {
        _endGame(outcome);
        return true;
      }
    }
    return false;
  }

  void _endGame(MatchOutcomeEvaluation outcome) {
    if (_isGameOverDialogShowing ||
        (outcome.winner == null && !outcome.isDraw)) {
      return;
    }
    _isGameOverDialogShowing = true;
    _cancelCpuActions();
    _turnTimer.stop();
    _toastTimer?.cancel();
    _gameLoopTicker?.stop();

    final PlayerColor? winner = outcome.winner;
    final bool isHumanWinner = !outcome.isDraw &&
        (widget.gameMode == GameMode.passAndPlay ||
            (widget.gameMode == GameMode.vsCpu &&
                winner == PlayerColor.white) ||
            widget.gameMode == GameMode.practice);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        matchOutcome: outcome,
        winner: winner,
        whiteScore: outcome.whiteScore,
        blackScore: outcome.blackScore,
        whiteRemaining: outcome.whiteRemaining,
        blackRemaining: outcome.blackRemaining,
        queenCoveredBy: outcome.queenCoveredBy,
        gameMode: widget.gameMode,
        ruleset: widget.ruleset,
        targetScore: widget.targetScore,
        isHumanWinner: isHumanWinner,
        matchId: '${widget.gameMode.name}_${DateTime.now().millisecondsSinceEpoch}',
        onRematch: () {
          Navigator.of(ctx).pop();
          setState(() {
            _initGame();
            _lastElapsed = null;
            if (_gameLoopTicker != null && !_gameLoopTicker!.isTicking) {
              _gameLoopTicker!.start();
            }
          });
        },
        onMainMenu: () {
          _isGameOverDialogShowing = false;
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showToast(String message, [Color color = AppColors.ivory]) {
    _toastTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _toastMessage = message;
      _toastColor = color;
    });

    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted && _toastMessage == message) {
        setState(() => _toastMessage = null);
      }
    });
  }

  void _onPanStart(DragStartDetails details, BoxConstraints boardConstraints) {
    if (_stateMachine.currentState != GameState.placingStriker) return;
    if (widget.gameMode == GameMode.vsCpu &&
        _currentPlayer == PlayerColor.black) {
      return;
    }

    if (!_isStrikerPlacementValid()) {
      _showToast(
        '⚠️ Striker overlapping piece! Reposition slider.',
        AppColors.accentRed,
      );
      return;
    }

    if (!_stateMachine.transitionTo(GameState.aiming)) return;

    _lastPowerTier = 0;
    AudioService().hapticLight();
    _dragStart = details.localPosition;
    _dragCurrent = details.localPosition;
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_stateMachine.currentState != GameState.aiming) return;
    _dragCurrent = details.localPosition;

    if (_dragStart != null) {
      final double power =
          math.min(1.0, (_dragCurrent! - _dragStart!).distance / 110.0);
      final int tier = power > 0.76 ? 2 : (power > 0.38 ? 1 : 0);
      if (tier != _lastPowerTier && power > 0.1) {
        _lastPowerTier = tier;
        AudioService().hapticSelection();
      }
    }
    setState(() {});
  }

  void _onPanCancel() {
    if (_stateMachine.currentState == GameState.aiming) {
      _dragStart = null;
      _dragCurrent = null;
      _stateMachine.transitionTo(GameState.placingStriker);
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_stateMachine.currentState != GameState.aiming ||
        _dragStart == null ||
        _dragCurrent == null) {
      _dragStart = null;
      _dragCurrent = null;
      if (_stateMachine.currentState == GameState.aiming) {
        _stateMachine.transitionTo(GameState.placingStriker);
      }
      setState(() {});
      return;
    }

    final Offset delta = _dragCurrent! - _dragStart!;
    final double dist = delta.distance;

    _dragStart = null;
    _dragCurrent = null;

    if (dist > 15.0) {
      if (!_isStrikerPlacementValid()) {
        _showToast(
          '⚠️ Striker overlapping piece! Reposition slider.',
          AppColors.accentRed,
        );
        _stateMachine.transitionTo(GameState.placingStriker);
        setState(() {});
        return;
      }

      if (_stateMachine.transitionTo(GameState.simulating)) {
        _turnTimer.stop();
        final Vector2 dragV = Vector2(delta.dx, delta.dy);
        final double power = math.min(1.0, dist / 110.0);
        final double powerMag = power * GameConfig.strikerMaxPower;
        final Vector2 shotVelocity = -dragV.normalized() * powerMag;

        _physics.resetAccumulator();
        _striker.velocity = shotVelocity;
        _turnResult.reset();
        AudioService().hapticMedium();
        AudioService().playShoot();
        _spawnStrikerLaunchVfx(
          _striker.position,
          -dragV.normalized(),
          power,
        );
        setState(() {});
        return;
      }
    }

    // Gesture too small or cancelled; return safely to placingStriker
    _stateMachine.transitionTo(GameState.placingStriker);
    setState(() {});
  }

  void _pauseGame({bool fromLifecycle = false}) {
    if (_stateMachine.currentState == GameState.paused ||
        _stateMachine.currentState == GameState.gameOver ||
        _isGameOverDialogShowing) {
      return;
    }

    if (_stateMachine.currentState == GameState.aiming) {
      _dragStart = null;
      _dragCurrent = null;
    }

    if (_stateMachine.currentState == GameState.cpuThinking) {
      _cancelCpuActions();
    }

    _turnTimer.pause();
    _lastElapsed = null;
    _physics.resetAccumulator();
    _stateMachine.transitionTo(GameState.paused);
    setState(() {});

    if (!fromLifecycle) {
      _showPauseDialog();
    }
  }

  void _resumeGame() {
    if (_stateMachine.currentState != GameState.paused) return;

    _lastElapsed = null;
    _physics.resetAccumulator();

    if (_gameLoopTicker != null && !_gameLoopTicker!.isTicking) {
      _gameLoopTicker!.start();
    }

    final resumeState = _stateMachine.resolveResumeState();

    if (resumeState == GameState.cpuThinking) {
      if (widget.gameMode == GameMode.vsCpu &&
          _currentPlayer == PlayerColor.black) {
        _stateMachine.transitionTo(GameState.cpuThinking);
        _turnTimer.resume();
        _scheduleCpuTurn(preserveToast: true);
      } else {
        _stateMachine.transitionTo(GameState.placingStriker);
        _turnTimer.resume();
      }
    } else if (resumeState == GameState.simulating) {
      final bool piecesMoving =
          _physics.isAnyPieceMoving || _physics.isAnyPiecePocketing;
      if (!piecesMoving) {
        _simulatingDuration = 0.0;
        if (_stateMachine.transitionTo(GameState.evaluating)) {
          _handleTurnEnd();
        } else {
          _stateMachine.transitionTo(GameState.placingStriker);
          _turnTimer.resume();
        }
      } else {
        _stateMachine.transitionTo(GameState.simulating);
      }
    } else if (resumeState == GameState.evaluating ||
        resumeState == GameState.respotting) {
      _simulatingDuration = 0.0;
      if (_stateMachine.transitionTo(GameState.evaluating)) {
        _handleTurnEnd();
      } else {
        _stateMachine.transitionTo(GameState.placingStriker);
        _turnTimer.resume();
      }
    } else if (resumeState == GameState.gameOver) {
      _stateMachine.transitionTo(GameState.gameOver);
    } else {
      _stateMachine.transitionTo(GameState.placingStriker);
      _turnTimer.resume();
    }

    setState(() {});
  }

  void _showPauseDialog() {
    if (_isPauseDialogShowing ||
        _stateMachine.isGameOver ||
        _isGameOverDialogShowing) {
      return;
    }
    _isPauseDialogShowing = true;
    _pauseGame(fromLifecycle: true);

    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 348),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.gold,
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1814243B),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: Color(0x35FFFFFF),
                  blurRadius: 1.5,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Header with Close Button
                  Row(
                    children: [
                      const SizedBox(width: 32),
                      Expanded(
                        child: Text(
                          'GAME PAUSED',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          AudioService().hapticSelection();
                          Navigator.of(ctx).pop('resume');
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cardBgElevated,
                            border: Border.all(
                              color: AppColors.cardBorder,
                            ),
                          ),
                          child: const Center(
                            child: ClubIcon(
                              type: ClubIconType.close,
                              color: AppColors.textSecondary,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Primary Resume CTA (Gold Hero Button)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AudioService().hapticSelection();
                        Navigator.of(ctx).pop('resume');
                      },
                      icon: const ClubIcon(
                        type: ClubIconType.play,
                        size: 16,
                        color: AppColors.bgDark,
                      ),
                      label: Text(
                        'RESUME',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          fontSize: 13.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.bgDark,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Action Menu Items
                  _pauseActionTile(
                    customIcon: ClubIconType.restart,
                    label: 'Restart Match',
                    color: AppColors.ivoryWarm,
                    onTap: () {
                      AudioService().hapticSelection();
                      Navigator.of(ctx).pop('restart');
                    },
                  ),
                  const SizedBox(height: 8),
                  _pauseActionTile(
                    customIcon: ClubIconType.school,
                    label: 'How to Play / Rules',
                    color: AppColors.tealLight,
                    onTap: () {
                      AudioService().hapticSelection();
                      TutorialDialog.show(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  _pauseActionTile(
                    customIcon: ClubIconType.settings,
                    label: 'Club Settings',
                    color: AppColors.ivoryWarm,
                    onTap: () async {
                      AudioService().hapticSelection();
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                      if (mounted) {
                        setState(() {
                          _boardTheme = StorageService().getBoardTheme();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _pauseActionTile(
                    customIcon: ClubIconType.trophy,
                    label: 'Themes & Boards',
                    color: AppColors.goldBright,
                    onTap: () async {
                      AudioService().hapticSelection();
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ThemeCollectionScreen(),
                        ),
                      );
                      if (mounted) {
                        setState(() {
                          _boardTheme = StorageService().getBoardTheme();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _pauseActionTile(
                    customIcon: ClubIconType.home,
                    label: 'Quit to Menu',
                    color: AppColors.ivoryWarm,
                    onTap: () {
                      AudioService().hapticSelection();
                      Navigator.of(ctx).pop('quit');
                    },
                  ),

                  const SizedBox(height: 14),

                  // Compact Quick Audio & Haptic Toggles
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBgElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.cardBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        _pauseToggleTile(
                          customIcon: ClubIconType.sfx,
                          label: 'Sound Effects',
                          value: AudioService().sfxEnabled,
                          onChanged: (val) {
                            setDialogState(() {
                              AudioService().sfxEnabled = val;
                              StorageService().setSfxEnabled(val);
                            });
                            setState(() {});
                          },
                        ),
                        Divider(
                          color: AppColors.cardBorderSubtle,
                          height: 1,
                        ),
                        _pauseToggleTile(
                          customIcon: ClubIconType.music,
                          label: 'Background Music',
                          value: AudioService().musicEnabled,
                          onChanged: (val) {
                            setDialogState(() {
                              AudioService().musicEnabled = val;
                              StorageService().setMusicEnabled(val);
                              if (val) {
                                AudioService().playBgm();
                              } else {
                                AudioService().pauseBgm();
                              }
                            });
                            setState(() {});
                          },
                        ),
                        Divider(
                          color: AppColors.cardBorderSubtle,
                          height: 1,
                        ),
                        _pauseToggleTile(
                          customIcon: ClubIconType.haptic,
                          label: 'Haptic Vibration',
                          value: AudioService().hapticsEnabled,
                          onChanged: (val) {
                            setDialogState(() {
                              AudioService().hapticsEnabled = val;
                              StorageService().setHapticsEnabled(val);
                            });
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((action) {
      _isPauseDialogShowing = false;
      if (action == 'quit') {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (action == 'restart') {
        if (mounted) setState(() => _initGame());
        return;
      }
      if (mounted && _stateMachine.currentState == GameState.paused) {
        _resumeGame();
      }
    });
  }

  Widget _pauseToggleTile({
    required ClubIconType customIcon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ClubIcon(type: customIcon, color: AppColors.goldLight, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ClubToggleSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _pauseActionTile({
    required ClubIconType customIcon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBgElevated,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClubIcon(type: customIcon, color: color, size: 18),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelCpuActions();
    _toastTimer?.cancel();
    _turnTimer.dispose();
    _gameLoopTicker?.dispose();
    _glowController.dispose();
    _cpuAnimController?.dispose();
    _stateMachine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = ClubMotion.isReducedMotion(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!_isPauseDialogShowing && !_stateMachine.isGameOver) {
          _showPauseDialog();
        } else if (_stateMachine.isGameOver) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: ClubBackground(
        preset: ClubBackgroundPreset.gameplay,
        showWatermark: false,
        accentTint: AppColors.getThemeAccent(_boardTheme),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              final bool isPassAndPlay = widget.gameMode == GameMode.passAndPlay;
              final bool isFreestyle = widget.ruleset == CarromRuleset.freestyle;
              final bool isWhiteTurn = _currentPlayer == PlayerColor.white;
              final bool isPlayer2TurnAtTop = isPassAndPlay && !isWhiteTurn;

              // In Pass & Play, reserve height for Top Section (~156px) and Bottom Section (~124px)
              // ensuring zero overflow on smaller screens and zero vertical shifts between turns.
              final double hudAndControlsReserve = isPassAndPlay ? 280.0 : 236.0;
              final double maxBoardDim = math.max(
                120.0,
                math.min(
                  viewport.maxWidth - 8.0,
                  viewport.maxHeight - hudAndControlsReserve,
                ),
              );

              final String p1Name = isPassAndPlay
                  ? 'Player 1'
                  : (isFreestyle ? 'You (P1)' : 'You (White)');
              String p2Name = isPassAndPlay
                  ? 'Player 2'
                  : (isFreestyle ? 'CPU (P2)' : 'CPU (Black)');

              if (widget.gameMode == GameMode.practice) {
                p2Name = 'Target';
              }

              final int whiteRemaining = _pieces
                  .where((p) => p.type == PieceType.white && !p.isPocketed)
                  .length;
              final int blackRemaining = _pieces
                  .where((p) => p.type == PieceType.black && !p.isPocketed)
                  .length;

              String queenText = isFreestyle
                  ? 'Q:50 · W:20 · B:10'
                  : '👑 Queen in Play';
              Color queenColor = AppColors.goldLight;
              if (_queenCovered) {
                queenText = isFreestyle
                    ? '👑 Queen Covered! (+${GameConfig.freestyleQueenPoints})'
                    : '👑 Queen Covered! (+3)';
                queenColor = AppColors.accentGreen;
              } else if (_queenPocketed) {
                queenText = isFreestyle
                    ? '👑 Cover Queen (+${GameConfig.freestyleQueenPoints})!'
                    : '👑 Cover Queen!';
                queenColor = AppColors.queenPiece;
              }

              final String turnLabel = widget.gameMode == GameMode.practice
                  ? 'Practice Arena'
                  : (isWhiteTurn
                      ? (isPassAndPlay
                          ? 'Player 1 Turn'
                          : 'Your Turn')
                      : (widget.gameMode == GameMode.vsCpu
                          ? 'CPU Turn'
                          : 'Player 2 Turn'));

              final Widget boardWidget = _buildCarromBoardWidget(
                maxBoardDim: maxBoardDim,
                reducedMotion: reducedMotion,
              );

              // 1. Single-player / Practice modes: Original layout preserved untouched
              if (!isPassAndPlay) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 6.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTopOpponentRow(
                                p2Name: p2Name,
                                blackRemaining: blackRemaining,
                                isWhiteTurn: isWhiteTurn,
                              ),
                              const SizedBox(height: 8),
                              _buildIndicatorsRow(
                                isWhiteTurn: isWhiteTurn,
                                turnLabel: turnLabel,
                                queenText: queenText,
                                queenColor: queenColor,
                              ),
                            ],
                          ),
                          boardWidget,
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildBottomPlayerRow(
                                p1Name: p1Name,
                                whiteRemaining: whiteRemaining,
                                isWhiteTurn: isWhiteTurn,
                              ),
                              const SizedBox(height: 8),
                              _buildBottomControls(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // 2. Pass & Play Mode: Fixed-slot layout guaranteeing ZERO layout shifts / jumps between turns
              final double availHeight = viewport.maxHeight - 12.0;
              final double remainingHeight = math.max(
                hudAndControlsReserve,
                availHeight - maxBoardDim,
              );
              final double topAreaHeight = remainingHeight * (158.0 / 282.0);
              final double bottomAreaHeight = remainingHeight - topAreaHeight;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 6.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Slot (Fixed height, no shift)
                        SizedBox(
                          height: topAreaHeight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTopOpponentRow(
                                p2Name: p2Name,
                                blackRemaining: blackRemaining,
                                isWhiteTurn: isWhiteTurn,
                              ),
                              const SizedBox(height: 6),
                              _buildIndicatorsRow(
                                isWhiteTurn: isWhiteTurn,
                                turnLabel: turnLabel,
                                queenText: queenText,
                                queenColor: queenColor,
                              ),
                              if (isPlayer2TurnAtTop) ...[
                                const SizedBox(height: 6),
                                _buildBottomControls(),
                              ],
                            ],
                          ),
                        ),

                        // Center Section: Carrom Board (Invariant Y-position across turns)
                        boardWidget,

                        // Bottom Slot (Fixed height, no shift)
                        SizedBox(
                          height: bottomAreaHeight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildBottomPlayerRow(
                                p1Name: p1Name,
                                whiteRemaining: whiteRemaining,
                                isWhiteTurn: isWhiteTurn,
                              ),
                              if (!isPlayer2TurnAtTop) ...[
                                const SizedBox(height: 6),
                                _buildBottomControls(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildCarromBoardWidget({
    required double maxBoardDim,
    required bool reducedMotion,
  }) {
    return SizedBox(
      width: maxBoardDim,
      height: maxBoardDim,
      child: LayoutBuilder(
        builder: (context, boardConstraints) {
          return GestureDetector(
            onPanStart: (d) => _onPanStart(d, boardConstraints),
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onPanCancel: _onPanCancel,
            child: Stack(
              children: [
                // 1. Carrom Board Surface & Frame
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(
                      boardConstraints.maxWidth,
                      boardConstraints.maxHeight,
                    ),
                    painter: BoardPainter(theme: _boardTheme),
                  ),
                ),

                // 2. Aim Trajectory & Power Gauge
                if ((_stateMachine.isAiming || _stateMachine.isCpuThinking) &&
                    _dragStart != null &&
                    _dragCurrent != null)
                  CustomPaint(
                    size: Size(
                      boardConstraints.maxWidth,
                      boardConstraints.maxHeight,
                    ),
                    painter: AimPainter(
                      strikerPos: _striker.position,
                      dragVector: Vector2(
                        _dragCurrent!.dx - _dragStart!.dx,
                        _dragCurrent!.dy - _dragStart!.dy,
                      ),
                      power: math.min(
                        1.0,
                        (_dragCurrent! - _dragStart!).distance / 110.0,
                      ),
                    ),
                  ),

                // 3. Pieces & Striker
                CustomPaint(
                  size: Size(
                    boardConstraints.maxWidth,
                    boardConstraints.maxHeight,
                  ),
                  painter: PiecePainter(
                    theme: _boardTheme,
                    pieces: _pieces,
                    striker: _striker,
                    strikerGlowPhase:
                        reducedMotion ? 0.5 : _glowController.value,
                    isAiming: (_stateMachine.isAiming ||
                            _stateMachine.isCpuThinking) &&
                        _dragStart != null &&
                        _dragCurrent != null,
                    aimPower: (_stateMachine.isAiming ||
                                _stateMachine.isCpuThinking) &&
                            _dragStart != null &&
                            _dragCurrent != null
                        ? math.min(
                            1.0,
                            (_dragCurrent! - _dragStart!).distance / 110.0,
                          )
                        : 0.0,
                    aimAngle: (_stateMachine.isAiming ||
                                _stateMachine.isCpuThinking) &&
                            _dragStart != null &&
                            _dragCurrent != null
                        ? math.atan2(
                            _dragStart!.dy - _dragCurrent!.dy,
                            _dragStart!.dx - _dragCurrent!.dx,
                          )
                        : 0.0,
                    strikerTrail:
                        reducedMotion ? const [] : _strikerTrail,
                  ),
                ),

                // 4. Celebration Sparkles & Floating Scores
                CustomPaint(
                  size: Size(
                    boardConstraints.maxWidth,
                    boardConstraints.maxHeight,
                  ),
                  painter: ParticlePainter(
                    particles: _particles,
                    rings: _rings,
                    floatingScores: _floatingScores,
                    strikerSparks:
                        reducedMotion ? const [] : _strikerSparks,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopOpponentRow({
    required String p2Name,
    required int blackRemaining,
    required bool isWhiteTurn,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Circular Pause Button positioned immediately to the left of CPU card
          _buildPauseButton(),
          const SizedBox(width: 10),
          // CPU / Opponent Card at Top-Right
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 165, maxWidth: 220),
            child: _playerBadge(
              name: p2Name,
              score: _blackScore,
              remaining: blackRemaining,
              penaltyDue: _blackPenaltyDue,
              isTurn: !isWhiteTurn && widget.gameMode != GameMode.practice,
              isWhitePiece: false,
              alignRight: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton() {
    return GestureDetector(
      onTap: (_stateMachine.isPaused || _stateMachine.isGameOver)
          ? null
          : () => _showPauseDialog(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.cardBg,
          border: Border.all(
            color: AppColors.gold,
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1414243B),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
            BoxShadow(
              color: Color(0x40FFFFFF),
              blurRadius: 1.5,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const ClubIcon(
              type: ClubIconType.pause,
              color: AppColors.goldLight,
              size: 20,
            ),
            // Semantics / test finder anchor
            Opacity(
              opacity: 0.01,
              child: const Icon(
                Icons.pause_circle_filled_rounded,
                size: 24,
                color: AppColors.goldLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorsRow({
    required bool isWhiteTurn,
    required String turnLabel,
    required String queenText,
    required Color queenColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Prominent Turn Pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 5.5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isWhiteTurn
                  ? const LinearGradient(
                      colors: [Color(0xFFE8BD56), Color(0xFFC5993B)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF334B68), Color(0xFF1E2E42)],
                    ),
              border: Border.all(
                color: isWhiteTurn ? AppColors.gold : const Color(0xFF6B8DB5),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isWhiteTurn
                      ? const Color(0x28C5993B)
                      : const Color(0x281E2E42),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              turnLabel,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: isWhiteTurn
                    ? const Color(0xFF162030)
                    : AppColors.ivory,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Queen Status Pill
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5.5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.cardBg,
              border: Border.all(
                color: queenColor.withOpacity(0.55),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1014243B),
                  blurRadius: 6,
                  offset: Offset(0, 1.5),
                ),
              ],
            ),
            child: Text(
              queenText,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: queenColor,
              ),
            ),
          ),

          if (_toastMessage != null) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.cardBg,
                  border: Border.all(
                    color: _toastColor.withOpacity(0.55),
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1014243B),
                      blurRadius: 6,
                      offset: Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Text(
                  _toastMessage!,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _toastColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomPlayerRow({
    required String p1Name,
    required int whiteRemaining,
    required bool isWhiteTurn,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Player Card at Bottom-Left (directly below board)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 165, maxWidth: 220),
            child: _playerBadge(
              name: p1Name,
              score: _whiteScore,
              remaining: whiteRemaining,
              penaltyDue: _whitePenaltyDue,
              isTurn: isWhiteTurn,
              isWhitePiece: true,
              alignRight: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerBadge({
    required String name,
    required int score,
    required int remaining,
    int penaltyDue = 0,
    required bool isTurn,
    required bool isWhitePiece,
    required bool alignRight,
  }) {
    final bool isFreestyle = widget.ruleset == CarromRuleset.freestyle;
    final bool showActiveTimer =
        isTurn && widget.gameMode != GameMode.practice && _turnTimer.enabled;

    final Widget coinAvatar = ClubTurnTimerRing(
      controller: _turnTimer,
      isActiveTurn: showActiveTimer,
      size: 34,
      child: isFreestyle
          ? Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTurn
                    ? const Color(0xFFF7E6B8)
                    : AppColors.cardBgElevated,
                border: Border.all(
                  color: isTurn ? AppColors.gold : AppColors.cardBorder,
                  width: 1.0,
                ),
              ),
              child: Icon(
                alignRight
                    ? (widget.gameMode == GameMode.vsCpu
                        ? Icons.smart_toy_rounded
                        : Icons.person_outline_rounded)
                    : Icons.person_rounded,
                size: 16,
                color: isTurn
                    ? const Color(0xFF946A14)
                    : AppColors.textSecondary,
              ),
            )
          : ClubCoinBadge(
              theme: _boardTheme,
              isWhite: isWhitePiece,
              size: 26,
            ),
    );
    final String remainingText = isFreestyle
        ? '• /${widget.targetScore}'
        : (penaltyDue > 0
            ? '• $remaining left ($penaltyDue Due)'
            : '• $remaining left');

    final Widget infoColumn = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alignRight && showActiveTimer) ...[
                ClubTurnTimerPill(
                  controller: _turnTimer,
                  isActiveTurn: showActiveTimer,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: isTurn ? FontWeight.w800 : FontWeight.w600,
                    color:
                        isTurn ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              if (!alignRight && showActiveTimer) ...[
                const SizedBox(width: 4),
                ClubTurnTimerPill(
                  controller: _turnTimer,
                  isActiveTurn: showActiveTimer,
                ),
              ],
            ],
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score pts',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isTurn ? const Color(0xFFB8861E) : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  remainingText,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: penaltyDue > 0 && !isFreestyle
                        ? const Color(0xFFE5484D)
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isTurn ? const Color(0xFFFFFBF2) : AppColors.cardBg,
        border: Border.all(
          color: isTurn
              ? (_turnTimer.isWarning && showActiveTimer
                  ? AppColors.accentRed
                  : AppColors.gold)
              : AppColors.cardBorder,
          width: isTurn ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isTurn ? const Color(0x22C5993B) : const Color(0x1014243B),
            blurRadius: isTurn ? 12 : 8,
            offset: const Offset(0, 3),
          ),
          const BoxShadow(
            color: Color(0x35FFFFFF),
            blurRadius: 1.5,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: alignRight
            ? [infoColumn, const SizedBox(width: 8), coinAvatar]
            : [coinAvatar, const SizedBox(width: 8), infoColumn],
      ),
    );
  }

  Widget _buildBottomControls() {
    final bool isStrikerBlocked = !_isStrikerPlacementValid();
    final bool canInteract = _stateMachine.isInteractive &&
        !(widget.gameMode == GameMode.vsCpu &&
            _currentPlayer == PlayerColor.black);

    double currentAimPower = 0.0;
    if ((_stateMachine.isAiming || _stateMachine.isCpuThinking) &&
        _dragStart != null &&
        _dragCurrent != null) {
      currentAimPower =
          math.min(1.0, (_dragCurrent! - _dragStart!).distance / 110.0);
    }

    String statusHint;
    Color statusColor;

    if (_stateMachine.isPaused) {
      statusHint = 'Game Paused';
      statusColor = AppColors.textMuted;
    } else if (_stateMachine.isCpuThinking) {
      if (currentAimPower > 0.05) {
        final int powerPercent = (currentAimPower * 100).round();
        statusHint = 'CPU Power: $powerPercent%';
      } else {
        statusHint = 'CPU is lining up shot...';
      }
      statusColor = AppColors.accentBlue;
    } else if (_stateMachine.isSimulating) {
      statusHint = 'Shot in motion...';
      statusColor = AppColors.goldLight;
    } else if (_stateMachine.currentState == GameState.evaluating ||
        _stateMachine.currentState == GameState.respotting) {
      statusHint = 'Evaluating turn...';
      statusColor = AppColors.goldLight;
    } else if (_stateMachine.isAiming) {
      if (currentAimPower > 0.05) {
        statusHint =
            'POWER ${(currentAimPower * 100).round()}% • Release to shoot';
        statusColor = currentAimPower > 0.75
            ? AppColors.accentRed
            : (currentAimPower > 0.38
                ? AppColors.accentAmber
                : AppColors.accentGreen);
      } else {
        statusHint = 'Aiming • Drag away to power up (or return to cancel)';
        statusColor = AppColors.goldLight;
      }
    } else if (isStrikerBlocked) {
      statusHint = 'Overlapping piece • Slide to clear spot';
      statusColor = AppColors.accentRed;
    } else {
      statusHint = 'Slide striker • Drag board to aim & flick';
      statusColor = AppColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isStrikerBlocked
                ? AppColors.accentRed.withOpacity(0.65)
                : AppColors.cardBorder,
            width: 1.2,
          ),
          boxShadow: [
            const BoxShadow(
              color: Color(0x1414243B),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
            const BoxShadow(
              color: Color(0x35FFFFFF),
              blurRadius: 1.5,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact Status / Power Bar Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STRIKER POSITION',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      statusHint,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: (isStrikerBlocked || _stateMachine.isAiming)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            // Baseline Track Slider with Nudge Left & Right Buttons
            Row(
              children: [
                // Nudge Left Button
                _nudgeButton(
                  customIcon: ClubIconType.nudgeLeft,
                  tooltip: 'Nudge Left',
                  enabled: canInteract,
                  onTap: () {
                    AudioService().hapticLight();
                    setState(() {
                      _strikerSliderX = (_strikerSliderX - 3.5)
                          .clamp(_sliderMinX, _sliderMaxX);
                      final double y = _currentPlayer == PlayerColor.white
                          ? GameConfig.baselineYWhite
                          : GameConfig.baselineYBlack;
                      _striker.position = Vector2(_strikerSliderX, y);
                    });
                  },
                ),

                const SizedBox(width: 8),

                // Baseline Track
                Expanded(
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      color: AppColors.cardBgElevated,
                      border: Border.all(
                        color: isStrikerBlocked
                            ? AppColors.accentRed.withOpacity(0.65)
                            : AppColors.cardBorder,
                        width: 1.0,
                      ),
                    ),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: isStrikerBlocked
                            ? AppColors.accentRed
                            : AppColors.gold,
                        inactiveTrackColor: const Color(0xFFD4C8B5),
                        thumbColor: isStrikerBlocked
                            ? AppColors.accentRed
                            : AppColors.gold,
                        overlayColor: (isStrikerBlocked
                                ? AppColors.accentRed
                                : AppColors.gold)
                            .withOpacity(0.16),
                        trackHeight: 4.5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 9.5,
                        ),
                      ),
                      child: Slider(
                        value: _strikerSliderX,
                        min: _sliderMinX,
                        max: _sliderMaxX,
                        onChanged: canInteract
                            ? (val) {
                                setState(() {
                                  _strikerSliderX = val;
                                  final double y =
                                      _currentPlayer == PlayerColor.white
                                          ? GameConfig.baselineYWhite
                                          : GameConfig.baselineYBlack;
                                  _striker.position = Vector2(val, y);
                                });
                              }
                            : null,
                        onChangeEnd: canInteract
                            ? (val) {
                                final double y =
                                    _currentPlayer == PlayerColor.white
                                        ? GameConfig.baselineYWhite
                                        : GameConfig.baselineYBlack;
                                final double safeX = _findValidStrikerX(val, y);
                                if (safeX != val) {
                                  AudioService().hapticSelection();
                                  setState(() {
                                    _strikerSliderX = safeX;
                                    _striker.position = Vector2(safeX, y);
                                  });
                                }
                              }
                            : null,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Nudge Right Button
                _nudgeButton(
                  customIcon: ClubIconType.nudgeRight,
                  tooltip: 'Nudge Right',
                  enabled: canInteract,
                  onTap: () {
                    AudioService().hapticLight();
                    setState(() {
                      _strikerSliderX = (_strikerSliderX + 3.5)
                          .clamp(_sliderMinX, _sliderMaxX);
                      final double y = _currentPlayer == PlayerColor.white
                          ? GameConfig.baselineYWhite
                          : GameConfig.baselineYBlack;
                      _striker.position = Vector2(_strikerSliderX, y);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nudgeButton({
    required ClubIconType customIcon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final Color iconColor = enabled
        ? AppColors.goldLight
        : AppColors.textMuted.withOpacity(0.35);

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.cardBgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C14243B),
            blurRadius: 6,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: ClubIcon(type: customIcon, size: 16, color: iconColor),
        tooltip: tooltip,
        onPressed: enabled ? onTap : null,
      ),
    );
  }
}
