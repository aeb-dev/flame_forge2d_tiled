import "package:flame/extensions.dart";
import "package:tmx_parser/tmx_parser.dart";

/// Extension functions on [TileSet]
extension TileSetExtensions on TileSet {
  /// Creates an [Offset] from [tileOffset]
  Vector2 get offset => Vector2(
        this.tileOffset.x,
        this.tileOffset.y,
      );

  Vector2 get tileSize => Vector2(
        tileWidth,
        tileHeight,
      );

  /// Calculates the [Offset] needed to extract the correct tile from the [TileSet]
  Vector2 getTileOffset(int tileIndex) {
    int tileX = tileIndex % this.columns;
    int tileY = tileIndex ~/ this.columns;

    Vector2 sourceOffset = Vector2(
      tileX * this.tileWidth,
      tileY * this.tileHeight,
    );

    return sourceOffset;
  }
}
