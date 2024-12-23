/// Unique entity type.
extension type const Entity(int id) {
  /// Check if an entity is alive.
  bool isAlive(IMess mess) => mess.hasEntity(this);
}

/// {@template mess}
/// Mess: entity-component-system manager.
/// Manage, create, and destroy entities.
/// {@endtemplate}
abstract interface class IMess {
  /// The number of used entities in this manager.
  /// This includes entities that have been destroyed but not recycled.
  int get usedEntitiesCount;

  /// The number of active entities in this manager.
  int get entitiesCount;

  /// Create a new entity
  Entity createEntity();

  /// Remove an entity from the current manager (world)
  void destroyEntity(Entity entity);

  /// Check if an entity is alive.
  bool hasEntity(Entity entity);

  /*
  /// Add a component to an entity
  void addComponent<C extends Object>(Entity entity, C component);

  /// Create a new pool
  IPool<C> createPool<C extends Object>();

  /// Update all systems
  void update(double deltaTime);

  Query createQuery(List<Type> types);
  */
}

/// {@template system}
/// System: processes entities with specific components
/// {@endtemplate}
abstract interface class ISystem {
  /// World reference for current system
  IMess? get world;
}

/* /// {@template pool}
/// Pool: manages components of a specific type
/// Components are stored in a dense array for cache efficiency.
/// A sparse array maps entity IDs to indices in the dense array.
/// Recycled indices are used to minimize memory usage and fragmentation.
/// {@endtemplate}
abstract interface class IPool<C extends Object> {
  /// World reference for pool
  IMess get world;

  /// Pool ID
  int get id;

  /// Type of components stored in pool
  Type get type;

  /// Increase sparse capacity
  void resize(int capacity);

  /// Get component by entity
  C? get(Entity entity);

  /// Add data
  void add(Entity entity, C component);

  /// Check if pool contains entity
  bool has(Entity entity);

  /// Exclude entity from the current pool
  void del(Entity entity);
} */
