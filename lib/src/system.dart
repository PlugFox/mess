import 'managers.dart';

/// System base class
abstract interface class System {
  /// Update the system with the given component manager
  void update(ComponentManager components);
}
