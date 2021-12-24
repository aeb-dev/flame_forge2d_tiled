import 'package:flame/extensions.dart';
import 'package:tmx_parser/tmx_parser.dart';

extension TileSetExtensions on TileSet {
  Offset getOffset() => Offset(tileOffset.x, tileOffset.y);

  Offset getSourceOffset(int tileIndex) {
    final int tileX = tileIndex % columns;
    final int tileY = tileIndex ~/ columns;

    final Offset sourceOffset = Offset(
      tileX * tileWidth,
      tileY * tileHeight,
    );

    return sourceOffset;
  }
}
