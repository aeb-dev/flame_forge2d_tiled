import "package:flame/flame.dart";
import "package:flame_forge2d/forge2d_game.dart";
import "package:flutter/foundation.dart";
import "package:tmx_parser/tmx_parser.dart";

import "../flame_forge2d_tiled.dart";

// TODO: is there anyway to make TiledGame work both with BaseGame and Forge2DGame

/// This class loads all required assets and creates a [TiledMap] and adds it as children
class TiledGame extends Forge2DGame {
  /// The in memory representation of tmx file
  late TmxMap tmxMap;

  /// The path of tiled map
  final String tmxFile;

  /// A game instance based on the supplied [tmxFile]
  /// The [zoom] parameters is required because Box2D work with KMS while Tiled works with pixels.
  /// For example if a Tile in Tiled is 32 pixels and if your zoom is 32, then every 32 pixel in Tiled
  /// will be treated as 1 meters in Box2D
  TiledGame({
    required this.tmxFile,
    required double zoom,
  }) : super(
          zoom: zoom,
        );

  @override
  @mustCallSuper
  Future<void> onLoad() async {
    String xml = await Flame.bundle.loadString("assets/tiles/$tmxFile");
    tmxMap = TmxParser.parse(xml);

    await _loadImages();
    await super.add(TiledMap());
    await super.onLoad();
  }

  Future<void> _loadImages() async {
    List<String> filePathList = <String>[];

    for (TileSet tileSet in tmxMap.tileSets.values) {
      if (tileSet.image != null) {
        filePathList.add(tileSet.image!.source!);
      } else {
        tileSet.tiles.values
            .where((tile) => tile.image?.source != null)
            .forEach((tile) => filePathList.add(tile.image!.source!));
      }
    }

    for (ImageLayer imageLayer in tmxMap.imageLayers
        .where((imageLayer) => imageLayer.image?.source != null)) {
      filePathList.add(imageLayer.image!.source!);
    }

    await Flame.images.loadAll(filePathList);
  }
}
