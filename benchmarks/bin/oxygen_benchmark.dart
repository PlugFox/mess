import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:mess/mess.dart' as mess;
import 'package:oxygen/oxygen.dart' as oxygen;

void main() {
  (<BenchmarkBase>[
    _CreateEntity$Oxygen$Benchmark(),
    _CreateEntity$Mess$Benchmark(),
  ].map<({String name, double us})>(_measure).toList(growable: false)
        ..sort((a, b) => a.us.compareTo(b.us)))
      .map<String>((e) => 'Benchmark ${e.name}: ${e.us.toStringAsFixed(2)} us')
      .forEach(print); // ignore: avoid_print
}

({String name, double us}) _measure(BenchmarkBase benchmark) =>
    (name: benchmark.name, us: benchmark.measure());

class _CreateEntity$Oxygen$Benchmark extends BenchmarkBase {
  _CreateEntity$Oxygen$Benchmark() : super('CreateEntity#Oxygen');

  late oxygen.World world;

  @override
  void setup() {
    super.setup();
    world = oxygen.World();
  }

  @override
  void run() {
    oxygen.Entity? entity;
    for (var i = 0; i < 10000; i++) entity = world.createEntity();
    if (entity?.id == null)
      throw StateError('Incorrect entity id: ${entity?.id}');
  }
}

class _CreateEntity$Mess$Benchmark extends BenchmarkBase {
  _CreateEntity$Mess$Benchmark() : super('CreateEntity#Mess');

  late mess.Mess world;

  @override
  void setup() {
    super.setup();
    world = mess.Mess.pools([]);
  }

  @override
  void run() {
    mess.Entity? entity;
    for (var i = 0; i < 10000; i++) entity = world.createEntity();
    if (entity?.id == null)
      throw StateError('Incorrect entity id: ${entity?.id}');
  }
}
