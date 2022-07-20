import "dart:ui";

import 'package:forge2d/src/dynamics/fixture_def.dart';
import 'package:forge2d/src/dynamics/body.dart';
import "package:tmx_parser/tmx_parser.dart";
import 'package:vector_math/vector_math_64.dart';

import "layer_component.dart";

class GroupLayerComponent extends LayerComponent<Group> {
  GroupLayerComponent({
    required super.layer,
  });

  @override
  Future<void> onLoad() async {
    List<LayerComponent> layerComponents = layer.renderOrderedLayers
        .where((l) => l.visible)
        .map(
          (l) => LayerComponent.create(l),
        )
        .toList();

    await super.addAll(layerComponents);
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.translate(layer.offsetX, layer.offsetY);
    canvas.restore();
  }
}
