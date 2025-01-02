import 'package:meta/meta.dart';

/// Bitmask for a list of types.
/// Used in queries to filter entities by components.
@internal
extension type const Mask(int _v) implements int {
  /// Creates a empty mask.
  const Mask.empty() : this(0);

  /// Creates a mask from a list of component indices.
  factory Mask.fromIndices(Iterable<int> indices) {
    var mask = 0;
    for (final index in indices) {
      if (index < 0)
        throw ArgumentError(
            'Index out of range: $index. Must be between 0 and 31.');
      mask |= 1 << index;
    }
    return Mask(mask);
  }

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

  /*
  /// Combines multiple masks into a single mask using a bitwise OR.
  factory Mask.combine(Iterable<int> masks) {
    var combined = 0;
    for (final mask in masks) combined |= mask;
    return Mask(combined);
  } */

  /// Returns the number of bits set to 1 in this mask.
  int get length {
    var count = 0;
    var mask = _v;
    while (mask != 0) {
      count += mask & 1;
      mask >>= 1;
    }
    return count;
  }

  /// Returns a list of indices of all set bits in this mask.
  Iterable<int> get bits sync* {
    var mask = _v, index = 0;
    while (mask != 0) {
      if ((mask & 1) == 1) yield index;
      mask >>= 1;
      index++;
    }
  }

  // --- Indexes --- //

  /// Checks if this mask contains the index [index].
  bool hasIndex(int index) => (_v & (1 << index)) != 0;

  /// Sets the bit at the specified [index].
  Mask setBit(int index) => Mask(_v | (1 << index));

  /// Clears the bit at the specified [index].
  Mask clearBit(int index) => Mask(_v & ~(1 << index));

  /// Toggles the bit at the specified [index].
  Mask toggleBit(int index) => Mask(_v ^ (1 << index));

  // --- Masks --- //

  /*
  /// Checks if this mask includes all the bits set in [other].
  ///
  /// Returns `true` if all bits in [other] are also set in this mask.
  bool has(int other) => (_v & other) == other;

  /// Checks if this mask includes any of the bits set in [other].
  ///
  /// Returns `true` if at least one bit in [other] is also set in this mask.
  bool hasAny(int other) => (_v & other) != 0;

  /// Checks if this mask includes none of the bits set in [other].
  ///
  /// Returns `true` if no bits in [other] are set in this mask.
  bool hasNone(int other) => (_v & other) == 0;

  /// Clears the bits specified in [other] from this mask.
  Mask clear(int other) => Mask(_v & ~other);
  */

  // --- Operators --- //

  /*
  /// Performs a bitwise AND operation with [other].
  ///
  /// Returns a new mask where only the bits present in both masks are set.
  Mask operator &(int other) => Mask(_v & other);

  /// Performs a bitwise OR operation with [other].
  ///
  /// Returns a new mask where all bits present in either mask are set.
  Mask operator |(int other) => Mask(_v | other);

  /// Performs a bitwise XOR operation with [other].
  ///
  /// Returns a new mask where bits present in one mask but not both are set.
  Mask operator ^(int other) => Mask(_v ^ other);

  /// Performs a bitwise NOT operation on this mask.
  ///
  /// Returns a new mask with all bits inverted.
  Mask operator ~() => Mask(~_v);
  */

  /// Returns a binary string representation of this mask.
  String toBinaryString({int minLength = 0}) =>
      _v.toRadixString(2).padLeft(minLength, '0');
}
