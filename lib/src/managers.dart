import 'dart:typed_data';

import 'component.dart';
import 'entity.dart';
import 'entity_event_listener.dart';

/// {@template component_pool}
/// ComponentPool: manages components of a specific type
/// {@endtemplate}
class ComponentPool<T extends Component> {
  /// {@macro component_pool}
  ComponentPool(int initialCapacity)
      : _dense = List<T?>.filled(initialCapacity, null, growable: true),
        _sparse = Uint32List(initialCapacity);

  /// Dense array of components
  final List<T?> _dense;

  /// Sparse array of component indices
  final Uint32List _sparse;

  /// Recycled indices
  final List<int> _recycled = <int>[];

  /// Get a component for an entity
  T? get(Entity entity) {
    assert(entity.id < _sparse.length, 'Entity ID out of bounds');
    final index = _sparse[entity.id];
    return index != 0 ? _dense[index - 1] : null;
  }

  /// Add a component to an entity
  void add(Entity entity, T component) {
    assert(entity.id < _sparse.length, 'Entity ID out of bounds');
    if (_sparse[entity.id] != 0) {
      throw StateError('Component already exists for entity: ${entity.id}');
    }

    if (_recycled.isNotEmpty) {
      final index = _recycled.removeLast();
      _dense[index] = component;
      _sparse[entity.id] = index + 1;
    } else {
      _dense.add(component);
      _sparse[entity.id] = _dense.length;
    }
  }

  /// Remove a component from an entity
  void remove(Entity entity) {
    assert(entity.id < _sparse.length, 'Entity ID out of bounds');
    final index = _sparse[entity.id];
    if (index == 0) return;

    _dense[index - 1] = null;
    _sparse[entity.id] = 0;
    _recycled.add(index - 1);
  }

  /// Get all components
  Iterable<Entity> entities() sync* {
    for (var i = 0; i < _dense.length; i++) {
      if (_dense[i] != null) {
        yield Entity(i);
      }
    }
  }

  /// Resize the sparse array if needed
  void resizeSparseIfNeeded(int newCapacity) {
    if (newCapacity <= _sparse.length) return;
    final newSparse = Uint32List(newCapacity)
      ..setRange(0, _sparse.length, _sparse)
      ..fillRange(_sparse.length, newCapacity, 0);
    _sparse.setAll(0, newSparse);
  }
}

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
  ComponentPool<T> getPool<T extends Component>() =>
      _pools.putIfAbsent(T, () => ComponentPool<T>(_initialCapacity))
          as ComponentPool<T>;

  /// Remove all components associated with an entity
  void removeAllComponents(Entity entity) {
    for (final pool in _pools.values) {
      pool.remove(entity);
    }
  }
}

/// {@template entity_manager}
/// /// EntityManager: manages entities
/// {@endtemplate}
class EntityManager {
  /// {@macro entity_manager}
  EntityManager({required int initialCapacity})
      : _generations = List<int>.filled(initialCapacity, 0, growable: true),
        _recycled = <int>[],
        _listeners = <EntityEventListener>[];

  final List<int> _generations;
  final List<int> _recycled;
  final List<EntityEventListener> _listeners;

  /// Create a new entity
  Entity createEntity() {
    late Entity entity;
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
  void addListener(EntityEventListener listener) {
    _listeners.add(listener);
  }

  /// Remove an event listener
  void validateEntity(Entity entity) {
    assert(entity.id < _generations.length && _generations[entity.id] > 0,
        'Invalid or dead entity: $entity');
  }
}
