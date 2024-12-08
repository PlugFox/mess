// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

/*
Benchmark Uint32List: 3934.20 us
Benchmark ExtensionList: 3965.76 us
Benchmark MutableIntList: 4003.09 us
Benchmark ImmutableIntList: 4324.56 us
Benchmark ObjectList: 7862.72 us
Benchmark 2dList: 16965.59 us
*/

const int _listLength = 1000000;

// dart run benchmarks/iterator_benchmark.dart
void main() {
  (<BenchmarkBase>[
    _MutableIntListBenchmark(),
    _ImmutableIntListBenchmark(),
    _ListListBenchmark(),
    _ObjectListBenchmark(),
    _Uint32ListBenchmark(),
    _ExtensionListBenchmark(),
  ].map<({String name, double us})>(_measure).toList(growable: false)
        ..sort((a, b) => a.us.compareTo(b.us)))
      .map<String>((e) => 'Benchmark ${e.name}: ${e.us.toStringAsFixed(2)} us')
      .forEach(print);
}

@pragma('vm:never-inline')
({String name, double us}) _measure(BenchmarkBase benchmark) =>
    (name: benchmark.name, us: benchmark.measure());

class _ImmutableIntListBenchmark extends BenchmarkBase {
  _ImmutableIntListBenchmark() : super('ImmutableIntList');

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
    if (result != _listLength * (_listLength - 1) ~/ 2)
      throw StateError('Incorrect result: $result');
  }
}

class _MutableIntListBenchmark extends BenchmarkBase {
  _MutableIntListBenchmark() : super('MutableIntList');

  final List<int> _list = <int>[];

  @override
  void setup() {
    super.setup();
    _list.clear();
    for (var i = 0; i < _listLength; i++) _list.add(i);
  }

  @override
  void run() {
    var result = 0;
    for (var i = 0; i < _list.length; i++) result += _list[i];
    if (result != _listLength * (_listLength - 1) ~/ 2)
      throw StateError('Incorrect result: $result');
  }
}

class _Uint32ListBenchmark extends BenchmarkBase {
  _Uint32ListBenchmark() : super('Uint32List');

  final Uint32List _list = Uint32List(_listLength);

  @override
  void setup() {
    super.setup();
    for (var i = 0; i < _listLength; i++) _list[i] = i;
  }

  @override
  void run() {
    var result = 0;
    for (var i = 0; i < _list.length; i++) result += _list[i];
    if (result != _listLength * (_listLength - 1) ~/ 2)
      throw StateError('Incorrect result: $result');
  }
}

class _ObjectListBenchmark extends BenchmarkBase {
  _ObjectListBenchmark() : super('ObjectList');

  final List<_EntityObject> _list = <_EntityObject>[];

  @override
  void setup() {
    super.setup();
    _list.clear();
    for (var i = 0; i < _listLength; i++) _list.add(_EntityObject(i));
  }

  @override
  void run() {
    var result = 0;
    for (var i = 0; i < _list.length; i++) result += _list[i].id;
    if (result != _listLength * (_listLength - 1) ~/ 2)
      throw StateError('Incorrect result: $result');
  }
}

class _ListListBenchmark extends BenchmarkBase {
  _ListListBenchmark() : super('2dList');

  final List<List<int>> _list = <List<int>>[];

  @override
  void setup() {
    super.setup();
    _list.clear();
    for (var i = 0; i < _listLength; i++) _list.add(List<int>.filled(1, i));
  }

  @override
  void run() {
    var result = 0;
    for (var i = 0; i < _list.length; i++) result += _list[i][0];
    if (result != _listLength * (_listLength - 1) ~/ 2)
      throw StateError('Incorrect result: $result');
  }
}

final class _EntityObject {
  _EntityObject(this.id);

  /// Internal identifier.
  final int id;
}

class _ExtensionListBenchmark extends BenchmarkBase {
  _ExtensionListBenchmark() : super('ExtensionList');

  final List<_EntityExtension> _list = <_EntityExtension>[];

  @override
  void setup() {
    super.setup();
    _list.clear();
    for (var i = 0; i < _listLength; i++) _list.add(_EntityExtension(i));
  }

  @override
  void run() {
    var result = 0;
    for (var i = 0; i < _list.length; i++) result += _list[i].id;
    if (result != _listLength * (_listLength - 1) ~/ 2)
      throw StateError('Incorrect result: $result');
  }
}

extension type _EntityExtension(int _id) implements int {
  int get id => _id;
}
