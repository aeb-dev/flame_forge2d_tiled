import "dart:collection";
import "dart:math";
import "dart:ui";

import "package:flame/extensions.dart";
import "package:flame/flame.dart";
import "package:flame_forge2d/body_component.dart";
import "package:forge2d/forge2d.dart";
import "package:tmx_parser/tmx_parser.dart";

import "draw_context.dart";
import "extensions/point.dart";
import "extensions/tmx_object.dart";
import "tiled_game.dart";

/// The map with its physical objects
class TiledMap extends BodyComponent<TiledGame> {
  static final Paint _paint = Paint();
  late TmxMap _tmxMap;
  late double _zoom;

  @override
  bool get debugMode => false;

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
      canvas: canvas,
      layers: _tmxMap.renderOrderedLayers,
      baseOffset: Offset.zero,
    );
  }

  void _render({
    required Canvas canvas,
    required List<dynamic> layers,
    required Offset baseOffset,
  }) {
    layers.where((layer) => layer.visible).forEach((layer) {
      if (layer is Layer) {
        _renderLayer(
          canvas: canvas,
          layer: layer,
          baseOffset: baseOffset,
        );
      } else if (layer is ObjectGroup) {
        _renderObjectLayer(
          canvas: canvas,
          objectLayer: layer,
          baseOffset: baseOffset,
        );
      } else if (layer is ImageLayer) {
        _renderImageLayer(
          canvas: canvas,
          imageLayer: layer,
          baseOffset: baseOffset,
        );
      } else if (layer is Group) {
        _renderGroup(
          canvas: canvas,
          groupLayer: layer,
          baseOffset: baseOffset,
        );
      }
    });
  }

  void _renderLayer({
    required Canvas canvas,
    required Layer layer,
    required Offset baseOffset,
  }) {
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

    Offset layerOffset = Offset(
      layer.offsetX,
      layer.offsetY,
    );

    for (int y = startY; y != endY; y += incY) {
      for (int x = startX; x != endX; x += incX) {
        int tileId = layer.tileMatrix[y][x];
        if (tileId == 0) {
          continue;
        }

        // offset for the location on the canvas
        Offset indexOffset = Offset(
          x * _tmxMap.tileWidth,
          y * _tmxMap.tileHeight,
        );

        Offset offset = layerOffset + baseOffset + indexOffset;

        _renderTile(
          canvas: canvas,
          gid: tileId,
          baseOffset: offset,
        );
      }
    }
  }

  void _renderObjectLayer({
    required Canvas canvas,
    required ObjectGroup objectLayer,
    required Offset baseOffset,
  }) {
    Offset layerOffset = Offset(
      objectLayer.offsetX,
      objectLayer.offsetY,
    );

    Offset offset = baseOffset + layerOffset;

    objectLayer.objectMapById.values
        .where((object) => object.gid != null)
        .forEach(
          (object) => _renderObjectTile(
            canvas: canvas,
            object: object,
            baseOffset: offset,
          ),
        );
  }

  void _renderImageLayer({
    required Canvas canvas,
    required ImageLayer imageLayer,
    required Offset baseOffset,
  }) {
    Offset layerOffset = Offset(
      imageLayer.offsetX,
      imageLayer.offsetY,
    );

    Offset offset = baseOffset + layerOffset;

    canvas.drawImage(
      Flame.images.fromCache(imageLayer.image!.source!),
      offset,
      _paint,
    );
  }

  void _renderGroup({
    required Canvas canvas,
    required Group groupLayer,
    required Offset baseOffset,
  }) {
    Offset layerOffset = Offset(
      groupLayer.offsetX,
      groupLayer.offsetY,
    );

    Offset offset = baseOffset + layerOffset;
    _render(
      canvas: canvas,
      layers: groupLayer.renderOrderedLayers,
      baseOffset: offset,
    );
  }

  void _renderTile({
    required Canvas canvas,
    required int gid,
    required Offset baseOffset,
  }) {
    DrawContext drawContext = DrawContext.createTileContext(
      tmxMap: _tmxMap,
      gid: gid,
      baseOffset: baseOffset,
      zoom: _zoom,
    );

    Rect screenRect = camera.position.toPositionedRect(camera.gameSize);

    bool inViewport = screenRect.overlaps(drawContext.destinationRect);
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

  void _renderObjectTile({
    required Canvas canvas,
    required TmxObject object,
    required Offset baseOffset,
  }) {
    DrawContext drawContext = DrawContext.createTileObjectContext(
      tmxMap: _tmxMap,
      object: object,
      baseOffset: baseOffset,
      zoom: _zoom,
    );

    bool inViewport = camera.position
        .toPositionedRect(camera.gameSize)
        .overlaps(drawContext.destinationRect);
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

    Map<Vector2, Vector2> edges = {};

    _createFixtureDefs(
      body: body,
      layers: _tmxMap.renderOrderedLayers,
      edges: edges,
    );

    // if there are edges on the map create chain for them
    // visit every vertex with dfs
    if (edges.isNotEmpty) {
      _createChains(
        body: body,
        edges: edges,
      );
    }

    return body;
  }

  void _createFixtureDefs({
    required Body body,
    required List<dynamic> layers,
    required Map<Vector2, Vector2> edges,
    Offset baseOffset = Offset.zero,
  }) {
    for (dynamic layer in layers.where((layer) => layer.visible)) {
      if (layer is Layer) {
        _addLayerFixtures(
          body: body,
          layer: layer,
          edges: edges,
          baseOffset: baseOffset,
        );
      } else if (layer is ObjectGroup) {
        _addObjectLayerFixtures(
          body: body,
          objectLayer: layer,
          edges: edges,
          baseOffset: baseOffset,
        );
      } else if (layer is ImageLayer) {
        // do nothing
      } else if (layer is Group) {
        _addGroupLayerFixtures(
          body: body,
          groupLayer: layer,
          edges: edges,
          baseOffset: baseOffset,
        );
      }
    }
  }

  void _addLayerFixtures({
    required Body body,
    required Layer layer,
    required Map<Vector2, Vector2> edges,
    Offset baseOffset = Offset.zero,
  }) {
    Offset layerOffset = baseOffset +
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

        TileSet tileSet = _tmxMap.getTileSetByGid(tileId);
        Tile? tile = tileSet.getTileByGid(tileId);

        if (tile == null) {
          continue;
        }

        Offset offset = layerOffset +
            Offset(
              x * _tmxMap.tileWidth,
              y * _tmxMap.tileHeight,
            ) +
            Offset(
              0,
              _tmxMap.tileHeight - (tile.image?.height ?? tileSet.tileHeight),
            );

        _addTileObjectFixtures(
          body: body,
          tileSet: tileSet,
          tile: tile,
          edges: edges,
          baseOffset: offset,
        );
      }
    }
  }

  void _addObjectLayerFixtures({
    required Body body,
    required ObjectGroup objectLayer,
    required Map<Vector2, Vector2> edges,
    Offset baseOffset = Offset.zero,
  }) {
    for (TmxObject object in objectLayer.objectMapById.values) {
      Offset offset = baseOffset +
          Offset(
            objectLayer.offsetX,
            objectLayer.offsetY,
          );

      if (object.gid != null) {
        TileSet tileSet = _tmxMap.getTileSetByGid(object.gid!);
        Tile tile = tileSet.getTileByGid(object.gid!)!;

        Offset alignment = object.getAlignedOffset(tileSet.objectAlignment);

        offset += Offset(object.x, object.y) + alignment;

        _addTileObjectFixtures(
          body: body,
          tileSet: tileSet,
          tile: tile,
          edges: edges,
          baseOffset: offset,
        );
      } else {
        _addObjectFixture(
          body: body,
          object: object,
          edges: edges,
          baseOffset: offset,
        );
      }
    }
  }

  void _addGroupLayerFixtures({
    required Body body,
    required Group groupLayer,
    required Map<Vector2, Vector2> edges,
    Offset baseOffset = Offset.zero,
  }) {
    _createFixtureDefs(
      body: body,
      layers: groupLayer.renderOrderedLayers,
      edges: edges,
      baseOffset: baseOffset +
          Offset(
            groupLayer.offsetX,
            groupLayer.offsetY,
          ),
    );
  }

  void _addTileObjectFixtures({
    required Body body,
    required TileSet tileSet,
    required Tile tile,
    required Map<Vector2, Vector2> edges,
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

    for (TmxObject object in tile.objectGroup!.objectMapById.values) {
      _addObjectFixture(
        body: body,
        object: object,
        edges: edges,
        baseOffset: offset,
      );
    }
  }

  void _addObjectFixture({
    required Body body,
    required TmxObject object,
    required Map<Vector2, Vector2> edges,
    Offset baseOffset = Offset.zero,
  }) {
    Iterable<Vector2> vertices =
        object.points!.map((point) => point.toVector2());

    Vector2 firstPoint = vertices.first;
    if (object.rotation != 0) {
      vertices = vertices.map((v) {
        v -= firstPoint;
        v.rotate(object.rotation * pi / 180.0);
        v += firstPoint;
        return v;
      });
    }

    Offset objectOffset = Offset(
      object.x,
      object.y,
    );

    Offset offset = baseOffset + objectOffset;

    vertices = vertices
        .map((v) => Vector2(v.x + offset.dx, -(v.y + offset.dy)) / _zoom)
        .toList(growable: false);

    Shape shape;
    if (vertices.length > 2 && !(object.height == 0 || object.width == 0)) {
      PolygonShape ps = PolygonShape();
      ps.set(vertices.toList());

      shape = ps;
    } else {
      Vector2? adj = edges[vertices.first];
      if (adj != null) {
        throw "No vertex should have more than one adjacent vertex";
      }

      edges[vertices.first] = vertices.last;
      return;
    }

    FixtureDef fd = FixtureDef(shape);
    fd.friction = object.properties?["friction"]?.value ?? 0.0;
    body.createFixture(fd);
  }

  void _createChains({
    required Body body,
    required Map<Vector2, Vector2> edges,
  }) {
    Map<Vector2, bool> visitMap = Map.fromIterables(
      edges.keys,
      List<bool>.generate(
        edges.length,
        (index) => false,
        growable: false,
      ),
    );

    // create open chains
    // find vertices that no other vertices are adjacent to
    for (Vector2 vertex
        in edges.keys.where((key) => !edges.values.contains(key))) {
      List<Vector2> vertices = _traverseVertices(
        edges: edges,
        visitMap: visitMap,
        vertex: vertex,
      );
      _createChain(
        body: body,
        vertices: vertices,
        isClosed: false,
      );
    }

    // create closed chains
    // find vertices that are not visited
    for (Vector2 vertex
        in visitMap.entries.where((entry) => !entry.value).map((e) => e.key)) {
      List<Vector2> vertices = _traverseVertices(
        edges: edges,
        visitMap: visitMap,
        vertex: vertex,
      );
      _createChain(
        body: body,
        vertices: vertices,
        isClosed: true,
      );
    }
  }

  List<Vector2> _traverseVertices({
    required Map<Vector2, Vector2> edges,
    required Map<Vector2, bool> visitMap,
    required Vector2 vertex,
  }) {
    Queue<Vector2> verticesToVisit = Queue<Vector2>();
    verticesToVisit.add(vertex);

    List<Vector2> visitedVertices = List.empty(growable: true);

    do {
      vertex = verticesToVisit.removeFirst();
      visitMap[vertex] = true;
      visitedVertices.add(vertex);

      Vector2? adj = edges[vertex];
      // if chain is not a loop, visitMap[adj] will return null,
      // in order to add last vertex to the map we return true by using null check false
      if (adj != null && !(visitMap[adj] ?? false)) {
        verticesToVisit.addFirst(adj);
      }
    } while (verticesToVisit.isNotEmpty);

    return visitedVertices;
  }

  void _createChain({
    required Body body,
    required List<Vector2> vertices,
    required bool isClosed,
  }) {
    ChainShape cs = ChainShape();
    if (isClosed) {
      cs.createLoop(vertices);
    } else {
      cs.createChain(vertices);
    }

    FixtureDef fd = FixtureDef(cs);
    fd.friction = 0.0;
    body.createFixture(fd);
  }
}
