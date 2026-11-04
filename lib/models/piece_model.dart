import '../core/vector2.dart';

enum PieceType {
  white,
  black,
  queen,
  striker,
}

class PieceModel {
  final int id;
  final PieceType type;
  Vector2 position;
  Vector2 velocity;
  final double radius;
  final double mass;
  bool isPocketed;
  double pocketProgress; // 0.0 -> not pocketed, 1.0 -> fully dropped
  Vector2? pocketTarget;

  PieceModel({
    required this.id,
    required this.type,
    required this.position,
    this.velocity = Vector2.zero,
    required this.radius,
    required this.mass,
    this.isPocketed = false,
    this.pocketProgress = 0.0,
    this.pocketTarget,
  });

  bool get isMoving => velocity.isValid && velocity.lengthSquared > 0.005;

  PieceModel copyWith({
    int? id,
    PieceType? type,
    Vector2? position,
    Vector2? velocity,
    double? radius,
    double? mass,
    bool? isPocketed,
    double? pocketProgress,
    Vector2? pocketTarget,
  }) {
    return PieceModel(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      radius: radius ?? this.radius,
      mass: mass ?? this.mass,
      isPocketed: isPocketed ?? this.isPocketed,
      pocketProgress: pocketProgress ?? this.pocketProgress,
      pocketTarget: pocketTarget ?? this.pocketTarget,
    );
  }
}
