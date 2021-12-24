import 'package:flame/flame.dart';
import 'package:flame_forge2d/forge2d_game.dart';
import 'package:flutter/foundation.dart';
import 'package:tmx_parser/tmx_parser.dart';

import '../flame_tiled.dart';

class TiledGame extends Forge2DGame {
  late TmxMap tmxMap;
  String tmxFile;

  TiledGame({
    required this.tmxFile,
  }) : super(
          zoom: 32.0,
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
    List<String> filePathList = [];

    tmxMap.tileSets.values.forEach((tileSet) {
      if (tileSet.image != null) {
        filePathList.add(tileSet.image!.source!);
      } else {
        tileSet.tiles.values
            .where((tile) => tile.image?.source != null)
            .forEach((tile) => filePathList.add(tile.image!.source!));
      }
    });

    tmxMap.imageLayers
        .where((imageLayer) => imageLayer.image?.source != null)
        .forEach((imageLayer) => filePathList.add(imageLayer.image!.source!));

    await Flame.images.loadAll(filePathList);
  }
}
