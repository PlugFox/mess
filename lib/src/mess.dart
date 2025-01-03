import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'interfaces.dart';
import 'mask.dart';

// --- Pools implementations --- //

class _MessPool$MapImpl<C extends Object> implements IMessPool<C> {
  /// Create a new pool for components of a specific type.
  _MessPool$MapImpl() : _components = HashMap<int, C>();

  /// Type of components in this pool.
  @override
  Type get type => C;

  final Map<int, C> _components;

  // TODO(plugfox): Create a new implementation with dense and sparse arrays
  // instead of HashMap for better performance and memory usage.
  // Mike Matiunin <plugfox@gmail.com>, 03 January 2025

  /* final List<C> _denseItems;
  final List<int> _sparseItems;
  final int _denseItemsCount;
  final List<int> _recycledItems;
  final int _recycledItemsCount; */

  @override
  bool contains(int entity) => _components.containsKey(entity);

  @override
  C? remove(int entity) => _components.remove(entity);

  @override
  C operator [](int entity) =>
      _components[entity] ?? (throw Exception('Component not found'));

  @override
  void operator []=(int entity, C component) => _components[entity] = component;

  // Optionally, implement the copy method if needed in the future.
  // void copy(int from, int to) {
  //   if (!_components.containsKey(from)) {
  //     throw Exception('Source entity $from does not exist in pool.');
  //   }
  //   _components[to] = _components[from]!;
  // }
}

class _MessPool$ListImpl<C extends Object> implements IMessPool<C> {
  /// Create a new pool for components of a specific type.
  _MessPool$ListImpl()
      : _components = List<C?>.filled(512, null, growable: false);

  /// Type of components in this pool.
  @override
  Type get type => C;

  List<C?> _components;

  @override
  bool contains(int entity) {
    if (entity < 0 || entity >= _components.length) return false;
    return _components[entity] != null;
  }

  @override
  C? remove(int entity) {
    if (entity < 0 || entity >= _components.length) return null;
    final component = _components[entity];
    _components[entity] = null;
    return component;
  }

  @override
  C operator [](int entity) {
    if (entity < 0 || entity >= _components.length)
      throw Exception('Component not found');
    return _components[entity] ?? (throw Exception('Component not found'));
  }

  @override
  void operator []=(int entity, C component) {
    if (entity >= _components.length) {
      final newSize = entity << 1;
      _components = List<C?>.filled(newSize, null, growable: false)
        ..setAll(0, _components);
      //_components.length = newSize;
    }
    _components[entity] = component;
  }
}

class _MessPool$Disposed implements IMessPool<Object> {
  const _MessPool$Disposed();

  @override
  Type get type => Null;

  static Never _throwDisposedError() => throw StateError('Pool is disposed');

  @override
  bool contains(int entity) => _throwDisposedError();

  @override
  void remove(int entity) => _throwDisposedError();

  @override
  Object operator [](int entity) => _throwDisposedError();

  @override
  void operator []=(int entity, Object component) => _throwDisposedError();
}

// --- Pools registry / helper --- //

/// A registry helper to create pools for a [Mess] instance.
final class PoolRegistry {
  /// Create a new [PoolRegistry] instance with a default HashMap pool factory.
  factory PoolRegistry() => PoolRegistry._(PoolRegistry.list());

  /// Create a new [PoolRegistry] instance with a specified custom pool factory.
  factory PoolRegistry.custom(IMessPool<C> Function<C extends Object>() fn) =>
      PoolRegistry._(fn);

  /// Create a new [PoolRegistry] instance.
  PoolRegistry._(this._factoryByDefault)
      : _factories = <Type, IMessPool Function()>{};

  /// Get a HashMap pool factory for a specific component type.
  static IMessPool<C> Function<C extends Object>() map() =>
      // ignore: unnecessary_lambdas
      <T extends Object>() => _MessPool$MapImpl<T>();

  /// Get a HashMap pool factory for a specific component type.
  static IMessPool<C> Function<C extends Object>() list() =>
      // ignore: unnecessary_lambdas
      <T extends Object>() => _MessPool$ListImpl<T>();

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
  _MessQuery(this.components) : _entities = <int>[];

  @override
  final Set<Type> components;

  // TODO(plugfox): Instead of List use a custom Uint32List and
  // and instead of View use a custom buffer from Uint32List (0..size)
  // Mike Matiunin <plugfox@gmail.com>, 03 January 2025

  /// Mutable list of entities with specified components.
  final List<int> _entities;

  @override
  late final List<int> entities = UnmodifiableListView<int>(_entities);
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
        _masks = Uint64List(math.max(entitiesCapacity, 64)),
        assert(
          entitiesCapacity > 63 && recycledCapacity > 63,
          'Capacity must be 64 or greater',
        ),
        assert(
          pools.map((e) => e.type).toSet().length == pools.length,
          'Duplicate pool type found',
        ),
        assert(
          entitySize > 1,
          'Entity size must be greater than 1 '
          'or you will not be able to add components',
        ),
        assert(
          entitySize <= 65,
          'Entity size must be less than 65 '
          'or you will get an mask overflow',
        );

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
  //List<_Entity> _refs;

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
  int createEntity() {
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

        // Resize masks array
        _masks = _resizeUint64List(_masks, newSize);

        // Resize refs array
        /* final refs = _refs;
        _refs = List<_Entity>.filled(
          newSize,
          _Entity(0, this),
          growable: false,
        )..setRange(0, _entitiesCount, refs);
        for (var i = _entitiesCount; i < newSize; i++)
          _refs[i] = _Entity(i, this); // Fill the rest with new entities
         */
      }
      id = _entitiesCount++; // 0..n
    }
    _entities[_getEntityOffset(id)] = 1; // Entity exists with 0 components
    _masks[id] = const Mask.empty();
    //_trigger(ENTITY_CREATED, entity);
    return id;
  }

  @override
  List<int> entities() {
    final result = Uint32List(_entitiesCount - _recycledEntitiesCount);
    var pos = 0;
    var offset = 0;
    final list = _entities;
    for (var i = 0, iMax = _entitiesCount;
        i < iMax;
        i++, offset += _entitySize) {
      if (list[offset] != 0) result[pos++] = i; // Add entity ID
      //result[pos++] = _Entity(i, this); // _refs[i];
    }
    return result;
  }

  @override
  void destroyEntity(int id) {
    assert(isAlive, 'Manager is disposed');

    if (id < 0 || id >= _entitiesCount) return;
    final offset = _getEntityOffset(id);
    // If entity is already destroyed
    if (_entities[offset] == 0) return;

    // Remove all components from entity
    for (var i = 1; i < _entities[offset]; i++)
      _poolsList[_entities[offset + i]].remove(id);

    _masks[id] = const Mask.empty(); // Clear entity mask

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
  bool hasEntity(int id) {
    assert(isAlive, 'Manager is disposed');

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
  int componentsCount(int id) {
    assert(isAlive, 'Manager is disposed');

    if (id < 0 || id >= _entitiesCount) {
      _throwAssertionError('Entity does not exist');
      return 0;
    }
    return math.max(0, _entities[_getEntityOffset(id)] - 1);
  }

  @override
  void upsertComponent<C extends Object>(int id, C component) {
    assert(isAlive, 'Manager is disposed');

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
    if (!pool.contains(id)) {
      if (componentsCount + 1 >= _entitySize)
        return _throwAssertionError('No more space for components');
      _entities[offset] = componentsCount + 1; // Increase components count
      _entities[offset + 1 + componentsCount] = _types[C]!; // Add component ID
    }

    // Add component to pool
    pool[id] = component;
  }

  /// Remove a component from an entity in the current manager (world) by type.
  @override
  void removeComponent<C extends Object>(int id) {
    assert(isAlive, 'Manager is disposed');

    if (C == Object)
      return _throwAssertionError('An implemented Component was expected');

    if (id < 0 || id >= _entitiesCount)
      return _throwAssertionError('Entity does not exist');

    final offset = _getEntityOffset(id); // Entity offset

    final pool = _poolsMap[C];
    if (pool == null || pool.remove(id) == null) return;

    // Update mask
    _masks[id] = Mask(_masks[id]).clearBit(_types[C]!);

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
  C getComponent<C extends Object>(int id) {
    assert(isAlive, 'Manager is disposed');

    final pool = _poolsMap[C];
    if (pool == null) throw Exception('Component $C not registered');
    return pool[id] as C;
  }

  @override
  bool hasComponent<C extends Object>(int id) {
    assert(isAlive, 'Manager is disposed');

    if (id < 0 || id >= _entitiesCount) return false;

    final mask = Mask(_masks[id]);
    final index = _types[C];
    if (index == null) return false;
    return mask.hasIndex(index);
  }

  @override
  List<Object> getComponents(int id) {
    assert(isAlive, 'Manager is disposed');

    if (id < 0 || id >= _entitiesCount) return const <Object>[];
    final offset = _getEntityOffset(id);
    return List<Object>.generate(
      _entities[offset] - 1,
      (i) => _poolsList[_entities[offset + 1 + i]][id],
      growable: false,
    );
  }

  // --- Systems --- //

  // --- Queries --- //

  /// Map of entity mask.
  /// Allow to check if entity has specified components.
  Uint64List _masks;

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
    //_refs = const <_Entity>[];
    _masks = Uint64List(0);
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

Uint64List _resizeUint64List(Uint64List array, int newCapacity) {
  assert(
    newCapacity > array.length,
    'New capacity must be greater than current capacity',
  );
  final newEntities = Uint64List(newCapacity)..setAll(0, array);
  return newEntities;
}

/// A helper function to throw a debug error.
void _throwAssertionError(String message) {
  assert(false, message);
}
