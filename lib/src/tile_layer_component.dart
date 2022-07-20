import "dart:ui";

import "package:flame/components.dart";
import "package:flame/extensions.dart";
import "package:flame/flame.dart";
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:forge2d/src/dynamics/body.dart';
import "package:tmx_parser/tmx_parser.dart";

import "../flame_forge2d_tiled.dart";
import "draw_context.dart";
import 'extensions/layer.dart';
import "layer_component.dart";

class TileLayerComponent extends LayerComponent<TileLayer> {
  TileLayerComponent({
    required super.layer,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    int startX;
    int startY;
    int endX;
    int endY;
    int incX;
    int incY;
    switch (tmxMap.renderOrder) {
      case RenderOrder.rightDown:
        startX = 0;
        startY = 0;
        incX = 1;
        incY = 1;
        endX = layer.width;
        endY = layer.height;
        break;
      case RenderOrder.rightUp:
        startX = 0;
        startY = layer.height - 1;
        incX = 1;
        incY = -1;
        endX = layer.width;
        endY = -1;
        break;
      case RenderOrder.leftDown:
        startX = layer.width - 1;
        startY = 0;
        incX = -1;
        incY = 1;
        endX = -1;
        endY = layer.height;
        break;
      case RenderOrder.leftUp:
        startX = layer.width - 1;
        startY = layer.height - 1;
        incX = -1;
        incY = -1;
        endX = -1;
        endY = -1;
        break;
    }

    for (int y = startY; y != endY; y += incY) {
      for (int x = startX; x != endX; x += incX) {
        int gid = layer.tileMatrix[y][x];
        if (gid == 0) {
          continue;
        }

        Vector2 indexOffset = Vector2(
          x * tmxMap.tileWidth,
          y * tmxMap.tileHeight,
        );

        TileSet tileSet = tmxMap.getTileSetByGid(gid);
        int tileId = gid - tileSet.firstGid;
        Tile? tile = tileSet.getTileById(tileId);
        if (tileSet.image != null) {
          Image image = Flame.images.fromCache(tileSet.image!.source!);
          if (tile != null && tile.animation != null) {
            List<SpriteAnimationFrameData> frameData = [];
            for (Frame f in tile.animation!.frameList) {
              Vector2 tileOffset = tileSet.getTileOffset(f.tileId);
              SpriteAnimationFrameData safd = SpriteAnimationFrameData(
                srcPosition: tileOffset,
                srcSize: tileSet.tileSize,
                stepTime: (f.duration / 1000).toDouble(),
              );
              frameData.add(safd);
            }

            SpriteAnimationData sad = SpriteAnimationData(frameData);

            SpriteAnimation sp = SpriteAnimation.fromFrameData(image, sad);

            SpriteAnimationComponent sac = SpriteAnimationComponent(
              animation: sp,
              anchor: Anchor.topLeft,
              size: tileSet.tileSize / zoom,
              position: (indexOffset +
                      Vector2(
                        0.0,
                        tmxMap.tileHeight - tileSet.tileHeight,
                      )) /
                  zoom,
            );
            await super.add(sac);
          } else {
            DrawContext dc = super.drawContextMap[image] ??= DrawContext(
              tmxMap: super.tmxMap,
              zoom: super.zoom,
            );
            dc.addTileSetContext(
              tileId: tileId,
              tileSet: tileSet,
              dstOffset: indexOffset,
            );
          }
        } else if (tile != null) {
          Image image = Flame.images.fromCache(tile.image!.source!);
          if (tile.animation != null) {
            List<Sprite> sprites = [];
            List<double> steps = [];
            for (Frame f in tile.animation!.frameList) {
              Sprite s = Sprite(
                Flame.images
                    .fromCache(tileSet.getTileById(f.tileId)!.image!.source!),
              );
              sprites.add(s);
              steps.add((f.duration / 1000).toDouble());
            }

            SpriteAnimation sp = SpriteAnimation.variableSpriteList(
              sprites,
              stepTimes: steps,
            );

            SpriteAnimationComponent sac = SpriteAnimationComponent(
              animation: sp,
              anchor: Anchor.topLeft,
              size: tile.image!.size / zoom,
              position: (indexOffset +
                      Vector2(
                        0.0,
                        tmxMap.tileHeight - image.height,
                      )) /
                  zoom,
            );

            await super.add(sac);
          } else {
            DrawContext dc = super.drawContextMap[image] ??= DrawContext(
              tmxMap: super.tmxMap,
              zoom: super.zoom,
            );
            dc.addTileContext(
              tile: tile,
              dstOffset: indexOffset + tileSet.offset,
            );
          }
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (MapEntry<Image, DrawContext> c in super.drawContextMap.entries) {
      canvas.drawAtlas(
        c.key,
        c.value.rsTransforms,
        c.value.sourceRects,
        c.value.colors,
        c.value.blendMode,
        c.value.cullRect,
        super.paint,
      );
    }
  }

  @override
  Iterable<FixtureDef> createFixtures({
    required Map<Vector2, Vector2> edges,
  }) sync* {
    for (int y = 0; y < super.tmxMap.height; ++y) {
      for (int x = 0; x < super.tmxMap.width; ++x) {
        int tileId = super.layer.tileMatrix[y][x];
        if (tileId == 0) {
          continue;
        }

        TileSet tileSet = super.tmxMap.getTileSetByGid(tileId);
        Tile? tile = tileSet.getTileByGid(tileId);

        if (tile == null) {
          continue;
        }

        Vector2 offset = Vector2(
              x * super.tmxMap.tileWidth,
              y * super.tmxMap.tileHeight,
            ) +
            Vector2(
              0,
              super.tmxMap.tileHeight -
                  (tile.image?.height ?? tileSet.tileHeight),
            ) +
            tileSet.offset;

        yield* createTileObjectFixtures(
          tile: tile,
          edges: edges,
          baseOffset: offset,
        );
      }
    }
  }
}
