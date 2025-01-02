import 'package:mess/mess.dart';
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
                (l) => l.map((p) => p.id),
                'length',
                containsAllInOrder([0, 1, 2]),
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
    });

class _MessPool$Fake<T extends Object> implements IMessPool<T> {
  const _MessPool$Fake(this.id);

  @override
  final int id;

  @override
  Type get type => T;

  static Never _throwFakeError() => throw StateError('Fake');

  @override
  bool contains(Entity entity) => _throwFakeError();

  @override
  T? remove(Entity entity) => _throwFakeError();

  @override
  T operator [](Entity entity) => _throwFakeError();

  @override
  void operator []=(Entity entity, T component) => _throwFakeError();
}
