import "package:flame/input.dart";
import "package:flame_forge2d/flame_forge2d.dart";
import "package:flame_forge2d_tiled/flame_forge2d_tiled.dart";

import "char.dart";

class GameInstance extends TiledGame
    with TapDetector, HasKeyboardHandlerComponents {
  late Char char;

  GameInstance({
    required String tmxFile,
  }) : super(
          tmxFile: tmxFile,
          zoom: 32,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    char = Char();

    await super.add(char);
  }

  @override
  void update(double dt) {
    super.update(dt);

    super.camera.followBodyComponent(char);
  }
}
