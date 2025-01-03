import 'dart:collection';

import 'package:mess/mess.dart';
import 'package:mess/src/mask.dart';
import 'package:test/test.dart';

void main() => group('Pool', () {
      test('HashMap PoolRegistry', () {
        final reg = PoolRegistry()
          ..register<int>()
          ..register<String>()
          ..registerFactory<num>(_MessPool$Fake<num>.new);
        expect(reg.build, returnsNormally);
        expect(reg.createMess, returnsNormally);
        expect(
          reg.build(),
          isA<List<IMessPool<Object>>>()
              .having(
                (l) => l.length,
                'length',
                equals(3),
              )
              .having(
                (l) => l.map((p) => p.type),
                'types',
                containsAll([int, String, num]),
              ),
        );
        expect(reg.clear, returnsNormally);
        expect(
          reg.build(),
          isA<List<IMessPool<Object>>>().having(
            (l) => l.isEmpty,
            'isEmpty',
            isTrue,
          ),
        );
      });

      test('Mask', () {
        final pools = [
          const _MessPool$Fake<int>(),
          const _MessPool$Fake<String>(),
          const _MessPool$Fake<num>(),
          const _MessPool$Fake<Exception>(),
        ];
        final types = HashMap<Type, int>.of(
            {for (var i = 0; i < pools.length; i++) pools[i].type: i});

        expect(
          Mask.calculate([int, String], types),
          allOf(
            equals(Mask.calculate([int, String], types)),
            equals(Mask.calculate([String, int], types)),
            isNot(equals(Mask.calculate([int], types))),
            isNot(equals(Mask.calculate([String], types))),
            isNot(equals(Mask.calculate([int, String, num], types))),
            isNot(equals(Mask.calculate([int, num], types))),
            isNot(equals(Mask.calculate([num, String], types))),
          ),
        );

        final queries = <List<Type>>[
          [int, String],
          [String, int],
          [int],
          [String],
          [int, String, num],
          [int, num],
          [Exception],
          [num, String],
        ];
        final masks = <int, List<Type>>{
          for (final query in queries) Mask.calculate(query, types): query
        };

        expect(
          masks,
          allOf(
            isNotEmpty,
            hasLength(7),
          ),
        );

        // Try to find the masks for each type.
        final numsMask = 1 << types[num]!;
        final found = <List<Type>>[
          for (final mask in masks.entries)
            if ((mask.key & numsMask) != 0) mask.value
        ];
        expect(
          found,
          allOf(
            isNotEmpty,
            hasLength(3),
            containsAll([
              [num, String],
              [int, String, num],
              [int, num],
            ]),
          ),
        );

        // Try to find mask for combinations of int and String.
        /*
        final combinedMask = 1 << poolMap[int]!.id | 1 << poolMap[String]!.id;
        final found2 = <List<Type>>[
          for (final mask in masks.entries)
            if ((mask.key & combinedMask) != 0) mask.value
        ];
        expect(
          found2,
          allOf(
            isNotEmpty,
            hasLength(2),
            containsAll([
              [String, int],
              [int, String, num],
            ]),
          ),
        ); */
      });
    });

class _MessPool$Fake<T extends Object> implements IMessPool<T> {
  const _MessPool$Fake();

  @override
  Type get type => T;

  static Never _throwFakeError() => throw StateError('Fake');

  @override
  bool contains(int id) => _throwFakeError();

  @override
  T? remove(int id) => _throwFakeError();

  @override
  T get(int id) => _throwFakeError();

  @override
  void upsert(int id, T component) => _throwFakeError();
}
