// ignore_for_file: cascade_invocations, avoid_print

import 'package:mess/mess.dart';

// --- Components --- //

/// Position component
class Position implements Component {
  Position(this.x, this.y);

  /// Position coordinates
  double x, y;
}

/// Velocity component
class Velocity implements Component {
  Velocity(this.dx, this.dy);

  /// Velocity vector
  double dx, dy;
}

// --- Example System --- //

class MovementSystem implements System {
  @override
  void update(ComponentManager components) {
    final positionPool = components.getPool<Position>();
    final velocityPool = components.getPool<Velocity>();

    for (final entity in positionPool.entities()) {
      final position = positionPool.get(entity);
      final velocity = velocityPool.get(entity);

      if (position != null && velocity != null) {
        position.x += velocity.dx;
        position.y += velocity.dy;
      }
    }
  }
}

// --- Main program --- //

void main() {
  final world = World(const WorldConfig());

  // Add a movement system
  world.addSystem(MovementSystem());

  // Create entities
  final entity1 = world.entityManager.createEntity();
  final entity2 = world.entityManager.createEntity();

  // Add components to entities
  world.componentManager.getPool<Position>().add(entity1, Position(0, 0));
  world.componentManager.getPool<Velocity>().add(entity1, Velocity(1, 1));

  world.componentManager.getPool<Position>().add(entity2, Position(5, 5));
  world.componentManager.getPool<Velocity>().add(entity2, Velocity(-1, -1));

  // Update the ECS
  for (var i = 0; i < 5; i++) {
    world.update();

    // Print positions
    final entities = world.componentManager.getPool<Position>().entities();
    for (final entity in entities) {
      final position = world.componentManager.getPool<Position>().get(entity);
      if (position != null) {
        print('Entity $entity: Position(${position.x}, ${position.y})');
      }
    }
  }
}
