import "package:flame/components.dart";
import "package:flame_forge2d/flame_forge2d.dart";
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

class Char extends BodyComponent<TiledGame>
    with
        KeyboardHandler,
        // ignore: prefer_mixin
        ContactCallbacks,
        HasGameRef<TiledGame> {
  late double _zoom;
  late Tile tile;
  late SpriteComponent sp;

  int contact = 0;

  Direction direction = Direction.right;
  PlayerState playerState = PlayerState.falling;

  Set<LogicalKeyboardKey> keysPressed = <LogicalKeyboardKey>{};

  Char() : super(renderBody: false);

  @override
  Future<void> onLoad() async {
    _zoom = super.gameRef.camera.viewfinder.zoom;

    TileSet tileSet = super.gameRef.tmxMap.tileSets["char"]!;

    this.tile = tileSet.tiles.values.first;

    Sprite sprite = await Sprite.load(tileSet.tiles.values.first.image!.source);

    sp = SpriteComponent(
      sprite: await Sprite.load(tileSet.tiles.values.first.image!.source),
      size: sprite.srcSize / _zoom,
    );

    await super.world.add(sp);

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
            double velChange = -15 - super.body.linearVelocity.y;
            double push = velChange * super.body.mass;
            super.body.applyLinearImpulse(Vector2(0, push));
            this.playerState = PlayerState.jumping;
          }
        case "A":
          double velChange = -6 - super.body.linearVelocity.x;
          double push = velChange * super.body.mass;
          super.body.applyLinearImpulse(Vector2(push, 0));

          if (!sp.transform.scale.x.isNegative) {
            sp.flipHorizontallyAroundCenter();
          }
        case "S":
          break;
        case "D":
          double velChange = 6 - super.body.linearVelocity.x;
          double push = velChange * super.body.mass;
          super.body.applyLinearImpulse(Vector2(push, 0));

          if (sp.transform.scale.x.isNegative) {
            sp.flipHorizontallyAroundCenter();
          }
      }
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (contact.fixtureA.isSensor || contact.fixtureB.isSensor) {
      String sensorName =
          (contact.fixtureA.userData ?? contact.fixtureB.userData)! as String;
      switch (sensorName) {
        case "down":
          this.contact++;
      }
    }
  }

  @override
  void endContact(Object other, Contact contact) {
    if (contact.fixtureA.isSensor || contact.fixtureB.isSensor) {
      String sensorName =
          (contact.fixtureA.userData ?? contact.fixtureB.userData)! as String;
      switch (sensorName) {
        case "down":
          this.contact--;
      }
    }
  }

  @override
  Body createBody() {
    BodyDef bd = BodyDef()
      ..position = Vector2(20, -20)
      ..type = BodyType.dynamic
      ..userData = this
      ..fixedRotation = true
      ..gravityScale = Vector2(0, 10)
      ..linearDamping = 2
      ..userData = this;
    Body body = world.createBody(bd);

    for (TmxObject object in this.tile.objectGroup!.objects.values) {
      FixtureDef fd = object.createFixture(
        zoom: _zoom,
        baseOffset: Vector2.zero(),
      )!
        ..density = 50;

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
