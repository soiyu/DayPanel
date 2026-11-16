import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  archiveTask,
  completeTask,
  createTask,
  deleteTask,
  taskDoneOn,
  type CreateTaskInput,
} from '../src/application/task-actions.ts';
import type { ActionContext } from '../src/application/habit-actions.ts';
import { emptyState } from '../src/domain/models.ts';

const TODAY = '2026-11-16';

function context(): ActionContext {
  let next = 0;
  return { today: TODAY, idFactory: () => `t${++next}` };
}

test('task: one-time task keeps planned date and actual completion date separate', () => {
  const ctx = context();
  const created = createTask(
    emptyState(),
    { title: 'Return the book', dueDay: TODAY },
    ctx,
  );
  const task = created.tasks[0];
  assert.equal(task.dueDay, TODAY);
  assert.equal(task.completedDay, null);
  assert.equal(task.resident, false);

  const done = completeTask(created, task.id, true, TODAY, ctx);
  assert.equal(done.tasks[0].dueDay, TODAY);
  assert.equal(done.tasks[0].completedDay, TODAY);
  assert.equal(taskDoneOn(done.tasks[0], done.taskDays, TODAY), true);

  const reopened = completeTask(done, task.id, false, TODAY, ctx);
  assert.equal(reopened.tasks[0].completedDay, null);
  assert.equal(reopened.tasks[0].dueDay, TODAY);
});

test('task: resident task records a local day and has no due date', () => {
  const ctx = context();
  const created = createTask(
    emptyState(),
    { title: 'Water the plants', resident: true },
    ctx,
  );
  const task = created.tasks[0];
  assert.equal(task.dueDay, null);
  assert.equal(task.startDay, TODAY);
  assert.equal(task.resident, true);

  const done = completeTask(created, task.id, true, TODAY, ctx);
  assert.deepEqual(done.taskDays[TODAY], [task.id]);
  assert.equal(done.tasks[0].completedDay, null);
  assert.equal(taskDoneOn(done.tasks[0], done.taskDays, TODAY), true);

  const undone = completeTask(done, task.id, false, TODAY, ctx);
  assert.equal(undone.taskDays[TODAY], undefined);
});

test('task: resident task can correct a past day but not future', () => {
  const ctx = context();
  const created = createTask(
    emptyState(),
    { title: 'Resident', resident: true },
    ctx,
  );
  const done = completeTask(created, 't1', true, '2026-11-15', ctx);
  assert.deepEqual(done.taskDays['2026-11-15'], ['t1']);
  assert.throws(
    () => completeTask(created, 't1', true, '2026-11-17', ctx),
    /future_day/,
  );
});

test('task: validation, archive and delete', () => {
  const ctx = context();
  assert.throws(
    () => createTask(emptyState(), { title: '  ', dueDay: TODAY }, ctx),
    /invalid_title/,
  );
  assert.throws(
    () =>
      createTask(
        emptyState(),
        { title: 'Resident with due', resident: true, dueDay: TODAY },
        ctx,
      ),
    /resident_has_due/,
  );

  const created = createTask(emptyState(), { title: 'Task' }, ctx);
  const archived = archiveTask(created, 't1');
  assert.throws(
    () => completeTask(archived, 't1', true, TODAY, ctx),
    /task_archived/,
  );
  const deleted = deleteTask(created, 't1');
  assert.equal(deleted.tasks.length, 0);
});

test('task: create input type is explicit and id is injectable', () => {
  const ctx = context();
  const input: CreateTaskInput = { title: 'Type check', dueDay: null };
  const state = createTask(emptyState(), input, ctx);
  assert.equal(state.tasks[0].id, 't1');
  assert.equal(state.tasks[0].dueDay, null);
});