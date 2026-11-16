import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  createNote,
  deleteNote,
  filterNotes,
  monthKey,
  noteMonthOptions,
  updateNote,
} from '../src/application/journal-actions.ts';
import { createHabit, type ActionContext } from '../src/application/habit-actions.ts';
import { emptyState } from '../src/domain/models.ts';

const TODAY = '2026-11-16';

function context(): ActionContext {
  let next = 0;
  return { today: TODAY, idFactory: () => `n${++next}` };
}

test('journal: note can be independent, date defaults to today', () => {
  const ctx = context();
  const state = createNote(emptyState(), { body: 'A small step' }, ctx);
  assert.equal(state.notes.length, 1);
  assert.equal(state.notes[0].body, 'A small step');
  assert.equal(state.notes[0].day, TODAY);
  assert.equal(state.notes[0].habitId, null);
});

test('journal: associated note requires an existing habit', () => {
  const ctx = context();
  const habit = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    { ...ctx, idFactory: () => 'h1' },
  );
  const state = createNote(
    habit,
    { body: 'Read ten pages', habitId: 'h1', day: '2026-11-15' },
    ctx,
  );
  assert.equal(state.notes[0].habitId, 'h1');
  assert.equal(state.notes[0].day, '2026-11-15');
  assert.throws(
    () => createNote(habit, { body: 'Missing', habitId: 'h999' }, ctx),
    /habit_missing/,
  );
});

test('journal: update changes body/date/association and rejects future dates', () => {
  const ctx = context();
  const base = createNote(emptyState(), { body: 'First' }, ctx);
  const updated = updateNote(
    base,
    'n1',
    { body: '  Second  ', day: '2026-11-10', habitId: null },
    ctx,
  );
  assert.equal(updated.notes[0].body, 'Second');
  assert.equal(updated.notes[0].day, '2026-11-10');
  assert.throws(
    () => updateNote(base, 'n1', { day: '2026-11-17' }, ctx),
    /future_day/,
  );
  assert.throws(() => updateNote(base, 'n1', { body: ' ' }, ctx), /empty_note/);
});

test('journal: filtering intersects month, day, habit and case-insensitive text', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    { ...ctx, idFactory: () => 'h1' },
  );
  state = createNote(state, { body: 'Tea memory', day: '2026-10-31' }, ctx);
  state = createNote(
    state,
    { body: 'tea and book', day: '2026-11-16', habitId: 'h1' },
    ctx,
  );
  state = createNote(state, { body: 'Other', day: '2026-11-16' }, ctx);

  assert.equal(filterNotes(state, { month: '2026-11' }).length, 2);
  assert.equal(filterNotes(state, { month: '2026-10' }).length, 1);
  assert.equal(filterNotes(state, { text: 'TEA' }).length, 2);
  assert.equal(filterNotes(state, { text: 'tea', habitId: 'h1' }).length, 1);
  assert.equal(
    filterNotes(state, { month: '2026-11', day: '2026-11-16', text: 'other' })
      .length,
    1,
  );
  assert.throws(() => filterNotes(state, { month: '2026-1' }), /invalid_month/);
});

test('journal: month helpers and delete', () => {
  const ctx = context();
  const state = createNote(emptyState(), { body: 'One', day: '2026-10-01' }, ctx);
  const withTwo = createNote(state, { body: 'Two', day: '2026-11-01' }, ctx);
  assert.equal(monthKey('2026-11-16'), '2026-11');
  assert.deepEqual(noteMonthOptions(withTwo.notes), ['2026-11', '2026-10']);
  const deleted = deleteNote(withTwo, 'n1');
  assert.equal(deleted.notes.length, 1);
  assert.throws(() => deleteNote(deleted, 'n1'), /note_missing/);
});
test('journal: independent filter excludes habit-linked notes', () => {
  const ctx = context();
  let state = createHabit(
    emptyState(),
    { title: 'Read', kind: 'check', target: 1000 },
    { ...ctx, idFactory: () => 'h1' },
  );
  state = createNote(state, { body: 'Linked', habitId: 'h1' }, ctx);
  state = createNote(state, { body: 'Standalone' }, ctx);
  assert.equal(filterNotes(state, { independent: true }).length, 1);
  assert.equal(filterNotes(state, { independent: true })[0].body, 'Standalone');
});
