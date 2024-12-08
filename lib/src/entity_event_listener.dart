import 'entity.dart';

/// Event listener base class
abstract interface class EntityEventListener {
  /// Called when an entity is created
  void onEntityCreated(Entity entity);

  /// Called when an entity is destroyed
  void onEntityDestroyed(Entity entity);
}
