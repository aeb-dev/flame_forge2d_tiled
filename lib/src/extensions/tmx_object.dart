import 'package:flame/extensions.dart';
import 'package:tmx_parser/tmx_parser.dart';

extension TmxObjectExtensions on TmxObject {
  Offset getOffset() => Offset(x, y);

  Offset getAlignedOffset(ObjectAlignment objectAlignment) {
    late Offset offset;
    switch (objectAlignment) {
      case ObjectAlignment.bottomLeft:
        offset = Offset(0.0, -height);
        break;
      case ObjectAlignment.bottomRight:
        offset = Offset(-width, -height);
        break;
      case ObjectAlignment.bottom:
        offset = Offset(-width / 2.0, -height);
        break;
      case ObjectAlignment.topLeft:
        // do nothing
        break;
      case ObjectAlignment.topRight:
        offset = Offset(-width, 0.0);
        break;
      case ObjectAlignment.top:
        offset = Offset(-width / 2.0, 0.0);
        break;
      case ObjectAlignment.left:
        offset = Offset(0.0, -height / 2.0);
        break;
      case ObjectAlignment.center:
        offset = Offset(-width / 2.0, -height / 2.0);
        break;
      case ObjectAlignment.right:
        offset = Offset(-width, -height / 2.0);
        break;
    }

    return offset;
  }
}
