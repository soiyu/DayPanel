import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/main.dart';

void main() {
  sqfliteFfiInit();
  for (final language in ['en', 'zh']) {
    for (final large in [false, true]) {
      testWidgets(
        '$language first-screen actions remain visible large=$large',
        (t) async {
          final store = await AppStore.open(
            factory: databaseFactoryFfiNoIsolate,
            path: inMemoryDatabasePath,
          );
          final app = AppController(store, clock: () => DateTime(2026, 11, 7));
          await store.preference('locale', language);
          await store.preference('theme', large ? 'dark' : 'light');
          for (var i = 0; i < 4; i++) {
            await store.saveHabit(
              Habit(
                id: 'h$i',
                title: language == 'zh'
                    ? ['阅读', '喝水', '散步', '拉伸'][i]
                    : [
                        'Read a page',
                        'Drink water',
                        'Take a walk',
                        'Stretch',
                      ][i],
                kind: i == 1 ? HabitKind.quantity : HabitKind.check,
                startDay: app.today,
                icon: i + 1,
                target: i == 1 ? 1500000 : 1000,
                unit: i == 1 ? 'ml' : '',
              ),
              create: true,
            );
          }
          await store.saveTask(
            SmallTask(
              id: 'due',
              title: language == 'zh' ? '寄出包裹' : 'Post the parcel',
              dueDay: app.today,
            ),
            create: true,
          );
          await store.saveTask(
            SmallTask(
              id: 'resident',
              title: 'Water plants',
              resident: true,
              startDay: app.today,
            ),
            create: true,
          );
          await store.saveNote(
            Note(
              id: 'note',
              body: language == 'zh'
                  ? '今天读到了一个有趣的故事。'
                  : 'A story I want to remember.',
              day: app.today,
            ),
            create: true,
          );
          await app.load();
          t.view.physicalSize = Size(large ? 320 : 360, 800);
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = large ? 1.6 : 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(() async {
            app.dispose();
            await store.close();
          });
          await t.pumpWidget(DayPanelApp(app: app));
          await t.pumpAndSettle();
          final first = find.byKey(const Key('habit-action-h0'));
          expect(first.hitTestable(), findsOneWidget);
          expect(t.getRect(first).bottom, lessThan(large ? 520 : 350));
          if (!large) {
            expect(
              find.byKey(const Key('habit-action-h1')).hitTestable(),
              findsOneWidget,
            );
          }
          await t.tap(first);
          await t.pumpAndSettle();
          expect(
            app.value(app.habits.firstWhere((h) => h.id == 'h0'), app.today),
            1000,
          );
          await t.tap(find.byKey(const Key('tab-1')));
          await t.pumpAndSettle();
          expect(
            find.byKey(const Key('task-action-due')).hitTestable(),
            findsOneWidget,
          );
          expect(
            t.getRect(find.byKey(const Key('task-action-due'))).bottom,
            lessThan(360),
          );
          await t.tap(find.byKey(const Key('task-action-due')));
          await t.pumpAndSettle();
          expect(
            (await store.tasks()).firstWhere((x) => x.id == 'due').done,
            isTrue,
          );
          await t.tap(find.byKey(const Key('tab-2')));
          await t.pumpAndSettle();
          final note = find.byKey(const Key('note-card-note'));
          expect(note.hitTestable(), findsOneWidget);
          expect(t.getRect(note).top, lessThan(large ? 530 : 400));
          await t.tap(find.byKey(const Key('tab-3')));
          await t.pumpAndSettle();
          for (final id in [
            'settings-habits',
            'settings-appearance',
            'settings-backup',
          ]) {
            expect(find.byKey(Key(id)).hitTestable(), findsOneWidget);
          }
          expect(t.takeException(), isNull);
          await t.tap(find.byKey(const Key('settings-appearance')));
          await t.pumpAndSettle();
          expect(
            find.byKey(const Key('palette-blue')).hitTestable(),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('appearance-save')).hitTestable(),
            findsOneWidget,
          );
          t.state<NavigatorState>(find.byType(Navigator).first).pop();
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('tab-0')));
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('add-entry')));
          await t.pumpAndSettle();
          expect(
            find.byKey(const Key('template-water')).hitTestable(),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('template-reading')).hitTestable(),
            findsOneWidget,
          );
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
