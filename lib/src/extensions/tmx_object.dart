import "dart:math";

import "package:flame/extensions.dart";
import "package:flame_forge2d/flame_forge2d.dart";
import "package:tmx_parser/tmx_parser.dart";

import "point.dart";

/// Extension functions on [TmxObject]
extension TmxObjectExtensions on TmxObject {
  /// Creates an [Offset] based on the position of the [TmxObject]
  Vector2 get offset => Vector2(
        x,
        y,
      );

  Vector2 get size => Vector2(
        width,
        height,
      );

  double get rotationInRadians => rotation * pi / 180.0;

  /// Creates an [Offset] to correct the alignment of the [TmxObject] according to the [objectAlignment]
  Vector2 getAlignmentOffset(ObjectAlignment objectAlignment) {
    Vector2 offset;
    switch (objectAlignment) {
      case ObjectAlignment.bottomLeft:
        offset = Vector2(0.0, height);
        break;
      case ObjectAlignment.bottomRight:
        offset = Vector2(width, height);
        break;
      case ObjectAlignment.bottom:
        offset = Vector2(width / 2.0, height);
        break;
      case ObjectAlignment.topLeft:
        offset = Vector2.zero();
        break;
      case ObjectAlignment.topRight:
        offset = Vector2(width, 0.0);
        break;
      case ObjectAlignment.top:
        offset = Vector2(width / 2.0, 0.0);
        break;
      case ObjectAlignment.left:
        offset = Vector2(0.0, height / 2.0);
        break;
      case ObjectAlignment.center:
        offset = Vector2(width / 2.0, height / 2.0);
        break;
      case ObjectAlignment.right:
        offset = Vector2(width, height / 2.0);
        break;
    }

    return offset;
  }

  FixtureDef? createFixture({
    Map<Vector2, Vector2>? edges,
    required double zoom,
    required Vector2 baseOffset,
  }) {
    if (objectType == ObjectType.rectangle && points.isEmpty) {
      points.addAll(
        [
          Point.zero(),
          Point.from(0.0, height),
          Point.from(width, height),
          Point.from(width, 0.0),
        ],
      );
    }

    Iterable<Vector2> verticesIt = points.map(
      (point) => (point.toVector2() + baseOffset + offset) / zoom,
    );

    if (rotation != 0) {
      Vector2 firstPoint = verticesIt.first;
      verticesIt = verticesIt.map((v) {
        v -= firstPoint;
        v.rotate(rotation * -pi / 180.0);
        v += firstPoint;
        return v;
      });
    }

    List<Vector2> vertices = verticesIt.toList();

    bool chain = properties["chain"]?.value as bool? ?? false;

    if (chain) {
      if (objectType == ObjectType.polygon) {
        vertices.add(vertices.first);
      }

      Vector2 prevVertex = vertices.first;
      for (Vector2 vertex in vertices.skip(1)) {
        Vector2? adj = edges![prevVertex];
        if (adj != null) {
          throw "No vertex should have more than one adjacent vertex";
        }

        edges[prevVertex] = vertex;
        prevVertex = vertex;
      }

      return null;
    }

    Shape shape;
    switch (objectType) {
      case ObjectType.rectangle:
      case ObjectType.polygon:
        shape = PolygonShape()..set(vertices);
        break;
      case ObjectType.ellipse:
        if (width != height) {
          throw "only circles are supported";
        }
        shape = CircleShape()..radius = width;
        break;
      case ObjectType.polyline:
        if (vertices.length == 2) {
          shape = EdgeShape()..set(vertices.first, vertices.last);
        } else {
          shape = ChainShape()..createChain(vertices);
        }
        break;
      case ObjectType.point:
      case ObjectType.text:
      default:
        throw "not supported";
    }

    FixtureDef fd = FixtureDef(shape);
    fd.density = properties["density"]?.value as double? ?? 0.0;
    fd.restitution = properties["restitution"]?.value as double? ?? 0.0;
    fd.friction = properties["friction"]?.value as double? ?? 0.0;
    fd.isSensor = properties["isSensor"]?.value as bool? ?? false;
    fd.userData = properties["name"]?.value;

    return fd;
  }
}
