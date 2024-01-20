import "dart:ui";

import "package:flame/components.dart";
import "package:tmx_parser/tmx_parser.dart";

import "extensions/tile_set.dart";
import "extensions/tmx_image.dart";
import "extensions/tmx_object.dart";

/// A context for drawing tiles based on tile type
class DrawContext {
  late TmxMap tmxMap;
  late double zoom;

  /// The part of the image to draw
  final List<Rect> sourceRects = <Rect>[];

  /// The part of the screen to draw
  final List<RSTransform> rsTransforms = <RSTransform>[];

  List<Color>? colors;

  BlendMode? blendMode;

  Rect? cullRect;

  DrawContext({
    required this.tmxMap,
    required this.zoom,
    this.blendMode,
    this.cullRect,
  });

  void addTileSetContext({
    required int tileId,
    required TileSet tileSet,
    required Vector2 dstOffset,
  }) {
    Vector2 sourceOffset = tileSet.getTileOffset(tileId);
    Rect sourceRect = sourceOffset & tileSet.tileSize;
    this.sourceRects.add(sourceRect);

    Vector2 correctionOffset = Vector2(
      0.0,
      tmxMap.tileHeight.toDouble() - tileSet.tileHeight.toDouble(),
    );
    Vector2 destinationOffset =
        (dstOffset + tileSet.offset + correctionOffset) / zoom;

    RSTransform rs = RSTransform(
      1 / zoom,
      0,
      destinationOffset.x,
      destinationOffset.y,
    );

    this.rsTransforms.add(rs);
  }

  void addTileContext({
    required Tile tile,
    required Vector2 dstOffset,
  }) {
    Vector2 imageSize = tile.image!.size;
    Rect sourceRect = Vector2.zero() & imageSize;
    this.sourceRects.add(sourceRect);

    Vector2 correctionOffset = Vector2(
      0.0,
      tmxMap.tileHeight - imageSize.y,
    );
    Vector2 destinationOffset = (dstOffset + correctionOffset) / zoom;

    RSTransform rs = RSTransform(
      1 / zoom,
      0,
      destinationOffset.x,
      destinationOffset.y,
    );
    rsTransforms.add(rs);
  }

  void addTileSetObjectContext({
    required TmxObject object,
    required TileSet tileSet,
    required int tileId,
    required Vector2 dstOffset,
  }) {
    Vector2 sourceOffset = tileSet.getTileOffset(tileId);
    Rect sourceRect = sourceOffset & tileSet.tileSize;
    this.sourceRects.add(sourceRect);

    Vector2 alignmentOffset =
        object.getAlignmentOffset(tileSet.objectAlignment);
    Vector2 destinationOffset =
        (dstOffset + object.offset + tileSet.offset) / zoom;

    RSTransform rs = RSTransform.fromComponents(
      rotation: object.rotationInRadians,
      scale: 1 / zoom,
      anchorX: alignmentOffset.x,
      anchorY: alignmentOffset.y,
      translateX: destinationOffset.x,
      translateY: destinationOffset.y,
    );
    this.rsTransforms.add(rs);
  }

  void addTileObjectContext({
    required TmxObject object,
    required TileSet tileSet,
    required int tileId,
    required Vector2 dstOffset,
  }) {
    Vector2 imageSize = tileSet.tiles[tileId]!.image!.size;
    Rect sourceRect = Vector2.zero() & imageSize;
    this.sourceRects.add(sourceRect);

    Vector2 alignmentOffset =
        object.getAlignmentOffset(tileSet.objectAlignment);
    Vector2 destinationOffset =
        (dstOffset + object.offset + tileSet.offset) / zoom;

    RSTransform rs = RSTransform.fromComponents(
      rotation: object.rotationInRadians,
      scale: 1 / zoom,
      anchorX: alignmentOffset.x,
      anchorY: alignmentOffset.y,
      translateX: destinationOffset.x,
      translateY: destinationOffset.y,
    );
    this.rsTransforms.add(rs);
  }
}
