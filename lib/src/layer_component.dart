import "dart:collection";
import "dart:ui";

import "package:flame/components.dart";
import "package:flame_forge2d/flame_forge2d.dart";
import "package:flutter/foundation.dart";
import "package:tmx_parser/tmx_parser.dart";

import "../flame_forge2d_tiled.dart";
import "draw_context.dart";
import "extensions/layer.dart";
import "group_layer_component.dart";
import "image_layer_component.dart";
import "object_layer_component.dart";
import "tile_layer_component.dart";

// TODO: use offsets as position

abstract class LayerComponent<T extends Layer> extends BodyComponent<TiledGame>
    with HasGameRef<TiledGame> {
  @protected
  TmxMap get tmxMap => super.gameRef.tmxMap;

  @override
  @protected
  CameraComponent get camera => super.gameRef.camera;

  @protected
  double get zoom => this.camera.viewfinder.zoom;

  @protected
  late T layer;

  @protected
  final LinkedHashMap<Image, DrawContext> drawContextMap =
      LinkedHashMap<Image, DrawContext>();

  LayerComponent({
    required this.layer,
  });

  factory LayerComponent.create(
    T layer,
  ) {
    if (layer is TileLayer) {
      return TileLayerComponent(
        layer: layer,
      ) as LayerComponent<T>;
    } else if (layer is ObjectGroup) {
      return ObjectLayerComponent(
        layer: layer,
      ) as LayerComponent<T>;
    } else if (layer is Group) {
      return GroupLayerComponent(
        layer: layer,
      ) as LayerComponent<T>;
    } else if (layer is ImageLayer) {
      return ImageLayerComponent(
        layer: layer,
      ) as LayerComponent<T>;
    }

    throw Exception("Unknown layer type");
  }

  @protected
  void renderLayer(Canvas canvas);

  @override
  void render(Canvas canvas) {
    if (!layer.visible) {
      return;
    }

    renderLayer(canvas);
    super.render(canvas);
  }

  @override
  Body createBody() {
    BodyDef bd = BodyDef()
      ..position = Vector2.zero()
      ..type = BodyType.static
      ..userData = this;

    Body body = world.createBody(bd);

    Map<Vector2, Vector2> edges = <Vector2, Vector2>{};

    for (FixtureDef fd in createFixtures(edges: edges)) {
      body.createFixture(fd);
    }

    // if there are edges on the map create chain for them
    // visit every vertex with dfs
    if (edges.isNotEmpty) {
      for (FixtureDef fd in _createChains(
        body: body,
        edges: edges,
      )) {
        body.createFixture(fd);
      }
    }

    return body;
  }

  @protected
  Iterable<FixtureDef> createFixtures({
    required Map<Vector2, Vector2> edges,
  }) =>
      const Iterable.empty();

  @protected
  Iterable<FixtureDef> createTileObjectFixtures({
    required Tile tile,
    required Map<Vector2, Vector2> edges,
    required Vector2 baseOffset,
  }) sync* {
    if (tile.objectGroup?.objects.isEmpty ?? true) {
      return;
    }

    baseOffset += layer.offset;

    for (TmxObject object in tile.objectGroup!.objects.values) {
      FixtureDef? fd = object.createFixture(
        edges: edges,
        zoom: zoom,
        baseOffset: baseOffset,
      );

      if (fd != null) {
        yield fd;
      }
    }
  }

  Iterable<FixtureDef> _createChains({
    required Body body,
    required Map<Vector2, Vector2> edges,
  }) sync* {
    Map<Vector2, bool> visitMap = Map.fromIterables(
      edges.keys,
      List<bool>.generate(
        edges.length,
        (int index) => false,
        growable: false,
      ),
    );

    // create open chains
    // find vertices that no other vertices are adjacent to
    for (Vector2 vertex
        in edges.keys.where((Vector2 key) => !edges.values.contains(key))) {
      List<Vector2> vertices = _traverseVertices(
        edges: edges,
        visitMap: visitMap,
        vertex: vertex,
      );
      yield _createChain(
        vertices: vertices,
        isClosed: false,
      );
    }

    // create closed chains
    // find vertices that are not visited
    for (MapEntry<Vector2, bool> entry
        in visitMap.entries.where((MapEntry<Vector2, bool> e) => !e.value)) {
      List<Vector2> vertices = _traverseVertices(
        edges: edges,
        visitMap: visitMap,
        vertex: entry.key,
      );
      yield _createChain(
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
    Queue<Vector2> verticesToVisit = Queue<Vector2>()..add(vertex);

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

  FixtureDef _createChain({
    required List<Vector2> vertices,
    required bool isClosed,
  }) {
    ChainShape cs = ChainShape();
    if (isClosed) {
      cs.createLoop(vertices);
    } else {
      cs.createChain(vertices);
    }

    FixtureDef fd = FixtureDef(cs)..friction = 0.0;
    return fd;
  }
}
