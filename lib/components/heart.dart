import 'package:flame/components.dart';
import 'package:pixel_adventure/pixel_adventure.dart'; // If required, adjust the import path.

class Heart extends SpriteComponent with HasGameRef<PixelAdventure> {
  Heart({required Vector2 position, required Vector2 size}) {
    this.position = position;
    this.size = size;
  }

  @override
  Future<void> onLoad() async {
    final image = game.images.fromCache('Other/Heart.png');
    sprite = Sprite(image);
  }
}
