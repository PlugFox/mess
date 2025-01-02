import 'dart:collection';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:mess/mess.dart' as mess;
import 'package:oxygen/oxygen.dart' as oxygen;

/*
Create 100 entities:
Benchmark CreateEntity#Mess: 1297.43 us
Benchmark CreateEntity#Oxygen: 1819.29 us

Create and remove 100 entity:
Benchmark RemoveEntity#Mess: 126.60 us
Benchmark RemoveEntity#Oxygen: 1504.43 us

Get components for 100 entities:
Benchmark GetComponent#Mess: 36.71 us
Benchmark GetComponent#Oxygen: 52.67 us
*/
void main() {
  final buffer = StringBuffer();

  void dvd(String title) => buffer
    ..writeln()
    ..writeln(title);

  void measure(List<BenchmarkBase> benchmarks) => (benchmarks
          .map<({String name, double us})>(_measure)
          .toList(growable: false)
        ..sort((a, b) => a.us.compareTo(b.us)))
      .map<String>((e) => 'Benchmark ${e.name}: ${e.us.toStringAsFixed(2)} us')
      .forEach(buffer.writeln);

  dvd('Create 100 entities:');
  measure(<BenchmarkBase>[
    _CreateEntity$Oxygen$Benchmark(),
    _CreateEntity$Mess$Benchmark(),
  ]);

  /* dvd('Retrieve all entities:');
  measure(<BenchmarkBase>[
    _GetEntities$Oxygen$Benchmark(),
    _GetEntities$Mess$Benchmark(),
  ]); */

  dvd('Create and remove 100 entity:');
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

// --- Create entity --- //

class _CreateEntity$Oxygen$Benchmark extends BenchmarkBase {
  _CreateEntity$Oxygen$Benchmark() : super('CreateEntity#Oxygen');

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
    oxygen.Entity? entity;
    for (var i = 0; i < 100; i++)
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
    mess.Entity? entity;
    for (var i = 0; i < 100; i++)
      entity = world.createEntity()
        ..upsert<int>(0)
        ..upsert<String>('string')
        ..upsert<num>(1)
        ..upsert<bool>(true)
        ..upsert<Symbol>(#symbol);
    if (entity?.id == null)
      throw StateError('Incorrect entity id: ${entity?.id}');
  }

  @override
  void teardown() {
    super.teardown();
    world.dispose();
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
          oxygen.ValueComponent<bool>.new)
      ..registerComponent<oxygen.ValueComponent<Symbol>, Symbol>(
          oxygen.ValueComponent<Symbol>.new);
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++)
      queue.add(world.createEntity()
        ..add<oxygen.ValueComponent<int>, int>(i)
        ..add<oxygen.ValueComponent<String>, String>('string')
        ..add<oxygen.ValueComponent<num>, num>(i)
        ..add<oxygen.ValueComponent<bool>, bool>(true)
        ..add<oxygen.ValueComponent<Symbol>, Symbol>(#symbol));
    for (var i = 0; i < 100; i++)
      world.entityManager.removeEntity(queue.removeLast());
    world.entityManager.processRemovedEntities();
  }

  @override
  void teardown() {
    super.teardown();
    if (queue.isNotEmpty) throw StateError('We should have no entities left');
  }
}

class _RemoveEntity$Mess$Benchmark extends BenchmarkBase {
  _RemoveEntity$Mess$Benchmark() : super('RemoveEntity#Mess');

  late mess.Mess world;
  final queue = Queue<mess.Entity>();

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
    for (var i = 0; i < 100; i++)
      queue.add(world.createEntity()
        ..upsert<int>(i)
        ..upsert<String>('string')
        ..upsert<num>(i)
        ..upsert<bool>(true)
        ..upsert<Symbol>(#symbol));
    for (var i = 0; i < 100; i++) world.destroyEntity(queue.removeLast());
  }

  @override
  void teardown() {
    super.teardown();
    if (queue.isNotEmpty) throw StateError('We should have no entities left');
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
  final queue = Queue<mess.Entity>();

  @override
  void setup() {
    super.setup();
    world = (mess.PoolRegistry()
          ..register<int>()
          ..register<String>()
          ..register<num>()
          ..register<bool>())
        .createMess();
    for (var i = 0; i < 100; i++)
      queue.add(world.createEntity()
        ..upsert<int>(0)
        ..upsert<String>('string')
        ..upsert<num>(1)
        ..upsert<bool>(true));
  }

  @override
  void run() {
    for (final e in queue) {
      final intValue = e.get<int>();
      final stringValue = e.get<String>();
      final numValue = e.get<num>();
      final boolValue = e.get<bool>();
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
