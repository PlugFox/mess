import 'package:meta/meta.dart';

/// Bitmask for a list of types.
/// Used in queries to filter entities by components.
@internal
extension type const Mask(int _v) implements int {
  /// Calculates a new mask from a collection of types.
  factory Mask.calculate(Iterable<Type> query, Map<Type, int> table) {
    var mask = 0;
    for (final type in query) {
      final id = table[type];
      if (id == null) continue;
      mask |= 1 << id;
    }
    return Mask(mask);
  }
}
