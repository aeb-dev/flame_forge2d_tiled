import "package:flame/flame.dart";
import "package:flame/game.dart";
import "package:flutter/material.dart";

import "game.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Flame.device.fullScreen();
  await Flame.device.setLandscapeLeftOnly();
  runApp(
    GameWidget(
      game: GameInstance(
        tmxFile: "map.tmx",
      ),
    ),
  );
}
