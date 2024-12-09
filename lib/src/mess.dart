// ignore_for_file: one_member_abstracts

import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'interfaces.dart';

@internal
sealed class BasePool<T extends Object> implements IPool<T> {
  abstract final Type _type;
  abstract final IWorld _world;
  abstract final int _id;

  // --- 1-based index. --- //

  abstract final List<int> _sparseItems;
  abstract final List<T?> _denseItems;
  abstract final int _denseItemsCount;
  abstract final List<int> _recycledItems;
  abstract final int _recycledItemsCount;
}

@internal
class Pool<T extends Object> extends BasePool<T> {
  Pool(
      {required IWorld world,
      required int id,
      required int denseCapacity,
      required int sparseCapacity,
      required int recycledCapacity})
      : _type = T,
        _world = world,
        _id = id,
        _denseItems = List<T?>.filled(denseCapacity + 1, null, growable: false),
        _denseItemsCount = 1,
        _sparseItems = List<int>.filled(sparseCapacity, 0),
        _recycledItems = List<int>.filled(recycledCapacity, 0),
        _recycledItemsCount = 0;

  @override
  final Type _type;

  @override
  final IWorld _world;

  @override
  final int _id;

  // 1-based index.
  @override
  List<int> _sparseItems;

  @override
  List<T?> _denseItems;

  @override
  int _denseItemsCount;

  @override
  List<int> _recycledItems;

  @override
  int _recycledItemsCount;

  @override
  IWorld get world => _world;

  @override
  int get id => _id;

  @override
  Type get type => _type;

  @override
  void resize(int capacity) {
    if (capacity <= _sparseItems.length) return;
    final newSparse = Uint32List(capacity)..setAll(0, _sparseItems);
    _sparseItems = newSparse;
  }

  @override
  T get(int entity) {
    assert(entity < _sparseItems.length, 'Entity ID out of bounds');
    // TODO(plugfox): Add assert
    //assert(
    // _world.isEntityAliveInternal(entity),
    // 'Cant touch destroyed entity.',
    //);
    // Mike Matiunin <plugfox@gmail.com>, 09 December 2024
    final result = _denseItems[_sparseItems[entity]];
    assert(result != null, 'Entity not found as dense items collection');
    return result!;
  }

  Object _getRaw(int entity) => get(entity);

  void _setRaw(int entity, Object dataRaw) {
    assert(
      dataRaw is Type,
      'Invalid component data, valid "$T" instance required.',
    );
    assert(
      _sparseItems[entity] > 0,
      'Component "$T" not attached to entity.',
    );
    _denseItems[_sparseItems[entity]] = dataRaw as T;
  }

  @override
  void add(int entity, T data) {
    // TODO(plugfox): Add assert
    //assert(
    // _world.isEntityAliveInternal(entity),
    // 'Cant touch destroyed entity.',
    //);
    // Mike Matiunin <plugfox@gmail.com>, 09 December 2024
    assert(
      _sparseItems[entity] <= 0,
      'Component "$T" already attached to entity.',
    );
    int idx;
    if (_recycledItemsCount > 0) {
      idx = _recycledItems[--_recycledItemsCount];
    } else {
      idx = _denseItemsCount;
      if (_denseItemsCount == _denseItems.length) {
        final newDenseItems = List<T?>.filled(
          _denseItemsCount << 1,
          null,
          growable: false,
        )..setAll(0, _denseItems);
        _denseItems = newDenseItems;
      }
      _denseItemsCount++;
    }
    _sparseItems[entity] = idx;
    // TODO(plugfox): Implement me
    //_world.OnEntityChangeInternal(entity, _id, true);
    //_world.AddComponentToRawEntityInternal(entity, _id);
    //_world.RaiseEntityChangeEvent (entity, _id, true);
    // Mike Matiunin <plugfox@gmail.com>, 09 December 2024
  }

  @internal
  void addRaw(int entity, Object dataRaw) {
    assert(
      dataRaw is Type,
      'Invalid component data, valid "$T" instance required.',
    );
    add(entity, dataRaw as T);
  }

  @override
  bool has(int entity) {
    // TODO(plugfox): Add assert
    //assert(
    // _world.isEntityAliveInternal(entity),
    // 'Cant touch destroyed entity.',
    //);
    // Mike Matiunin <plugfox@gmail.com>, 09 December 2024
    return _sparseItems[entity] > 0;
  }

  @override
  void del(int entity) {
    // TODO(plugfox): Add assert
    //assert(
    // _world.isEntityAliveInternal(entity),
    // 'Cant touch destroyed entity.',
    //);
    // Mike Matiunin <plugfox@gmail.com>, 09 December 2024
    var sparseData = _sparseItems[entity];
    if (sparseData > 0) {
      // TODO(plugfox): Implement me
      //_world.OnEntityChangeInternal(entity, _id, false);
      // Mike Matiunin <plugfox@gmail.com>, 09 December 2024
      if (_recycledItemsCount == _recycledItems.length) {
        final newRecycledItems = List<int>.filled(
          _recycledItemsCount << 1,
          0,
          growable: false,
        )..setAll(0, _recycledItems);
        _recycledItems = newRecycledItems;
      }
      _recycledItems[_recycledItemsCount++] = sparseData;
      _denseItems[sparseData] = null;
      sparseData = 0;
      // TODO(plugfox): Implement me
      //var componentsCount =
      //    _world.RemoveComponentFromRawEntityInternal(entity, _id);
      //_world.RaiseEntityChangeEvent (entity, _id, false);
      //if (componentsCount == 0) {
      //  _world.DelEntity(entity);
      //}
      // Mike Matiunin <plugfox@gmail.com>, 09 December 2024
    }
  }
}

/// {@template world}
/// World: manages entities, components, and systems
/// {@endtemplate}
class World implements IWorld {
  /* /// {@macro world}
  World(WorldConfig config)
      : entityManager =
            EntityManager(initialCapacity: config.initialEntityCapacity),
        componentManager =
            ComponentManager(initialCapacity: config.initialComponentCapacity),
        systems = <System>[];

  /// Entity manager
  final EntityManager entityManager;

  /// Component manager
  final ComponentManager componentManager;

  /// Systems
  final List<System> systems;

  /// Add a system
  void addSystem(System system) {
    systems.add(system);
  }

  /// Update all systems
  void update() {
    for (final system in systems) {
      system.update(componentManager);
    }
  } */
}
