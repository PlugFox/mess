// ignore_for_file: prefer_final_fields

import 'dart:math' as math;
import 'dart:typed_data';

import 'interfaces.dart';

// --- Entity offsets --- //

/// {@macro mess}
class Mess implements IMess {
  /// Create a new [Mess] instance
  ///
  /// {@macro mess}
  Mess({
    int entitySize = 8,
    int entitiesCapacity = 512,
    int recycledCapacity = 512,
  })  : _entitySize = entitySize,
        _entities = Uint16List(math.max(entitiesCapacity, 64) * entitySize),
        _recycledEntities = Uint32List(math.max(recycledCapacity, 64));

  // --- Entities --- //

  /// The size of each entity.
  int _entitySize;

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

  @override
  int componentsCount(Entity entity) {
    final id = entity.id;
    if (id < 0 || id >= _entitiesCount) return 0;
    return math.max(0, _entities[_getEntityOffset(id)] - 1);
  }

  // --- Systems --- //

  // --- Triggers --- //
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
