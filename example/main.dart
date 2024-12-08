// --- Example Components ---
// ignore_for_file: cascade_invocations

import 'package:mess/mess.dart';

class Position implements Component {
  Position(this.x, this.y);
  double x, y;
}

class Velocity implements Component {
  Velocity(this.dx, this.dy);
  double dx, dy;
}

// --- Example System ---
class MovementSystem implements System {
  @override
  void update(ComponentManager components) {
    final entities = components.getEntitiesWithComponent<Position>();
    for (final entity in entities) {
      final position = components.getComponent<Position>(entity);
      final velocity = components.getComponent<Velocity>(entity);

      if (position != null && velocity != null) {
        position.x += velocity.dx;
        position.y += velocity.dy;
      }
    }
  }
}

// --- Main Program ---
void main() {
  final world = World();

  // Add a movement system
  world.addSystem(MovementSystem());

  // Create entities
  final entity1 = world.entityManager.createEntity();
  final entity2 = world.entityManager.createEntity();

  // Add components to entities
  world.componentManager.addComponent(entity1, Position(0, 0));
  world.componentManager.addComponent(entity1, Velocity(1, 1));

  world.componentManager.addComponent(entity2, Position(5, 5));
  world.componentManager.addComponent(entity2, Velocity(-1, -1));

  // Update the ECS
  for (var i = 0; i < 5; i++) {
    world.update();

    // Print positions
    for (final entity in world.entityManager.entities) {
      final position = world.componentManager.getComponent<Position>(entity);
      if (position != null) {
        print('Entity $entity: Position(${position.x}, ${position.y})');
      }
    }
  }
}
