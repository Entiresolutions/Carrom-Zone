import 'dart:math' as math;
import '../core/vector2.dart';
import '../core/game_config.dart';
import '../models/piece_model.dart';

typedef CollisionCallback = void Function(double impulse);
typedef WallCallback = void Function();
typedef PocketCallback = void Function(PieceModel piece, Vector2 pocket);
typedef StrikerCollisionCallback = void Function(Vector2 contactPoint, double impulse, bool isWall);

class CarromPhysics {
  final List<PieceModel> pieces;
  final PieceModel striker;

  CollisionCallback? onPieceCollision;
  WallCallback? onWallCollision;
  PocketCallback? onPocket;
  StrikerCollisionCallback? onStrikerCollision;

  // Fixed timestep physics parameters
  static const double fixedTimeStep = 1.0 / 60.0;
  static const double maxAccumulatedTime = 0.1; // Caps spiral of death under sudden frame drops
  static const int subSteps = 6;
  static const double subDt = fixedTimeStep / subSteps; // 1.0 / 360.0 reference

  double _accumulator = 0.0;

  double get accumulator => _accumulator;

  void resetAccumulator() {
    _accumulator = 0.0;
  }

  CarromPhysics({
    required this.pieces,
    required this.striker,
    this.onPieceCollision,
    this.onWallCollision,
    this.onPocket,
    this.onStrikerCollision,
  });

  final List<PieceModel> _activePieces = [];

  List<PieceModel> get allActivePieces {
    _populateActivePieces();
    return List.unmodifiable(_activePieces);
  }

  void _populateActivePieces() {
    _activePieces.clear();
    for (int i = 0; i < pieces.length; i++) {
      final p = pieces[i];
      if (!p.isPocketed) _activePieces.add(p);
    }
    if (!striker.isPocketed) {
      _activePieces.add(striker);
    }
  }

  bool get isAnyPieceMoving {
    if (striker.isMoving && !striker.isPocketed) return true;
    for (final p in pieces) {
      if (!p.isPocketed && p.isMoving) return true;
    }
    return false;
  }

  bool get isAnyPiecePocketing {
    if (striker.isPocketed && striker.pocketProgress < 1.0) return true;
    for (final p in pieces) {
      if (p.isPocketed && p.pocketProgress < 1.0) return true;
    }
    return false;
  }

  /// Advances physics simulation using a fixed timestep with a bounded accumulator.
  /// Frame-rate independent: identical total elapsed time yields identical simulation steps.
  void update(double dt) {
    if (dt <= 0.0 || dt.isNaN || dt.isInfinite) return;

    // Bounded clamp prevents spiral of death during backgrounding or frame drops
    final double clampedDt = math.min(dt, maxAccumulatedTime);
    _accumulator += clampedDt;

    while (_accumulator >= fixedTimeStep) {
      step(fixedTimeStep);
      _accumulator -= fixedTimeStep;
    }
  }

  /// Executes a single discrete simulation step divided into 6 substeps.
  void step(double dt) {
    if (dt <= 0.0 || dt.isNaN || dt.isInfinite) return;

    final double stepSubDt = dt / subSteps;
    _populateActivePieces();

    for (int step = 0; step < subSteps; step++) {
      _integratePositions(stepSubDt);
      _checkPocketCapture(stepSubDt);
      _resolveCircleCollisions();
      _resolveWallCollisions();
      _applyFriction(stepSubDt);
    }

    _updatePocketShrinkAnimations(dt);
    _sanitizeStates();
  }

  void _integratePositions(double dt) {
    final double moveFactor = dt * 60.0;
    for (int i = 0; i < _activePieces.length; i++) {
      final p = _activePieces[i];
      if (p.isPocketed) continue;
      p.position = p.position + (p.velocity * moveFactor);
    }
  }

  void _applyFriction(double dt) {
    final double stepTime = dt * 60.0;
    final double damping = math.pow(1.0 - GameConfig.friction, stepTime).toDouble();
    final double airDamping = math.pow(1.0 - GameConfig.frictionAir, stepTime).toDouble();
    final double combined = damping * airDamping;

    const double stopThreshSq =
        GameConfig.velocityStopThreshold * GameConfig.velocityStopThreshold;

    for (int i = 0; i < _activePieces.length; i++) {
      final p = _activePieces[i];
      if (p.isPocketed) continue;
      p.velocity = p.velocity * combined;
      if (p.velocity.lengthSquared < stopThreshSq) {
        p.velocity = Vector2.zero;
      }
    }
  }

  void _resolveCircleCollisions() {
    final int count = _activePieces.length;

    for (int i = 0; i < count; i++) {
      final a = _activePieces[i];
      if (a.isPocketed) continue;

      for (int j = i + 1; j < count; j++) {
        final b = _activePieces[j];
        if (b.isPocketed) continue;

        final double minDistance = a.radius + b.radius;
        final double distSq = a.position.distanceSquaredTo(b.position);

        if (distSq < minDistance * minDistance) {
          // Gracefully resolve exact zero-distance or near-zero distance overlap
          final double distance = math.sqrt(math.max(distSq, 1e-10));
          final Vector2 normal = distSq > 1e-8
              ? (b.position - a.position) / distance
              : const Vector2(1.0, 0.0); // Deterministic separation axis

          // Relative velocity along normal
          final Vector2 relativeVelocity = b.velocity - a.velocity;
          final double velAlongNormal = relativeVelocity.dot(normal);

          // Only apply impulse if pieces are moving towards each other
          if (velAlongNormal < 0) {
            const double e = GameConfig.restitution;
            final double impulseMag = -(1.0 + e) * velAlongNormal /
                ((1.0 / a.mass) + (1.0 / b.mass));

            final Vector2 impulse = normal * impulseMag;
            a.velocity = a.velocity - (impulse / a.mass);
            b.velocity = b.velocity + (impulse / b.mass);

            onPieceCollision?.call(impulseMag);

            if (a.type == PieceType.striker || b.type == PieceType.striker) {
              final double ratioA = a.radius / (a.radius + b.radius);
              final Vector2 contact = a.position + (b.position - a.position) * ratioA;
              onStrikerCollision?.call(contact, impulseMag, false);
            }
          }

          // Positional correction to prevent sink/overlap
          final double overlap = minDistance - distance;
          if (overlap > 0) {
            const double percent = 0.8;
            final Vector2 correction =
                normal * (overlap * percent / (a.mass + b.mass));
            a.position = a.position - (correction * b.mass);
            b.position = b.position + (correction * a.mass);
          }
        }
      }
    }
  }

  void _resolveWallCollisions() {
    const double halfPlay = GameConfig.halfBoard - 16.0; // 184.0
    const double pocketGap = GameConfig.pocketRadius + 8.0; // 27.0
    const double maxOuterBound = GameConfig.halfBoard - 4.0; // 196.0

    for (int i = 0; i < _activePieces.length; i++) {
      final p = _activePieces[i];
      if (p.isPocketed) continue;

      // In the corners, check if near corner pocket opening
      final bool nearCornerX = (p.position.x.abs() > halfPlay - pocketGap);
      final bool nearCornerY = (p.position.y.abs() > halfPlay - pocketGap);
      final bool isNearCornerPocket = nearCornerX && nearCornerY;

      bool hitWall = false;

      if (isNearCornerPocket) {
        // Corner pocket zone: allow pieces to roll towards pocket,
        // but strictly bound them to maxOuterBound (196.0) so pieces
        // can NEVER escape the board or tunnel through the corner frame.
        if (p.position.x - p.radius < -maxOuterBound) {
          p.position = Vector2(-maxOuterBound + p.radius, p.position.y);
          if (p.velocity.x < 0) {
            p.velocity =
                Vector2(-p.velocity.x * GameConfig.restitution, p.velocity.y * 0.95);
            hitWall = true;
          }
        } else if (p.position.x + p.radius > maxOuterBound) {
          p.position = Vector2(maxOuterBound - p.radius, p.position.y);
          if (p.velocity.x > 0) {
            p.velocity =
                Vector2(-p.velocity.x * GameConfig.restitution, p.velocity.y * 0.95);
            hitWall = true;
          }
        }

        if (p.position.y - p.radius < -maxOuterBound) {
          p.position = Vector2(p.position.x, -maxOuterBound + p.radius);
          if (p.velocity.y < 0) {
            p.velocity =
                Vector2(p.velocity.x * 0.95, -p.velocity.y * GameConfig.restitution);
            hitWall = true;
          }
        } else if (p.position.y + p.radius > maxOuterBound) {
          p.position = Vector2(p.position.x, maxOuterBound - p.radius);
          if (p.velocity.y > 0) {
            p.velocity =
                Vector2(p.velocity.x * 0.95, -p.velocity.y * GameConfig.restitution);
            hitWall = true;
          }
        }
      } else {
        // Standard cushion bounds
        // Left Wall
        if (p.position.x - p.radius < -halfPlay) {
          p.position = Vector2(-halfPlay + p.radius, p.position.y);
          if (p.velocity.x < 0) {
            p.velocity =
                Vector2(-p.velocity.x * GameConfig.restitution, p.velocity.y * 0.95);
            hitWall = true;
          }
        }
        // Right Wall
        else if (p.position.x + p.radius > halfPlay) {
          p.position = Vector2(halfPlay - p.radius, p.position.y);
          if (p.velocity.x > 0) {
            p.velocity =
                Vector2(-p.velocity.x * GameConfig.restitution, p.velocity.y * 0.95);
            hitWall = true;
          }
        }

        // Top Wall
        if (p.position.y - p.radius < -halfPlay) {
          p.position = Vector2(p.position.x, -halfPlay + p.radius);
          if (p.velocity.y < 0) {
            p.velocity =
                Vector2(p.velocity.x * 0.95, -p.velocity.y * GameConfig.restitution);
            hitWall = true;
          }
        }
        // Bottom Wall
        else if (p.position.y + p.radius > halfPlay) {
          p.position = Vector2(p.position.x, halfPlay - p.radius);
          if (p.velocity.y > 0) {
            p.velocity =
                Vector2(p.velocity.x * 0.95, -p.velocity.y * GameConfig.restitution);
            hitWall = true;
          }
        }
      }

      if (hitWall) {
        onWallCollision?.call();
        if (p.type == PieceType.striker) {
          onStrikerCollision?.call(p.position, p.velocity.length, true);
        }
      }
    }
  }

  void _checkPocketCapture(double subDt) {
    const double pocketThreshold = GameConfig.pocketRadius + 14.0;
    const double pocketDropRadius = GameConfig.pocketRadius + 2.0;

    // Scale suction parameters relative to reference substep (1.0 / 360.0)
    final double dtRatio = subDt / (1.0 / 360.0);
    final double damping = math.pow(0.88, dtRatio).toDouble();
    final double pull = 1.5 * dtRatio;
    bool pocketedAny = false;

    for (int i = 0; i < _activePieces.length; i++) {
      final p = _activePieces[i];
      if (p.isPocketed) continue;

      for (final pocket in GameConfig.pockets) {
        final double dist = p.position.distanceTo(pocket);

        // Pocket suction / funnel effect when close to hole
        if (dist < pocketThreshold) {
          final Vector2 pullDir =
              dist > 1e-4 ? (pocket - p.position) / dist : Vector2.zero;
          p.velocity = p.velocity * damping + pullDir * pull;

          if (dist < pocketDropRadius) {
            p.isPocketed = true;
            p.pocketTarget = pocket;
            p.velocity = Vector2.zero;
            pocketedAny = true;
            onPocket?.call(p, pocket);
            break;
          }
        }
      }
    }

    if (pocketedAny) {
      _populateActivePieces();
    }
  }

  void _updatePocketShrinkAnimations(double dt) {
    final double lerpFactor = 1.0 - math.pow(0.8, dt * 60.0).toDouble();

    for (int i = 0; i < pieces.length; i++) {
      final p = pieces[i];
      if (p.isPocketed && p.pocketProgress < 1.0) {
        p.pocketProgress = math.min(1.0, p.pocketProgress + dt * 4.0);
        if (p.pocketTarget != null) {
          p.position = p.position + (p.pocketTarget! - p.position) * lerpFactor;
        }
      }
    }
    if (striker.isPocketed && striker.pocketProgress < 1.0) {
      striker.pocketProgress = math.min(1.0, striker.pocketProgress + dt * 4.0);
      if (striker.pocketTarget != null) {
        striker.position = striker.position + (striker.pocketTarget! - striker.position) * lerpFactor;
      }
    }
  }

  void _sanitizeStates() {
    const double maxOuterBound = GameConfig.halfBoard - 4.0; // 196.0
    for (int i = 0; i < _activePieces.length; i++) {
      final p = _activePieces[i];
      if (!p.velocity.isValid) {
        p.velocity = Vector2.zero;
      }
      if (!p.position.isValid) {
        p.position = Vector2.zero;
      }

      // Hard safety guard: clamp non-pocketed active pieces strictly within outer boundary
      if (!p.isPocketed) {
        final double clampedX = p.position.x.clamp(-maxOuterBound, maxOuterBound);
        final double clampedY = p.position.y.clamp(-maxOuterBound, maxOuterBound);
        if (clampedX != p.position.x || clampedY != p.position.y) {
          p.position = Vector2(clampedX, clampedY);
          p.velocity = p.velocity * 0.5; // Absorb rogue energy
        }
      }
    }
  }
}
