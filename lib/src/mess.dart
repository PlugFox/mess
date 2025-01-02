import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'interfaces.dart';

/// {@template mess_pool}
/// Pool for components of a specific type.
/// {@endtemplate}
class MessPool {
  /// Create a new [MessPool] instance
  ///
  /// {@macro mess_pool}
  MessPool({
    required this.id,
    required this.type,
  });

  /// The identifier of this pool.
  final int id;

  /// Type of components in this pool.
  final Type type;
}

/// {@macro mess}
class Mess implements IMess {
  /// Create a new [Mess] instance
  ///
  /// {@macro mess}
  Mess(
    Set<Type> components, {
    int entitySize = 8,
    int entitiesCapacity = 512,
    int recycledCapacity = 512,
  })  : _entitySize = entitySize,
        _entities = Uint16List(math.max(entitiesCapacity, 64) * entitySize),
        _recycledEntities = Uint32List(math.max(recycledCapacity, 64)),
        poolsCount = components.length,
        _pools = components.indexed
            .map((e) => MessPool(id: e.$1, type: e.$2))
            .toList(growable: false) {
    for (final pool in _pools) _poolsMap[pool.type] = pool;
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
    return Entity(id);
  }

  @override
  void destroyEntity(Entity entity) {
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
    final id = entity.id;
    if (id < 0 || id >= _entitiesCount) return false;
    return _entities[_getEntityOffset(id)] > 0;
  }

  // --- Components --- //

  /// The number of pools in this manager.
  final int poolsCount;

  final List<MessPool> _pools;

  final Map<Type, MessPool> _poolsMap = <Type, MessPool>{};

  @override
  int componentsCount(Entity entity) {
    final id = entity.id;
    if (id < 0 || id >= _entitiesCount) return 0;
    return math.max(0, _entities[_getEntityOffset(id)] - 1);
  }

  @override
  void setComponent<C extends Object>(Entity entity, C component) {
    final id = entity.id;
    if (C == Object)
      return _throwAssertionError('An implemented Component was expected');
    if (id < 0 || id >= _entitiesCount)
      return _throwAssertionError('Entity does not exist');
    final offset = _getEntityOffset(id); // Entity offset
    final componentsCount = _entities[offset]; // Number of current components
    if (componentsCount < 1)
      return _throwAssertionError('Entity does not exist');
    if (componentsCount + 1 >= _entitySize)
      return _throwAssertionError('No more space for components');
    _entities[offset] = componentsCount + 1; // Increase components count
    //_entities[offset + 1 + componentsCount] = component;

    // TODO(plugfox): Implement me
    // Mike Matiunin <plugfox@gmail.com>, 23 December 2024
  }

  /* @override
  void setComponents(Entity entity, Map<Type, Object> components) {
    final id = entity.id;
    if (id < 0 || id >= _entitiesCount) return;
    final offset = _getEntityOffset(id);
    final componentsCount = _entities[offset];
    if (componentsCount + components.length >= _entitySize) return;
    _entities[offset] = componentsCount + components.length;

    // TODO(plugfox): Implement me
    // Mike Matiunin <plugfox@gmail.com>, 23 December 2024
  } */

  @override
  List<Object> getComponents(Entity entity) {
    final id = entity.id;
    if (id < 0 || id >= _entitiesCount) return const <Object>[];
    final offset = _getEntityOffset(id);
    return List<Object>.generate(
      _entities[offset],
      (i) => _entities[offset + 1 + i],
      growable: false,
    );
  }

  // --- Systems --- //

  // --- Triggers --- //

  // --- Dispose --- //

  @override
  void dispose() {
    _entities = Uint16List(0);
    _recycledEntities = Uint32List(0);
    final emptyPool = MessPool(id: 0, type: Object);
    for (var i = 0; i < _pools.length; i++) {
      _poolsMap[_pools[i].type] = emptyPool;
      _pools[i] = emptyPool;
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
