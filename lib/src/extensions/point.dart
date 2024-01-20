import "package:flame/extensions.dart";
import "package:tmx_parser/tmx_parser.dart";

/// Extension functions on [Point]
extension PointExtensions on Point {
  /// Converts a Point to Vector2
  Vector2 toVector2() => Vector2(this.x, this.y);
}
