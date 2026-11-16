import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  archiveHabit,
  clearHabit,
  createHabit,
  deleteAccount,
  deleteHabit,
  recordHabit,
  updateReminderPrefs,
  type ActionContext,
} from '../src/application/habit-actions.ts';
import { emptyState, findHabit } from '../src/domain/models.ts';
import { MemoryCloud, RevisionConflict } from '../src/data/cloud-store.ts';

const TODAY = '2026-11-16'; // Monday

function context(): ActionContext {
  let next = 0;
  return {
    today: TODAY,
    idFactory: () => `h${++next}`,
  };
}

test('create habit: check, position, initial plan, reminders all on', () => {
  const ctx = context();
  const state = createHabit(
    emptyState(),
    { title: '  Read a page  ', kind: 'check', target: 1000 },
    ctx,
  );
  assert.equal(state.profile.habits.length, 1);
  const habit = state.profile.habits[0];
  assert.equal(habit.title, 'Read a page');
  assert.equal(habit.position, 0);
  assert.equal(habit.plans.length, 1);
  assert.equal(habit.plans[0].effectiveDay, TODAY);
  assert.equal(habit.plans[0].target, 1000);
  assert.equal(state.profile.reminders.once, true);
  assert.equal(state.profile.reminders.digest, true);
  assert.equal(state.profile.reminders.calendar, true);
  assert.equal(state.profile.reminders.digestMinute, 1260);
});

test('create habit: validates target, weekday, interval, weekly total and start day', () => {
  const ctx = context();
  assert.throws(
    () =>
      createHabit(
        emptyState(),
        { title: 'Bad', kind: 'check', target: 1500 },
        ctx,
      ),
    /invalid_check_target/,
  );
  assert.throws(
    () =>
      createHabit(
        emptyState(),
        { title: 'Bad', kind: 'count', target: 1500 },
        ctx,
      ),
    /invalid_count_target/,
  );
  assert.throws(
    () =>
      createHabit(
        emptyState(),
        {
          title: 'Bad',
          kind: 'check',
          target: 1000,
          schedule: 'weeklyTotal',
        },
        ctx,
      ),
    /weekly_total_requires_numeric/,
  );
  assert.throws(
    () =>
      createHabit(
        emptyState(),
        {
          title: 'Bad',
          kind: 'check',
          target: 1000,
          weekdays: 0,
        },
        ctx,
      ),
    /invalid_weekdays/,
  );
  assert.throws(
    () =>
      createHabit(
        emptyState(),
        {
          title: 'Bad',
          kind: 'check',
          target: 1000,
          intervalDays: 0,
        },
        ctx,
      ),
    /invalid_interval/,
  );
  assert.throws(
    () =>
      createHabit(
        emptyState(),
        {
          title: 'Future',
          kind: 'check',
          target: 1000,
          startDay: '2026-11-17',
        },
        ctx,
      ),
    /start_day_in_future/,
  );
});

test('record/clear: explicit value, zero is a record, future and unscheduled rejected', () => {
  const ctx = context();
  const created = createHabit(
    emptyState(),
    {
      title: 'Read',
      kind: 'quantity',
      target: 10_000,
      unit: 'pages',
      weekdays: 127,
    },
    ctx,
  );
  const withZero = recordHabit(created, 'h1', TODAY, 0, ctx);
  assert.equal(withZero.days[TODAY].entries.h1, 0);
  const cleared = clearHabit(withZero, 'h1', TODAY);
  assert.equal(cleared.days[TODAY], undefined);

  assert.throws(
    () => recordHabit(created, 'h1', '2026-11-17', 1000, ctx),
    /future_day/,
  );
});

test('record: schedules, archived, rest and value validation', () => {
  const ctx = context();
  const mondayOnly = createHabit(
    emptyState(),
    {
      title: 'Monday only',
      kind: 'check',
      target: 1000,
      weekdays: 1,
      startDay: '2026-11-15',
    },
    ctx,
  );
  assert.throws(
    () => recordHabit(mondayOnly, 'h1', '2026-11-15', 1000, ctx),
    /not_scheduled/,
  );
  const archived = archiveHabit(mondayOnly, 'h1');
  assert.throws(
    () => recordHabit(archived, 'h1', TODAY, 1000, ctx),
    /habit_archived/,
  );
  const rest = {
    ...mondayOnly,
    breaks: [
      {
        id: 'b1',
        habitId: 'h1',
        startDay: TODAY,
        endDay: TODAY,
        kind: 'pause' as const,
      },
    ],
  };
  assert.throws(() => recordHabit(rest, 'h1', TODAY, 1000, ctx), /rest_day/);
  assert.throws(
    () => recordHabit(mondayOnly, 'h1', TODAY, 500, ctx),
    /invalid_value/,
  );
});

test('delete habit removes entries and unlinks notes, keeps cards', () => {
  const ctx = context();
  const created = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    ctx,
  );
  const recorded = recordHabit(created, 'h1', TODAY, 1000, ctx);
  const withNote = {
    ...recorded,
    notes: [
      { id: 'n1', body: 'A note', day: TODAY, habitId: 'h1' },
      { id: 'n2', body: 'Another', day: TODAY, habitId: null },
    ],
    cards: [
      {
        day: TODAY,
        artwork: 1,
        favorite: true,
        reflection: '',
        evidence: '[]',
      },
    ],
  };
  const deleted = deleteHabit(withNote, 'h1');
  assert.equal(findHabit(deleted, 'h1'), null);
  assert.equal(deleted.days[TODAY], undefined);
  assert.equal(deleted.notes[0].habitId, null);
  assert.equal(deleted.notes[1].habitId, null);
  assert.equal(deleted.cards.length, 1);
});

test('reminder prefs: defaults are on, digest minute is validated', () => {
  const ctx = context();
  const state = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    ctx,
  );
  const changed = updateReminderPrefs(state, {
    digestMinute: 20 * 60,
    calendar: false,
  });
  assert.equal(changed.profile.reminders.digestMinute, 1200);
  assert.equal(changed.profile.reminders.calendar, false);
  assert.throws(
    () => updateReminderPrefs(state, { digestMinute: 1440 }),
    /invalid_digest_minute/,
  );
});

test('deleteAccount returns the empty cloud state', () => {
  const ctx = context();
  const state = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    ctx,
  );
  const deleted = deleteAccount(state);
  assert.equal(deleted.profile.habits.length, 0);
  assert.equal(deleted.days[TODAY], undefined);
  assert.equal(deleted.profile.reminders.digest, true);
});

test('vertical slice: create -> record -> reload -> stale conflict -> account deletion', async () => {
  const cloud = new MemoryCloud();
  const ctx = context();

  const first = await cloud.load();
  assert.equal(first.revision, 0);
  assert.equal(first.state.profile.habits.length, 0);

  const created = createHabit(
    first.state,
    { title: 'Read a page', kind: 'check', target: 1000 },
    ctx,
  );
  const revision1 = await cloud.commit(first.revision, created);
  assert.equal(revision1, 1);

  const second = await cloud.load();
  assert.equal(second.revision, 1);
  assert.equal(second.state.profile.habits.length, 1);

  const recorded = recordHabit(second.state, 'h1', TODAY, 1000, ctx);
  const revision2 = await cloud.commit(second.revision, recorded);
  assert.equal(revision2, 2);

  const third = await cloud.load();
  assert.equal(third.revision, 2);
  assert.equal(third.state.days[TODAY].entries.h1, 1000);

  // A page that loaded at revision 1 must not overwrite revision 2.
  await assert.rejects(
    () => cloud.commit(second.revision, created),
    (error: unknown) => error instanceof RevisionConflict,
  );

  const deletedRevision = await cloud.deleteAccount(third.revision);
  assert.equal(deletedRevision, 3);
  const afterDelete = await cloud.load();
  assert.equal(afterDelete.revision, 3);
  assert.equal(afterDelete.state.profile.habits.length, 0);
  assert.equal(afterDelete.state.days[TODAY], undefined);

  // Old page cannot re-delete or re-create after the account deletion.
  await assert.rejects(
    () => cloud.deleteAccount(third.revision),
    (error: unknown) => error instanceof RevisionConflict,
  );
});