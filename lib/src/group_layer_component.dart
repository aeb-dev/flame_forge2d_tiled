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
        .where((Layer l) => l.visible)
        .map(
          (Layer l) => LayerComponent.create(l),
        )
        .toList();

    await super.world.addAll(layerComponents);
    await super.onLoad();
  }

  @override
  void renderLayer(Canvas canvas) {
    canvas
      ..save()
      ..translate(layer.offsetX, layer.offsetY)
      ..restore();
  }
}
