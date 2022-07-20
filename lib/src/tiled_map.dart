import "dart:collection";
import "dart:math";

import 'package:flame/components.dart';
import "package:flame/extensions.dart";
import "package:flame_forge2d/body_component.dart";
import "package:forge2d/forge2d.dart";
import "package:tmx_parser/tmx_parser.dart";

import 'extensions/layer.dart';
import "extensions/point.dart";
import 'extensions/tile_set.dart';
import "extensions/tmx_object.dart";
import 'layer_component.dart';
import "tiled_game.dart";

/// The map with its physical objects
class TiledMap extends Component with HasGameRef<TiledGame> {
  late TmxMap _tmxMap;
  late double _zoom;

  @override
  bool get debugMode => false;

  @override
  Future<void> onLoad() async {
    _tmxMap = super.gameRef.tmxMap;
    _zoom = super.gameRef.camera.zoom;

    await super.onLoad();

    await super.addAll(
      _tmxMap.renderOrderedLayers.where((l) => l.visible).map(
            (l) => LayerComponent.create(l),
          ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
  }

  // @override
  // Body createBody() {
  //   BodyDef bd = BodyDef();
  //   bd.position = Vector2.zero();
  //   bd.type = BodyType.static;
  //   bd.userData = this;

  //   Body body = world.createBody(bd);

  //   Map<Vector2, Vector2> edges = {};

  //   // _createFixtureDefs(
  //   //   body: body,
  //   //   layers: _tmxMap.renderOrderedLayers,
  //   //   edges: edges,
  //   //   baseOffset: Vector2.zero(),
  //   // );

  //   // if there are edges on the map create chain for them
  //   // visit every vertex with dfs
  //   if (edges.isNotEmpty) {
  //     // _createChains(
  //     //   body: body,
  //     //   edges: edges,
  //     // );
  //   }

  //   return body;
  // }
}
