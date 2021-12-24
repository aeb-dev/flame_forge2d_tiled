import 'package:flame/extensions.dart';
import 'package:tmx_parser/tmx_parser.dart';

extension TmxImageExtensions on TmxImage {
  Size get size => Size(width!, height!);
}
