import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/player.dart';

class Level extends World {
  final String levelName;
  final Player player;
  Level({required this.levelName, required this.player});
  late TiledComponent level;
  List<CollisionBlock> collisionBlocks = [];

  // This will run when the level is being loaded.
  // Add futureOr if the return value could be synchronous (immediate) or asynchronous (future).
  @override
  FutureOr<void> onLoad() async {
    // Load the Tiled map named 'level-01.tmx' with each tile size being 16x16 units.
    // The Vector2.all(16) means that both width and height of each tile is set to 16 units.
    level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));
    // Add the loaded level to the game's components to be rendered and updated
    add(level);
    // getLayer is a method that can fetch a layer of any type from the tile map.
    // <ObjectGroup> is a generic type argument. By using this, you're specifically telling the getLayer method that you expect it to return a layer that contains objects (like spawn points) and not just tiles.
    final spawnPointLayer = level.tileMap.getLayer<ObjectGroup>('Spawnpoints');

    if (spawnPointLayer != null) {
      for (final spawnPoint in spawnPointLayer.objects) {
        switch (spawnPoint.class_) {
          case 'Player':
            // Add player to specific spawn location.
            player.position = Vector2(spawnPoint.x, spawnPoint.y);
            add(player);
            break;
          default:
        }
      }
    }

    final collisionsLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');

    if (collisionsLayer != null) {
      for (final collison in collisionsLayer.objects) {
        switch (collison.class_) {
          case 'Platform':
            final platform = CollisionBlock(
                position: Vector2(collison.x, collison.y),
                size: Vector2(collison.width, collison.height),
                isPlatform: true);
            collisionBlocks.add(platform);
            // Only if we add this, it will be visible in the game.
            add(platform);
            break;
          default:
            final block = CollisionBlock(
              position: Vector2(collison.x, collison.y),
              size: Vector2(collison.width, collison.height),
            );
            collisionBlocks.add(block);
            add(block);
        }
      }
    }
    player.collisionBlocks = collisionBlocks;
    // Make sure to call the onLoad method on the class we inherit from, at the end.
    return super.onLoad();
  }
}
