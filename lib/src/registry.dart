/* @experimental
import 'package:meta/meta.dart';

@internal
abstract class Entity {
  abstract final int id;

  abstract Set<int> indices;

  abstract Set<String> tags;
}

@internal
abstract class Registry {
  Registry();

  int createEntity();
} */
