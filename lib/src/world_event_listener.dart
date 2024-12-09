/* // ignore_for_file: avoid_positional_boolean_parameters

import 'entity.dart';
import 'filter.dart';

/// World listener interface
abstract interface class WorldEventListener {
  /// Called when an entity is created
  void onEntityCreated(Entity entity);

  /// Called when an entity is changed
  void onEntityChanged(Entity entity, int poolId, bool added);

  /// Called when an entity is destroyed
  void onEntityDestroyed(Entity entity);

  /// Called when a filter is created
  void onFilterCreated(Filter filter);

  /// Called when a world is resized
  void onWorldResized(int newSize);

  /// Called when a world is destroyed
  void onWorldDestroyed();
}
 */