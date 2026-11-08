import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/completion_feedback.dart';
import 'package:daypanel/domain/achievement.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/domain/models.dart';

class FakeFeedback implements CompletionFeedback {
  final calls = <(bool, bool)>[];
  bool fail = false;
  @override
  Future<void> play({required bool sound, required bool haptics}) async {
    calls.add((sound, haptics));
    if (fail) throw StateError('Platform unavailable');
  }
}

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late Directory dir;
  final today = Day.parse('2026-11-06');
  Habit habit(
    String id, {
    HabitKind kind = HabitKind.check,
    ScheduleKind schedule = ScheduleKind.weekdays,
    int weekdays = 127,
    int target = 1000,
  }) => Habit(
    id: id,
    title: 'Habit $id',
    kind: kind,
    startDay: today.plus(-20),
    schedule: schedule,
    weekdays: weekdays,
    target: target,
    unit: kind == HabitKind.quantity ? 'ml' : '',
  );
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('daypanel-cards-');
    store = await AppStore.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/data.db',
    );
  });
  tearDown(() async {
    await store.close();
    await dir.delete(recursive: true);
  });
  Future<void> earn() async {
    await store.saveHabit(habit('a'), create: true);
    await store.setRecord('a', today, 1000, today: today);
  }

  List<int> alter(BackupSnapshot snap, void Function(Map) change) {
    final e = jsonDecode(utf8.decode(snap.encode())) as Map;
    final p = jsonDecode(e['payload'] as String) as Map;
    change(p);
    e['payload'] = jsonEncode(p);
    e['sha256'] = sha256
        .convert(utf8.encode(e['payload'] as String))
        .toString();
    return utf8.encode(jsonEncode(e));
  }

  test(
    'nonempty daily obligations require all explicit values, excluding weekly and non-scheduled habits',
    () {
      final a = habit('a');
      final b = habit('b', kind: HabitKind.quantity, target: 2000000);
      final weekly = habit('w', schedule: ScheduleKind.weekly);
      final saturday = habit('s', weekdays: 32);
      final archived = Habit.fromMap({...habit('x').toMap(), 'archived': 1});
      final habits = [a, b, weekly, saturday, archived];
      final plans = habits
          .map((h) => HabitPlan.fromHabit(h, h.startDay))
          .toList();
      expect(completedCardEvidence(today, [], [], []), isNull);
      expect(completedCardEvidence(today, [weekly], plans, []), isNull);
      final entries = [
        HabitEntry(habitId: 'a', day: today, value: 1000),
        HabitEntry(habitId: 'b', day: today, value: 1999999),
      ];
      expect(completedCardEvidence(today, habits, plans, entries), isNull);
      entries[1] = HabitEntry(habitId: 'b', day: today, value: 2000000);
      expect(
        completedCardEvidence(today, habits, plans, entries)!.map((h) => h.id),
        ['a', 'b'],
      );
      expect(
        completedCardEvidence(today.plus(-1), habits, plans, entries),
        isNull,
      );
    },
  );
  test(
    'last daily completion earns exactly once independent of group filters',
    () async {
      await store.saveHabit(habit('a'), create: true);
      await store.saveHabit(habit('b'), create: true);
      await store.setRecord('a', today, 1000, today: today);
      expect(await store.cards(), isEmpty);
      await expectLater(store.claimCard(today, today: today), throwsStateError);
      await store.setRecord('b', today, 1000, today: today);
      await store.setRecord('b', today, 1000, today: today);
      await store.claimCard(today, today: today);
      final card = (await store.cards()).single;
      expect(card.day, today);
      expect(card.evidence.length, 2);
      expect(card.artwork, AchievementCard.artworkFor(today));
    },
  );
  test(
    'current version decides quantity and tomorrow edits do not change snapshot',
    () async {
      final h = habit('q', kind: HabitKind.quantity, target: 2000000);
      await store.saveHabit(h, create: true);
      await store.saveHabit(
        Habit.fromMap({...h.toMap(), 'target': 1000000, 'unit': 'cups'}),
        today: today,
      );
      await store.setRecord('q', today, 1000000, today: today);
      expect(await store.cards(), isEmpty);
      await store.setRecord('q', today, 2000000, today: today);
      expect((await store.cards()).single.evidence.single.unit, 'ml');
      await store.setRecord('q', today.plus(1), 1000000, today: today.plus(1));
      expect((await store.cards()).first.evidence.single.unit, 'cups');
      expect((await store.cards()).length, 2);
    },
  );
  test(
    'undo rename archive delete and added obligation keep earned snapshot and reflection',
    () async {
      await earn();
      await store.favoriteCard(today, true);
      await store.reflectOnCard(today, 'Keep this moment 🌱');
      final before = (await store.cards()).single.toMap();
      await store.setRecord('a', today, null, today: today);
      await store.saveHabit(
        Habit.fromMap({...habit('a').toMap(), 'title': 'Renamed'}),
        today: today,
      );
      await store.setArchived('a', true);
      await store.remove('habits', 'a');
      await store.saveHabit(habit('b'), create: true);
      expect((await store.cards()).single.toMap(), before);
      final snapshot = await store.exportSnapshot();
      expect(BackupSnapshot.decode(snapshot.encode()).count('cards'), 1);
      expect((await store.cards()).single.evidence.single.title, 'Habit a');
    },
  );
  test(
    'archive delete restore and historical completion never issue a card automatically',
    () async {
      await store.saveHabit(habit('a'), create: true);
      await store.saveHabit(habit('b'), create: true);
      await store.setRecord('a', today, 1000, today: today);
      await store.setArchived('b', true);
      expect(await store.cards(), isEmpty);
      await store.remove('habits', 'b');
      expect(await store.cards(), isEmpty);
      final snapshot = await store.exportSnapshot();
      await store.restoreSnapshot(snapshot);
      expect(await store.cards(), isEmpty);
      await store.setRecord('a', today.plus(-1), 1000, today: today);
      expect(await store.cards(), isEmpty);
      await store.claimCard(today, today: today);
      expect((await store.cards()).single.evidence.length, 1);
      await expectLater(
        store.claimCard(today, today: today.plus(1)),
        throwsArgumentError,
      );
    },
  );
  test('empty days and weekly-only completion cannot earn cards', () async {
    await expectLater(store.claimCard(today, today: today), throwsStateError);
    await store.saveHabit(
      habit('w', schedule: ScheduleKind.weekly),
      create: true,
    );
    await store.setRecord('w', today, 1000, today: today);
    expect(await store.cards(), isEmpty);
    await expectLater(store.claimCard(today, today: today), throwsStateError);
  });
  test('record and card insertion commit atomically or both roll back', () async {
    await store.saveHabit(habit('a'), create: true);
    await store.db.execute(
      "CREATE TRIGGER reject_card BEFORE INSERT ON cards BEGIN SELECT RAISE(ABORT, 'Injected failure'); END",
    );
    await expectLater(
      store.setRecord('a', today, 1000, today: today),
      throwsA(isA<DatabaseException>()),
    );
    expect(await store.entries(), isEmpty);
    expect(await store.cards(), isEmpty);
    await store.db.execute('DROP TRIGGER reject_card');
    await store.setRecord('a', today, 1000, today: today);
    expect((await store.entries()).single.value, 1000);
    expect((await store.cards()).length, 1);
  });
  test(
    'favorite and reflection are explicit persistent fields and empty text clears',
    () async {
      await earn();
      await store.favoriteCard(today, true);
      await store.favoriteCard(today, true);
      await store.reflectOnCard(today, 'A small thing');
      await store.close();
      store = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/data.db',
      );
      expect((await store.cards()).single.favorite, isTrue);
      expect((await store.cards()).single.reflection, 'A small thing');
      await store.reflectOnCard(today, '');
      await store.favoriteCard(today, false);
      expect((await store.cards()).single.reflection, isEmpty);
      expect((await store.cards()).single.favorite, isFalse);
      await expectLater(
        store.reflectOnCard(today, 'x' * 10001),
        throwsArgumentError,
      );
      await expectLater(
        store.favoriteCard(today.plus(1), true),
        throwsStateError,
      );
    },
  );
  test(
    'v5 migration preserves all completed data without inventing cards',
    () async {
      await earn();
      await store.saveNote(
        Note(id: 'n', body: 'Keep', day: today, habitId: 'a'),
        create: true,
        today: today,
      );
      await store.db.execute('DROP TABLE cards');
      await store.db.execute('DROP TABLE habit_activity');
      await store.db.execute('ALTER TABLE habits DROP COLUMN color');
      await store.db.execute('ALTER TABLE habits DROP COLUMN frame');
      await store.db.execute('DROP TABLE habit_breaks');
      await store.db.setVersion(5);
      await store.close();
      store = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/data.db',
      );
      expect(await store.db.getVersion(), 11);
      expect(await store.cards(), isEmpty);
      expect((await store.entries()).single.value, 1000);
      expect((await store.notes()).single.habitId, 'a');
      await store.claimCard(today, today: today);
      expect((await store.cards()).length, 1);
    },
  );
  test(
    'backup restores cards settings and preserved deleted-habit snapshots with rollback',
    () async {
      await earn();
      await store.reflectOnCard(today, 'Backup reflection');
      await store.favoriteCard(today, true);
      await store.preference('completion_sound', 'on');
      await store.preference('completion_haptics', 'off');
      await store.remove('habits', 'a');
      final snapshot = await store.exportSnapshot();
      await store.reflectOnCard(today, 'Newer reflection');
      await store.restoreSnapshot(BackupSnapshot.decode(snapshot.encode()));
      expect((await store.cards()).single.reflection, 'Backup reflection');
      expect((await store.cards()).single.favorite, isTrue);
      expect(await store.habits(), isEmpty);
      expect((await store.settings())['completion_sound'], 'on');
      await store.restoreSnapshot(
        (await store.recoverySnapshot())!,
        rollback: true,
      );
      expect((await store.cards()).single.reflection, 'Newer reflection');
    },
  );
  for (final phase in ['cleared', 'inserted', 'before_commit']) {
    test(
      'card restore rollback at $phase preserves snapshot reflection and favorite',
      () async {
        await earn();
        final snapshot = await store.exportSnapshot();
        await store.reflectOnCard(today, 'Before interruption');
        await store.favoriteCard(today, true);
        final before = (await store.cards()).single.toMap();
        await expectLater(
          store.restoreSnapshot(
            snapshot,
            fault: (step) async {
              if (step == phase) throw StateError('Injected');
            },
          ),
          throwsStateError,
        );
        expect((await store.cards()).single.toMap(), before);
        expect(await store.generation(), 0);
      },
    );
  }
  for (final schema in [2, 3, 4, 5]) {
    test(
      'schema$schema backup and recovery copy import without historical cards',
      () async {
        await earn();
        await store.saveNote(
          Note(id: 'n', body: 'Old note', day: today),
          create: true,
          today: today,
        );
        final snapshot = await store.exportSnapshot();
        final old = alter(snapshot, (p) {
          p['schema'] = schema;
          (p['tables'] as Map).remove('habit_breaks');
          for (final h in p['tables']['habits'] as List) {
            (h as Map).remove('color');
            h.remove('frame');
          }
          (p['tables'] as Map).remove('cards');
          (p['tables'] as Map).remove('habit_activity');
          if (schema < 5) {
            for (final note in p['tables']['notes'] as List) {
              (note as Map).remove('habit_id');
            }
          }
          if (schema < 4) (p['tables'] as Map).remove('task_entries');
          if (schema < 3) (p['tables'] as Map).remove('reminders');
        });
        await store.restoreSnapshot(BackupSnapshot.decode(old));
        expect(await store.cards(), isEmpty);
        expect((await store.notes()).single.body, 'Old note');
        await store.restoreSnapshot(
          (await store.recoverySnapshot())!,
          rollback: true,
        );
        expect((await store.cards()).length, 1);
        await store.db.insert('recovery', {
          'id': 1,
          'snapshot': utf8.decode(old),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        await store.restoreSnapshot(
          (await store.recoverySnapshot())!,
          rollback: true,
        );
        expect(await store.cards(), isEmpty);
      },
    );
  }
  test(
    'tampered card fields artwork duplicate dates and evidence are strictly rejected',
    () async {
      await earn();
      final snapshot = await store.exportSnapshot();
      for (final edit in <void Function(Map)>[
        (m) => m['artwork'] = 9,
        (m) => m['favorite'] = true,
        (m) => m['reflection'] = 'x' * 10001,
        (m) => m['unexpected'] = 1,
        (m) => m.remove('evidence'),
        (m) => m['evidence'] = '[]',
        (m) => m['day'] = '2026-02-30',
        (m) {
          final e = jsonDecode(m['evidence'] as String) as List;
          e.add(e.first);
          m['evidence'] = jsonEncode(e);
        },
        (m) {
          final e = jsonDecode(m['evidence'] as String) as List;
          e.first['value'] = 0;
          m['evidence'] = jsonEncode(e);
        },
        (m) {
          final e = jsonDecode(m['evidence'] as String) as List;
          e.first['plan_day'] = '2027-01-01';
          m['evidence'] = jsonEncode(e);
        },
      ]) {
        expect(
          () => BackupSnapshot.decode(
            alter(snapshot, (p) => edit(p['tables']['cards'][0] as Map)),
          ),
          throwsA(isA<BackupInvalid>()),
        );
      }
      expect(
        () => BackupSnapshot.decode(
          alter(snapshot, (p) {
            final rows = p['tables']['cards'] as List;
            rows.add(rows.first);
          }),
        ),
        throwsA(isA<BackupInvalid>()),
      );
    },
  );
  test(
    'feedback requires saved transition today and enabled settings; failure never undoes data',
    () async {
      final feedback = FakeFeedback();
      final app = AppController(
        store,
        clock: () => today.date,
        completionFeedback: feedback,
      );
      final h = habit('a');
      await store.saveHabit(h, create: true);
      await app.load();
      expect(await app.recordHabit(h, today, 1000, app.generation), isTrue);
      expect(feedback.calls, isEmpty);
      await store.preference('completion_sound', 'on');
      await store.preference('completion_haptics', 'on');
      await app.load();
      await app.recordHabit(h, today, 1000, app.generation);
      await app.recordHabit(h, today.plus(-1), 1000, app.generation);
      expect(feedback.calls, isEmpty);
      await app.recordHabit(h, today, null, app.generation);
      await app.recordHabit(h, today, 1000, app.generation);
      expect(feedback.calls, [(true, true)]);
      await app.recordHabit(h, today, null, app.generation);
      feedback.fail = true;
      expect(await app.recordHabit(h, today, 1000, app.generation), isTrue);
      expect(app.feedbackFailed, isTrue);
      expect(app.value(h, today), 1000);
      expect(app.error, isNull);
      final epoch = app.generation;
      await app.run(
        () async => store.restoreSnapshot(await store.exportSnapshot()),
      );
      expect(
        await app.run(
          () => store.favoriteCard(today, true),
          expectedGeneration: epoch,
        ),
        isFalse,
      );
      expect(
        await app.run(
          () => store.reflectOnCard(today, 'Stale'),
          expectedGeneration: epoch,
        ),
        isFalse,
      );
      expect(await app.recordHabit(h, today, 1000, epoch), isFalse);
      expect(feedback.calls.length, 2);
      app.dispose();
    },
  );
}
