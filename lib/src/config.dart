import 'package:meta/meta.dart';

/// {@template config}
/// Body of the template
/// {@endtemplate}
@immutable
class WorldConfig {
  /// {@macro config}
  const WorldConfig({
    this.initialEntityCapacity = 1024,
    this.initialComponentCapacity = 256,
  });

  /// Initial entity capacity
  final int initialEntityCapacity;

  /// Initial component capacity
  final int initialComponentCapacity;
}
