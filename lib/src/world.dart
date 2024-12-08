import 'managers.dart';
import 'system.dart';

/// World
class World {
  /// Entity manager
  final EntityManager entityManager = EntityManager();

  /// Component manager
  final ComponentManager componentManager = ComponentManager();

  /// Systems
  final List<System> systems = [];

  /// Add a system
  void addSystem(System system) {
    systems.add(system);
  }

  /// Update all systems
  void update() {
    for (final system in systems) {
      system.update(componentManager);
    }
  }
}
