import 'config.dart';
import 'managers.dart';
import 'system.dart';

/// {@template world}
/// World: manages entities, components, and systems
/// {@endtemplate}
class World {
  /// {@macro world}
  World(WorldConfig config)
      : entityManager =
            EntityManager(initialCapacity: config.initialEntityCapacity),
        componentManager =
            ComponentManager(initialCapacity: config.initialComponentCapacity),
        systems = <System>[];

  /// Entity manager
  final EntityManager entityManager;

  /// Component manager
  final ComponentManager componentManager;

  /// Systems
  final List<System> systems;

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
