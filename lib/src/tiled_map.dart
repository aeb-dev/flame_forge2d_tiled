import 'dart:math';
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame_forge2d/body_component.dart';
import 'package:forge2d/forge2d.dart';
import 'package:tmx_parser/tmx_parser.dart';

import 'draw_context.dart';
import 'extensions/point.dart';
import 'extensions/tmx_object.dart';
import 'tiled_game.dart';

class TiledMap extends BodyComponent<TiledGame> {
  static Paint _paint = Paint();
  late TmxMap _tmxMap;
  late double _zoom;

  TiledMap();

  @override
  get debugMode => false;

  // @override
  // void update(double dt) {
  //   super.update(dt);
  // }

  @override
  Future<void> onLoad() async {
    _tmxMap = super.gameRef.tmxMap;
    _zoom = super.gameRef.camera.zoom;
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _render(
      canvas,
      _tmxMap.renderOrderedLayers,
      Offset.zero,
    );
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
  }

  _render(
    Canvas canvas,
    List<dynamic> layerList,
    Offset baseOffset,
  ) {
    layerList.where((layer) => layer.visible).forEach((layer) {
      if (layer is Layer) {
        _renderLayer(
          canvas,
          layer,
          baseOffset,
        );
      } else if (layer is ObjectGroup) {
        _renderObjectLayer(
          canvas,
          layer,
          baseOffset,
        );
      } else if (layer is ImageLayer) {
        _renderImageLayer(
          canvas,
          layer,
          baseOffset,
        );
      } else if (layer is Group) {
        _renderGroup(
          canvas,
          layer,
          baseOffset,
        );
      }
    });
  }

  void _renderLayer(
    Canvas canvas,
    Layer layer,
    Offset baseOffset,
  ) {
    int startX;
    int startY;
    int endX;
    int endY;
    int incX;
    int incY;
    switch (_tmxMap.renderOrder) {
      case "right-down":
        startX = 0;
        startY = 0;
        incX = 1;
        incY = 1;
        endX = layer.width;
        endY = layer.height;
        break;
      case "right-up":
        startX = 0;
        startY = layer.height - 1;
        incX = 1;
        incY = -1;
        endX = layer.width;
        endY = -1;
        break;
      case "left-down":
        startX = layer.width - 1;
        startY = 0;
        incX = -1;
        incY = 1;
        endX = -1;
        endY = layer.height;
        break;
      case "left-up":
        startX = layer.width - 1;
        startY = layer.height - 1;
        incX = -1;
        incY = -1;
        endX = -1;
        endY = -1;
        break;
      default:
        throw "unexpected 'renderorder'";
    }

    final layerOffset = Offset(
      layer.offsetX,
      layer.offsetY,
    );

    final Offset combinedOffset = layerOffset + baseOffset;

    for (int y = startY; y != endY; y += incY) {
      for (int x = startX; x != endX; x += incX) {
        int tileId = layer.tileMatrix[y][x];
        if (tileId == 0) {
          continue;
        }

        // offset for the location on the canvas
        final indexOffset = Offset(
          x * _tmxMap.tileWidth,
          y * _tmxMap.tileHeight,
        );

        final Offset offset = combinedOffset + indexOffset;

        _renderTile(
          canvas,
          tileId,
          offset,
        );
      }
    }
  }

  void _renderObjectLayer(
    Canvas canvas,
    ObjectGroup objectLayer,
    Offset baseOffset,
  ) {
    final Offset layerOffset = Offset(
      objectLayer.offsetX,
      objectLayer.offsetY,
    );

    final Offset offset = baseOffset + layerOffset;

    objectLayer.objectMapById.values
        .where((object) => object.gid != null)
        .forEach(
          (object) => _renderObjectTile(
            canvas,
            object,
            offset,
          ),
        );
  }

  void _renderImageLayer(
    Canvas canvas,
    ImageLayer imageLayer,
    Offset baseOffset,
  ) {
    final Offset layerOffset = Offset(
      imageLayer.offsetX,
      imageLayer.offsetY,
    );

    final Offset offset = baseOffset + layerOffset;

    canvas.drawImage(
      Flame.images.fromCache(imageLayer.image!.source!),
      offset,
      _paint,
    );
  }

  void _renderGroup(
    Canvas canvas,
    Group groupLayer,
    Offset baseOffset,
  ) {
    final Offset layerOffset = Offset(
      groupLayer.offsetX,
      groupLayer.offsetY,
    );

    final Offset offset = baseOffset + layerOffset;
    _render(
      canvas,
      groupLayer.renderOrderedLayers,
      offset,
    );
  }

  void _renderTile(
    Canvas canvas,
    int gid,
    Offset baseOffset,
  ) {
    final drawContext = DrawContext.createTileContext(
      tmxMap: _tmxMap,
      gid: gid,
      baseOffset: baseOffset,
      zoom: _zoom,
    );

    // camera.
    final Rect screenRect = camera.position.toPositionedRect(camera.gameSize);

    final bool inViewport =
        screenRect
        .overlaps(drawContext.destinationRect);
    // super.gameRef.camera.position.toPositionedRect(super.gameRef.camera)

    // final bool inViewport = _screenRect.overlaps(drawContext.destinationRect);
    if (!inViewport) {
      return;
    }

    // drawContext.adjust(screenRect: screenRect);

    canvas.drawImageRect(
      drawContext.image,
      drawContext.sourceRect,
      drawContext.destinationRect,
      _paint,
    );
  }

  void _renderObjectTile(
    Canvas canvas,
    TmxObject object,
    Offset baseOffset,
  ) {
    final drawContext = DrawContext.createTileObjectContext(
      tmxMap: _tmxMap,
      object: object,
      baseOffset: baseOffset,
      zoom: _zoom,
    );

    final bool inViewport = camera.position
        .toPositionedRect(camera.gameSize)
        .overlaps(drawContext.destinationRect);
    // final bool inViewport = _screenRect.overlaps(drawContext.destinationRect);
    if (!inViewport) {
      return;
    }

    // drawContext.adjustDrawContext(screenRect: _screenRect);

    canvas.drawImageRect(
      drawContext.image,
      drawContext.sourceRect,
      drawContext.destinationRect,
      _paint,
    );
  }

  @override
  Body createBody() {
    BodyDef bd = BodyDef();
    bd.position = Vector2.zero();
    bd.type = BodyType.static;
    bd.userData = this;

    Body body = world.createBody(bd);

    _createFixtureDefs(
      body,
      _tmxMap.renderOrderedLayers,
    );

    return body;
  }

  void _createFixtureDefs(
    Body body,
    List<dynamic> layers, {
    Offset baseOffset = Offset.zero,
  }) {
    layers.where((layer) => layer.visible).forEach((layer) {
      if (layer is Layer) {
        _addLayerFixtures(
          body,
          layer,
          baseOffset: baseOffset,
        );
      } else if (layer is ObjectGroup) {
        _addObjectLayerFixtures(
          body,
          layer,
          baseOffset: baseOffset,
        );
      } else if (layer is ImageLayer) {
        // do nothing
      } else if (layer is Group) {
        _addGroupLayerFixtures(
          body,
          layer,
          baseOffset: baseOffset,
        );
      }
    });
  }

  void _addLayerFixtures(
    Body body,
    Layer layer, {
    Offset baseOffset = Offset.zero,
  }) {
    final Offset layerOffset = baseOffset +
        Offset(
          layer.offsetX,
          layer.offsetY,
        );

    for (int y = 0; y < _tmxMap.height; ++y) {
      for (int x = 0; x < _tmxMap.width; ++x) {
        int tileId = layer.tileMatrix[y][x];
        if (tileId == 0) {
          continue;
        }

        final TileSet tileSet = _tmxMap.getTileSetByGid(tileId);
        final Tile? tile = tileSet.getTileByGid(tileId);

        if (tile == null) {
          continue;
        }

        final Offset offset = layerOffset +
            Offset(
              x * _tmxMap.tileWidth,
              y * _tmxMap.tileHeight,
            ) +
            Offset(
              0,
              _tmxMap.tileHeight - (tile.image?.height ?? tileSet.tileHeight),
            );

        _addTileObjectFixtures(
          body,
          tileSet,
          tile,
          baseOffset: offset,
        );
      }
    }
  }

  void _addObjectLayerFixtures(
    Body body,
    ObjectGroup objectLayer, {
    Offset baseOffset = Offset.zero,
  }) {
    objectLayer.objectMapById.values.forEach(
      (object) {
        Offset offset = baseOffset +
            Offset(
              objectLayer.offsetX,
              objectLayer.offsetY,
            );

        if (object.gid != null) {
          final TileSet tileSet = _tmxMap.getTileSetByGid(object.gid!);
          final Tile tile = tileSet.getTileByGid(object.gid!)!;

          final Offset alignment =
              object.getAlignedOffset(tileSet.objectAlignment);

          offset += Offset(object.x, object.y) + alignment;

          _addTileObjectFixtures(
            body,
            tileSet,
            tile,
            baseOffset: offset,
          );
        } else {
          _addObjectFixture(body, object, baseOffset: offset);
        }
      },
    );
  }

  void _addGroupLayerFixtures(
    Body body,
    Group group, {
    Offset baseOffset = Offset.zero,
  }) {
    _createFixtureDefs(
      body,
      group.renderOrderedLayers,
      baseOffset: baseOffset + Offset(group.offsetX, group.offsetY),
    );
  }

  void _addTileObjectFixtures(
    Body body,
    TileSet tileSet,
    Tile tile, {
    Offset baseOffset = Offset.zero,
  }) {
    if (tile.objectGroup?.objectMapById.isEmpty ?? true) {
      return;
    }

    Offset offset = baseOffset +
        Offset(
          tileSet.tileOffset.x,
          tileSet.tileOffset.y,
        );

    tile.objectGroup!.objectMapById.values.forEach(
      (object) => _addObjectFixture(body, object, baseOffset: offset),
    );
  }

  void _addObjectFixture(
    Body body,
    TmxObject object, {
    Offset baseOffset = Offset.zero,
  }) {
    Iterable<Vector2> vertices =
        object.points!.map((point) => point.toVector2());

    final Vector2 firstPoint = vertices.first;
    if (object.rotation != 0) {
      vertices = vertices.map((v) {
        v -= firstPoint;
        v.rotate(object.rotation * pi / 180.0);
        v += firstPoint;
        return v;
      });
    }

    final Offset objectOffset = Offset(
      object.x,
      object.y,
    );

    final Offset offset = baseOffset + objectOffset;

    vertices = vertices
        .map((v) => Vector2(v.x + offset.dx, -(v.y + offset.dy)) / _zoom)
        .toList(growable: false);

    Shape shape;
    if (vertices.length > 2 && !(object.height == 0 || object.width == 0)) {
      PolygonShape ps = PolygonShape();
      ps.set(vertices.toList());

      shape = ps;
    } else {
      EdgeShape es = EdgeShape();
      es.set(vertices.first, vertices.last);

      shape = es;
    }

    final FixtureDef fd = FixtureDef(shape);
    fd.friction = 0.6;
    // fd.density = 1;
    // fd.friction = .5;
    body.createFixture(fd);
  }
}
