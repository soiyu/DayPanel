import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/domain/models.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late Directory dir;
  final today = Day.parse('2026-11-05');
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('daypanel-backup-');
    store = await AppStore.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/data.db',
    );
    await store.saveGroup(const HabitGroup(id: 'g', name: '健康'), create: true);
    await store.saveHabit(
      Habit(
        id: 'h',
        title: '喝水',
        kind: HabitKind.quantity,
        startDay: today,
        unit: 'ml',
        target: 2000000,
        groupId: 'g',
      ),
      create: true,
    );
    await store.setRecord('h', today, 250001, today: today);
    await store.saveTask(
      SmallTask(id: 't', title: 'Return book', dueDay: today),
      create: true,
    );
    await store.saveNote(
      Note(id: 'n', body: '今天的小事 🌤', day: today),
      create: true,
    );
    await store.preference('locale', 'zh');
  });
  tearDown(() async {
    await store.close();
    await dir.delete(recursive: true);
  });
  test(
    'full round trip is Unicode-safe, previews counts and survives reopen',
    () async {
      final snapshot = await store.exportSnapshot();
      final decoded = BackupSnapshot.decode(snapshot.encode());
      expect(decoded.count('habits'), 1);
      expect(decoded.count('entries'), 1);
      expect(decoded.count('notes'), 1);
      await store.remove('notes', 'n');
      await store.completeTask('t', true, today);
      await store.restoreSnapshot(decoded);
      expect(await store.generation(), 1);
      expect((await store.exportSnapshot()).tables, decoded.tables);
      await store.close();
      store = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/data.db',
      );
      expect((await store.notes()).single.body, '今天的小事 🌤');
      expect((await store.tasks()).single.done, isFalse);
      final previous = await store.recoverySnapshot();
      expect(previous!.count('notes'), 0);
      await store.restoreSnapshot(previous, rollback: true);
      expect(await store.notes(), isEmpty);
      expect((await store.tasks()).single.done, isTrue);
      expect(await store.recoverySnapshot(), isNull);
      expect(await store.generation(), 2);
    },
  );
  for (final phase in ['cleared', 'inserted', 'before_commit']) {
    test(
      'restore failure at $phase rolls back data, recovery and generation',
      () async {
        final snapshot = await store.exportSnapshot();
        await store.saveNote(
          Note(id: 'new', body: 'Keep me', day: today),
          create: true,
        );
        final before = await store.exportSnapshot();
        await expectLater(
          store.restoreSnapshot(
            snapshot,
            fault: (step) async {
              if (step == phase) throw StateError('Injected');
            },
          ),
          throwsStateError,
        );
        expect((await store.exportSnapshot()).tables, before.tables);
        expect(await store.generation(), 0);
        expect(await store.recoverySnapshot(), isNull);
        await store.close();
        store = await AppStore.open(
          factory: databaseFactoryFfi,
          path: '${dir.path}/data.db',
        );
        expect((await store.exportSnapshot()).tables, before.tables);
      },
    );
  }
  test(
    'corrupt/truncated/unknown backup is rejected before touching current data',
    () async {
      final snapshot = await store.exportSnapshot();
      final bytes = snapshot.encode();
      for (final invalid in [
        bytes.sublist(0, bytes.length - 1),
        utf8.encode('{}'),
        List<int>.filled(BackupSnapshot.maxBytes + 1, 0),
      ]) {
        expect(
          () => BackupSnapshot.decode(invalid),
          throwsA(isA<BackupInvalid>()),
        );
      }
      final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      envelope['version'] = 999;
      expect(
        () => BackupSnapshot.decode(utf8.encode(jsonEncode(envelope))),
        throwsA(isA<BackupInvalid>()),
      );
      envelope['version'] = 1;
      envelope['sha256'] = 'bad';
      expect(
        () => BackupSnapshot.decode(utf8.encode(jsonEncode(envelope))),
        throwsA(isA<BackupInvalid>()),
      );
      expect((await store.exportSnapshot()).tables, snapshot.tables);
    },
  );
  test(
    'correct checksum cannot bypass dates, duplicate keys, unknown fields or references',
    () async {
      final snapshot = await store.exportSnapshot();
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (c) => c['tables']['entries'][0]['habit_id'] = 'missing',
        (c) => c['tables']['entries'][0]['day'] = '2026-02-30',
        (c) => c['tables']['entries'].add(c['tables']['entries'][0]),
        (c) => c['tables']['plans'].clear(),
        (c) => c['tables']['habits'][0]['group_id'] = 'missing',
        (c) => c['tables']['settings'][0]['key'] = 'purchased',
        (c) => c['tables']['habits'][0]['script'] = 'anything',
      ]) {
        final e =
            jsonDecode(utf8.decode(snapshot.encode())) as Map<String, dynamic>;
        final c = jsonDecode(e['payload'] as String) as Map<String, dynamic>;
        mutate(c);
        e['payload'] = jsonEncode(c);
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
    'stale editor command cannot write across restored generation',
    () async {
      final app = AppController(store, clock: () => today.date);
      await app.load();
      final old = app.generation;
      final snapshot = await store.exportSnapshot();
      await app.run(() => store.restoreSnapshot(snapshot));
      var called = false;
      expect(
        await app.run(() async {
          called = true;
        }, expectedGeneration: old),
        isFalse,
      );
      expect(called, isFalse);
      app.dispose();
    },
  );
  test(
    'out-of-band restore invalidates cached data before another write',
    () async {
      final app = AppController(store, clock: () => today.date);
      await app.load();
      final snapshot = await store.exportSnapshot();
      await store.restoreSnapshot(snapshot);
      var wrote = false;
      expect(
        await app.run(() async {
          wrote = true;
        }),
        isFalse,
      );
      expect(wrote, isFalse);
      expect(app.generation, await store.generation());
      app.dispose();
    },
  );
}
