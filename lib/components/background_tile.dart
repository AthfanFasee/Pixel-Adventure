import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/painting.dart';

class BackgroundTile extends ParallaxComponent {
  final String color;
  BackgroundTile({this.color = 'Gray', position}) : super(position: position);

  @override
  FutureOr<void> onLoad() async {
    priority = -10;
    size = Vector2.all(64);
    parallax =
        await gameRef.loadParallax([ParallaxImageData('Background/$color.png')],
            // Give some velocity to make the bg scroll if needed!
            baseVelocity: Vector2.zero(),
            repeat: ImageRepeat.repeat,
            fill: LayerFill.none);
    return super.onLoad();
  }
}
