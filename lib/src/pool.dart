

/*
/// {@macro pool}
class ComponentPool<T extends Component> {
  /// Initializes a new pool with a given initial capacity.
  ///
  /// [initialCapacity] - Initial size of the sparse and dense arrays.
  /// {@macro pool}
  ComponentPool({required int initialCapacity})
      : _sparse = Uint32List(initialCapacity),
        _dense = List<T?>.filled(initialCapacity, null, growable: true),
        _recycled = <int>[];

  /// Dense array storing components in a packed manner.
  /// Components are stored sequentially
  /// and can be accessed via their dense index.
  final List<T?> _dense;

  /// Sparse array mapping entity IDs to indices in the dense array.
  /// If `_sparse[entity.id] == 0`, the entity does not have a component.
  final Uint32List _sparse;

  /// List of recycled dense indices for reuse when components are removed.
  /// This helps minimize memory usage and fragmentation.
  final List<int> _recycled;

  /// Returns the current length of the sparse array.
  int get sparseLength => _sparse.length;

  /// Retrieves a component associated with a given [entity].
  ///
  /// Returns the component if it exists,
  /// or `null` if the entity has no component.
  T? get(Entity entity) {
    assert(entity.id < _sparse.length, 'Entity ID out of bounds');
    final index = _sparse[entity.id];
    return index != 0 ? _dense[index - 1] : null;
  }

  /// Adds a component to a specific [entity].
  ///
  /// Throws [StateError] if the entity already has a component of this type.
  void add(Entity entity, T component) {
    if (entity.id >= _sparse.length) {
      resizeSparseIfNeeded(entity.id + 1);
    }

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

  /// Removes the component associated with a specific [entity].
  ///
  /// If the entity has no component, the method does nothing.
  void remove(Entity entity) {
    assert(entity.id < _sparse.length, 'Entity ID out of bounds');
    final index = _sparse[entity.id];
    if (index == 0) return;

    // Remove the component from the dense array and recycle the index.
    _dense[index - 1] = null;
    _sparse[entity.id] = 0;
    _recycled.add(index - 1);
  }

  /// Retrieves all entities that currently have components in this pool.
  ///
  /// Returns an iterable of `Entity` objects.
  Iterable<Entity> entities() sync* {
    for (var i = 0; i < _dense.length; i++) {
      if (_dense[i] != null) {
        for (var j = 0; j < _sparse.length; j++) {
          if (_sparse[j] == i + 1) {
            yield Entity(j);
            break;
          }
        }
      }
    }
  }

  /// Resizes the sparse array to accommodate more entities if needed.
  ///
  /// [newCapacity] must be larger than the current sparse array size.
  void resizeSparseIfNeeded(int newCapacity) {
    if (newCapacity > _sparse.length) {
      final newSparse = Uint32List(newCapacity);
      // Копируем старые данные
      for (var i = 0; i < _sparse.length; i++) {
        newSparse[i] = _sparse[i];
      }
      // Заменяем ссылку на новый массив
      for (var i = 0; i < newCapacity; i++) _sparse[i]= newSparse
    }
  }
} */
