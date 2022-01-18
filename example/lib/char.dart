import "dart:math";

import "package:flame/components.dart";
import "package:flame/flame.dart";
import "package:flame/image_composition.dart";
import "package:flame/input.dart";
import "package:flame_forge2d/contact_callbacks.dart";
import "package:flame_forge2d/flame_forge2d.dart";
import "package:flame_forge2d/position_body_component.dart";
import "package:flame_forge2d_tiled/flame_forge2d_tiled.dart";
import "package:flutter/services.dart";
import "package:tmx_parser/tmx_parser.dart";

enum PlayerState {
  floor,
  jumping,
  falling,
}

enum Direction {
  left,
  right,
}

class AnimCharContactCallback extends ContactCallback<Char, TiledMap> {
  @override
  void begin(Char char, TiledMap tiledMap, Contact contact) {
    if (contact.fixtureA.isSensor || contact.fixtureB.isSensor) {
      String sensorName =
          (contact.fixtureA.userData ?? contact.fixtureB.userData) as String;
      switch (sensorName) {
        case "down":
          char.contact++;
          break;
      }
    }
  }

  @override
  void end(Char char, TiledMap tiledMap, Contact contact) {
    if (contact.fixtureA.isSensor || contact.fixtureB.isSensor) {
      String sensorName =
          (contact.fixtureA.userData ?? contact.fixtureB.userData) as String;
      switch (sensorName) {
        case "down":
          char.contact--;
          break;
      }
    }
  }
}

class Char extends PositionBodyComponent<TiledGame> with KeyboardHandler {
  late double _zoom;
  late Tile tile;

  int contact = 0;

  Direction direction = Direction.right;
  PlayerState playerState = PlayerState.falling;

  Set<LogicalKeyboardKey> keysPressed = {};

  @override
  bool get debugMode => false;

  Char() : super(size: Vector2.zero());

  @override
  Future<void> onLoad() async {
    _zoom = super.gameRef.camera.zoom;

    TileSet tileSet = super.gameRef.tmxMap.tileSets["char"]!;

    this.tile = tileSet.tiles.values.first;

    Image charImage =
        Flame.images.fromCache(tileSet.tiles.values.first.image!.source!);

    super.size.setFrom(charImage.size / _zoom);

    positionComponent = SpriteComponent(sprite: Sprite(charImage));

    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (this.contact > 0) {
      this.playerState = PlayerState.floor;
    }

    if (this.contact == 0 && super.body.linearVelocity.y < 0) {
      this.playerState = PlayerState.falling;
    }

    if (keysPressed.isEmpty && playerState == PlayerState.floor) {
      this.body.linearVelocity = Vector2.zero();
    }

    for (LogicalKeyboardKey key in keysPressed) {
      switch (key.keyLabel) {
        case "W":
          if (this.contact > 0) {
            double velChange = 15 - super.body.linearVelocity.y;
            double push = velChange * super.body.mass;
            super.body.applyLinearImpulse(Vector2(0, push));
            this.playerState = PlayerState.jumping;
          }
          break;
        case "A":
          double velChange = -6 - super.body.linearVelocity.x;
          double push = velChange * super.body.mass;
          super.body.applyLinearImpulse(Vector2(push, 0));

          if (!super.positionComponent!.transform.scale.x.isNegative) {
            super.positionComponent!.flipHorizontallyAroundCenter();
          }
          break;
        case "S":
          break;
        case "D":
          double velChange = 6 - super.body.linearVelocity.x;
          double push = velChange * super.body.mass;
          super.body.applyLinearImpulse(Vector2(push, 0));

          if (super.positionComponent!.transform.scale.x.isNegative) {
            super.positionComponent!.flipHorizontallyAroundCenter();
          }
          break;
      }
    }
  }

  @override
  Body createBody() {
    BodyDef bd = BodyDef();
    bd.position = Vector2(10, 0);
    bd.type = BodyType.dynamic;
    bd.userData = this;
    bd.fixedRotation = true;
    bd.gravityScale = 10;
    bd.linearDamping = 2;
    Body body = world.createBody(bd);

    for (TmxObject object in this.tile.objectGroup!.objectMapById.values) {
      Iterable<Vector2> vertices = object.points!
          .map(
            (point) =>
                Vector2(
                  point.x + object.x - tile.image!.width! / 2.0,
                  tile.image!.height! / 2.0 - point.y - object.y,
                ) /
                _zoom,
          )
          .toList();

      if (object.rotation != 0) {
        Vector2 firstPoint = vertices.first;
        vertices = vertices.map((v) {
          v -= firstPoint;
          v.rotate(object.rotation * -pi / 180.0);
          v += firstPoint;
          return v;
        });
      }

      Shape shape;
      if (vertices.length > 2 && !(object.height == 0 || object.width == 0)) {
        PolygonShape ps = PolygonShape();
        ps.set(vertices.toList());

        shape = ps;
      } else {
        EdgeShape es = EdgeShape();
        es.set(vertices.first, vertices.last);

        shape = es;
      }

      FixtureDef fd = FixtureDef(shape);
      fd.density = 50;
      fd.restitution = 0;
      fd.friction = object.properties?["friction"]?.value ?? 0.0;
      fd.isSensor = object.properties?["isSensor"]?.value ?? false;
      fd.userData = object.properties?["name"]?.value;

      body.createFixture(fd);
    }

    return body;
  }

  @override
  bool onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    this.keysPressed = keysPressed;

    return true;
  }
}
