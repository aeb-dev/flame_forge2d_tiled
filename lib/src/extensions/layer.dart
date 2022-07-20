import "dart:ui";

import "package:flame/extensions.dart";
import "package:tmx_parser/tmx_parser.dart";

extension LayerExtensions on Layer {
  Vector2 get offset => Vector2(
        offsetX,
        offsetY,
      );
}
