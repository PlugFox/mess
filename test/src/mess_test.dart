import 'package:mess/mess.dart';
import 'package:test/test.dart';

void main() => group(
      'Mess',
      () {
        test('Create', () {
          expect(Mess.new, returnsNormally);
        });

        test('Create entity', () {
          final mess = Mess();
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
          final mess = Mess();
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
        });

        test('Destroy entity', () {
          final mess = Mess();
          final entity = mess.createEntity();
          expect(mess.entitiesCount, equals(1));
          mess.destroyEntity(entity);
          expect(mess.entitiesCount, equals(0));
        });

        test('Destroy entities', () {
          final mess = Mess();
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
            final entity = Entity(i);
            mess.destroyEntity(entity);
          }
          expect(mess.entitiesCount, equals(0));
        });

        test('Reuse entity', () {
          final mess = Mess();
          final entity = mess.createEntity();
          expect(mess.entitiesCount, equals(1));
          expect(mess.hasEntity(entity), isTrue);
          mess
            ..createEntity()
            ..createEntity()
            ..destroyEntity(entity);
          expect(mess.entitiesCount, equals(2));
          expect(mess.hasEntity(entity), isFalse);
          expect(entity.isAlive(mess), isFalse);
          final reusedEntity = mess.createEntity();
          expect(mess.entitiesCount, equals(3));
          expect(entity, equals(reusedEntity));
          expect(entity.id, equals(reusedEntity.id));
          expect(mess.hasEntity(entity), isTrue);
          expect(mess.hasEntity(reusedEntity), isTrue);
          expect(entity.isAlive(mess), isTrue);
        });
      },
    );
