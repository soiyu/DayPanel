import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/domain/models.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late Directory temp;
  final today = Day.parse('2026-11-05');
  Habit habit({HabitKind kind = HabitKind.check}) =>
      Habit(id: 'h', title: 'Read', kind: kind, startDay: today.plus(-7));
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('daypanel-test-');
    store = await AppStore.open(
      factory: databaseFactoryFfi,
      path: '${temp.path}/test.db',
    );
  });
  tearDown(() async {
    await store.close();
    await temp.delete(recursive: true);
  });
  test(
    'real file survives close/reopen with habits tasks notes preferences',
    () async {
      await store.saveHabit(habit(), create: true);
      await store.setRecord('h', today, 1000, today: today);
      await store.saveTask(
        SmallTask(id: 't', title: 'Book', dueDay: today.plus(-1)),
        create: true,
      );
      await store.completeTask('t', true, today);
      await store.saveNote(
        Note(id: 'n', body: 'A good day', day: today),
        create: true,
      );
      await store.preference('locale', 'zh');
      await store.close();
      store = await AppStore.open(
        factory: databaseFactoryFfi,
        path: '${temp.path}/test.db',
      );
      expect((await store.habits()).single.title, 'Read');
      expect((await store.entries()).single.value, 1000);
      expect((await store.tasks()).single.completedDay, today);
      expect((await store.notes()).single.body, 'A good day');
      expect((await store.settings())['locale'], 'zh');
    },
  );
  test('repeated explicit habit completion remains one record', () async {
    await store.saveHabit(habit(), create: true);
    await store.setRecord('h', today, 1000, today: today);
    await store.setRecord('h', today, 1000, today: today);
    expect((await store.entries()).length, 1);
    expect((await store.entries()).single.value, 1000);
    await store.setRecord('h', today, null, today: today);
    expect(await store.entries(), isEmpty);
  });
  test(
    'zero is a real quantity, thousandths exact, future/start protected',
    () async {
      await store.saveHabit(habit(kind: HabitKind.quantity), create: true);
      await store.setRecord('h', today, 0, today: today);
      expect((await store.entries()).single.value, 0);
      await store.setRecord('h', today, 1, today: today);
      expect((await store.entries()).single.value, 1);
      await expectLater(
        store.setRecord('h', today.plus(1), 1000, today: today),
        throwsArgumentError,
      );
      await expectLater(
        store.setRecord('h', today.plus(-8), 1000, today: today),
        throwsArgumentError,
      );
      expect((await store.entries()).single.value, 1);
    },
  );
  test(
    'archive preserves entries; deletion cascades without stale resurrection',
    () async {
      await store.saveHabit(habit(), create: true);
      await store.setRecord('h', today, 1000, today: today);
      await store.setArchived('h', true);
      await expectLater(
        store.setRecord('h', today, 0, today: today),
        throwsArgumentError,
      );
      expect((await store.entries()).length, 1);
      await store.remove('habits', 'h');
      expect(await store.entries(), isEmpty);
      await expectLater(store.saveHabit(habit()), throwsStateError);
      await expectLater(
        store.setRecord('h', today, 1000, today: today),
        throwsStateError,
      );
    },
  );
  test(
    'task completion uses actual date; retry/edit preserves it; reopen keeps due date',
    () async {
      final task = SmallTask(id: 't', title: 'Book', dueDay: today.plus(3));
      await store.saveTask(task, create: true);
      await store.completeTask('t', true, today);
      await store.completeTask('t', true, today.plus(1));
      await store.saveTask(
        SmallTask(id: 't', title: 'Updated', dueDay: task.dueDay),
      );
      expect((await store.tasks()).single.completedDay, today);
      await store.completeTask('t', false, today);
      final reopened = (await store.tasks()).single;
      expect(reopened.completedDay, isNull);
      expect(reopened.dueDay, task.dueDay);
      await store.remove('tasks', 't');
      await expectLater(store.saveTask(task), throwsStateError);
    },
  );
  test('changing schedule and goal preserves raw historical facts', () async {
    final h = habit(kind: HabitKind.quantity);
    await store.saveHabit(h, create: true);
    await store.setRecord('h', today.plus(-1), 1000, today: today);
    await store.saveHabit(
      Habit.fromMap({...h.toMap(), 'target': 5000, 'weekdays': 1}),
    );
    expect((await store.entries()).single.value, 1000);
    expect((await store.entries()).single.day, today.plus(-1));
  });
  test(
    'invalid fields and immutable kind/start cannot corrupt existing data',
    () async {
      final h = habit();
      await store.saveHabit(h, create: true);
      await expectLater(
        store.saveHabit(Habit.fromMap({...h.toMap(), 'weekdays': 0})),
        throwsArgumentError,
      );
      await expectLater(
        store.saveHabit(Habit.fromMap({...h.toMap(), 'kind': 'quantity'})),
        throwsStateError,
      );
      expect((await store.habits()).single.weekdays, 127);
    },
  );
  test(
    'journal edit keeps identity and deleted notes cannot reappear',
    () async {
      final n = Note(id: 'n', body: 'Thought', day: today);
      await store.saveNote(n, create: true);
      await store.saveNote(Note(id: 'n', body: 'Revised', day: today));
      expect((await store.notes()).single.body, 'Revised');
      await store.remove('notes', 'n');
      await expectLater(store.saveNote(n), throwsStateError);
      expect(await store.notes(), isEmpty);
    },
  );
}
