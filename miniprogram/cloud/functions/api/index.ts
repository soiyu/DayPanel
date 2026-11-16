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
  deleteHabit,
  recordHabit,
  updateReminderPrefs,
  ValidationError,
} from '../../../src/application/habit-actions.ts';

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
  try {
    await db.collection(collection).where({ _openid: openid }).remove();
  } catch {
    // an empty/missing collection is acceptable
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
      default:
        return fail('bad_action');
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
    if (event?.action === 'today') {
      const day = event?.day ? parseDay(event.day) : todayKey();
      const loaded = await loadUser(OPENID, day);
      return {
        ok: true,
        revision: loaded.revision,
        profile: loaded.profile,
        day: loaded.todayRecord,
        card: loaded.card,
      };
    }
    return await mutate(OPENID, event);
  } catch (error) {
    if (error?.message === 'conflict') return fail('conflict');
    return fail('cloud_error');
  }
}