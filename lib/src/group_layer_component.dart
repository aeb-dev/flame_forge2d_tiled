import "dart:ui";

import "package:tmx_parser/tmx_parser.dart";

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
