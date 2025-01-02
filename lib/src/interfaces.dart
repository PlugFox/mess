import 'package:meta/meta.dart';

/// Entity
abstract interface class Entity {
  /// Entity ID.
  int get id;

  /// Check if an entity is alive.
  bool isAlive();

  /// Get components count of an entity.
  int get count;

  /// Add a component to an entity.
  /// If entity does not exist, we just skip the operation.
  void upsert<C extends Object>(C component);

  /// Remove a component from an entity.
  void remove<C extends Object>();

  /// Get component by type.
  C get<C extends Object>();

  /// Check if entity has a component.
  bool has<C extends Object>();

  /// Get components of an entity.
  List<Object> components();

  /// Destroy entity.
  void destroy();
}

/// {@template mess_pool}
/// Pool for components of a specific type.
/// {@endtemplate}
abstract interface class IMessPool<C extends Object> {
  /// Type of components in this pool.
  Type get type;

  /// Check if pool contains entity.
  bool contains(Entity entity);

  /// Remove entity from pool.
  /// Returns the removed component or null if entity does not exist.
  C? remove(Entity entity);

  /// Get component by entity.
  /// Throws [Exception] if entity does not exist.
  C operator [](Entity entity);

  /// Set component for entity.
  void operator []=(Entity entity, C component);

  // void copy(Entity from, Entity to);
}

/// {@template mess_query}
/// Query for entities with specific components.
/// {@endtemplate}
abstract interface class IMessQuery {
  /// Types of components in this query.
  Set<Type> get components;

  /// Immutable view of entities with specified components.
  List<Entity> get entities;
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

  /// Check if the manager (world) is alive and running (not disposed).
  bool get isAlive;

  /// Check if the manager (world) is disposed.
  bool get isDisposed;

  /// Create a new entity
  Entity createEntity();

  /// Get all entities ids in the current manager (world)
  /// Returns an empty list if no entities exist.
  /// Thats a relatively expensive operation.
  /// Do not use it in performance critical code, better use queries.
  @visibleForTesting
  List<int> entities();

  /// Remove an entity from the current manager (world)
  void destroyEntity(Entity entity);

  /// Check if an entity is alive.
  bool hasEntity(Entity entity);

  /// Add a component to an entity in the current manager (world)
  /// If entity does not exist, we just skip the operation.
  /// If the entity already has that component it will just return.
  void upsertComponent<C extends Object>(Entity entity, C component);

  /// Remove a component from an entity in the current manager (world) by type.
  void removeComponent<C extends Object>(Entity entity);

  /// Components count of an entity.
  /// Returns 0 if entity does not exist.
  int componentsCount(Entity entity);

  /// Get component by type.
  C getComponent<C extends Object>(Entity entity);

  /// Check if entity has a component.
  bool hasComponent<C extends Object>(Entity entity);

  /// Get components of an entity.
  List<Object> getComponents(Entity entity);

  /// Create a new query for entities with specific components.
  /// Provide a more rare component first for better performance.
  IMessQuery createQuery(Iterable<Type> components);

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
