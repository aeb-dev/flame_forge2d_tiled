import "package:flame/extensions.dart";
import "package:tmx_parser/tmx_parser.dart";

/// Extension functions on [TmxImage]
extension TmxImageExtensions on TmxImage {
  /// The size of the underlying [TmxImage]
  Vector2 get size => Vector2(
        this.width!,
        this.height!,
      );
}
