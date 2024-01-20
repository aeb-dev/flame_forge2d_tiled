import "dart:io";

import "package:flame_forge2d/flame_forge2d.dart";
import "package:flutter/foundation.dart";
import "package:tmx_parser/tmx_parser.dart";

import "../flame_forge2d_tiled.dart";

/// This class loads all required assets and creates a [TiledMap] and adds it as children
class TiledGame extends Forge2DGame {
  /// The in memory representation of tmx file
  late TmxMap tmxMap;

  /// The path of tiled map
  final String tmxFile;

  /// A game instance based on the supplied [tmxFile]
  /// The [zoom] parameters is required because Box2D works with MKS while Tiled works with pixels.
  /// For example if a Tile in Tiled is 32 pixels and if your zoom is 32, then every 32 pixel in Tiled
  /// will be treated as 1 meters in Box2D
  TiledGame({
    required this.tmxFile,
    super.zoom,
    super.gravity,
  });

  @override
  @mustCallSuper
  Future<void> onLoad() async {
    File file = File("assets/tiles/$tmxFile");
    tmxMap = await TmxParser.fromFile(file);

    TiledMap tiledMap = TiledMap(tmxMap);
    await super.world.add(tiledMap);

    await super.onLoad();
  }
}
