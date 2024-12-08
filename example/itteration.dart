import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

// dart run benchmarks/itteration.dart
void main() {
  _IntListBenchmark().report();
  _UInt16ListBenchmark().report();
}

const int _listLength = 1000000;

class _IntListBenchmark extends BenchmarkBase {
  _IntListBenchmark() : super('IntList');

  final List<int> _list = List<int>.filled(_listLength, 0, growable: false);

  @override
  void setup() {
    super.setup();
    for (var i = 0; i < _listLength; i++) _list[i] = i;
  }

  @override
  void run() {
    var result = 0;
    for (var i = 0; i < _list.length; i++) result += _list[i];
    print(result);
    if (result != _listLength * (_listLength - 1) ~/ 2)
      throw StateError('Incorrect result: $result');
  }
}

class _UInt16ListBenchmark extends BenchmarkBase {
  _UInt16ListBenchmark() : super('UInt16List');

  final Uint16List _list = Uint16List(_listLength);

  @override
  void setup() {
    super.setup();
    for (var i = 0; i < _listLength; i++) _list[i] = i;
  }

  @override
  void run() {
    var result = 0;
    for (var i = 0; i < _list.length; i++) result += _list[i];
    print(result);
    print(result);
    if (result != _listLength * (_listLength - 1) ~/ 2)
      throw StateError('Incorrect result: $result');
  }
}
