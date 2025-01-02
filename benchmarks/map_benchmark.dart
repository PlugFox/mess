import 'dart:collection';

import 'package:benchmark_harness/benchmark_harness.dart';

// $ dart run benchmarks/map_benchmark.dart
//
// $ dart compile exe -o benchmarks/map_benchmark.exe benchmarks/map_benchmark.dart
// $ benchmarks/map_benchmark.exe
void main() {
  (<BenchmarkBase>[
    _MapBenchmark(),
    _HashMapBenchmark(),
    _LinkedHashMapBenchmark(),
  ].map<({String name, double us})>(_measure).toList(growable: false)
        ..sort((a, b) => a.us.compareTo(b.us)))
      .map<String>((e) => 'Benchmark ${e.name}: ${e.us.toStringAsFixed(2)} us')
      .forEach(print); // ignore: avoid_print
}

({String name, double us}) _measure(BenchmarkBase benchmark) =>
    (name: benchmark.name, us: benchmark.measure());

class _MapBenchmark extends BenchmarkBase {
  _MapBenchmark() : super('Map');

  final Map<int, int> _map = <int, int>{};

  @override
  void setup() {
    super.setup();
    for (var i = 0; i < 10000; i++) _map[i] = i;
  }

  @override
  void run() {
    var total = 0;
    final length = _map.length;
    for (var i = 0; i < length; i++) total += _map[i]!;
    if (total != 49995000) throw StateError('Incorrect total: $total');
  }
}

class _HashMapBenchmark extends BenchmarkBase {
  _HashMapBenchmark() : super('HashMap');

  final Map<int, int> _map = HashMap.from(<int, int>{});

  @override
  void setup() {
    super.setup();
    for (var i = 0; i < 10000; i++) _map[i] = i;
  }

  @override
  void run() {
    var total = 0;
    final length = _map.length;
    for (var i = 0; i < length; i++) total += _map[i]!;
    if (total != 49995000) throw StateError('Incorrect total: $total');
  }
}

class _LinkedHashMapBenchmark extends BenchmarkBase {
  _LinkedHashMapBenchmark() : super('LinkedHashMap');

  final Map<int, int> _map = LinkedHashMap.from(<int, int>{});

  @override
  void setup() {
    super.setup();
    for (var i = 0; i < 10000; i++) _map[i] = i;
  }

  @override
  void run() {
    var total = 0;
    final length = _map.length;
    for (var i = 0; i < length; i++) total += _map[i]!;
    if (total != 49995000) throw StateError('Incorrect total: $total');
  }
}
