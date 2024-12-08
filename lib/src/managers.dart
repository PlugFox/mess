import 'component.dart';
import 'entity.dart';

/// ComponentManager: manages components of different types
class ComponentManager {
  final Map<Type, Map<Entity, Component>> _componentsByType = {};

  /// Add a component to an entity
  void addComponent<T extends Component>(Entity entity, T component) {
    final components = _componentsByType.putIfAbsent(T, () => {});
    components[entity] = component;
  }

  /// Get a component of a specific type for an entity
  T? getComponent<T extends Component>(Entity entity) {
    final components = _componentsByType[T];
    return components?[entity] as T?;
  }

  /// Remove a component from an entity
  void removeComponent<T extends Component>(Entity entity) {
    final components = _componentsByType[T];
    components?.remove(entity);
  }

  /// Get all entities with a specific component type
  Iterable<Entity> getEntitiesWithComponent<T extends Component>() {
    final components = _componentsByType[T];
    return components?.keys ?? const Iterable.empty();
  }
}

/// EntityManager: manages entities
class EntityManager {
  int _nextId = 0;
  final Set<Entity> _entities = {};

  /// Create a new entity
  Entity createEntity() {
    final entity = Entity(_nextId++);
    _entities.add(entity);
    return entity;
  }

  /// Destroy an entity
  void destroyEntity(Entity entity, ComponentManager components) {
    _entities.remove(entity);
    // Remove all components associated with the entity
    for (final type in components._componentsByType.keys) {
      components._componentsByType[type]?.remove(entity);
    }
  }

  /// Get all entities
  Iterable<Entity> get entities => _entities;
}
