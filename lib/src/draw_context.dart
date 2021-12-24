import 'dart:ui';

import 'package:flame/flame.dart';
import 'package:tmx_parser/tmx_parser.dart';

import 'extensions/tile_set.dart';
import 'extensions/tmx_object.dart';

class DrawContext {
  late Image image;
  late Rect sourceRect;
  late Rect destinationRect;

  void adjust({
    required Rect screenRect,
  }) {
    final Rect intersection = screenRect.intersect(destinationRect);

    Offset newOffset = sourceRect.topLeft;
    if (intersection.left == 0) {
      newOffset += Offset(
        destinationRect.width - intersection.right,
        0.0,
      );
    }

    if (intersection.top == 0) {
      newOffset += Offset(
        0.0,
        destinationRect.height - intersection.bottom,
      );
    }

    // TODO how to handle difference for size in tmxobject. currently
    // we are not using this function for tmxobjects

    this.sourceRect = newOffset & intersection.size;
    this.destinationRect = intersection;
  }

  DrawContext.createTileContext({
    required TmxMap tmxMap,
    required int gid,
    required Offset baseOffset,
    required double zoom,
  }) {
    final TileSet tileSet = tmxMap.getTileSetByGid(gid);

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

  DrawContext.createTileObjectContext({
    required TmxMap tmxMap,
    required TmxObject object,
    required Offset baseOffset,
    required double zoom,
  }) {
    final TileSet tileSet = tmxMap.getTileSetByGid(object.gid!);

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

    final int tileIndex = gid - tileSet.firstGid;
    final sourceSize = Size(
      tileSet.tileWidth,
      tileSet.tileHeight,
    );
    final Offset sourceOffset = tileSet.getSourceOffset(tileIndex);
    this.sourceRect = sourceOffset & sourceSize;

    final destionationSize = Size(
      tileSet.tileWidth + 1.0,
      tileSet.tileHeight + 1.0,
    );

    final Offset tileSetOffset = tileSet.getOffset();
    final correctionOffset = Offset(
      0.0,
      tmxMap.tileHeight - tileSet.tileHeight,
    );
    final Offset destinationOffset =
        baseOffset + tileSetOffset + correctionOffset;
    this.destinationRect = (destinationOffset / zoom) & (destionationSize / zoom);
  }

  void _createTileContext({
    required TmxMap tmxMap,
    required int gid,
    required TileSet tileSet,
    required Offset baseOffset,
    required double zoom,
  }) {
    final TileSet tileSet = tmxMap.getTileSetByGid(gid);
    final int tileIndex = gid - tileSet.firstGid;
    final Tile tile = tileSet.tiles[tileIndex]!;
    this.image = Flame.images.fromCache(tile.image!.source!);

    final Size sourceSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final sourceOffset = Offset.zero;
    this.sourceRect = sourceOffset & sourceSize;

    final destinationSize = Size(
      image.width.toDouble() + 1.0,
      image.height.toDouble() + 1.0,
    );

    final Offset tileSetOffset = tileSet.getOffset();
    final correctionOffset = Offset(
      0.0,
      tmxMap.tileHeight - image.height,
    );
    final Offset destinationOffset =
        baseOffset + tileSetOffset + correctionOffset;
    this.destinationRect = (destinationOffset / zoom) & (destinationSize / zoom);
  }

  void _createTileSetObjectContext({
    required TmxMap tmxMap,
    required TmxObject object,
    required TileSet tileSet,
    required Offset baseOffset,
    required double zoom,
  }) {
    this.image = Flame.images.fromCache(tileSet.image!.source!);

    final int tileIndex = object.gid! - tileSet.firstGid;

    final Offset sourceOffset = tileSet.getSourceOffset(tileIndex);
    final sourceSize = Size(
      tileSet.tileWidth,
      tileSet.tileHeight,
    );
    this.sourceRect = sourceOffset & sourceSize;

    final destinationSize = Size(
      object.width + 1.0,
      object.height + 1.0,
    );
    final Offset alignmentOffset =
        object.getAlignedOffset(tileSet.objectAlignment);
    final correctionOffset = Offset(
      tmxMap.tileWidth - tileSet.tileWidth,
      tmxMap.tileHeight - tileSet.tileHeight,
    );
    final Offset objectOffset = object.getOffset();
    final Offset tileSetOffset = tileSet.getOffset();
    final destinationOffset = baseOffset +
        alignmentOffset +
        correctionOffset +
        objectOffset +
        tileSetOffset;
    this.destinationRect = (destinationOffset / zoom) & (destinationSize / zoom);
  }

  void _createTileObjectContext({
    required TmxMap tmxMap,
    required TmxObject object,
    required TileSet tileSet,
    required Offset baseOffset,
    required double zoom,
  }) {
    final TileSet tileSet = tmxMap.getTileSetByGid(object.gid!);
    final int tileIndex = object.gid! - tileSet.firstGid;
    final Tile tile = tileSet.tiles[tileIndex]!;
    this.image = Flame.images.fromCache(tile.image!.source!);

    final sourceOffset = Offset.zero;
    final sourceSize = Size(
      tile.image!.width!,
      tile.image!.height!,
    );
    this.sourceRect = sourceOffset & sourceSize;

    final Offset alignmentOffset =
        object.getAlignedOffset(tileSet.objectAlignment);
    final objectOffset = object.getOffset();
    final tileSetOffset = tileSet.getOffset();

    final destinationOffset =
        baseOffset + alignmentOffset + objectOffset + tileSetOffset;
    final destinationSize = Size(
      object.width + 1.0,
      object.height + 1.0,
    );
    this.destinationRect = (destinationOffset / zoom) & (destinationSize / zoom);
  }
}
