import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'interfaces.dart';
import 'mask.dart';

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
  bool has<C extends Object>() => _mess.hasComponent<C>(this);

  @override
  List<Object> components() => _mess.getComponents(this);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Entity && identical(_mess, other._mess) && id == other.id;
}

// --- Pools implementations --- //

class _MessPool$MapImpl<C extends Object> implements IMessPool<C> {
  /// Create a new pool for components of a specific type.
  _MessPool$MapImpl() : _components = HashMap<int, C>();

  final Map<int, C> _components;

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
  factory PoolRegistry.custom(IMessPool<C> Function<C extends Object>() fn) =>
      PoolRegistry._(fn);

  /// Create a new [PoolRegistry] instance.
  PoolRegistry._(this._factoryByDefault)
      : _factories = <Type, IMessPool Function()>{};

  /// Get a HashMap pool factory for a specific component type.
  static IMessPool<C> Function<C extends Object>() hashMap() =>
      // ignore: unnecessary_lambdas
      <T extends Object>() => _MessPool$MapImpl<T>();

  /// Default pool factory for HashMap pools and method [register]
  final IMessPool<C> Function<C extends Object>() _factoryByDefault;

  /// Registered factories for specific component types.
  final Map<Type, IMessPool Function()> _factories;

  /// Register a new pool for a specific component type.
  void register<C extends Object>() => _factories[C] = _factoryByDefault<C>;

  /// Register a new pool for a specific component type with a custom factory.
  void registerFactory<C extends Object>(IMessPool<C> Function() factory) =>
      _factories[C] = factory;

  /// Build a list of pools for a [Mess] instance.
  List<IMessPool> build() =>
      _factories.values.map((f) => f()).toList(growable: false);

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

// --- Queries and Filters --- //

class _MessQuery implements IMessQuery {
  _MessQuery(this.components) : _entities = <_Entity>[];

  @override
  final Set<Type> components;

  /// Mutable list of entities with specified components.
  final List<_Entity> _entities;

  @override
  late final List<Entity> entities = UnmodifiableListView<Entity>(_entities);
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
  })  : _refs = const <_Entity>[],
        _entitySize = entitySize,
        _entities = Uint32List(math.max(entitiesCapacity, 64) * entitySize),
        _recycledEntities = Uint32List(math.max(recycledCapacity, 64)),
        poolsCount = pools.length,
        _poolsMap = HashMap<Type, IMessPool<Object>>.of({
          for (final pool in pools) pool.type: pool,
        }),
        _poolsList = List<IMessPool<Object>>.from(pools, growable: false),
        _queries = HashMap<Mask, _MessQuery>(),
        _types = HashMap<Type, int>.of({
          for (var i = 0; i < pools.length; i++) pools[i].type: i,
        }),
        _masks = HashMap<int, Mask>(),
        assert(
          pools.map((e) => e.type).toSet().length == pools.length,
          'Duplicate pool type',
        ),
        assert(
          entitySize > 1,
          'Entity size must be greater than 1 '
          'or you will not be able to add components',
        ) {
    _refs = List<_Entity>.generate(
      math.max(entitiesCapacity, 64),
      (i) => _Entity(i, this),
      growable: false,
    );
  }

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
  Uint32List _entities;

  /// List of entities in this manager.
  /// Allow to get the entity by its ID instead of creating a new instance.
  List<_Entity> _refs;

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
    assert(isAlive, 'Manager is disposed');
    final int id;
    if (_recycledEntitiesCount > 0) {
      // Reuse recycled entity
      id = _recycledEntities[--_recycledEntitiesCount];
    } else {
      // Add new entity
      if (_entitiesCount * _entitySize == _entities.length) {
        // Resize entities array
        final newSize = _entitiesCount << 1;
        _entities = _resizeUint32List(_entities, newSize * _entitySize);

        // Resize refs array
        final refs = _refs;
        _refs = List<_Entity>.filled(
          newSize,
          _Entity(0, this),
          growable: false,
        )..setRange(0, _entitiesCount, refs);
        for (var i = _entitiesCount; i < newSize; i++)
          _refs[i] = _Entity(i, this);
      }
      id = _entitiesCount++; // 0..n
    }
    _entities[_getEntityOffset(id)] = 1; // Entity exists with 0 components
    _masks[id] = const Mask.empty();
    //_trigger(ENTITY_CREATED, entity);
    return _refs[id];
  }

  @override
  List<Entity> entities() {
    /* var count = _entitiesCount - _recycledEntitiesCount;
    var id = 0;
    var offset = 0; */
    throw UnimplementedError();
  }

  @override
  void destroyEntity(Entity entity) {
    assert(isAlive, 'Manager is disposed');

    final id = entity.id;
    if (id < 0 || id >= _entitiesCount) return;
    final offset = _getEntityOffset(id);
    // If entity is already destroyed
    if (_entities[offset] == 0) return;

    // Remove all components from entity
    for (var i = 1; i < _entities[offset]; i++)
      _poolsList[_entities[offset + i]].remove(entity);

    _masks.remove(id); // Remove entity mask

    // Recycle entity
    _entities[offset] = 0; // Mark entity as destroyed
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
    assert(isAlive, 'Manager is disposed');

    final id = entity.id;
    if (id < 0 || id >= _entitiesCount) return false;
    return _entities[_getEntityOffset(id)] > 0;
  }

  // --- Components --- //

  /// The number of pools in this manager.
  final int poolsCount;

  /// Map of component types to their IDs.
  /// Allow to get the component index by its [Type].
  final Map<Type, int> _types;

  /// List of pools in this manager.
  /// Allows to retrieve the pool by index of the component type.
  final List<IMessPool> _poolsList;

  /// Map of component types to their pools.
  /// Allow to get the pool by component type.
  final Map<Type, IMessPool> _poolsMap;

  @override
  int componentsCount(Entity entity) {
    assert(isAlive, 'Manager is disposed');

    final id = entity.id;
    if (id < 0 || id >= _entitiesCount) {
      _throwAssertionError('Entity does not exist');
      return 0;
    }
    return math.max(0, _entities[_getEntityOffset(id)] - 1);
  }

  @override
  void upsertComponent<C extends Object>(Entity entity, C component) {
    assert(isAlive, 'Manager is disposed');

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
      _entities[offset + 1 + componentsCount] = _types[C]!; // Add component ID
    }

    // Add component to pool
    pool[entity] = component;
  }

  /// Remove a component from an entity in the current manager (world) by type.
  @override
  void removeComponent<C extends Object>(Entity entity) {
    assert(isAlive, 'Manager is disposed');

    final id = entity.id;

    if (C == Object)
      return _throwAssertionError('An implemented Component was expected');

    if (id < 0 || id >= _entitiesCount)
      return _throwAssertionError('Entity does not exist');

    final offset = _getEntityOffset(id); // Entity offset

    final pool = _poolsMap[C];
    if (pool == null || pool.remove(entity) == null) return;

    // Update mask
    _masks[id] = _masks[id]!.clearBit(_types[C]!);

    // Decrease components count
    final dataCount = _entities[offset] - 1;
    _entities[offset] = math.max(1, dataCount);
    final dataOffset = offset + 1;
    final typeId = _types[C];
    for (var i = 0; i <= dataCount; i++) {
      if (_entities[dataOffset + i] != typeId) continue; // Another component
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
    assert(isAlive, 'Manager is disposed');

    final pool = _poolsMap[C];
    if (pool == null) throw Exception('Component $C not registered');
    return pool[entity] as C;
  }

  @override
  bool hasComponent<C extends Object>(Entity entity) {
    assert(isAlive, 'Manager is disposed');

    final mask = _masks[entity.id];
    final index = _types[C];
    if (mask == null || index == null) return false;
    return mask.hasIndex(index);
  }

  @override
  List<Object> getComponents(Entity entity) {
    assert(isAlive, 'Manager is disposed');

    final id = entity.id;
    if (id < 0 || id >= _entitiesCount) return const <Object>[];
    final offset = _getEntityOffset(id);
    return List<Object>.generate(
      _entities[offset] - 1,
      (i) => _poolsList[_entities[offset + 1 + i]][entity],
      growable: false,
    );
  }

  // --- Systems --- //

  // --- Queries --- //

  /// Map of entity mask.
  /// key - entity ID, value - entity mask.
  /// Allow to check if entity has specified components.
  final Map<int, Mask> _masks;

  /// Map of queries by component mask.
  final Map<Mask, _MessQuery> _queries;

  @override
  IMessQuery createQuery(Iterable<Type> components) {
    assert(isAlive, 'Manager is disposed');

    final types = HashSet<Type>.of(components);
    if (types.isEmpty || types.length > _entitySize - 2)
      return _MessQuery(const <Type>{}); // Empty query

    // Calculate component mask
    final mask = Mask.calculate(types, _types);
    final exist = _queries[mask];
    if (exist != null) return exist; // Return existing query

    final query = _queries[mask] = _MessQuery(types);

    // Find entities with specified components

    // TODO(plugfox): Implement finding entities with specified components,
    // try to retrieve entities from other queries with similar components.
    // Mike Matiunin <plugfox@gmail.com>, 02 January 2025

    /* final componentsCount = types.length;
    for (var i = 0; i < _entitiesCount; i++) {
      final offset = _getEntityOffset(i);
      final componentsCount = _entities[offset] - 1;
      if (componentsCount < componentsCount) continue; // Not enough components
      var found = true;
      for (var j = 0; j < componentsCount; j++) {
        final poolId = _entities[offset + 1 + j];
        if (!types.contains(_pools[poolId].type)) {
          found = false;
          break;
        }
      }
      if (found) query._entities.add(_Entity(i, this));
    } */

    return query;
  }

  // --- Triggers --- //

  // --- Dispose --- //

  @override
  bool get isAlive => _isAlive;

  @override
  bool get isDisposed => _isDisposed;

  bool _isDisposed = false, _isAlive = true;

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _isAlive = false;
    _entities = _recycledEntities = Uint32List(0);
    _entitiesCount = _recycledEntitiesCount = 0;
    _refs = const <_Entity>[];
    _masks.clear();
    _queries.clear();
    const fakePool = _MessPool$Disposed();
    for (var i = 0; i < _poolsList.length; i++) {
      _poolsMap[_poolsList[i].type] = fakePool;
      _poolsList[i] = fakePool;
    }
  }
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
