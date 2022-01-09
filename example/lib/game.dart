import 'package:flame/game.dart';
import 'package:flame/input.dart';

import 'package:flame_forge2d_tiled/flame_forge2d_tiled.dart';

import 'char.dart';

class GameInstance extends TiledGame
    with TapDetector, HasKeyboardHandlerComponents, FPSCounter {
  late Char char;

  GameInstance({
    required String tmxFile,
  }) : super(tmxFile: tmxFile) {
    super.addContactCallback(AnimCharContactCallback());
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    char = Char();

    await super.add(char);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final Vector2 bodyPosition = this.char.body.position.clone()..y *= -1;
    super.camera.followVector2(bodyPosition);
  }
}
