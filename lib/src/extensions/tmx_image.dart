import "package:flame/extensions.dart";
import "package:tmx_parser/tmx_parser.dart";

/// Extension functions on [TmxImage]
extension TmxImageExtensions on TmxImage {
  /// The size of the underlying [TmxImage]
  Size get size => Size(this.width!, this.height!);
}
