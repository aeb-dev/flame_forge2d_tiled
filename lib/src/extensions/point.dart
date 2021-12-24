import 'dart:math';

import 'package:flame/extensions.dart';

extension PointExtensions on Point {
  Vector2 toVector2() => Vector2(x.toDouble(), y.toDouble());
}
