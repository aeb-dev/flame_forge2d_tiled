import "package:flame/extensions.dart";

extension ImageExtensions on Image {
  Vector2 get size => Vector2(
        width.toDouble(),
        height.toDouble(),
      );
}
