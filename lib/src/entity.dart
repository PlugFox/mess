// --- Entity --- //

import 'package:meta/meta.dart';

import 'interfaces.dart';

/// {@template mess_entity}
/// Wrapper for an entity for convenient operations with its components.
/// {@endtemplate}
@immutable
final class Entity {
  /// Create a new entity wrapper.
  const Entity({
    required this.id,
    required IMess manager,
  }) : _mess = manager;

  /// Entity ID.
  final int id;

  final IMess _mess;

  /// Check if an entity is alive.
  bool isAlive() => _mess.hasEntity(id);

  /// Get components count of an entity.
  int get count => _mess.componentsCount(id);

  /// Add a component to an entity.
  /// If entity does not exist, we just skip the operation.
  void upsert<C extends Object>(C component) =>
      _mess.upsertComponent(id, component);

  /// Remove a component from an entity.
  void remove<C extends Object>() => _mess.removeComponent<C>(id);

  /// Get component by type.
  C get<C extends Object>() => _mess.getComponent<C>(id);

  /// Check if entity has a component.
  bool has<C extends Object>() => _mess.hasComponent<C>(id);

  /// Get components of an entity.
  List<Object> components() => _mess.getComponents(id);

  /// Destroy entity.
  void destroy() => _mess.destroyEntity(id);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entity && identical(_mess, other._mess) && id == other.id;

  @override
  String toString() => 'Entity{$id}';
}
