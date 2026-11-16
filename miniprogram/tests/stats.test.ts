import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createHabit, recordHabit, startBreak, type ActionContext } from '../src/application/habit-actions.ts';
import { emptyState } from '../src/domain/models.ts';
import { habitStats } from '../src/domain/stats.ts';

const TODAY = '2026-11-16';

function context(): ActionContext {
  let next = 0;
  return { today: TODAY, idFactory: () => `h${++next}` };
}

test('stats: exclude today, count planned days, rate and streak', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    {
      title: 'Read',
      kind: 'check',
      target: 1000,
      startDay: '2026-11-01',
    },
    ctx,
  );
  state = recordHabit(state, 'h1', '2026-11-14', 1000, ctx);
  state = recordHabit(state, 'h1', '2026-11-15', 1000, ctx);
  const stats = habitStats(state, 7, TODAY);
  assert.equal(stats.length, 1);
  assert.equal(stats[0].planned, 7);
  assert.equal(stats[0].completed, 2);
  assert.equal(stats[0].streak, 2);
  assert.ok(Math.abs(stats[0].rate - 2 / 7) < 1e-9);
  assert.equal(stats[0].rangeStart, '2026-11-09');
  assert.equal(stats[0].rangeEnd, '2026-11-15');
});

test('stats: rest days are skipped and quantity totals are per range', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    {
      title: 'Water',
      kind: 'quantity',
      target: 1000,
      unit: 'ml',
      startDay: '2026-11-01',
    },
    ctx,
  );
  state = recordHabit(state, 'h1', '2026-11-14', 500, ctx);
  state = recordHabit(state, 'h1', '2026-11-15', 1500, ctx);
  state = startBreak(state, 'h1', 'skip', '2026-11-13', '2026-11-13', ctx);
  const stats = habitStats(state, 7, TODAY);
  assert.equal(stats[0].planned, 6);
  assert.equal(stats[0].completed, 1);
  assert.equal(stats[0].totalValue, 2000);
  assert.equal(stats[0].kind, 'quantity');
});

test('stats: no planned days does not invent a rate', () => {
  const ctx = context();
  const state = createHabit(
    emptyState(),
    { title: 'Future-ish', kind: 'check', target: 1000, startDay: TODAY },
    ctx,
  );
  const stats = habitStats(state, 30, TODAY);
  assert.equal(stats[0].planned, 0);
  assert.equal(stats[0].rate, 0);
});

test('stats: invalid range rejected', () => {
  assert.throws(() => habitStats(emptyState(), 0, TODAY), /Invalid stats range/);
  assert.throws(() => habitStats(emptyState(), 366, TODAY), /Invalid stats range/);
});
