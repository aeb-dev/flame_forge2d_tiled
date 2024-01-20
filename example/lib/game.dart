import "package:flame/input.dart";
import "package:flame_forge2d_tiled/flame_forge2d_tiled.dart";

import "char.dart";

class GameInstance extends TiledGame
    with TapDetector, HasKeyboardHandlerComponents {
  late Char char;

  GameInstance({
    required super.tmxFile,
  }) : super(
          zoom: 1,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    char = Char();

    await super.world.add(char);

    super.camera.follow(char);
  }
}
