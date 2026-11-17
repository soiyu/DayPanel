import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  abandonChallenge,
  challengeDaysLeft,
  challengeProgress,
  createChallenge,
} from '../src/application/challenge-actions.ts';
import { createHabit, recordHabit, type ActionContext } from '../src/application/habit-actions.ts';
import { emptyState } from '../src/domain/models.ts';
import { addDays } from '../src/domain/day.ts';

const TODAY = '2026-11-16';

function context(): ActionContext {
  let next = 0;
  return { today: TODAY, idFactory: () => `id${++next}` };
}

test('challenge: 21-day challenge counts planned days and today progress', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    ctx,
  );
  state = createChallenge(state, 'id1', 21, ctx);
  assert.equal(state.challenges.length, 1);
  assert.equal(state.challenges[0].targetDays, 21);
  assert.equal(state.challenges[0].endDay, '2026-12-06');
  assert.equal(challengeDaysLeft(state.challenges[0], TODAY), 21);

  state = recordHabit(state, 'id1', TODAY, 1000, ctx);
  const progress = challengeProgress(state, state.challenges[0], TODAY);
  assert.equal(progress.completed, 1);
  assert.equal(progress.rate, 1 / 21);
  assert.equal(progress.todayDone, true);
  assert.equal(progress.status, 'active');
});

test('challenge: rest days are excluded from target and progress', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000, startDay: '2026-11-01' },
    ctx,
  );
  state = {
    ...state,
    breaks: [
      {
        id: 'b1',
        habitId: 'id1',
        startDay: '2026-11-20',
        endDay: '2026-11-20',
        kind: 'vacation',
      },
    ],
  };
  // Habit h1 was created by context() with h1 id; create challenge after break.
  state = createChallenge(state, 'id1', 21, ctx);
  assert.equal(state.challenges[0].targetDays, 20);
});

test('challenge: duplicate active, abandon and completion', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    ctx,
  );
  state = createChallenge(state, 'id1', 21, ctx);
  assert.throws(() => createChallenge(state, 'id1', 100, ctx), /challenge_already_active/);
  const abandoned = abandonChallenge(state, state.challenges[0].id);
  assert.equal(abandoned.challenges[0].status, 'abandoned');

  let completedState = state;
  for (let i = 0; i < 21; i += 1) {
    const day = addDays(TODAY, i);
    completedState = recordHabit(completedState, 'id1', day, 1000, {
      ...ctx,
      today: day,
    });
  }
  const progress = challengeProgress(completedState, completedState.challenges[0], '2026-12-06');
  assert.equal(progress.status, 'completed');
  assert.equal(progress.completed, 21);
});

test('challenge: expiration marks failed without deleting history', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    ctx,
  );
  state = createChallenge(state, 'id1', 21, ctx);
  const progress = challengeProgress(state, state.challenges[0], '2027-01-01');
  assert.equal(progress.status, 'failed');
  assert.equal(state.challenges[0].status, 'active');
});
