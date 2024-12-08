import 'managers.dart';
import 'system.dart';

class World {
  final EntityManager entityManager = EntityManager();
  final ComponentManager componentManager = ComponentManager();
  final List<System> systems = [];

  // Add a system
  void addSystem(System system) {
    systems.add(system);
  }

  // Update all systems
  void update() {
    for (final system in systems) {
      system.update(componentManager);
    }
  }
}
