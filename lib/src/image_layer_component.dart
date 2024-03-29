import "package:flame/extensions.dart";
import "package:flame/flame.dart";
import "package:tmx_parser/tmx_parser.dart";

import "layer_component.dart";

class ImageLayerComponent extends LayerComponent<ImageLayer> {
  final Image image;
  late Rect srcRect;
  late Rect dstRect;

  ImageLayerComponent({
    required super.layer,
  }) : image = Flame.images.fromCache(layer.image!.source) {
    srcRect = image.getBoundingRect();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    dstRect = srcRect.topLeft & srcRect.size / super.zoom;
  }

  @override
  void renderLayer(Canvas canvas) {
    // TODO: handle image repeat
    canvas.drawImageRect(
      image,
      srcRect,
      dstRect,
      super.paint,
    );
  }
}
