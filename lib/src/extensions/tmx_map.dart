import "package:flame/extensions.dart";
import "package:tmx_parser/tmx_parser.dart";

extension TmxMapExtensions on TmxMap {
  Vector2 get tileSize => Vector2(
        tileWidth.toDouble(),
        tileHeight.toDouble(),
      );
}
