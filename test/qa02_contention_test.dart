import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/domain/models.dart';

class _BusyBodyFailure extends DatabaseException {
  _BusyBodyFailure() : super('database is locked');
  @override
  int getResultCode() => 5;
  @override
  Object? get result => null;
}

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late AppStore first, second;
  final today = Day.parse('2026-11-10');
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('qa02-lock-');
    first = await AppStore.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/db',
    );
    second = await AppStore.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/db',
    );
    await first.db.execute('PRAGMA busy_timeout=0');
    await second.db.execute('PRAGMA busy_timeout=0');
    await first.saveHabit(
      Habit(id: 'h', title: 'Stretch', kind: HabitKind.check, startDay: today),
      create: true,
      today: today,
    );
  });
  tearDown(() async {
    await first.close();
    await second.close();
    await dir.delete(recursive: true);
  });
  test(
    'P01 cold load survives a short independent reader-writer reservation',
    () async {
      final app = AppController(second, clock: () => today.date);
      await first.db.execute('BEGIN IMMEDIATE');
      final load = app.load().then(
        (_) => true,
        onError: (Object error) => false,
      );
      await Future<void>.delayed(const Duration(milliseconds: 140));
      await first.db.execute('COMMIT');
      expect(
        await load,
        isTrue,
        reason:
            'A short native snapshot transaction must not strand startup on a storage-error screen',
      );
      expect(app.habits.single.id, 'h');
      expect(app.ready, isTrue);
      app.dispose();
    },
  );
  test('contended transaction starts its mutating body exactly once', () async {
    var runs = 0;
    await first.db.execute('BEGIN IMMEDIATE');
    final write = second
        .inGeneration(0, () async {
          runs++;
          await second.setRecord('h', today, 1000, today: today);
        })
        .then((_) => true, onError: (Object e) => false);
    await Future<void>.delayed(const Duration(milliseconds: 140));
    await first.db.execute('COMMIT');
    expect(await write, isTrue);
    expect(runs, 1);
    expect((await first.entries()).single.value, 1000);
  });
  test(
    'a persistent lock fails within a bound without executing any mutation',
    () async {
      var runs = 0;
      await first.db.execute('BEGIN IMMEDIATE');
      final timer = Stopwatch()..start();
      await expectLater(
        second.inGeneration(0, () async {
          runs++;
        }),
        throwsA(isA<DatabaseException>()),
      );
      expect(runs, 0);
      expect(timer.elapsed, lessThan(const Duration(seconds: 3)));
      await first.db.execute('ROLLBACK');
      expect((await second.habits()).single.id, 'h');
    },
  );
  test(
    'generation is checked after waiting for the transaction, not before',
    () async {
      var runs = 0;
      await first.db.execute('BEGIN IMMEDIATE');
      final pending = second
          .inGeneration(0, () async {
            runs++;
          })
          .then((_) => true, onError: (Object e) => false);
      await Future<void>.delayed(const Duration(milliseconds: 140));
      await first.db.rawUpdate('UPDATE runtime SET generation=1 WHERE id=1');
      await first.db.execute('COMMIT');
      expect(await pending, isFalse);
      expect(runs, 0);
      expect(await second.generation(), 1);
    },
  );
  test(
    'a transaction-body failure is not replayed even if it mentions database locked',
    () async {
      var runs = 0;
      await expectLater(
        second.inGeneration(0, () async {
          runs++;
          await second.setRecord('h', today, 1000, today: today);
          throw _BusyBodyFailure();
        }),
        throwsA(isA<_BusyBodyFailure>()),
      );
      expect(runs, 1);
      expect(await first.entries(), isEmpty);
    },
  );
}
