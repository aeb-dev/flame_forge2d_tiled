import "dart:math";

import "package:flame/extensions.dart";

/// Extension functions on [Point]
extension PointExtensions on Point {
  /// Converts a Point to Vector2
  Vector2 toVector2() => Vector2(this.x.toDouble(), this.y.toDouble());
}
