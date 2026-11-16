import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  createHabit,
  recordHabit,
  clearHabit,
  type ActionContext,
} from '../src/application/habit-actions.ts';
import {
  cardEvidence,
  cardForDay,
  ensureCard,
  evidenceOf,
} from '../src/domain/achievement.ts';
import { emptyState } from '../src/domain/models.ts';

const TODAY = '2026-11-16';

function context(): ActionContext {
  let next = 0;
  return { today: TODAY, idFactory: () => `h${++next}` };
}

test('card: no card until every daily habit is achieved', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    ctx,
  );
  state = createHabit(
    state,
    { title: 'Water', kind: 'quantity', target: 1000, unit: 'ml' },
    { ...ctx, idFactory: () => 'h2' },
  );
  state = recordHabit(state, 'h1', TODAY, 1000, ctx);
  assert.equal(cardEvidence(state, TODAY), null);
  assert.equal(cardForDay(state, TODAY), null);

  state = recordHabit(state, 'h2', TODAY, 1000, ctx);
  const evidence = cardEvidence(state, TODAY);
  assert.ok(evidence);
  assert.equal(evidence!.length, 2);
  const withCard = ensureCard(state, TODAY);
  assert.ok(cardForDay(withCard, TODAY));
  assert.equal(cardForDay(withCard, TODAY)!.favorite, false);
  assert.equal(evidenceOf(cardForDay(withCard, TODAY)!).length, 2);
});

test('card: undo keeps the earned card and its snapshot', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    ctx,
  );
  state = recordHabit(state, 'h1', TODAY, 1000, ctx);
  state = ensureCard(state, TODAY);
  const card = cardForDay(state, TODAY)!;
  const undone = clearHabit(state, 'h1', TODAY);
  assert.equal(cardForDay(undone, TODAY)?.day, card.day);
  assert.equal(cardForDay(undone, TODAY)?.evidence, card.evidence);
});

test('card: weekly-only plan does not earn a daily card', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    {
      title: 'Weekly',
      kind: 'quantity',
      target: 10_000,
      schedule: 'weekly',
      weeklyGoal: 3,
    },
    ctx,
  );
  state = recordHabit(state, 'h1', TODAY, 10_000, ctx);
  assert.equal(cardEvidence(state, TODAY), null);
  assert.equal(cardForDay(state, TODAY), null);
});

test('card: ensureCard is idempotent and artwork is stable', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    ctx,
  );
  state = recordHabit(state, 'h1', TODAY, 1000, ctx);
  const once = ensureCard(state, TODAY);
  const twice = ensureCard(once, TODAY);
  assert.equal(once.cards.length, 1);
  assert.equal(twice.cards.length, 1);
  assert.equal(twice.cards[0].artwork, once.cards[0].artwork);
  assert.ok(once.cards[0].artwork >= 0 && once.cards[0].artwork < 6);
});
