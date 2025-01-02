import 'package:mess/mess.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

void main() => group(
      'Mess',
      () {
        test('Create and dispose', () {
          expect(() => Mess.pools([]).dispose(), returnsNormally);
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
          mess.dispose();
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
          mess.dispose();
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
          mess.dispose();
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
          mess.dispose();
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
          mess.dispose();
        });

        test('Get all entities', () {
          final mess = Mess.pools([]);
          expect(mess.entities(), isEmpty);

          final ids = <int>{};
          for (var i = 0; i < 1920; i++) {
            final entity = mess.createEntity();
            ids.add(entity.id);
          }
          expect(
            mess.entities(),
            allOf([
              isA<List<Entity>>(),
              hasLength(1920),
              everyElement(allOf([
                isA<Entity>(),
                predicate<Entity>((e) => ids.contains(e.id) && e.id < 1920),
              ])),
            ]),
          );

          final toDestroy = <int>{
            0,
            12,
            13,
            48,
            for (var i = 450; i < 630; i++) i,
            700,
            702,
            703,
            705,
            for (var i = 1000; i < 1024; i++) i,
            1919,
          };

          for (final id in toDestroy) {
            mess.destroyEntity(_EntityFake(id));
            ids.remove(id);
          }

          expect(
            mess.entities(),
            allOf([
              isA<List<Entity>>(),
              hasLength(1920 - toDestroy.length),
              hasLength(ids.length),
              everyElement(allOf([
                isA<Entity>(),
                predicate<Entity>((e) => ids.contains(e.id) && e.id < 1920),
              ])),
            ]),
          );

          final a = mess.createEntity();
          final b = mess.createEntity();
          final c = mess.createEntity();

          expect(a.id, lessThan(1920)); // Reuse
          expect(b.id, lessThan(1920)); // Reuse
          expect(c.id, lessThan(1920)); // Reuse
          ids.addAll([a.id, b.id, c.id]);

          expect(
            mess.entities(),
            allOf([
              isA<List<Entity>>(),
              hasLength(ids.length),
              everyElement(predicate<Entity>(
                (e) => ids.contains(e.id) && e.id < 1920,
              )),
            ]),
          );

          mess.dispose();
        });
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
  bool isAlive() {
    throw UnimplementedError();
  }

  @override
  bool has<C extends Object>() {
    throw UnimplementedError();
  }

  @override
  C get<C extends Object>() {
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
