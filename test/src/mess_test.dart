import 'package:mess/mess.dart';
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
                isA<int>(),
                predicate<int>((id) => id == 0),
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
            expect(mess.hasEntity(i), isFalse);
            final entity = mess.createEntity();
            expect(
              entity,
              allOf(
                [
                  isNotNull,
                  isA<int>(),
                  predicate<int>((id) => id == i),
                  predicate<int>((id) => mess.hasEntity(id) && id < 1024),
                ],
              ),
            );
            expect(mess.hasEntity(i), isTrue);
          }
          expect(mess.entitiesCount, equals(1024));
          expect(mess.capacity, greaterThanOrEqualTo(1024));
          mess.dispose();
        });

        test('Destroy entity', () {
          final mess = Mess.pools([]);
          expect(() => mess.destroyEntity(-1), returnsNormally);
          expect(() => mess.destroyEntity(0), returnsNormally);
          expect(() => mess.destroyEntity(1000), returnsNormally);
          final entity = mess.createEntity();
          expect(mess.hasEntity(entity), isTrue);
          expect(mess.entitiesCount, equals(1));
          mess.destroyEntity(entity);
          expect(mess.entitiesCount, equals(0));
          expect(mess.hasEntity(entity), isFalse);
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
                  isA<int>(),
                  predicate<int>((id) => id == i),
                ],
              ),
            );
          }
          expect(mess.entitiesCount, equals(1024));
          for (var i = 0; i < 1024; i++) {
            mess.destroyEntity(i);
          }
          expect(mess.entitiesCount, equals(0));
          expect(mess.capacity, greaterThanOrEqualTo(1024));
          mess.dispose();
        });

        test('Reuse entity', () {
          final mess = Mess.pools([]);
          final id = mess.createEntity();
          expect(mess.entitiesCount, equals(1));
          expect(mess.hasEntity(id), isTrue);
          mess
            ..createEntity()
            ..createEntity()
            ..destroyEntity(id);
          expect(mess.entitiesCount, equals(2));
          expect(mess.capacity, equals(512));
          expect(mess.hasEntity(id), isFalse);
          expect(mess.hasEntity(id), isFalse);
          final reusedEntity = mess.createEntity();
          expect(mess.entitiesCount, equals(3));
          expect(id, equals(reusedEntity));
          expect(mess.hasEntity(id), isTrue);
          expect(mess.hasEntity(reusedEntity), isTrue);
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
            ids.add(entity);
          }
          expect(
            mess.entities(),
            allOf([
              isA<List<int>>(),
              hasLength(1920),
              everyElement(allOf([
                isA<int>(),
                predicate<int>((id) => ids.contains(id) && id < 1920),
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
            mess.destroyEntity(id);
            ids.remove(id);
          }

          expect(
            mess.entities(),
            allOf([
              isA<List<int>>(),
              hasLength(1920 - toDestroy.length),
              hasLength(ids.length),
              everyElement(allOf([
                isA<int>(),
                predicate<int>((id) => ids.contains(id) && id < 1920),
              ])),
            ]),
          );

          final a = mess.createEntity();
          final b = mess.createEntity();
          final c = mess.createEntity();

          expect(a, lessThan(1920)); // Reuse
          expect(b, lessThan(1920)); // Reuse
          expect(c, lessThan(1920)); // Reuse
          ids.addAll([a, b, c]);

          expect(
            mess.entities(),
            allOf([
              isA<List<int>>(),
              hasLength(ids.length),
              everyElement(predicate<int>(
                (id) => ids.contains(id) && id < 1920,
              )),
            ]),
          );

          mess.dispose();
        });
      },
    );
