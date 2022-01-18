import "package:flame/extensions.dart";
import "package:tmx_parser/tmx_parser.dart";

/// Extension functions on [TileSet]
extension TileSetExtensions on TileSet {
  /// Creates an [Offset] from [tileOffset]
  Offset getOffset() => Offset(this.tileOffset.x, this.tileOffset.y);

  /// Calculates the [Offset] needed to extract the correct tile from the [TileSet]
  Offset getSourceOffset(int tileIndex) {
    int tileX = tileIndex % this.columns;
    int tileY = tileIndex ~/ this.columns;

    Offset sourceOffset = Offset(
      tileX * this.tileWidth,
      tileY * this.tileHeight,
    );

    return sourceOffset;
  }
}
