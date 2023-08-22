import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:pixel_adventure/components/background_tile.dart';
import 'package:pixel_adventure/components/checkpoint.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/fruit.dart';
import 'package:pixel_adventure/components/heart.dart';
import 'package:pixel_adventure/components/player.dart';
import 'package:pixel_adventure/components/saw.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class Level extends World with HasGameRef<PixelAdventure> {
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

    _addBackground();
    _spawningObjects();
    _addCollisions();

    // Make sure to call the onLoad method on the class we inherit from, at the end.
    return super.onLoad();
  }

  void _addBackground() {
    final backgroundLayer = level.tileMap.getLayer('Background');
    const tileSize = 64;

    final numOfTilesY = (game.size.y / tileSize).floor();
    final numOfTilesX = (game.size.x / tileSize).floor();

    if (backgroundLayer != null) {
      final backgroundColor =
          backgroundLayer.properties.getValue('BackgroundColor');
      for (double y = 0; y < numOfTilesY; y++) {
        for (double x = 0; x < numOfTilesX; x++) {
          final backgroundTile = BackgroundTile(
              color: backgroundColor ?? 'Gray',
              position: Vector2(x * tileSize, y * tileSize - tileSize));
          add(backgroundTile);
        }
      }
    }
  }

  void _spawningObjects() {
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
          case 'Fruit':
            final fruit = Fruit(
                fruit: spawnPoint.name,
                position: Vector2(spawnPoint.x, spawnPoint.y),
                size: Vector2(spawnPoint.width, spawnPoint.height));
            add(fruit);
            break;
          case 'Saw':
            final isVertical = spawnPoint.properties.getValue('isVerticle');
            final offNeg = spawnPoint.properties.getValue('offNeg');
            final offPos = spawnPoint.properties.getValue('offPos');
            final saw = Saw(
                isVertical: isVertical,
                offNeg: offNeg,
                offPos: offPos,
                position: Vector2(spawnPoint.x, spawnPoint.y),
                size: Vector2(spawnPoint.width, spawnPoint.height));
            add(saw);
            break;
          case 'Checkpoint':
            final checkpoint = Checkpoint(
                position: Vector2(spawnPoint.x, spawnPoint.y),
                size: Vector2(spawnPoint.width, spawnPoint.height));
            add(checkpoint);
            break;
          case 'Heart':
            final heart = Heart(
                position: Vector2(spawnPoint.x, spawnPoint.y),
                size: Vector2(40, 40));
            add(heart);
            break;
          default:
        }
      }
    }
  }

  void _addCollisions() {
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
  }
}
