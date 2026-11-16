import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  archiveHabit,
  clearHabit,
  createHabit,
  deleteAccount,
  deleteHabit,
  endBreak,
  recordHabit,
  startBreak,
  updateHabit,
  updateReminderPrefs,
  type ActionContext,
} from '../src/application/habit-actions.ts';
import {
  currentPlan,
  emptyState,
  findHabit,
  isRestOn,
} from '../src/domain/models.ts';
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

test('habit edit: plan changes take effect tomorrow and replace pending versions', () => {
  const ctx = context();
  const created = createHabit(
    emptyState(),
    { title: 'Water', kind: 'quantity', target: 10_000, unit: 'ml' },
    ctx,
  );
  const changed = updateHabit(
    created,
    'h1',
    { target: 20_000, unit: 'ml' },
    ctx,
  );
  assert.equal(currentPlan(findHabit(changed, 'h1')!, TODAY).target, 10_000);
  assert.equal(
    currentPlan(findHabit(changed, 'h1')!, '2026-11-17').target,
    20_000,
  );
  assert.equal(findHabit(changed, 'h1')!.plans.length, 2);

  const replaced = updateHabit(changed, 'h1', { target: 30_000 }, ctx);
  const plans = findHabit(replaced, 'h1')!.plans.filter(
    (plan) => plan.effectiveDay === '2026-11-17',
  );
  assert.equal(plans.length, 1);
  assert.equal(plans[0].target, 30_000);

  const reverted = updateHabit(replaced, 'h1', { target: 10_000 }, ctx);
  assert.equal(
    findHabit(reverted, 'h1')!.plans.some(
      (plan) => plan.effectiveDay === '2026-11-17',
    ),
    false,
  );
});

test('habit edit: title-only change does not discard a pending plan', () => {
  const ctx = context();
  const created = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    ctx,
  );
  const changed = updateHabit(created, 'h1', { title: 'Read more' }, ctx);
  assert.equal(findHabit(changed, 'h1')!.title, 'Read more');
  assert.equal(currentPlan(findHabit(changed, 'h1')!, TODAY).target, 1000);
});

test('rest: pause blocks recording, ends explicitly, and rejects overlap', () => {
  const ctx = context();
  const created = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    ctx,
  );
  const paused = startBreak(created, 'h1', 'pause', TODAY, null, ctx);
  assert.equal(isRestOn(paused.breaks, 'h1', TODAY), true);
  assert.throws(() => recordHabit(paused, 'h1', TODAY, 1000, ctx), /rest_day/);
  assert.throws(
    () => startBreak(paused, 'h1', 'pause', TODAY, null, ctx),
    /break_overlap/,
  );
  const breakId = paused.breaks[0].id;
  assert.throws(
    () => endBreak(paused, breakId, '2026-11-17', ctx),
    /future_day/,
  );
  const ended = endBreak(paused, breakId, TODAY, ctx);
  assert.equal(ended.breaks[0].endDay, TODAY);
  assert.equal(isRestOn(ended.breaks, 'h1', TODAY), true);
  // Resuming a pause today keeps today a rest day; tomorrow is recordable.
  assert.throws(() => recordHabit(ended, 'h1', TODAY, 1000, ctx), /rest_day/);
});

test('rest: vacation range and skip validation', () => {
  const ctx = context();
  const created = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    ctx,
  );
  const vacation = startBreak(
    created,
    'h1',
    'vacation',
    TODAY,
    '2026-11-20',
    ctx,
  );
  assert.equal(isRestOn(vacation.breaks, 'h1', '2026-11-20'), true);
  assert.equal(isRestOn(vacation.breaks, 'h1', '2026-11-21'), false);
  assert.throws(
    () => startBreak(created, 'h1', 'vacation', TODAY, '2027-11-17', ctx),
    /vacation_too_long/,
  );

  const withRecord = recordHabit(created, 'h1', TODAY, 1000, ctx);
  assert.throws(
    () => startBreak(withRecord, 'h1', 'skip', TODAY, TODAY, ctx),
    /skip_has_record/,
  );
  const skipped = startBreak(created, 'h1', 'skip', '2026-11-15', '2026-11-15', ctx);
  assert.equal(isRestOn(skipped.breaks, 'h1', '2026-11-15'), true);
});