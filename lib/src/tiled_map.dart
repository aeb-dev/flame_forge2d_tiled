import "package:flame/components.dart";
import "package:flame/flame.dart";
import "package:tmx_parser/tmx_parser.dart";

import "layer_component.dart";
import "tiled_game.dart";

/// The map with its physical objects
class TiledMap extends Component with HasGameRef<TiledGame> {
  final TmxMap _tmxMap;

  @override
  bool get debugMode => false;

  TiledMap(this._tmxMap);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await _loadImages();

    await super.addAll(
      _tmxMap.renderOrderedLayers.map(
        (Layer l) => LayerComponent.create(l),
      ),
    );
  }

  Future<void> _loadImages() async {
    List<String> filePathList = <String>[];

    for (TileSet tileSet in _tmxMap.tileSets.values) {
      if (tileSet.image != null) {
        filePathList.add(tileSet.image!.source);
      } else {
        for (Tile tile in tileSet.tiles.values
            .where((Tile tile) => tile.image?.source != null)) {
          filePathList.add(tile.image!.source);
        }
      }
    }

    for (ImageLayer imageLayer in _tmxMap.imageLayers
        .where((ImageLayer imageLayer) => imageLayer.image?.source != null)) {
      filePathList.add(imageLayer.image!.source);
    }

    await Flame.images.loadAll(filePathList);
  }
}
