import "dart:ui";

import "package:flame/components.dart";
import "package:flame/flame.dart";
import 'package:forge2d/src/dynamics/fixture_def.dart';
import 'package:forge2d/src/dynamics/body.dart';
import "package:tmx_parser/tmx_parser.dart";

import "draw_context.dart";
import 'extensions/layer.dart';
import "extensions/object_alignment.dart";
import "extensions/tile_set.dart";
import "extensions/tmx_image.dart";
import "extensions/tmx_object.dart";
import "layer_component.dart";

class ObjectLayerComponent extends LayerComponent<ObjectGroup> {
  ObjectLayerComponent({
    required super.layer,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    for (TmxObject tmxObject in layer.objectMapById.values
        .where((object) => object.gid != null && object.visible)) {
      TileSet tileSet = tmxMap.getTileSetByGid(tmxObject.gid!);
      int tileId = tmxObject.gid! - tileSet.firstGid;
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
            anchor: tileSet.objectAlignment.toAnchor(),
            size: tileSet.tileSize / zoom,
            position: tmxObject.offset / zoom,
            angle: tmxObject.rotationInRadians,
          );
          await super.add(sac);
        } else {
          DrawContext dc = super.drawContextMap[image] ??= DrawContext(
            tmxMap: super.tmxMap,
            zoom: super.zoom,
          );
          dc.addTileSetObjectContext(
            object: tmxObject,
            tileId: tileId,
            tileSet: tileSet,
            dstOffset: Vector2.zero(),
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
            anchor: tileSet.objectAlignment.toAnchor(),
            size: tile.image!.size / zoom,
            position: tmxObject.offset / zoom,
            angle: tmxObject.rotationInRadians,
          );

          await super.add(sac);
        } else {
          DrawContext dc = super.drawContextMap[image] ??= DrawContext(
            tmxMap: super.tmxMap,
            zoom: super.zoom,
          );
          dc.addTileObjectContext(
            object: tmxObject,
            tileId: tileId,
            tileSet: tileSet,
            dstOffset: Vector2.zero(),
          );
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (MapEntry<Image, DrawContext> c in drawContextMap.entries) {
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
    for (TmxObject object in super.layer.objectMapById.values) {
      if (object.gid != null) {
        TileSet tileSet = super.tmxMap.getTileSetByGid(object.gid!);
        Tile? tile = tileSet.getTileByGid(object.gid!);

        if (tile == null) {
          continue;
        }

        Vector2 alignment = object.getAlignmentOffset(tileSet.objectAlignment);

        yield* createTileObjectFixtures(
          tile: tile,
          edges: edges,
          baseOffset: tileSet.offset + object.offset - alignment,
        );
      } else {
        FixtureDef? fd = object.createFixture(
          edges: edges,
          zoom: zoom,
          baseOffset: super.layer.offset,
        );

        if (fd != null) {
          yield fd;
        }
      }
    }
  }
}
