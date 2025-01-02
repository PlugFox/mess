/// Unique entity type.
extension type const Entity(int id) {
  /// Check if an entity is alive.
  bool isAlive(IMess mess) => mess.hasEntity(this);
}

/// {@template mess}
/// Mess: entity-component-system manager.
/// Manage, create, and destroy entities.
/// Operate on entities with components via pools.
/// {@endtemplate}
abstract interface class IMess {
  /// Current reserved capacity for entities.
  int get capacity;

  /// The size of an entity in bytes.
  /// The first byte is a flag for entity existence.
  /// The next bytes are components pointers.
  int get entitySize;

  /// The number of active entities in this manager.
  int get entitiesCount;

  /// Create a new entity
  Entity createEntity();

  /// Remove an entity from the current manager (world)
  void destroyEntity(Entity entity);

  /// Check if an entity is alive.
  bool hasEntity(Entity entity);

  /// Add a component to an entity in the current manager (world)
  /// If entity does not exist, we just skip the operation.
  /// If the entity already has that component it will just return.
  void setComponent<C extends Object>(Entity entity, C component);

  /// Add multiple components to an entity
  /// If entity does not exist, we just skip the operation.
  /// If the entity already has that component it will just skip it.
  void setComponents(Entity entity, Map<Type, Object> components);

  /// Components count of an entity.
  /// Returns 0 if entity does not exist.
  int componentsCount(Entity entity);

  /// Get components of an entity.
  List<Object> getComponents(Entity entity);

  /*

  /// Create a new pool
  IPool<C> createPool<C extends Object>();

  /// Update all systems
  void update(double deltaTime);

  Query createQuery(List<Type> types);
  */

  /// Dispose of the current manager (world)
  void dispose();
}

/// {@template system}
/// System: processes entities with specific components
/// {@endtemplate}
abstract interface class ISystem {
  /// Entity manager (world) reference for current system
  IMess get world;

  /// Execute system logic with delta time
  void execute(double delta);
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
