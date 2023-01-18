import "package:flame/components.dart";
import "package:tmx_parser/tmx_parser.dart";

import "layer_component.dart";
import "tiled_game.dart";

/// The map with its physical objects
class TiledMap extends Component with HasGameRef<TiledGame> {
  late TmxMap _tmxMap;
  // late double _zoom;

  @override
  bool get debugMode => false;

  @override
  Future<void> onLoad() async {
    _tmxMap = super.gameRef.tmxMap;
    // _zoom = super.gameRef.camera.zoom;

    await super.onLoad();

    await super.addAll(
      _tmxMap.renderOrderedLayers.where((l) => l.visible).map(
            (l) => LayerComponent.create(l),
          ),
    );
  }
}
