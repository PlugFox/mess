/* import 'component.dart';
import 'pool.dart';
import 'entity.dart';
import 'world_event_listener.dart';

/// {@template component_manager}
/// ComponentManager: manages components of different types
/// {@endtemplate}
class ComponentManager {
  /// {@macro component_manager}
  ComponentManager({required int initialCapacity})
      : _initialCapacity = initialCapacity;

  /// Initial component capacity
  final int _initialCapacity;

  /// Map of components by type
  final Map<Type, ComponentPool<Component>> _pools =
      <Type, ComponentPool<Component>>{};

  /// Get or create a pool for a specific component type
  ComponentPool<T> getPool<T extends Component>() => _pools.putIfAbsent(
          T, () => ComponentPool<T>(initialCapacity: _initialCapacity))
      as ComponentPool<T>;

  /// Remove all components associated with an entity
  void removeAllComponents(Entity entity) {
    for (final pool in _pools.values) {
      pool.remove(entity);
    }
  }
}

/// {@template entity_manager}
/// EntityManager: manages entities
/// {@endtemplate}
class EntityManager {
  /// {@macro entity_manager}
  EntityManager({required int initialCapacity})
      : _generations = List<int>.filled(initialCapacity, 0, growable: true),
        _recycled = <int>[],
        _listeners = <WorldEventListener>[];

  final List<int> _generations;
  final List<int> _recycled;
  final List<WorldEventListener> _listeners;

  /// Create a new entity
  Entity createEntity() {
    Entity entity;
    if (_recycled.isNotEmpty) {
      final id = _recycled.removeLast();
      _generations[id]++;
      entity = Entity(id);
    } else {
      final id = _generations.length;
      _generations.add(1);
      entity = Entity(id);
    }
    for (final listener in _listeners) {
      listener.onEntityCreated(entity);
    }
    return entity;
  }

  /// Destroy an entity
  void destroyEntity(Entity entity, ComponentManager components) {
    assert(isAlive(entity), 'Attempting to destroy a non-existent entity');
    components.removeAllComponents(entity);
    _generations[entity.id] = 0;
    _recycled.add(entity.id);
    for (final listener in _listeners) {
      listener.onEntityDestroyed(entity);
    }
  }

  /// Check if an entity is alive
  bool isAlive(Entity entity) =>
      entity.id < _generations.length && _generations[entity.id] > 0;

  /// Add an event listener
  void addListener(WorldEventListener listener) {
    _listeners.add(listener);
  }

  /// Remove an event listener
  void validateEntity(Entity entity) {
    assert(entity.id < _generations.length && _generations[entity.id] > 0,
        'Invalid or dead entity: $entity');
  }
}
 */