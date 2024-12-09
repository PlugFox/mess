abstract interface class IWorld {}

/// {@template pool}
/// Pool: manages components of a specific type
/// Components are stored in a dense array for cache efficiency.
/// A sparse array maps entity IDs to indices in the dense array.
/// Recycled indices are used to minimize memory usage and fragmentation.
/// {@endtemplate}
abstract interface class IPool<T extends Object> {
  IWorld get world;
  int get id;
  Type get type;

  /// Increase sparse capacity
  void resize(int capacity);

  /// Get data by entity
  T get(int entity);

  /// Add data
  void add(int entity, T data);

  bool has(int entity);

  void del(int entity);
}
