// @ts-nocheck
/**
 * CloudBase API for the P1 slice. All writes go through this function; the
 * client never writes collections directly. Business data is only read by the
 * caller's OPENID, which is taken from the WeChat context, not the event.
 */
import cloud from 'wx-server-sdk';
import { randomUUID } from 'node:crypto';
import { parseDay, todayKey } from '../../../src/domain/day.ts';
import {
  defaultProfile,
  emptyState,
  type UserState,
} from '../../../src/domain/models.ts';
import {
  archiveHabit,
  clearHabit,
  createHabit,
  deleteBreak,
  deleteHabit,
  endBreak,
  recordHabit,
  startBreak,
  updateHabit,
  updateReminderPrefs,
  ValidationError,
} from '../../../src/application/habit-actions.ts';
import {
  archiveTask,
  completeTask,
  createTask,
  deleteTask,
  updateTask,
} from '../../../src/application/task-actions.ts';
import {
  abandonChallenge,
  challengeProgress,
  createChallenge,
} from '../../../src/application/challenge-actions.ts';
import {
  createNote,
  deleteNote,
  filterNotes,
  updateNote,
} from '../../../src/application/journal-actions.ts';
import { updateSettings } from '../../../src/application/settings-actions.ts';
import { habitStats } from '../../../src/domain/stats.ts';
import { insights } from '../../../src/domain/insights.ts';
import {
  ensureCard,
  saveCardReflection,
  setCardFavorite,
} from '../../../src/domain/achievement.ts';

cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });
const db = cloud.database();

const COLLECTIONS = [
  'dp_days',
  'dp_profile',
  'dp_cards',
  'dp_tasks',
  'dp_task_days',
  'dp_notes',
  'dp_activity',
  'dp_breaks',
  'dp_events',
  'dp_jobs',
  'dp_backfills',
  'dp_challenges',
  'dp_step_days',
];

function fail(code) {
  return { ok: false, error: code };
}

async function getDoc(collection, id) {
  try {
    const result = await db.collection(collection).doc(id).get();
    return result.data ?? null;
  } catch {
    return null;
  }
}

async function listAll(collection, openid) {
  const rows = [];
  const size = 100;
  for (let skip = 0; ; skip += size) {
    const result = await db
      .collection(collection)
      .where({ _openid: openid })
      .skip(skip)
      .limit(size)
      .get();
    rows.push(...result.data);
    if (result.data.length < size) break;
    if (rows.length > 20_000) throw new Error('too_many_rows');
  }
  return rows;
}

async function loadUser(openid, day) {
  const meta = await getDoc('dp_meta', openid);
  const revision = meta?.revision ?? 0;
  const generation = meta?.generation ?? 0;
  const deleted = meta?.deleted === true;
  const state = emptyState();

  if (!deleted) {
    const profileDoc = await getDoc('dp_profile', openid);
    if (profileDoc?.profile) state.profile = profileDoc.profile;
    for (const row of await listAll('dp_days', openid)) {
      state.days[row.day] = { day: row.day, entries: row.entries ?? {} };
    }
    for (const row of await listAll('dp_tasks', openid)) {
      if (row.task) state.tasks.push(row.task);
    }
    for (const row of await listAll('dp_task_days', openid)) {
      if (row.day) state.taskDays[row.day] = row.taskIds ?? [];
    }
    for (const row of await listAll('dp_notes', openid)) {
      if (row.note) state.notes.push(row.note);
    }
    for (const row of await listAll('dp_breaks', openid)) {
      if (row.breakItem) state.breaks.push(row.breakItem);
    }
    for (const row of await listAll('dp_cards', openid)) {
      if (row.card) state.cards.push(row.card);
    }
    for (const row of await listAll('dp_backfills', openid)) {
      if (row.backfill) state.backfills.push(row.backfill);
    }
    for (const row of await listAll('dp_challenges', openid)) {
      if (row.challenge) state.challenges.push(row.challenge);
    }
  }

  let card = null;
  if (!deleted && day) {
    try {
      const result = await db
        .collection('dp_cards')
        .where({ _openid: openid, day })
        .limit(1)
        .get();
      card = result.data[0] ?? null;
    } catch {
      card = null;
    }
  }

  return {
    revision,
    generation,
    deleted,
    state,
    card,
    profile: deleted ? defaultProfile() : state.profile,
    todayRecord: deleted ? null : state.days[day] ?? null,
  };
}

function changedDays(previous, next) {
  const changed = [];
  for (const [day, record] of Object.entries(next.days)) {
    if (JSON.stringify(previous.days[day]?.entries ?? {}) !== JSON.stringify(record.entries)) {
      changed.push(record);
    }
  }
  for (const day of Object.keys(previous.days)) {
    if (!next.days[day]) changed.push({ day, entries: null });
  }
  return changed;
}

function changedTasks(previous, next) {
  const before = new Map(previous.tasks.map((task) => [task.id, task]));
  const after = new Map(next.tasks.map((task) => [task.id, task]));
  const changed = [];
  for (const [id, task] of after) {
    if (JSON.stringify(before.get(id) ?? null) !== JSON.stringify(task)) {
      changed.push(task);
    }
  }
  const removed = [...before.keys()].filter((id) => !after.has(id));
  return { changed, removed };
}

function changedTaskDays(previous, next) {
  const days = new Set([...Object.keys(previous.taskDays), ...Object.keys(next.taskDays)]);
  const changed = [];
  for (const day of days) {
    const before = previous.taskDays[day] ?? [];
    const after = next.taskDays[day] ?? [];
    if (JSON.stringify(before) !== JSON.stringify(after)) {
      changed.push({ day, taskIds: after.length ? after : null });
    }
  }
  return changed;
}

function changedChallenges(previous, next) {
  const before = new Map(previous.challenges.map((item) => [item.id, item]));
  const after = new Map(next.challenges.map((item) => [item.id, item]));
  const changed = [];
  for (const [id, item] of after) {
    if (JSON.stringify(before.get(id) ?? null) !== JSON.stringify(item)) {
      changed.push(item);
    }
  }
  return changed;
}

function changedBackfills(previous, next) {
  const before = new Map(
    previous.backfills.map((item) => [`${item.habitId}|${item.day}`, item]),
  );
  const after = new Map(
    next.backfills.map((item) => [`${item.habitId}|${item.day}`, item]),
  );
  const changed = [];
  for (const [key, item] of after) {
    if (JSON.stringify(before.get(key) ?? null) !== JSON.stringify(item)) {
      changed.push(item);
    }
  }
  const removed = [...before.keys()].filter((key) => !after.has(key));
  return { changed, removed };
}

function changedCards(previous, next) {
  const before = new Map(previous.cards.map((card) => [card.day, card]));
  const after = new Map(next.cards.map((card) => [card.day, card]));
  const changed = [];
  for (const [day, card] of after) {
    if (JSON.stringify(before.get(day) ?? null) !== JSON.stringify(card)) {
      changed.push(card);
    }
  }
  return changed;
}

function changedBreaks(previous, next) {
  const before = new Map(previous.breaks.map((item) => [item.id, item]));
  const after = new Map(next.breaks.map((item) => [item.id, item]));
  const changed = [];
  for (const [id, item] of after) {
    if (JSON.stringify(before.get(id) ?? null) !== JSON.stringify(item)) {
      changed.push(item);
    }
  }
  const removed = [...before.keys()].filter((id) => !after.has(id));
  return { changed, removed };
}

function changedNotes(previous, next) {
  const before = new Map(previous.notes.map((note) => [note.id, note]));
  const after = new Map(next.notes.map((note) => [note.id, note]));
  const changed = [];
  for (const [id, note] of after) {
    if (JSON.stringify(before.get(id) ?? null) !== JSON.stringify(note)) {
      changed.push(note);
    }
  }
  const removed = [...before.keys()].filter((id) => !after.has(id));
  return { changed, removed };
}

async function persist(openid, expected, previous, next) {
  const tx = await db.startTransaction();
  try {
    let meta = null;
    try {
      meta = (await tx.collection('dp_meta').doc(openid).get()).data ?? null;
    } catch {
      meta = null;
    }
    if ((meta?.revision ?? 0) !== expected) {
      await tx.rollback();
      return { conflict: true, revision: meta?.revision ?? 0 };
    }

    await tx.collection('dp_profile').doc(openid).set({
      data: { _openid: openid, profile: next.profile, updatedAt: db.serverDate() },
    });

    for (const record of changedDays(previous, next)) {
      const id = `${openid}_${record.day}`;
      if (record.entries === null) {
        try {
          await tx.collection('dp_days').doc(id).remove();
        } catch {
          // already absent
        }
      } else {
        await tx.collection('dp_days').doc(id).set({
          data: {
            _openid: openid,
            day: record.day,
            entries: record.entries,
            updatedAt: db.serverDate(),
          },
        });
      }
    }

    const taskDiff = changedTasks(previous, next);
    for (const task of taskDiff.changed) {
      await tx.collection('dp_tasks').doc(`${openid}_${task.id}`).set({
        data: { _openid: openid, task, updatedAt: db.serverDate() },
      });
    }
    for (const id of taskDiff.removed) {
      try {
        await tx.collection('dp_tasks').doc(`${openid}_${id}`).remove();
      } catch {
        // already absent
      }
    }
    for (const record of changedTaskDays(previous, next)) {
      const id = `${openid}_${record.day}`;
      if (record.taskIds === null) {
        try {
          await tx.collection('dp_task_days').doc(id).remove();
        } catch {
          // already absent
        }
      } else {
        await tx.collection('dp_task_days').doc(id).set({
          data: {
            _openid: openid,
            day: record.day,
            taskIds: record.taskIds,
            updatedAt: db.serverDate(),
          },
        });
      }
    }

    const noteDiff = changedNotes(previous, next);
    for (const note of noteDiff.changed) {
      await tx.collection('dp_notes').doc(`${openid}_${note.id}`).set({
        data: { _openid: openid, note, updatedAt: db.serverDate() },
      });
    }
    for (const id of noteDiff.removed) {
      try {
        await tx.collection('dp_notes').doc(`${openid}_${id}`).remove();
      } catch {
        // already absent
      }
    }

    for (const challenge of changedChallenges(previous, next)) {
      await tx.collection('dp_challenges').doc(`${openid}_${challenge.id}`).set({
        data: { _openid: openid, challenge, updatedAt: db.serverDate() },
      });
    }

    const backfillDiff = changedBackfills(previous, next);
    for (const item of backfillDiff.changed) {
      await tx.collection('dp_backfills').doc(`${openid}_${item.habitId}_${item.day}`).set({
        data: { _openid: openid, backfill: item, updatedAt: db.serverDate() },
      });
    }
    for (const key of backfillDiff.removed) {
      try {
        await tx.collection('dp_backfills').doc(`${openid}_${key.replace('|', '_')}`).remove();
      } catch {
        // already absent
      }
    }

    for (const card of changedCards(previous, next)) {
      await tx.collection('dp_cards').doc(`${openid}_${card.day}`).set({
        data: { _openid: openid, card, updatedAt: db.serverDate() },
      });
    }

    const breakDiff = changedBreaks(previous, next);
    for (const item of breakDiff.changed) {
      await tx.collection('dp_breaks').doc(`${openid}_${item.id}`).set({
        data: { _openid: openid, breakItem: item, updatedAt: db.serverDate() },
      });
    }
    for (const id of breakDiff.removed) {
      try {
        await tx.collection('dp_breaks').doc(`${openid}_${id}`).remove();
      } catch {
        // already absent
      }
    }

    await tx.collection('dp_meta').doc(openid).set({
      data: {
        _openid: openid,
        schema: 1,
        revision: expected + 1,
        generation: meta?.generation ?? 0,
        deleted: false,
        updatedAt: db.serverDate(),
      },
    });
    await tx.commit();
    return { revision: expected + 1 };
  } catch (error) {
    try {
      await tx.rollback();
    } catch {
      // transaction may already be rolled back
    }
    throw error;
  }
}

async function removeAll(collection, openid) {
  // Delete in batches of 100 so a large account deletion cannot silently stop
  // after the first page. Re-running is safe when a previous attempt failed.
  for (;;) {
    let batch;
    try {
      batch = await db
        .collection(collection)
        .where({ _openid: openid })
        .limit(100)
        .get();
    } catch {
      return;
    }
    if (!batch?.data?.length) return;
    for (const row of batch.data) {
      // Fail the run on a delete error; re-running is safe because the
      // tombstone remains. Ignoring errors could loop forever on the same page.
      await db.collection(collection).doc(row._id).remove();
    }
    if (batch.data.length < 100) return;
  }
}

async function deleteAccount(openid, expected) {
  const meta = await getDoc('dp_meta', openid);
  const revision = meta?.revision ?? 0;
  // A previous deletion may have stopped after marking the tombstone. Resume
  // cleanup without requiring the old revision, so retry is possible.
  if (meta?.deleted !== true && revision !== expected) {
    return { conflict: true, revision };
  }

  if (meta?.deleted !== true) {
    await db.collection('dp_meta').doc(openid).set({
      data: {
        _openid: openid,
        schema: 1,
        revision: revision + 1,
        generation: (meta?.generation ?? 0) + 1,
        deleted: true,
        updatedAt: db.serverDate(),
      },
    });
  }

  for (const collection of COLLECTIONS) await removeAll(collection, openid);
  return { revision: revision + (meta?.deleted === true ? 0 : 1) };
}

function normalizeJobPayload(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return {};
  const result = {};
  for (const [key, item] of Object.entries(value)) {
    if (typeof item === 'string' || typeof item === 'number') result[key] = String(item);
  }
  return result;
}

async function createReminderJob(openid, event) {
  const kind = event?.kind;
  if (kind !== 'once' && kind !== 'digest') return fail('bad_reminder_kind');
  const templateId = String(event?.templateId ?? '').trim();
  if (!templateId) return fail('template_missing');
  const sendAt = Number(event?.sendAt);
  if (!Number.isFinite(sendAt) || sendAt < Date.now() - 60_000) {
    return fail('invalid_send_at');
  }
  let day;
  try {
    day = event?.day ? parseDay(event.day) : todayKey();
  } catch {
    return fail('invalid_day');
  }
  const jobId = `${openid}_${randomUUID()}`;
  await db.collection('dp_jobs').doc(jobId).set({
    data: {
      _openid: openid,
      id: jobId,
      kind,
      habitId: event?.habitId ? String(event.habitId) : null,
      day,
      sendAt: new Date(sendAt),
      status: 'pending',
      templateId,
      page: typeof event?.page === 'string' ? event.page : '',
      payload: normalizeJobPayload(event?.payload),
      createdAt: db.serverDate(),
    },
  });
  return { ok: true, jobId };
}

async function reminderStatus(openid, event) {
  const day = event?.day ? parseDay(event.day) : todayKey();
  const result = await db
    .collection('dp_jobs')
    .where({ _openid: openid, day })
    .limit(50)
    .get();
  return {
    ok: true,
    jobs: result.data.map((row) => ({
      id: row.id,
      kind: row.kind,
      habitId: row.habitId ?? null,
      day: row.day,
      sendAt: row.sendAt instanceof Date ? row.sendAt.toISOString() : row.sendAt,
      status: row.status,
      templateId: row.templateId,
    })),
  };
}

function contextFrom(event) {
  const day = event?.today;
  const today = day ? parseDay(day) : todayKey();
  return { today, idFactory: () => randomUUID() };
}

async function mutate(openid, event) {
  if (!event?.action || typeof event.action !== 'string') return fail('bad_action');
  if (event.action === 'deleteAccount') {
    const result = await deleteAccount(openid, Number(event.expectedRevision ?? -1));
    if (result.conflict) return { ...fail('conflict'), revision: result.revision };
    return { ok: true, revision: result.revision };
  }

  const expected = Number(event.expectedRevision ?? -1);
  const loaded = await loadUser(openid, event.day);
  if (loaded.revision !== expected) {
    return { ...fail('conflict'), revision: loaded.revision };
  }

  const ctx = contextFrom(event);
  let next: UserState;
  try {
    switch (event.action) {
      case 'createHabit':
        next = createHabit(loaded.state, event.input, ctx);
        break;
      case 'recordHabit':
        next = recordHabit(
          loaded.state,
          String(event.habitId ?? ''),
          String(event.day ?? ''),
          Number(event.value),
          ctx,
        );
        break;
      case 'clearHabit':
        next = clearHabit(
          loaded.state,
          String(event.habitId ?? ''),
          String(event.day ?? ''),
        );
        break;
      case 'archiveHabit':
        next = archiveHabit(
          loaded.state,
          String(event.habitId ?? ''),
          event.archived !== false,
        );
        break;
      case 'deleteHabit':
        next = deleteHabit(loaded.state, String(event.habitId ?? ''));
        break;
      case 'updateReminderPrefs':
        next = updateReminderPrefs(loaded.state, event.patch ?? {});
        break;
      case 'createChallenge':
        next = createChallenge(
          loaded.state,
          String(event.habitId ?? ''),
          Number(event.length) as any,
          ctx,
        );
        break;
      case 'abandonChallenge':
        next = abandonChallenge(loaded.state, String(event.challengeId ?? ''));
        break;
      case 'updateSettings':
        next = updateSettings(loaded.state, event.patch ?? {});
        break;
      case 'favoriteCard':
        next = setCardFavorite(
          loaded.state,
          String(event.day ?? ''),
          event.favorite === true,
        );
        break;
      case 'saveReflection':
        next = saveCardReflection(
          loaded.state,
          String(event.day ?? ''),
          String(event.reflection ?? ''),
        );
        break;
      case 'createTask':
        next = createTask(loaded.state, event.input, ctx);
        break;
      case 'completeTask':
        next = completeTask(
          loaded.state,
          String(event.taskId ?? ''),
          event.done === true,
          String(event.day ?? ''),
          ctx,
        );
        break;
      case 'archiveTask':
        next = archiveTask(
          loaded.state,
          String(event.taskId ?? ''),
          event.archived !== false,
        );
        break;
      case 'deleteTask':
        next = deleteTask(loaded.state, String(event.taskId ?? ''));
        break;
      case 'updateTask':
        next = updateTask(
          loaded.state,
          String(event.taskId ?? ''),
          event.patch ?? {},
        );
        break;
      case 'createNote':
        next = createNote(loaded.state, event.input, ctx);
        break;
      case 'updateNote':
        next = updateNote(
          loaded.state,
          String(event.noteId ?? ''),
          event.patch ?? {},
          ctx,
        );
        break;
      case 'deleteNote':
        next = deleteNote(loaded.state, String(event.noteId ?? ''));
        break;
      default:
        return fail('bad_action');
    }
    if (event.action === 'recordHabit' && event.day === ctx.today) {
      // A day card is earned only after all daily obligations are met; it is
      // immutable afterwards, including undo/plan edits.
      next = ensureCard(next, ctx.today);
    }
  } catch (error) {
    if (error instanceof ValidationError) return fail(error.code);
    if (error?.message === 'Invalid calendar date') return fail('invalid_day');
    return fail('invalid_input');
  }

  const result = await persist(openid, expected, loaded.state, next);
  if (result.conflict) return { ...fail('conflict'), revision: result.revision };
  return { ok: true, revision: result.revision };
}

export async function main(event) {
  const { OPENID } = cloud.getWXContext();
  if (!OPENID) return fail('unauthenticated');

  try {
    if (event?.action === 'reminderStatus') {
      return await reminderStatus(OPENID, event);
    }
    if (event?.action === 'createReminderJob') {
      return await createReminderJob(OPENID, event);
    }
    if (event?.action === 'today') {
      const day = event?.day ? parseDay(event.day) : todayKey();
      const loaded = await loadUser(OPENID, day);
      return {
        ok: true,
        revision: loaded.revision,
        profile: loaded.profile,
        day: loaded.todayRecord,
        card: loaded.card,
        breaks: loaded.state.breaks,
        backfills: loaded.state.backfills,
      };
    }
    if (event?.action === 'tasks') {
      const loaded = await loadUser(OPENID, event?.day);
      return {
        ok: true,
        revision: loaded.revision,
        tasks: loaded.state.tasks,
        taskDays: loaded.state.taskDays,
      };
    }
    if (event?.action === 'challenges') {
      const today = event?.today ? parseDay(event.today) : todayKey();
      const loaded = await loadUser(OPENID, today);
      return {
        ok: true,
        revision: loaded.revision,
        challenges: loaded.state.challenges.map((challenge) =>
          challengeProgress(loaded.state, challenge, today),
        ),
      };
    }
    if (event?.action === 'cards') {
      const loaded = await loadUser(OPENID, event?.day);
      return {
        ok: true,
        revision: loaded.revision,
        cards: [...loaded.state.cards].sort((a, b) =>
          String(b.day).localeCompare(String(a.day)),
        ),
      };
    }
    if (event?.action === 'syncSteps') {
      const cloudID = String(event?.cloudID ?? '');
      if (!cloudID) return fail('missing_cloud_id');
      const opened = await cloud.getOpenData([cloudID]);
      const data = opened?.list?.[0]?.data;
      if (!data || !Array.isArray(data.stepInfoList)) return fail('step_data_missing');
      const rows = [];
      for (const item of data.stepInfoList) {
        const timestamp = Number(item.timestamp);
        const steps = Number(item.step);
        if (!Number.isFinite(timestamp) || !Number.isFinite(steps)) continue;
        const local = new Date(timestamp + 8 * 60 * 60 * 1000);
        const day = `${local.getUTCFullYear()}-${String(local.getUTCMonth() + 1).padStart(2, '0')}-${String(local.getUTCDate()).padStart(2, '0')}`;
        rows.push({ day, steps: Math.max(0, Math.trunc(steps)) });
        await db.collection('dp_step_days').doc(`${OPENID}_${day}`).set({
          data: { _openid: OPENID, day, steps: Math.max(0, Math.trunc(steps)), updatedAt: db.serverDate() },
        });
      }
      return { ok: true, steps: rows.sort((a, b) => a.day.localeCompare(b.day)) };
    }
    if (event?.action === 'settings') {
      const loaded = await loadUser(OPENID, event?.day);
      return {
        ok: true,
        revision: loaded.revision,
        settings: loaded.profile.settings,
      };
    }
    if (event?.action === 'year') {
      const year = Number(event?.year);
      if (!Number.isInteger(year) || year < 1900 || year > 2200) {
        return fail('invalid_year');
      }
      const loaded = await loadUser(OPENID, event?.day);
      const prefix = `${year}-`;
      return {
        ok: true,
        revision: loaded.revision,
        year,
        days: Object.values(loaded.state.days)
          .filter((record) => record.day.startsWith(prefix))
          .map((record) => ({ day: record.day, entries: record.entries })),
        cards: loaded.state.cards.filter((card) => card.day.startsWith(prefix)),
      };
    }
    if (event?.action === 'timeline') {
      const month = String(event?.month ?? '');
      if (!/^\d{4}-\d{2}$/.test(month)) return fail('invalid_month');
      const loaded = await loadUser(OPENID, event?.day);
      const days = Object.keys(loaded.state.days).filter((day) =>
        day.startsWith(`${month}-`),
      );
      const events = [];
      const habitById = new Map(
        loaded.state.profile.habits.map((habit) => [habit.id, habit]),
      );
      for (const day of days) {
        const record = loaded.state.days[day];
        for (const [habitId, value] of Object.entries(record.entries)) {
          const habit = habitById.get(habitId);
          if (!habit) continue;
          events.push({
            type: 'habit',
            day,
            id: habitId,
            title: habit.title,
            value,
            kind: habit.kind,
            backfilled: loaded.state.backfills.some(
              (item) => item.habitId === habitId && item.day === day,
            ),
          });
        }
      }
      for (const task of loaded.state.tasks) {
        if (!task.resident && task.completedDay?.startsWith(`${month}-`)) {
          events.push({
            type: 'task',
            day: task.completedDay,
            id: task.id,
            title: task.title,
            resident: false,
          });
        }
      }
      for (const [day, ids] of Object.entries(loaded.state.taskDays)) {
        if (!day.startsWith(`${month}-`)) continue;
        for (const id of ids) {
          const task = loaded.state.tasks.find((item) => item.id === id);
          if (!task) continue;
          events.push({
            type: 'task',
            day,
            id,
            title: task.title,
            resident: true,
          });
        }
      }
      for (const note of loaded.state.notes) {
        if (note.day.startsWith(`${month}-`)) {
          events.push({
            type: 'note',
            day: note.day,
            id: note.id,
            title: note.body.slice(0, 80),
          });
        }
      }
      for (const card of loaded.state.cards) {
        if (card.day.startsWith(`${month}-`)) {
          events.push({ type: 'card', day: card.day, id: card.day, title: '成就卡' });
        }
      }
      events.sort((a, b) => String(b.day).localeCompare(String(a.day)));
      return { ok: true, revision: loaded.revision, month, events };
    }
    if (event?.action === 'insights') {
      const today = event?.today ? parseDay(event.today) : todayKey();
      const range = Number(event?.range ?? 30);
      const loaded = await loadUser(OPENID, today);
      return {
        ok: true,
        revision: loaded.revision,
        insights: insights(loaded.state, range, today),
      };
    }
    if (event?.action === 'stats') {
      const today = event?.today ? parseDay(event.today) : todayKey();
      const rangeDays = Number(event?.rangeDays ?? 30);
      const loaded = await loadUser(OPENID, today);
      return {
        ok: true,
        revision: loaded.revision,
        stats: habitStats(loaded.state, rangeDays, today),
      };
    }
    if (event?.action === 'notes') {
      const loaded = await loadUser(OPENID, event?.day);
      return {
        ok: true,
        revision: loaded.revision,
        notes: filterNotes(loaded.state, event?.query ?? {}),
      };
    }
    return await mutate(OPENID, event);
  } catch (error) {
    if (error?.message === 'conflict') return fail('conflict');
    return fail('cloud_error');
  }
}