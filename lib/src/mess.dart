import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'interfaces.dart';

// --- Entity --- //

@immutable
final class _Entity implements Entity {
  const _Entity(this.id, this._mess);

  @override
  final int id;

  final IMess _mess;

  @override
  bool isAlive() => _mess.hasEntity(this);

  @override
  int get count => _mess.componentsCount(this);

  @override
  void upsert<C extends Object>(C component) =>
      _mess.upsertComponent(this, component);

  @override
  void remove<C extends Object>() => _mess.removeComponent<C>(this);

  @override
  C get<C extends Object>() => _mess.getComponent<C>(this);

  @override
  List<Object> components() => _mess.getComponents(this);
}

// --- Pools implementations --- //

class _MessPool$MapImpl<C extends Object> implements IMessPool<C> {
  /// Create a new pool for components of a specific type.
  _MessPool$MapImpl({
    required this.id,
  }) : _components = HashMap<int, C>();

  final Map<int, C> _components;

  /// Pool ID.
  @override
  final int id;

  /// Type of components in this pool.
  @override
  Type get type => C;

  /* final List<C> _denseItems;
  final List<int> _sparseItems;
  final int _denseItemsCount;
  final List<int> _recycledItems;
  final int _recycledItemsCount; */

  @override
  bool contains(Entity entity) => _components.containsKey(entity.id);

  @override
  C? remove(Entity entity) => _components.remove(entity.id);

  @override
  C operator [](Entity entity) =>
      _components[entity.id] ?? (throw Exception('Component not found'));

  @override
  void operator []=(Entity entity, C component) =>
      _components[entity.id] = component;

  // Optionally, implement the copy method if needed in the future.
  // void copy(int from, int to) {
  //   if (!_components.containsKey(from)) {
  //     throw Exception('Source entity $from does not exist in pool.');
  //   }
  //   _components[to] = _components[from]!;
  // }
}

class _MessPool$Disposed implements IMessPool<Object> {
  const _MessPool$Disposed();

  @override
  int get id => -1;

  @override
  Type get type => Null;

  static Never _throwDisposedError() => throw StateError('Pool is disposed');

  @override
  bool contains(Entity entity) => _throwDisposedError();

  @override
  void remove(Entity entity) => _throwDisposedError();

  @override
  Object operator [](Entity entity) => _throwDisposedError();

  @override
  void operator []=(Entity entity, Object component) => _throwDisposedError();
}

// --- Pools registry / helper --- //

/// A registry helper to create pools for a [Mess] instance.
final class PoolRegistry {
  /// Create a new [PoolRegistry] instance with a default HashMap pool factory.
  factory PoolRegistry() => PoolRegistry._(PoolRegistry.hashMap());

  /// Create a new [PoolRegistry] instance with a specified custom pool factory.
  factory PoolRegistry.custom(
          IMessPool<C> Function<C extends Object>(int id) builder) =>
      PoolRegistry._(builder);

  /// Create a new [PoolRegistry] instance.
  PoolRegistry._(this._factoryByDefault)
      : _factories = <Type, IMessPool Function(int id)>{};

  /// Get a HashMap pool factory for a specific component type.
  static IMessPool<C> Function<C extends Object>(int id) hashMap() =>
      <T extends Object>(id) => _MessPool$MapImpl<T>(id: id);

  /// Default pool factory for HashMap pools and method [register]
  final IMessPool<C> Function<C extends Object>(int id) _factoryByDefault;

  /// Registered factories for specific component types.
  final Map<Type, IMessPool Function(int id)> _factories;

  /// Register a new pool for a specific component type.
  void register<C extends Object>() => _factories[C] = _factoryByDefault<C>;

  /// Register a new pool for a specific component type with a custom factory.
  void registerFactory<C extends Object>(
          IMessPool<C> Function(int id) factory) =>
      _factories[C] = factory;

  /// Build a list of pools for a [Mess] instance.
  List<IMessPool> build() => List<IMessPool>.generate(
        _factories.length,
        (i) => _factories.values.elementAt(i)(i),
        growable: false,
      );

  /// Create a new [Mess] instance with registered pools.
  Mess createMess({
    int entitySize = 8,
    int entitiesCapacity = 512,
    int recycledCapacity = 512,
  }) =>
      Mess.pools(
        build(),
        entitySize: entitySize,
        entitiesCapacity: entitiesCapacity,
        recycledCapacity: recycledCapacity,
      );

  /// Clear all registered factories.
  void clear() => _factories.clear();
}

// --- MESS / Entity Manager --- //

/// {@macro mess}
class Mess implements IMess {
  /// Create a new [Mess] instance from ordered [IMessPool] pools list.
  /// Each pool must have a unique ID and type of components.
  /// Id of each pool must be in range 0..n.
  ///
  /// {@macro mess}
  Mess.pools(
    List<IMessPool<Object>> pools, {
    int entitySize = 8,
    int entitiesCapacity = 512,
    int recycledCapacity = 512,
  })  : _entitySize = entitySize,
        _entities = Uint16List(math.max(entitiesCapacity, 64) * entitySize),
        _recycledEntities = Uint32List(math.max(recycledCapacity, 64)),
        poolsCount = pools.length,
        _poolsMap = HashMap<Type, IMessPool<Object>>.of({
          for (final pool in pools) pool.type: pool,
        }),
        _pools = List<IMessPool<Object>>.from(pools, growable: false),
        assert(() {
          final ids = <int>[];
          for (final pool in pools) ids.add(pool.id);
          if (ids.toSet().length != pools.length) return false;
          for (var i = 0; i < pools.length; i++) if (ids[i] != i) return false;
          return true;
        }(), 'Invalid pool IDs'),
        assert(() {
          final types = <Type>{for (final pool in pools) pool.type};
          return types.length == pools.length;
        }(), 'Duplicate pool types');

  // --- Entities --- //

  /// The size of each entity.
  /// This is the max number of components an entity can have + 1.
  final int _entitySize;

  /// The next identifier for an [Entity]
  /// and total number of entities in this manager.
  int _entitiesCount = 0;

  /// All entities in this manager.
  /// First byte is a flag for entity existence and also size of entity.
  /// Next bytes are components.
  ///
  /// For example:
  /// 0 - entity does not exist
  /// 1 - entity exists
  /// 2 - entity exists and has one component
  /// 3 - entity exists and has two components
  ///
  /// Use [_getEntityOffset] to get the offset of an entity.
  Uint16List _entities;

  /// Recycled entities in this manager.
  int _recycledEntitiesCount = 0;

  /// Recycled entities in this manager.
  Uint32List _recycledEntities;

  @override
  int get capacity => _entities.length ~/ _entitySize;

  @override
  int get entitiesCount => _entitiesCount - _recycledEntitiesCount;

  @override
  int get entitySize => _entitySize;

  int _getEntityOffset(int id) => id * _entitySize;

  @override
  Entity createEntity() {
    assert(isDisposed, 'Manager is disposed');

    final int id;
    if (_recycledEntitiesCount > 0) {
      // Reuse recycled entity
      id = _recycledEntities[--_recycledEntitiesCount];
    } else {
      // Add new entity
      if (_entitiesCount * _entitySize == _entities.length) {
        // Resize entities array
        final newSize = _entitiesCount << 1;
        _entities = _resizeUint16List(_entities, newSize * _entitySize);
      }
      id = _entitiesCount++; // 0..n
    }
    _entities[_getEntityOffset(id)] = 1; // Entity exists with 0 components
    //_trigger(ENTITY_CREATED, entity);
    return _Entity(id, this);
  }

  @override
  void destroyEntity(Entity entity) {
    assert(isDisposed, 'Manager is disposed');

    final id = entity.id;
    if (id < 0 || id >= _entitiesCount) return;
    final offset = _getEntityOffset(id);
    // If entity is already destroyed
    if (_entities[offset] == 0) return;
    // Recycle entity
    _entities[offset] = 0; // Entity does not exist
    if (_recycledEntitiesCount == _recycledEntities.length) {
      // Resize recycled entities array
      final newSize = _recycledEntitiesCount << 1;
      _recycledEntities = _resizeUint32List(_recycledEntities, newSize);
    }
    _recycledEntities[_recycledEntitiesCount++] = id;
    //_trigger(ENTITY_DESTROYED, entity);
  }

  @override
  bool hasEntity(Entity entity) {
    assert(isDisposed, 'Manager is disposed');

    final id = entity.id;
    if (id < 0 || id >= _entitiesCount) return false;
    return _entities[_getEntityOffset(id)] > 0;
  }

  // --- Components --- //

  /// The number of pools in this manager.
  final int poolsCount;

  final List<IMessPool> _pools;

  final Map<Type, IMessPool> _poolsMap;

  @override
  int componentsCount(Entity entity) {
    assert(isDisposed, 'Manager is disposed');

    final id = entity.id;
    if (id < 0 || id >= _entitiesCount) {
      _throwAssertionError('Entity does not exist');
      return 0;
    }
    return math.max(0, _entities[_getEntityOffset(id)] - 1);
  }

  @override
  void upsertComponent<C extends Object>(Entity entity, C component) {
    assert(isDisposed, 'Manager is disposed');

    final id = entity.id;

    if (C == Object)
      return _throwAssertionError('An implemented Component was expected');

    if (id < 0 || id >= _entitiesCount)
      return _throwAssertionError('Entity does not exist');

    final offset = _getEntityOffset(id); // Entity offset
    final componentsCount = _entities[offset]; // Number of current components
    if (componentsCount < 1)
      return _throwAssertionError('Entity does not exist');

    final pool = _poolsMap[C];
    if (pool == null)
      return _throwAssertionError('Component $C not registered');

    // Check if component already exists in entity
    if (!pool.contains(entity)) {
      if (componentsCount + 1 >= _entitySize)
        return _throwAssertionError('No more space for components');
      _entities[offset] = componentsCount + 1; // Increase components count
      _entities[offset + 1 + componentsCount] = pool.id; // Add component ID
    }

    // Add component to pool
    pool[entity] = component;
  }

  /// Remove a component from an entity in the current manager (world) by type.
  @override
  void removeComponent<C extends Object>(Entity entity) {
    assert(isDisposed, 'Manager is disposed');

    final id = entity.id;

    if (C == Object)
      return _throwAssertionError('An implemented Component was expected');

    if (id < 0 || id >= _entitiesCount)
      return _throwAssertionError('Entity does not exist');

    final offset = _getEntityOffset(id); // Entity offset

    final pool = _poolsMap[C];
    if (pool == null || pool.remove(entity) == null) return;

    // Decrease components count
    final dataCount = _entities[offset] - 1;
    _entities[offset] = math.max(1, dataCount);
    final dataOffset = offset + 1;
    final poolId = pool.id;
    for (var i = 0; i <= dataCount; i++) {
      if (_entities[dataOffset + i] != poolId) continue; // Another component
      // Component found
      if (i == dataCount) return; // Last component - do nothing
      // Move last component to the removed component position and fill the gap
      _entities[dataOffset + i] = _entities[dataOffset + dataCount];
      return;
    }
    _throwAssertionError('Component $C not found');
  }

  @override
  C getComponent<C extends Object>(Entity entity) {
    assert(isDisposed, 'Manager is disposed');

    final pool = _poolsMap[C];
    if (pool == null) throw Exception('Component $C not registered');
    return pool[entity] as C;
  }

  @override
  List<Object> getComponents(Entity entity) {
    assert(isDisposed, 'Manager is disposed');

    final id = entity.id;
    if (id < 0 || id >= _entitiesCount) return const <Object>[];
    final offset = _getEntityOffset(id);
    return List<Object>.generate(
      _entities[offset],
      (i) => _pools[_entities[offset + 1 + i]][entity],
      growable: false,
    );
  }

  // --- Systems --- //

  // --- Queries --- //

  // --- Triggers --- //

  // --- Dispose --- //

  @override
  bool get isDisposed => _isDisposed;
  bool _isDisposed = false;

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _entities = Uint16List(0);
    _entitiesCount = 0;
    _recycledEntities = Uint32List(0);
    _recycledEntitiesCount = 0;
    const fakePool = _MessPool$Disposed();
    for (var i = 0; i < _pools.length; i++) {
      _poolsMap[_pools[i].type] = fakePool;
      _pools[i] = fakePool;
    }
  }
}

Uint16List _resizeUint16List(Uint16List array, int newCapacity) {
  assert(
    newCapacity > array.length,
    'New capacity must be greater than current capacity',
  );
  final newEntities = Uint16List(newCapacity)..setAll(0, array);
  return newEntities;
}

Uint32List _resizeUint32List(Uint32List array, int newCapacity) {
  assert(
    newCapacity > array.length,
    'New capacity must be greater than current capacity',
  );
  final newEntities = Uint32List(newCapacity)..setAll(0, array);
  return newEntities;
}

/// A helper function to throw a debug error.
void _throwAssertionError(String message) {
  assert(false, message);
}
