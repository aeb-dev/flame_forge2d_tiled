import "package:flame/components.dart";
import "package:tmx_parser/tmx_parser.dart";

extension ObjectAlignmentExtension on ObjectAlignment {
  Anchor toAnchor() {
    Anchor anchor;
    switch (this) {
      case ObjectAlignment.bottomLeft:
        anchor = Anchor.bottomLeft;
        break;
      case ObjectAlignment.bottomRight:
        anchor = Anchor.bottomRight;
        break;
      case ObjectAlignment.bottom:
        anchor = Anchor.bottomCenter;
        break;
      case ObjectAlignment.topLeft:
        anchor = Anchor.topLeft;
        break;
      case ObjectAlignment.topRight:
        anchor = Anchor.topRight;
        break;
      case ObjectAlignment.top:
        anchor = Anchor.topCenter;
        break;
      case ObjectAlignment.left:
        anchor = Anchor.centerLeft;
        break;
      case ObjectAlignment.center:
        anchor = Anchor.center;
        break;
      case ObjectAlignment.right:
        anchor = Anchor.centerRight;
        break;
    }

    return anchor;
  }
}
