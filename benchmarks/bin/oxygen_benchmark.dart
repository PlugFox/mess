import 'dart:collection';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:mess/mess.dart' as mess;
import 'package:oxygen/oxygen.dart' as oxygen;

/*
Create World:
Benchmark CreateWorld#Oxygen: 9.68 us
Benchmark CreateWorld#Mess: 24.48 us
Ratio: 2.53

Create 1000 entities:
Benchmark CreateEntity#Mess: 1590.07 us
Benchmark CreateEntity#Oxygen: 11947.30 us
Ratio: 7.51

Create and remove 100 entities:
Benchmark RemoveEntity#Mess: 101.68 us
Benchmark RemoveEntity#Oxygen: 1402.18 us
Ratio: 13.79

Get components for 100 entities:
Benchmark GetComponent#Mess: 41.81 us
Benchmark GetComponent#Oxygen: 48.39 us
Ratio: 1.16
*/

// $ dart run benchmarks/bin/oxygen_benchmark.dart
//
// $ dart compile exe -o benchmarks/oxygen_benchmark.exe benchmarks/bin/oxygen_benchmark.dart
// $ benchmarks/oxygen_benchmark.exe
void main() {
  final buffer = StringBuffer();

  void dvd(String title) => buffer
    ..writeln()
    ..writeln(title);

  void measure(List<BenchmarkBase> benchmarks) {
    final results = benchmarks
        .map<({String name, double us})>(_measure)
        .toList(growable: false)
      ..sort((a, b) => a.us.compareTo(b.us));
    results
        .map<String>(
            (e) => 'Benchmark ${e.name}: ${e.us.toStringAsFixed(2)} us')
        .forEach(buffer.writeln);
    final ratio = results.last.us / results.first.us;
    buffer.writeln('Ratio: ${ratio.toStringAsFixed(2)}');
  }

  dvd('Create World:');
  measure(<BenchmarkBase>[
    _CreateWorld$Oxygen$Benchmark(),
    _CreateWorld$Mess$Benchmark(),
  ]);

  dvd('Create 1000 entities:');
  measure(<BenchmarkBase>[
    _CreateEntity$Oxygen$Benchmark(),
    _CreateEntity$Mess$Benchmark(),
  ]);

  /* dvd('Retrieve all entities:');
  measure(<BenchmarkBase>[
    _GetEntities$Oxygen$Benchmark(),
    _GetEntities$Mess$Benchmark(),
  ]); */

  dvd('Create and remove 100 entities:');
  measure(<BenchmarkBase>[
    _RemoveEntity$Oxygen$Benchmark(),
    _RemoveEntity$Mess$Benchmark(),
  ]);

  dvd('Get components for 100 entities:');
  measure(<BenchmarkBase>[
    _GetComponent$Oxygen$Benchmark(),
    _GetComponent$Mess$Benchmark(),
  ]);

  print(buffer.toString()); // ignore: avoid_print
}

({String name, double us}) _measure(BenchmarkBase benchmark) =>
    (name: benchmark.name, us: benchmark.measure());

// --- Create world --- //

class _CreateWorld$Oxygen$Benchmark extends BenchmarkBase {
  _CreateWorld$Oxygen$Benchmark() : super('CreateWorld#Oxygen');

  @override
  void run() {
    final world = oxygen.World()
      ..registerComponent<oxygen.ValueComponent<int>, int>(
          oxygen.ValueComponent<int>.new)
      ..registerComponent<oxygen.ValueComponent<String>, String>(
          oxygen.ValueComponent<String>.new)
      ..registerComponent<oxygen.ValueComponent<num>, num>(
          oxygen.ValueComponent<num>.new)
      ..registerComponent<oxygen.ValueComponent<bool>, bool>(
          oxygen.ValueComponent<bool>.new)
      ..registerComponent<oxygen.ValueComponent<Symbol>, Symbol>(
          oxygen.ValueComponent<Symbol>.new);
    if (world.entities.isNotEmpty)
      throw StateError('We should have no entities');
  }
}

class _CreateWorld$Mess$Benchmark extends BenchmarkBase {
  _CreateWorld$Mess$Benchmark() : super('CreateWorld#Mess');

  @override
  void run() {
    final world = (mess.PoolRegistry()
          ..register<int>()
          ..register<String>()
          ..register<num>()
          ..register<bool>()
          ..register<Symbol>())
        .createMess();
    if (world.entitiesCount != 0)
      throw StateError('We should have no entities');
  }
}

// --- Create entity --- //

class _CreateEntity$Oxygen$Benchmark extends BenchmarkBase {
  _CreateEntity$Oxygen$Benchmark() : super('CreateEntity#Oxygen');

  @override
  void run() {
    final world = oxygen.World()
      ..registerComponent<oxygen.ValueComponent<int>, int>(
          oxygen.ValueComponent<int>.new)
      ..registerComponent<oxygen.ValueComponent<String>, String>(
          oxygen.ValueComponent<String>.new)
      ..registerComponent<oxygen.ValueComponent<num>, num>(
          oxygen.ValueComponent<num>.new)
      ..registerComponent<oxygen.ValueComponent<bool>, bool>(
          oxygen.ValueComponent<bool>.new)
      ..registerComponent<oxygen.ValueComponent<Symbol>, Symbol>(
          oxygen.ValueComponent<Symbol>.new);

    oxygen.Entity? entity;
    for (var i = 0; i < 1000; i++)
      entity = world.createEntity()
        ..add<oxygen.ValueComponent<int>, int>(0)
        ..add<oxygen.ValueComponent<String>, String>('string')
        ..add<oxygen.ValueComponent<num>, num>(1)
        ..add<oxygen.ValueComponent<bool>, bool>(true)
        ..add<oxygen.ValueComponent<Symbol>, Symbol>(#symbol);
    if (entity?.id == null)
      throw StateError('Incorrect entity id: ${entity?.id}');
  }
}

class _CreateEntity$Mess$Benchmark extends BenchmarkBase {
  _CreateEntity$Mess$Benchmark() : super('CreateEntity#Mess');

  @override
  void run() {
    final world = (mess.PoolRegistry()
          ..register<int>()
          ..register<String>()
          ..register<num>()
          ..register<bool>()
          ..register<Symbol>())
        .createMess();
    int? entity;
    for (var i = 0; i < 1000; i++) {
      entity = world.createEntity();
      world
        ..upsertComponent<int>(entity, 0)
        ..upsertComponent<String>(entity, 'string')
        ..upsertComponent<num>(entity, 1)
        ..upsertComponent<bool>(entity, true)
        ..upsertComponent<Symbol>(entity, #symbol);
    }
    if (entity == null) throw StateError('Incorrect entity id: $entity');
  }
}

// --- Get all entities --- //

class _GetEntities$Oxygen$Benchmark extends BenchmarkBase {
  _GetEntities$Oxygen$Benchmark() : super('GetEntities#Oxygen');

  late oxygen.World world;

  @override
  void setup() {
    super.setup();
    world = oxygen.World();
    for (var i = 0; i < 10; i++) world.createEntity();
  }

  @override
  void run() {
    final entities = world.entities;
    if (entities.length != 10)
      throw StateError('Incorrect entities length: ${entities.length}');
  }
}

class _GetEntities$Mess$Benchmark extends BenchmarkBase {
  _GetEntities$Mess$Benchmark() : super('GetEntities#Mess');

  late mess.Mess world;

  @override
  void setup() {
    super.setup();
    world = mess.Mess.pools([]);
    for (var i = 0; i < 10; i++) world.createEntity();
  }

  @override
  void run() {
    final entities = world.entities();
    if (entities.length != 10)
      throw StateError('Incorrect entities length: ${entities.length}');
  }

  @override
  void teardown() {
    super.teardown();
    world.dispose();
  }
}

// --- Remove entity --- //

class _RemoveEntity$Oxygen$Benchmark extends BenchmarkBase {
  _RemoveEntity$Oxygen$Benchmark() : super('RemoveEntity#Oxygen');

  late oxygen.World world;

  @override
  void setup() {
    super.setup();
    world = oxygen.World()
      ..registerComponent<oxygen.ValueComponent<int>, int>(
          oxygen.ValueComponent<int>.new)
      ..registerComponent<oxygen.ValueComponent<String>, String>(
          oxygen.ValueComponent<String>.new)
      ..registerComponent<oxygen.ValueComponent<num>, num>(
          oxygen.ValueComponent<num>.new)
      ..registerComponent<oxygen.ValueComponent<bool>, bool>(
          oxygen.ValueComponent<bool>.new)
      ..registerComponent<oxygen.ValueComponent<Symbol>, Symbol>(
          oxygen.ValueComponent<Symbol>.new);
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      world.createEntity()
        ..add<oxygen.ValueComponent<int>, int>(i)
        ..add<oxygen.ValueComponent<String>, String>('string')
        ..add<oxygen.ValueComponent<num>, num>(i)
        ..add<oxygen.ValueComponent<bool>, bool>(true)
        ..add<oxygen.ValueComponent<Symbol>, Symbol>(#symbol)
        ..dispose();
    }
    world.entityManager.processRemovedEntities();
  }

  @override
  void teardown() {
    super.teardown();
    if (world.entities.isNotEmpty)
      throw StateError('We should have no entities left');
  }
}

class _RemoveEntity$Mess$Benchmark extends BenchmarkBase {
  _RemoveEntity$Mess$Benchmark() : super('RemoveEntity#Mess');

  late mess.Mess world;

  @override
  void setup() {
    super.setup();
    world = (mess.PoolRegistry()
          ..register<int>()
          ..register<String>()
          ..register<num>()
          ..register<bool>()
          ..register<Symbol>())
        .createMess();
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      final entity = world.createEntity();
      world
        ..upsertComponent<int>(entity, i)
        ..upsertComponent<String>(entity, 'string')
        ..upsertComponent<num>(entity, i)
        ..upsertComponent<bool>(entity, true)
        ..upsertComponent<Symbol>(entity, #symbol)
        ..destroyEntity(entity);
    }
  }

  @override
  void teardown() {
    super.teardown();
    if (world.entitiesCount != 0)
      throw StateError('We should have no entities left');
    world.dispose();
  }
}

// --- Get component --- //

class _GetComponent$Oxygen$Benchmark extends BenchmarkBase {
  _GetComponent$Oxygen$Benchmark() : super('GetComponent#Oxygen');

  late oxygen.World world;
  final queue = Queue<oxygen.Entity>();

  @override
  void setup() {
    super.setup();
    world = oxygen.World()
      ..registerComponent<oxygen.ValueComponent<int>, int>(
          oxygen.ValueComponent<int>.new)
      ..registerComponent<oxygen.ValueComponent<String>, String>(
          oxygen.ValueComponent<String>.new)
      ..registerComponent<oxygen.ValueComponent<num>, num>(
          oxygen.ValueComponent<num>.new)
      ..registerComponent<oxygen.ValueComponent<bool>, bool>(
          oxygen.ValueComponent<bool>.new);
    for (var i = 0; i < 100; i++)
      queue.add(world.createEntity()
        ..add<oxygen.ValueComponent<int>, int>(0)
        ..add<oxygen.ValueComponent<String>, String>('string')
        ..add<oxygen.ValueComponent<num>, num>(1)
        ..add<oxygen.ValueComponent<bool>, bool>(true));
  }

  @override
  void run() {
    for (final e in queue) {
      final intValue = e.get<oxygen.ValueComponent<int>>()!.value!;
      final stringValue = e.get<oxygen.ValueComponent<String>>()!.value!;
      final numValue = e.get<oxygen.ValueComponent<num>>()!.value!;
      final boolValue = e.get<oxygen.ValueComponent<bool>>()!.value!;
      if (intValue != 0 ||
          stringValue != 'string' ||
          numValue != 1 ||
          boolValue != true) throw StateError('Incorrect component value');
    }
  }
}

class _GetComponent$Mess$Benchmark extends BenchmarkBase {
  _GetComponent$Mess$Benchmark() : super('GetComponent#Mess');

  late mess.Mess world;
  final queue = Queue<int>();

  @override
  void setup() {
    super.setup();
    world = (mess.PoolRegistry()
          ..register<int>()
          ..register<String>()
          ..register<num>()
          ..register<bool>())
        .createMess();
    for (var i = 0; i < 100; i++) {
      final entity = world.createEntity();
      world
        ..upsertComponent<int>(entity, 0)
        ..upsertComponent<String>(entity, 'string')
        ..upsertComponent<num>(entity, 1)
        ..upsertComponent<bool>(entity, true);
      queue.add(entity);
    }
  }

  @override
  void run() {
    for (final e in queue) {
      final intValue = world.getComponent<int>(e);
      final stringValue = world.getComponent<String>(e);
      final numValue = world.getComponent<num>(e);
      final boolValue = world.getComponent<bool>(e);
      if (intValue != 0 ||
          stringValue != 'string' ||
          numValue != 1 ||
          boolValue != true) throw StateError('Incorrect component value');
    }
  }

  @override
  void teardown() {
    super.teardown();
    world.dispose();
  }
}
