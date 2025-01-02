import 'package:mess/mess.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

void main() => group(
      'Mess',
      () {
        test('Create', () {
          expect(() => Mess.pools([]), returnsNormally);
        });

        test('Create entity', () {
          final mess = Mess.pools([]);
          final entity = mess.createEntity();
          expect(
            entity,
            allOf(
              [
                isNotNull,
                isA<Entity>(),
                predicate<Entity>((e) => e.id == 0),
              ],
            ),
          );
          expect(mess.entitiesCount, equals(1));
        });

        test('Create entities', () {
          final mess = Mess.pools([]);
          expect(mess.capacity, equals(512));
          for (var i = 0; i < 1024; i++) {
            expect(mess.hasEntity(_EntityFake(i)), isFalse);
            final entity = mess.createEntity();
            expect(
              entity,
              allOf(
                [
                  isNotNull,
                  isA<Entity>(),
                  predicate<Entity>((e) => e.id == i),
                ],
              ),
            );
            expect(mess.hasEntity(_EntityFake(i)), isTrue);
          }
          expect(mess.entitiesCount, equals(1024));
          expect(mess.capacity, greaterThanOrEqualTo(1024));
        });

        test('Destroy entity', () {
          final mess = Mess.pools([]);
          expect(
              () => mess.destroyEntity(const _EntityFake(-1)), returnsNormally);
          expect(
              () => mess.destroyEntity(const _EntityFake(0)), returnsNormally);
          expect(() => mess.destroyEntity(const _EntityFake(1000)),
              returnsNormally);
          final entity = mess.createEntity();
          expect(mess.hasEntity(entity), isTrue);
          expect(mess.entitiesCount, equals(1));
          mess.destroyEntity(entity);
          expect(mess.entitiesCount, equals(0));
          expect(mess.hasEntity(entity), isFalse);
          expect(entity.isAlive(), isFalse);
          expect(() => mess.destroyEntity(entity), returnsNormally);
        });

        test('Destroy entities', () {
          final mess = Mess.pools([]);
          expect(mess.capacity, equals(512));
          for (var i = 0; i < 1024; i++) {
            final entity = mess.createEntity();
            expect(
              entity,
              allOf(
                [
                  isNotNull,
                  isA<Entity>(),
                  predicate<Entity>((e) => e.id == i),
                ],
              ),
            );
          }
          expect(mess.entitiesCount, equals(1024));
          for (var i = 0; i < 1024; i++) {
            final entity = _EntityFake(i);
            mess.destroyEntity(entity);
          }
          expect(mess.entitiesCount, equals(0));
          expect(mess.capacity, greaterThanOrEqualTo(1024));
        });

        test('Reuse entity', () {
          final mess = Mess.pools([]);
          final entity = mess.createEntity();
          expect(mess.entitiesCount, equals(1));
          expect(mess.hasEntity(entity), isTrue);
          mess
            ..createEntity()
            ..createEntity()
            ..destroyEntity(entity);
          expect(mess.entitiesCount, equals(2));
          expect(mess.capacity, equals(512));
          expect(mess.hasEntity(entity), isFalse);
          expect(entity.isAlive(), isFalse);
          final reusedEntity = mess.createEntity();
          expect(mess.entitiesCount, equals(3));
          expect(entity, equals(reusedEntity));
          expect(entity.id, equals(reusedEntity.id));
          expect(mess.hasEntity(entity), isTrue);
          expect(mess.hasEntity(reusedEntity), isTrue);
          expect(entity.isAlive(), isTrue);
          expect(mess.capacity, equals(512));
          expect(mess.entitiesCount, equals(3));
        });

        test('Add components', () {});
      },
    );

@immutable
class _EntityFake implements Entity {
  const _EntityFake(this.id);

  @override
  final int id;

  @override
  List<Object> components() {
    throw UnimplementedError();
  }

  @override
  int get count => throw UnimplementedError();

  @override
  C get<C extends Object>() {
    throw UnimplementedError();
  }

  @override
  bool isAlive() {
    throw UnimplementedError();
  }

  @override
  void remove<C extends Object>() {
    throw UnimplementedError();
  }

  @override
  void upsert<C extends Object>(C component) {
    throw UnimplementedError();
  }
}
