import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/reminder_platform.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/domain/reminder.dart';

class FakeReminderPlatform implements ReminderPlatform {
  int syncs = 0, requests = 0;
  bool fail = false, allowed = false;
  Map<String, Object?>? open;
  void Function()? callback;
  @override
  Future<ReminderStatus> sync() async {
    syncs++;
    if (fail) throw StateError('Native failure');
    return ReminderStatus(notifications: allowed, exact: false);
  }

  @override
  Future<ReminderStatus> requestPermission() async {
    requests++;
    return ReminderStatus(notifications: allowed);
  }

  @override
  Future<void> openSettings({bool exact = false}) async {}
  @override
  Future<Map<String, Object?>?> takeOpenRequest() async {
    final value = open;
    open = null;
    return value;
  }

  @override
  void onOpen(void Function() callback) {
    this.callback = callback;
  }
}

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late Directory temp;
  final day = Day.parse('2026-11-06');
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('reminders-');
    store = await AppStore.open(
      factory: databaseFactoryFfi,
      path: '${temp.path}/app.db',
    );
    await store.saveHabit(
      Habit(id: 'h', title: 'Read', kind: HabitKind.check, startDay: day),
      create: true,
    );
  });
  tearDown(() async {
    await store.close();
    await temp.delete(recursive: true);
  });
  test(
    'multiple times persist sorted and disabling preserves config with revision',
    () async {
      await store.saveReminder(
        HabitReminder(habitId: 'h', enabled: true, minutes: [1200, 480]),
      );
      var r = (await store.reminders()).single;
      expect(r.minutes, [480, 1200]);
      expect(r.revision, 0);
      await store.saveReminder(
        HabitReminder(habitId: 'h', enabled: false, minutes: r.minutes),
      );
      await store.close();
      store = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${temp.path}/app.db',
      );
      r = (await store.reminders()).single;
      expect(r.enabled, isFalse);
      expect(r.minutes, [480, 1200]);
      expect(r.revision, 1);
    },
  );
  test('invalid or missing habit reminder cannot be saved', () async {
    for (final times in <List<int>>[
      [],
      [-1],
      [1440],
      [540, 540],
      [1, 2, 3, 4, 5, 6],
    ]) {
      await expectLater(
        store.saveReminder(
          HabitReminder(habitId: 'h', enabled: true, minutes: times),
        ),
        throwsArgumentError,
      );
    }
    await expectLater(
      store.saveReminder(
        HabitReminder(habitId: 'missing', enabled: true, minutes: [540]),
      ),
      throwsStateError,
    );
    expect(await store.reminders(), isEmpty);
  });
  test(
    'archive preserves reminder settings, deleting habit cascades reminders',
    () async {
      await store.saveReminder(
        HabitReminder(habitId: 'h', enabled: true, minutes: [540]),
      );
      await store.setArchived('h', true);
      expect((await store.reminders()).single.enabled, isTrue);
      await store.remove('habits', 'h');
      expect(await store.reminders(), isEmpty);
    },
  );
  test(
    'schema2 backup imports with empty reminders, rollback recovers schema3 config',
    () async {
      await store.saveReminder(
        HabitReminder(habitId: 'h', enabled: true, minutes: [540, 1200]),
      );
      final full = await store.exportSnapshot();
      final e = jsonDecode(utf8.decode(full.encode())) as Map<String, dynamic>;
      final payload =
          jsonDecode(e['payload'] as String) as Map<String, dynamic>;
      payload['schema'] = 2;
      (payload['tables'] as Map).remove('habit_breaks');
      for (final h in payload['tables']['habits'] as List) {
        (h as Map).remove('color');
        h.remove('frame');
      }
      (payload['tables'] as Map).remove('cards');
      (payload['tables'] as Map).remove('habit_activity');
      (payload['tables'] as Map).remove('reminders');
      (payload['tables'] as Map).remove('task_entries');
      for (final row in payload['tables']['tasks'] as List) {
        (row as Map).removeWhere(
          (k, v) => {'resident', 'start_day', 'archived'}.contains(k),
        );
      }
      e['payload'] = jsonEncode(payload);
      e['sha256'] = sha256
          .convert(utf8.encode(e['payload'] as String))
          .toString();
      final old = BackupSnapshot.decode(utf8.encode(jsonEncode(e)));
      expect(old.count('reminders'), 0);
      await store.restoreSnapshot(old);
      expect(await store.reminders(), isEmpty);
      await store.restoreSnapshot(
        (await store.recoverySnapshot())!,
        rollback: true,
      );
      expect((await store.reminders()).single.minutes, [540, 1200]);
    },
  );
  test(
    'schema3 backup validates reminder references and time payloads',
    () async {
      await store.saveReminder(
        HabitReminder(habitId: 'h', enabled: true, minutes: [540]),
      );
      final full = await store.exportSnapshot();
      expect(BackupSnapshot.decode(full.encode()).count('reminders'), 1);
      for (final mutate in <void Function(Map)>[
        (m) => m['habit_id'] = 'missing',
        (m) => m['minutes'] = '[1440]',
        (m) => m['minutes'] = '[1,1]',
        (m) => m['enabled'] = 3,
        (m) => m['revision'] = -1,
      ]) {
        final e =
            jsonDecode(utf8.decode(full.encode())) as Map<String, dynamic>;
        final p = jsonDecode(e['payload'] as String) as Map<String, dynamic>;
        mutate(p['tables']['reminders'][0] as Map);
        e['payload'] = jsonEncode(p);
        e['sha256'] = sha256
            .convert(utf8.encode(e['payload'] as String))
            .toString();
        expect(
          () => BackupSnapshot.decode(utf8.encode(jsonEncode(e))),
          throwsA(isA<BackupInvalid>()),
        );
      }
    },
  );
  test(
    'scheduling failure is separate from committed user data, next sync recovers',
    () async {
      final platform = FakeReminderPlatform()..fail = true;
      final app = AppController(store, reminderPlatform: platform);
      await app.load();
      expect(
        await app.run(
          () => store.saveReminder(
            HabitReminder(habitId: 'h', enabled: true, minutes: [540]),
          ),
        ),
        isTrue,
      );
      expect(app.reminderSyncFailed, isTrue);
      expect(app.reminders.single.enabled, isTrue);
      expect(app.error, isNull);
      platform.fail = false;
      await app.syncReminders();
      expect(app.reminderSyncFailed, isFalse);
      app.dispose();
    },
  );
  test(
    'completion, deletion and restore all synchronize the native scheduler',
    () async {
      final platform = FakeReminderPlatform();
      final app = AppController(store, reminderPlatform: platform);
      await app.load();
      await app.run(() => store.setRecord('h', day, 1000, today: day));
      expect(platform.syncs, 1);
      final backup = await store.exportSnapshot();
      await app.run(() => store.remove('habits', 'h'));
      expect(platform.syncs, 2);
      await app.run(() => store.restoreSnapshot(backup));
      expect(platform.syncs, 3);
      app.dispose();
    },
  );
}
