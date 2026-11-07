import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/appearance.dart';
import 'package:daypanel/domain/backup.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/presentation/theme.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late Directory dir;
  final day = Day.parse('2026-11-06');
  final h = Habit(id: 'h', title: 'Read', kind: HabitKind.check, startDay: day);
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('appearance-');
    store = await AppStore.open(
      factory: databaseFactoryFfi,
      path: '${dir.path}/data.db',
    );
    await store.saveHabit(h, create: true);
  });
  tearDown(() async {
    await store.close();
    await dir.delete(recursive: true);
  });
  List<int> change(BackupSnapshot snap, void Function(Map p) mutate) {
    final e = jsonDecode(utf8.decode(snap.encode())) as Map;
    final p = jsonDecode(e['payload'] as String) as Map;
    mutate(p);
    e['payload'] = jsonEncode(p);
    e['sha256'] = sha256
        .convert(utf8.encode(e['payload'] as String))
        .toString();
    return utf8.encode(jsonEncode(e));
  }

  test(
    'appearance defaults and unknown runtime preferences fall back safely',
    () {
      expect(
        Appearance.fromSettings({}).toSettings(),
        const Appearance().toSettings(),
      );
      expect(
        Appearance.fromSettings({
          'palette': 'invalid',
          'font': 'download',
          'icon_frame': 'bad',
        }).toSettings(),
        const Appearance().toSettings(),
      );
      expect(Appearance.validPreference('font', 'serif'), isTrue);
      expect(Appearance.validPreference('font', 'url'), isFalse);
      expect(habitIcons.length, Appearance.iconCount);
    },
  );
  test('appearance persistence is atomic and generation guarded', () async {
    final app = AppController(store);
    await app.load();
    final draft = const Appearance(
      palette: 'teal',
      font: 'serif',
      mode: 'dark',
      frame: 'ring',
    );
    expect(
      await app.run(() => store.saveAppearance(draft), expectedGeneration: 0),
      isTrue,
    );
    final snap = await store.exportSnapshot();
    await app.run(() => store.restoreSnapshot(snap));
    expect(
      await app.run(
        () => store.saveAppearance(const Appearance()),
        expectedGeneration: 0,
      ),
      isFalse,
    );
    expect(
      Appearance.fromSettings(await store.settings()).toSettings(),
      draft.toSettings(),
    );
    await expectLater(
      store.saveAppearance(const Appearance(font: 'invalid')),
      throwsArgumentError,
    );
    expect(Appearance.fromSettings(await store.settings()).font, 'serif');
    app.dispose();
  });
  test(
    'style-only habit editing preserves schedule records and earned card',
    () async {
      await store.setRecord('h', day, 1000, today: day);
      final plans = (await store.plans()).map((p) => p.toMap()).toList();
      final cards = (await store.cards()).map((c) => c.toMap()).toList();
      await store.saveHabit(
        Habit.fromMap({
          ...h.toMap(),
          'icon': 23,
          'color': 'rose',
          'frame': 'ring',
        }),
        today: day,
      );
      expect((await store.plans()).map((p) => p.toMap()).toList(), plans);
      expect((await store.cards()).map((c) => c.toMap()).toList(), cards);
      expect((await store.entries()).single.value, 1000);
      await store.close();
      store = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/data.db',
      );
      expect((await store.habits()).single.icon, 23);
      expect((await store.habits()).single.frame, 'ring');
    },
  );
  test(
    'all habit decorations validate and invalid inputs do not partially save',
    () async {
      for (var i = 0; i < Appearance.iconCount; i++) {
        await store.saveHabit(
          Habit.fromMap({
            ...h.toMap(),
            'icon': i,
            'color': Appearance.habitColors[i % 6],
            'frame': Appearance.habitFrames[i % 4],
          }),
        );
      }
      for (final update in [
        {'icon': 24},
        {'icon': -1},
        {'color': '#bad'},
        {'frame': 'invalid'},
      ]) {
        await expectLater(
          store.saveHabit(Habit.fromMap({...h.toMap(), ...update})),
          throwsArgumentError,
        );
      }
      expect((await store.habits()).single.icon, 23);
    },
  );
  test(
    'v7 migration preserves original fields and adds automatic decoration only',
    () async {
      await store.setRecord('h', day, 1000, today: day);
      await store.db.execute('ALTER TABLE habits DROP COLUMN color');
      await store.db.execute('ALTER TABLE habits DROP COLUMN frame');
      await store.db.execute('DROP TABLE habit_breaks');
      await store.db.setVersion(7);
      await store.close();
      store = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/data.db',
      );
      expect(await store.db.getVersion(), 10);
      expect((await store.habits()).single.toMap(), h.toMap());
      expect((await store.entries()).single.value, 1000);
      expect((await store.cards()).length, 1);
      expect(await store.settings(), isEmpty);
      expect(await store.db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    },
  );
  test(
    'schema8 strict backup contains appearance and rollback restores prior styles',
    () async {
      await store.saveAppearance(
        const Appearance(font: 'serif', palette: 'teal', frame: 'ring'),
      );
      await store.saveHabit(
        Habit.fromMap({
          ...h.toMap(),
          'icon': 23,
          'color': 'rose',
          'frame': 'plain',
        }),
      );
      final snap = await store.exportSnapshot();
      final payload = jsonDecode(
        jsonDecode(utf8.decode(snap.encode()))['payload'],
      );
      expect(payload['schema'], 10);
      await store.saveAppearance(const Appearance());
      await store.saveHabit(h);
      await store.restoreSnapshot(snap);
      expect((await store.habits()).single.icon, 23);
      expect(Appearance.fromSettings(await store.settings()).font, 'serif');
      await store.restoreSnapshot(
        (await store.recoverySnapshot())!,
        rollback: true,
      );
      expect((await store.habits()).single.icon, 0);
      expect(Appearance.fromSettings(await store.settings()).font, 'system');
      for (final mutation in <void Function(Map)>[
        (p) => p['tables']['habits'][0]['color'] = 'unknown',
        (p) => p['tables']['habits'][0]['frame'] = 'unknown',
        (p) => p['tables']['habits'][0]['icon'] = 24,
        (p) => (p['tables']['habits'][0] as Map).remove('color'),
        (p) => p['tables']['settings'][0]['value'] = 'unknown',
        (p) => p['tables']['settings'].add({'key': 'font', 'value': 'url'}),
      ]) {
        expect(
          () => BackupSnapshot.decode(change(snap, mutation)),
          throwsA(isA<BackupInvalid>()),
        );
      }
    },
  );
  for (final version in [2, 3, 4, 5, 6, 7]) {
    test(
      'schema$version restores default decoration and legacy recovery copy',
      () async {
        final snap = await store.exportSnapshot();
        final bytes = change(snap, (p) {
          p['schema'] = version;
          (p['tables'] as Map).remove('habit_breaks');
          for (final row in p['tables']['habits']) {
            (row as Map).remove('color');
            row.remove('frame');
          }
          if (version < 7) (p['tables'] as Map).remove('habit_activity');
          if (version < 6) (p['tables'] as Map).remove('cards');
          if (version < 4) (p['tables'] as Map).remove('task_entries');
          if (version < 3) (p['tables'] as Map).remove('reminders');
        });
        await store.restoreSnapshot(BackupSnapshot.decode(bytes));
        expect((await store.habits()).single.color, 'auto');
        expect(Appearance.fromSettings(await store.settings()).palette, 'blue');
        await store.db.insert('recovery', {
          'id': 1,
          'snapshot': utf8.decode(bytes),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        await store.restoreSnapshot(
          (await store.recoverySnapshot())!,
          rollback: true,
        );
        expect((await store.habits()).single.frame, 'auto');
      },
    );
  }
  test(
    'theme action and body text meet readable contrast across palettes and modes',
    () {
      double contrast(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return (x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05));
      }

      for (final p in Appearance.palettes) {
        for (final b in Brightness.values) {
          final t = dayPanelTheme(
            b,
            appearance: Appearance(palette: p, font: 'serif'),
          );
          final style = t.extension<DayPanelStyle>()!;
          expect(
            contrast(style.actionStart, Colors.white),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(style.actionEnd, Colors.white),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(t.colorScheme.onSurface, t.colorScheme.surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(t.textTheme.bodyMedium!.fontFamily, 'NotoSerifSC');
        }
      }
    },
  );
}
