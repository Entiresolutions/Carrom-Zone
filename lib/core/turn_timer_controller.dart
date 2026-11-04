import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'game_config.dart';

/// State-driven, deterministic Ludo Star-style turn countdown controller.
///
/// Guarantees:
/// - Starts a fresh countdown on every new turn or continuation shot.
/// - Stops immediately when a shot is released into physics simulation.
/// - Pauses/resumes cleanly across pause dialogs and app lifecycle transitions.
/// - Fires [onTimeout] at most once per turn token, preventing double-timeout
///   or race conditions between shot release and timer expiration.
class TurnTimerController extends ChangeNotifier {
  final double turnDurationSeconds;
  final double warningThresholdSeconds;
  final bool enabled;
  final void Function(int turnToken)? onTimeout;
  final void Function(int secondsRemaining)? onWarningTick;

  double _remainingSeconds;
  bool _isRunning = false;
  bool _isPaused = false;
  int _activeTurnToken = 0;
  int _lastTimedOutToken = -1;
  int _lastWarningSecondNotified = -1;

  TurnTimerController({
    this.turnDurationSeconds = GameConfig.defaultTurnDurationSeconds,
    this.warningThresholdSeconds = GameConfig.turnWarningThresholdSeconds,
    this.enabled = true,
    this.onTimeout,
    this.onWarningTick,
  }) : _remainingSeconds = turnDurationSeconds;

  /// Remaining seconds on the active shot clock.
  double get remainingSeconds => _remainingSeconds;

  /// Integer seconds for HUD display (ceiling of remaining seconds).
  int get displaySeconds =>
      _remainingSeconds.ceil().clamp(0, turnDurationSeconds.ceil());

  /// Normalized countdown progress from 1.0 (full) down to 0.0 (expired).
  double get progress => turnDurationSeconds > 0
      ? (_remainingSeconds / turnDurationSeconds).clamp(0.0, 1.0)
      : 0.0;

  /// Whether the shot clock is actively counting down.
  bool get isRunning => _isRunning;

  /// Whether the shot clock is temporarily paused.
  bool get isPaused => _isPaused;

  /// Whether the shot clock is in the final warning window (last 5 seconds).
  bool get isWarning =>
      enabled &&
      _isRunning &&
      !_isPaused &&
      _remainingSeconds > 0.0 &&
      _remainingSeconds <= warningThresholdSeconds;

  /// Monotonically increasing token identifying the current shot opportunity.
  int get activeTurnToken => _activeTurnToken;

  /// Whether the current turn timer has expired.
  bool get isExpired => _remainingSeconds <= 0.0;

  /// Starts a fresh countdown for a new turn or continuation shot.
  /// Returns the new [activeTurnToken].
  int startNewTurn() {
    _activeTurnToken++;
    _remainingSeconds = turnDurationSeconds;
    _lastWarningSecondNotified = -1;
    _isPaused = false;
    _isRunning = enabled;
    notifyListeners();
    return _activeTurnToken;
  }

  /// Immediately stops the countdown (e.g., when a valid shot is released or match ends).
  void stop() {
    if (!_isRunning && !_isPaused) return;
    _isRunning = false;
    _isPaused = false;
    notifyListeners();
  }

  /// Pauses the active countdown without losing remaining time.
  void pause() {
    if (!_isRunning || _isPaused) return;
    _isPaused = true;
    notifyListeners();
  }

  /// Resumes a paused countdown.
  void resume() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    notifyListeners();
  }

  /// Advances the countdown by [dt] seconds.
  /// Returns `true` if the timer expired on this tick, `false` otherwise.
  bool tick(double dt) {
    if (!enabled ||
        !_isRunning ||
        _isPaused ||
        dt <= 0.0 ||
        dt.isNaN ||
        dt.isInfinite) {
      return false;
    }

    _remainingSeconds = math.max(0.0, _remainingSeconds - dt);

    // Trigger once-per-second warning feedback in the final warning window
    if (_remainingSeconds > 0.0 &&
        _remainingSeconds <= warningThresholdSeconds) {
      final int secLeft = _remainingSeconds.ceil();
      if (secLeft != _lastWarningSecondNotified &&
          secLeft >= 1 &&
          secLeft <= warningThresholdSeconds.ceil()) {
        _lastWarningSecondNotified = secLeft;
        onWarningTick?.call(secLeft);
      }
    }

    // Check expiration and guard against duplicate timeout invocations
    if (_remainingSeconds <= 0.0) {
      _remainingSeconds = 0.0;
      _isRunning = false;
      _isPaused = false;
      if (_lastTimedOutToken != _activeTurnToken) {
        _lastTimedOutToken = _activeTurnToken;
        notifyListeners();
        onTimeout?.call(_activeTurnToken);
        return true;
      }
      notifyListeners();
      return false;
    }

    notifyListeners();
    return false;
  }
}

/// Ludo Star-style circular animated countdown ring wrapping a player's badge/avatar.
class ClubTurnTimerRing extends StatelessWidget {
  final TurnTimerController controller;
  final bool isActiveTurn;
  final Widget child;
  final double size;

  const ClubTurnTimerRing({
    super.key,
    required this.controller,
    required this.isActiveTurn,
    required this.child,
    this.size = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.enabled || !isActiveTurn) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      );
    }

    final bool isWarning = controller.isWarning;
    final double progress = controller.progress;
    final Color ringColor =
        isWarning ? AppColors.accentRed : AppColors.goldBright;

    // Subtle pulse during final 5-second warning
    final double fractionalSec =
        controller.remainingSeconds - controller.remainingSeconds.floor();
    final double pulseScale = isWarning
        ? 1.0 + 0.06 * math.sin(fractionalSec * math.pi)
        : 1.0;

    return Transform.scale(
      scale: pulseScale,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _TurnTimerRingPainter(
                progress: progress,
                ringColor: ringColor,
                trackColor: isWarning
                    ? AppColors.accentRed.withOpacity(0.20)
                    : AppColors.gold.withOpacity(0.22),
                strokeWidth: 2.8,
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Compact countdown pill displaying remaining seconds (`18s`) on the active HUD card.
class ClubTurnTimerPill extends StatelessWidget {
  final TurnTimerController controller;
  final bool isActiveTurn;

  const ClubTurnTimerPill({
    super.key,
    required this.controller,
    required this.isActiveTurn,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.enabled || !isActiveTurn || !controller.isRunning) {
      return const SizedBox.shrink();
    }

    final bool isWarning = controller.isWarning;
    final Color fgColor =
        isWarning ? AppColors.accentRed : const Color(0xFF8B6415);
    final Color bgColor =
        isWarning ? const Color(0xFFFDECEC) : const Color(0xFFFFF6DF);
    final Color borderColor =
        isWarning ? AppColors.accentRed.withOpacity(0.65) : AppColors.gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 10,
            color: fgColor,
          ),
          const SizedBox(width: 2.5),
          Text(
            '${controller.displaySeconds}s',
            style: GoogleFonts.outfit(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: fgColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnTimerRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  const _TurnTimerRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0.0) {
      final Paint arcPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final double sweepAngle = 2.0 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TurnTimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.trackColor != trackColor;
  }
}

