import "package:flame/components.dart";
import "package:tmx_parser/tmx_parser.dart";

extension ObjectAlignmentExtension on ObjectAlignment {
  Anchor toAnchor() {
    Anchor anchor;
    switch (this) {
      case ObjectAlignment.bottomLeft:
        anchor = Anchor.bottomLeft;
      case ObjectAlignment.bottomRight:
        anchor = Anchor.bottomRight;
      case ObjectAlignment.bottom:
        anchor = Anchor.bottomCenter;
      case ObjectAlignment.topLeft:
        anchor = Anchor.topLeft;
      case ObjectAlignment.topRight:
        anchor = Anchor.topRight;
      case ObjectAlignment.top:
        anchor = Anchor.topCenter;
      case ObjectAlignment.left:
        anchor = Anchor.centerLeft;
      case ObjectAlignment.center:
        anchor = Anchor.center;
      case ObjectAlignment.right:
        anchor = Anchor.centerRight;
    }

    return anchor;
  }
}
