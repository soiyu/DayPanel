import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createHabit, recordHabit, type ActionContext } from '../src/application/habit-actions.ts';
import { emptyState } from '../src/domain/models.ts';
import { insights } from '../src/domain/insights.ts';

const TODAY = '2026-11-16';

function context(): ActionContext {
  let next = 0;
  return { today: TODAY, idFactory: () => `h${++next}` };
}

test('insights: overall totals, weekday strength and habit trend', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    {
      title: 'Read',
      kind: 'check',
      target: 1000,
      startDay: '2026-10-01',
    },
    ctx,
  );
  state = recordHabit(state, 'h1', '2026-11-14', 1000, ctx);
  state = recordHabit(state, 'h1', '2026-11-15', 1000, ctx);
  const result = insights(state, 30, TODAY);
  assert.equal(result.range, 30);
  assert.equal(result.end, '2026-11-15');
  assert.ok(result.overall.planned >= 30);
  assert.equal(result.overall.completed, 2);
  assert.equal(result.habits.length, 1);
  assert.equal(result.habits[0].completed, 2);
  assert.equal(result.weekdays.length, 7);
  assert.equal(result.months.some((month) => month.month === '2026-11'), true);
});

test('insights: pair co-occurrence counts days where both are achieved', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000, startDay: '2026-10-01' },
    ctx,
  );
  state = createHabit(
    state,
    { title: 'Walk', kind: 'check', target: 1000, startDay: '2026-10-01' },
    { ...ctx, idFactory: () => 'h2' },
  );
  for (const day of ['2026-11-10', '2026-11-11', '2026-11-12']) {
    state = recordHabit(state, 'h1', day, 1000, ctx);
    state = recordHabit(state, 'h2', day, 1000, ctx);
  }
  const result = insights(state, 30, TODAY);
  assert.equal(result.pairs.length, 1);
  assert.equal(result.pairs[0].days, 3);
  assert.equal(result.cards, 0);
});

test('insights: invalid range rejected and empty state is safe', () => {
  assert.throws(() => insights(emptyState(), 14 as any, TODAY), /Invalid insight range/);
  const result = insights(emptyState(), 90, TODAY);
  assert.equal(result.overall.planned, 0);
  assert.equal(result.overall.rate, 0);
  assert.equal(result.habits.length, 0);
  assert.equal(result.pairs.length, 0);
});
