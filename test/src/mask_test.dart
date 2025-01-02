import 'package:mess/src/mask.dart';
import 'package:test/test.dart';

void main() => group('Mask', () {
      test('Create mask', () {
        const mask = Mask(2);
        expect(mask, allOf(equals(2), isA<int>()));
      });

      test('Empty mask', () {
        const mask = Mask.empty();
        expect(mask, allOf(equals(0), isA<int>()));
      });

      test('Search for component', () {
        final mask = Mask.fromIndices([1, 3, 5, 29, 50]);
        expect(mask.hasIndex(1), isTrue);
        expect(mask.hasIndex(3), isTrue);
        expect(mask.hasIndex(5), isTrue);
        expect(mask.hasIndex(29), isTrue);
        expect(mask.hasIndex(50), isTrue);
        expect(mask.hasIndex(2), isFalse);
        expect(mask.hasIndex(4), isFalse);
        expect(mask.hasIndex(32), isFalse);
        expect(mask.hasIndex(0), isFalse);
      });

      test('Change indexes', () {
        var mask = const Mask.empty();
        expect(mask.hasIndex(0), isFalse);
        mask = mask.setBit(0);
        expect(mask.hasIndex(0), isTrue);
        expect(mask.hasIndex(2), isFalse);
        mask = mask.setBit(2);
        expect(mask.hasIndex(0), isTrue);
        expect(mask.hasIndex(2), isTrue);
        expect(mask.hasIndex(1), isFalse);
        mask = mask.clearBit(0);
        expect(mask.hasIndex(0), isFalse);
        expect(mask.hasIndex(2), isTrue);
        mask = mask.setBit(0).setBit(2);
        expect(mask.hasIndex(0), isTrue);
        expect(mask.hasIndex(2), isTrue);
        mask = mask.clearBit(0).clearBit(2);
        expect(mask.hasIndex(0), isFalse);
        expect(mask.hasIndex(2), isFalse);
        expect(mask.hasIndex(1), isFalse);
        mask = mask.clearBit(0).clearBit(2);
        expect(mask.hasIndex(0), isFalse);
        expect(mask.hasIndex(2), isFalse);
        expect(mask.hasIndex(1), isFalse);
      });
    });
