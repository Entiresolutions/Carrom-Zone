import 'dart:math' as math;

/// Fast, immutable 2D vector for Carrom physics and math calculations.
class Vector2 {
  final double x;
  final double y;

  const Vector2(this.x, this.y);

  static const Vector2 zero = Vector2(0.0, 0.0);

  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);
  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);
  Vector2 operator *(double scalar) => Vector2(x * scalar, y * scalar);
  Vector2 operator /(double scalar) {
    if (scalar == 0 || scalar.isNaN || scalar.isInfinite || scalar.abs() < 1e-15) {
      return Vector2.zero;
    }
    return Vector2(x / scalar, y / scalar);
  }
  Vector2 operator -() => Vector2(-x, -y);

  bool get isValid => !x.isNaN && !x.isInfinite && !y.isNaN && !y.isInfinite;

  double get length => math.sqrt(x * x + y * y);
  double get lengthSquared => x * x + y * y;

  Vector2 normalized() {
    final len = length;
    if (len.isNaN || len.isInfinite || len <= 0.00001) {
      return Vector2.zero;
    }
    return this / len;
  }

  double dot(Vector2 other) => x * other.x + y * other.y;

  double distanceTo(Vector2 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  double distanceSquaredTo(Vector2 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return dx * dx + dy * dy;
  }

  double angle() => math.atan2(y, x);

  Vector2 rotated(double rad) {
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);
    return Vector2(x * cosA - y * sinA, x * sinA + y * cosA);
  }

  Vector2 clamped(double maxLength) {
    if (maxLength <= 0.0 || maxLength.isNaN || maxLength.isInfinite) {
      return Vector2.zero;
    }
    if (lengthSquared > maxLength * maxLength) {
      return normalized() * maxLength;
    }
    return this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector2 &&
          (x - other.x).abs() < 1e-6 &&
          (y - other.y).abs() < 1e-6;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Vector2(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}
