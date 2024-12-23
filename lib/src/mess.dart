// ignore_for_file: prefer_final_fields

import 'dart:typed_data';

import 'interfaces.dart';

/// {@macro mess}
class Mess implements IMess {
  /// Create a new [Mess] instance
  ///
  /// {@macro mess}
  Mess()
      : _entities = Uint32List(512),
        _recycledEntities = Uint32List(512);

  // --- Entities --- //

  /// The next identifier for an [Entity].
  int _entitiesCount = 0;

  /// All entities in this manager.
  Uint32List _entities;

  /// Recycled entities in this manager.
  int _recycledEntitiesCount = 0;

  /// Recycled entities in this manager.
  Uint32List _recycledEntities;

  /// The number of used entities in this manager.
  int get usedEntitiesCount => _entitiesCount;

  /// The number of active entities in this manager.
  int get entitiesCount => _entitiesCount - _recycledEntitiesCount;

  @override
  Entity createEntity() {
    final int id;
    if (_recycledEntitiesCount > 0) {
      // Reuse recycled entity
      id = _recycledEntities[--_recycledEntitiesCount];
    } else {
      // Add new entity
      if (_entitiesCount == _entities.length) {
        // Resize entities array
        final newSize = _entitiesCount << 1;
        _entities = _resizeUint32List(_entities, newSize);
      }
      id = _entitiesCount++; // 0..n
    }
    _entities[id] = 1;
    //_trigger(ENTITY_CREATED, entity);
    return Entity(id);
  }

  @override
  void destroyEntity(Entity entity) {
    final id = entity.id;
    assert(id >= 0 && id < _entities.length, 'Entity ID out of bounds');
    // If entity is already destroyed
    if (_entities[id] < 0) return;
    // Recycle entity
    _entities[id] = 0;
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
    assert(id >= 0 && id < _entities.length, 'Entity ID out of bounds');
    return _entities[id] > 0;
  }

  // --- Components --- //

  // --- Systems --- //

  // --- Triggers --- //
}

Uint32List _resizeUint32List(Uint32List array, int newCapacity) {
  assert(
    newCapacity > array.length,
    'New capacity must be greater than current capacity',
  );
  final newEntities = Uint32List(newCapacity)..setAll(0, array);
  return newEntities;
}
