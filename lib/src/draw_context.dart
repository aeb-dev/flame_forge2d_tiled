import "dart:ui";

import "package:flame/flame.dart";
import "package:tmx_parser/tmx_parser.dart";

import "extensions/tile_set.dart";
import "extensions/tmx_object.dart";

/// A context for drawing tiles based on tile type
class DrawContext {
  /// The image to draw
  late Image image;

  /// The part of the image to draw
  late Rect sourceRect;

  /// The part of the screen to draw
  late Rect destinationRect;

  // this used to adjust screenRect in order to optimize how much to draw on the screen
  // for example if the image is far bigger than the screen, this changes corresponding parameters
  // to only get screen part of the image and draw only the part of image that is visible on the screen
  // void adjust({
  //   required Rect screenRect,
  // }) {
  //   Rect intersection = screenRect.intersect(destinationRect);

  //   Offset newOffset = sourceRect.topLeft;
  //   if (intersection.left == 0) {
  //     newOffset += Offset(
  //       destinationRect.width - intersection.right,
  //       0.0,
  //     );
  //   }

  //   if (intersection.top == 0) {
  //     newOffset += Offset(
  //       0.0,
  //       destinationRect.height - intersection.bottom,
  //     );
  //   }

  //   // TODO how to handle difference for size in tmxobject. currently
  //   // we are not using this function for tmxobjects

  //   this.sourceRect = newOffset & intersection.size;
  //   this.destinationRect = intersection;
  // }

  /// Creates a context for [Tile].
  ///
  /// The algorithm differs if the [TileSet] is based on images rather than tiles
  DrawContext.createTileContext({
    required TmxMap tmxMap,
    required int gid,
    required Offset baseOffset,
    required double zoom,
  }) {
    TileSet tileSet = tmxMap.getTileSetByGid(gid);

    if (tileSet.image != null) {
      _createTileSetContext(
        tmxMap: tmxMap,
        gid: gid,
        tileSet: tileSet,
        baseOffset: baseOffset,
        zoom: zoom,
      );
    } else {
      _createTileContext(
        tmxMap: tmxMap,
        gid: gid,
        tileSet: tileSet,
        baseOffset: baseOffset,
        zoom: zoom,
      );
    }
  }

  /// Creates a context for [TmxObject]
  ///
  /// The algorithm differs if the [TileSet] is based on images rather than tiles
  DrawContext.createTileObjectContext({
    required TmxMap tmxMap,
    required TmxObject object,
    required Offset baseOffset,
    required double zoom,
  }) {
    TileSet tileSet = tmxMap.getTileSetByGid(object.gid!);

    if (tileSet.image != null) {
      _createTileSetObjectContext(
        tmxMap: tmxMap,
        object: object,
        tileSet: tileSet,
        baseOffset: baseOffset,
        zoom: zoom,
      );
    } else {
      _createTileObjectContext(
        tmxMap: tmxMap,
        object: object,
        tileSet: tileSet,
        baseOffset: baseOffset,
        zoom: zoom,
      );
    }
  }

  void _createTileSetContext({
    required TmxMap tmxMap,
    required int gid,
    required TileSet tileSet,
    required Offset baseOffset,
    required double zoom,
  }) {
    this.image = Flame.images.fromCache(tileSet.image!.source!);

    int tileIndex = gid - tileSet.firstGid;
    Size sourceSize = Size(
      tileSet.tileWidth,
      tileSet.tileHeight,
    );
    Offset sourceOffset = tileSet.getSourceOffset(tileIndex);
    this.sourceRect = sourceOffset & sourceSize;

    Size destionationSize = Size(
      tileSet.tileWidth + 1.0,
      tileSet.tileHeight + 1.0,
    );

    Offset tileSetOffset = tileSet.getOffset();
    Offset correctionOffset = Offset(
      0.0,
      tmxMap.tileHeight - tileSet.tileHeight,
    );
    Offset destinationOffset = baseOffset + tileSetOffset + correctionOffset;
    this.destinationRect =
        (destinationOffset / zoom) & (destionationSize / zoom);
  }

  void _createTileContext({
    required TmxMap tmxMap,
    required int gid,
    required TileSet tileSet,
    required Offset baseOffset,
    required double zoom,
  }) {
    TileSet tileSet = tmxMap.getTileSetByGid(gid);
    int tileIndex = gid - tileSet.firstGid;
    Tile tile = tileSet.tiles[tileIndex]!;
    this.image = Flame.images.fromCache(tile.image!.source!);

    Size sourceSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    this.sourceRect = Offset.zero & sourceSize;

    Size destinationSize = Size(
      image.width.toDouble() + 1.0,
      image.height.toDouble() + 1.0,
    );

    Offset tileSetOffset = tileSet.getOffset();
    Offset correctionOffset = Offset(
      0.0,
      tmxMap.tileHeight - image.height,
    );
    Offset destinationOffset = baseOffset + tileSetOffset + correctionOffset;
    this.destinationRect =
        (destinationOffset / zoom) & (destinationSize / zoom);
  }

  void _createTileSetObjectContext({
    required TmxMap tmxMap,
    required TmxObject object,
    required TileSet tileSet,
    required Offset baseOffset,
    required double zoom,
  }) {
    this.image = Flame.images.fromCache(tileSet.image!.source!);

    int tileIndex = object.gid! - tileSet.firstGid;

    Offset sourceOffset = tileSet.getSourceOffset(tileIndex);
    Size sourceSize = Size(
      tileSet.tileWidth,
      tileSet.tileHeight,
    );
    this.sourceRect = sourceOffset & sourceSize;

    Size destinationSize = Size(
      object.width + 1.0,
      object.height + 1.0,
    );
    Offset alignmentOffset = object.getAlignedOffset(tileSet.objectAlignment);
    Offset correctionOffset = Offset(
      tmxMap.tileWidth - tileSet.tileWidth,
      tmxMap.tileHeight - tileSet.tileHeight,
    );
    Offset objectOffset = object.getOffset();
    Offset tileSetOffset = tileSet.getOffset();
    Offset destinationOffset = baseOffset +
        alignmentOffset +
        correctionOffset +
        objectOffset +
        tileSetOffset;
    this.destinationRect =
        (destinationOffset / zoom) & (destinationSize / zoom);
  }

  void _createTileObjectContext({
    required TmxMap tmxMap,
    required TmxObject object,
    required TileSet tileSet,
    required Offset baseOffset,
    required double zoom,
  }) {
    TileSet tileSet = tmxMap.getTileSetByGid(object.gid!);
    int tileIndex = object.gid! - tileSet.firstGid;
    Tile tile = tileSet.tiles[tileIndex]!;
    this.image = Flame.images.fromCache(tile.image!.source!);

    Size sourceSize = Size(
      tile.image!.width!,
      tile.image!.height!,
    );
    this.sourceRect = Offset.zero & sourceSize;

    Offset alignmentOffset = object.getAlignedOffset(tileSet.objectAlignment);
    Offset objectOffset = object.getOffset();
    Offset tileSetOffset = tileSet.getOffset();

    Offset destinationOffset =
        baseOffset + alignmentOffset + objectOffset + tileSetOffset;
    Size destinationSize = Size(
      object.width + 1.0,
      object.height + 1.0,
    );
    this.destinationRect =
        (destinationOffset / zoom) & (destinationSize / zoom);
  }
}
