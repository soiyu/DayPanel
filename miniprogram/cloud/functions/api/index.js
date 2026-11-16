"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// cloud/functions/api/index.ts
var index_exports = {};
__export(index_exports, {
  main: () => main
});
module.exports = __toCommonJS(index_exports);
var import_wx_server_sdk = __toESM(require("wx-server-sdk"));
var import_node_crypto = require("node:crypto");

// src/domain/day.ts
var DAY_RE = /^(\d{4})-(\d{2})-(\d{2})$/;
var MS_PER_DAY = 864e5;
function pad(value, width = 2) {
  return String(value).padStart(width, "0");
}
function makeDay(year, month, day) {
  if (!Number.isInteger(year) || !Number.isInteger(month) || !Number.isInteger(day) || year < 1900 || year > 2200 || month < 1 || month > 12 || day < 1 || day > 31) {
    throw new RangeError("Invalid calendar date");
  }
  const date = new Date(Date.UTC(year, month - 1, day));
  if (date.getUTCFullYear() !== year || date.getUTCMonth() !== month - 1 || date.getUTCDate() !== day) {
    throw new RangeError("Invalid calendar date");
  }
  return `${pad(year, 4)}-${pad(month)}-${pad(day)}`;
}
function parseDay(value) {
  const match = DAY_RE.exec(value);
  if (!match) throw new FormatException("Invalid calendar date");
  const [, y, m, d] = match;
  return makeDay(Number(y), Number(m), Number(d));
}
function todayKey(now = /* @__PURE__ */ new Date()) {
  return makeDay(now.getFullYear(), now.getMonth() + 1, now.getDate());
}
function utcMillis(day) {
  const match = DAY_RE.exec(day);
  if (!match) throw new FormatException("Invalid calendar date");
  return Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
}
function daysSince(day, other) {
  return Math.round((utcMillis(parseDay(day)) - utcMillis(parseDay(other))) / MS_PER_DAY);
}
function compareDay(a, b) {
  const left = parseDay(a);
  const right = parseDay(b);
  return left < right ? -1 : left > right ? 1 : 0;
}
function weekday(day) {
  const date = new Date(utcMillis(parseDay(day)));
  const sundayBased = date.getUTCDay();
  return sundayBased === 0 ? 7 : sundayBased;
}
function weekdayBit(day) {
  return 1 << weekday(day) - 1;
}
var FormatException = class extends Error {
  constructor(message = "Invalid calendar date") {
    super(message);
    this.name = "FormatException";
  }
};

// src/domain/quantity.ts
function isValidRecordValue(kind, value) {
  if (!Number.isSafeInteger(value) || value < 0) return false;
  if (kind === "check") return value === 1e3;
  if (kind === "count") return value % 1e3 === 0;
  return true;
}

// src/domain/models.ts
var DEFAULT_SETTINGS = {
  locale: "system",
  theme: "system",
  palette: "blue",
  font: "system",
  iconFrame: "soft",
  completionSound: false,
  completionHaptics: false
};
function defaultReminderPrefs() {
  return {
    once: true,
    digest: true,
    calendar: true,
    digestMinute: 21 * 60
  };
}
function defaultProfile() {
  return {
    habits: [],
    groups: [],
    settings: { ...DEFAULT_SETTINGS },
    reminders: defaultReminderPrefs()
  };
}
function emptyState() {
  return {
    profile: defaultProfile(),
    days: {},
    tasks: [],
    taskDays: {},
    notes: [],
    cards: [],
    activity: [],
    breaks: [],
    events: [],
    jobs: []
  };
}
function cloneState(state) {
  if (typeof structuredClone === "function") return structuredClone(state);
  return JSON.parse(JSON.stringify(state));
}
function findHabit(state, id) {
  return state.profile.habits.find((habit) => habit.id === id) ?? null;
}
function currentPlan(habit, day) {
  const plans = [...habit.plans].sort(
    (a, b) => compareDay(a.effectiveDay, b.effectiveDay)
  );
  let current = plans[0];
  if (!current) throw new Error("Habit has no plan");
  for (const plan of plans) {
    if (compareDay(plan.effectiveDay, day) <= 0) current = plan;
  }
  return current;
}
function scheduledOn(plan, day) {
  if (compareDay(day, plan.effectiveDay) < 0) return false;
  switch (plan.schedule) {
    case "weekdays":
      return (plan.weekdays & weekdayBit(day)) !== 0;
    case "interval":
      return daysSince(day, plan.effectiveDay) % plan.intervalDays === 0;
    case "weekly":
    case "weeklyTotal":
      return true;
  }
}
function isRestOn(breaks, habitId, day) {
  return breaks.some(
    (item) => item.habitId === habitId && compareDay(day, item.startDay) >= 0 && (item.endDay === null || compareDay(day, item.endDay) <= 0)
  );
}

// src/application/habit-actions.ts
var ValidationError = class extends Error {
  code;
  constructor(code, message = code) {
    super(message);
    this.name = "ValidationError";
    this.code = code;
  }
};
var HABIT_COLORS = ["auto", "blue", "violet", "peach", "teal", "rose"];
var HABIT_FRAMES = ["auto", "soft", "ring", "plain"];
var HABIT_CONTEXTS = [
  "anytime",
  "morning",
  "daytime",
  "evening"
];
var fallbackCounter = 0;
function defaultId() {
  const cryptoApi = globalThis.crypto;
  if (cryptoApi?.randomUUID) return cryptoApi.randomUUID();
  fallbackCounter += 1;
  return `local-${Date.now().toString(36)}-${fallbackCounter.toString(36)}`;
}
function requireToday(context) {
  return parseDay(context.today);
}
function assertUniqueId(state, id) {
  if (state.profile.habits.some((habit) => habit.id === id) || state.tasks.some((task) => task.id === id) || state.notes.some((note) => note.id === id)) {
    throw new ValidationError("id_conflict");
  }
}
function validatePlan(kind, target, schedule, weekdays, intervalDays, weeklyGoal, unit) {
  if (!Number.isSafeInteger(target) || target <= 0) {
    throw new ValidationError("invalid_target");
  }
  if (kind === "check" && target !== 1e3) {
    throw new ValidationError("invalid_check_target");
  }
  if (kind === "count" && target % 1e3 !== 0) {
    throw new ValidationError("invalid_count_target");
  }
  if (kind === "check" && schedule === "weeklyTotal") {
    throw new ValidationError("weekly_total_requires_numeric");
  }
  if (!["weekdays", "interval", "weekly", "weeklyTotal"].includes(schedule)) {
    throw new ValidationError("invalid_schedule");
  }
  if (!Number.isInteger(weekdays) || weekdays < 1 || weekdays > 127) {
    throw new ValidationError("invalid_weekdays");
  }
  if (!Number.isInteger(intervalDays) || intervalDays < 1 || intervalDays > 365) {
    throw new ValidationError("invalid_interval");
  }
  if (!Number.isInteger(weeklyGoal) || weeklyGoal < 1 || weeklyGoal > 7) {
    throw new ValidationError("invalid_weekly_goal");
  }
  if (unit.length > 12) throw new ValidationError("unit_too_long");
}
function createHabit(state, input, context) {
  const today = requireToday(context);
  const id = (context.idFactory ?? defaultId)();
  assertUniqueId(state, id);
  const title = input.title.trim();
  if (!title || title.length > 100) {
    throw new ValidationError("invalid_title");
  }
  if (!["check", "quantity", "count"].includes(input.kind)) {
    throw new ValidationError("invalid_kind");
  }
  const startDay = parseDay(input.startDay ?? today);
  if (compareDay(startDay, today) > 0) {
    throw new ValidationError("start_day_in_future");
  }
  const unit = (input.unit ?? "").trim();
  const schedule = input.schedule ?? "weekdays";
  const weekdays = input.weekdays ?? 127;
  const intervalDays = input.intervalDays ?? 1;
  const weeklyGoal = input.weeklyGoal ?? 3;
  validatePlan(
    input.kind,
    input.target,
    schedule,
    weekdays,
    intervalDays,
    weeklyGoal,
    unit
  );
  const icon = input.icon ?? 0;
  if (!Number.isInteger(icon) || icon < 0 || icon >= 28) {
    throw new ValidationError("invalid_icon");
  }
  const color = input.color ?? "auto";
  const frame = input.frame ?? "auto";
  const habitContext = input.context ?? "anytime";
  if (!HABIT_COLORS.includes(color)) throw new ValidationError("invalid_color");
  if (!HABIT_FRAMES.includes(frame)) throw new ValidationError("invalid_frame");
  if (!HABIT_CONTEXTS.includes(habitContext)) {
    throw new ValidationError("invalid_context");
  }
  const next = cloneState(state);
  const position = next.profile.habits.reduce((max, habit2) => Math.max(max, habit2.position), -1) + 1;
  const plan = {
    effectiveDay: startDay,
    target: input.target,
    unit,
    schedule,
    weekdays,
    intervalDays,
    weeklyGoal
  };
  const habit = {
    id,
    title,
    kind: input.kind,
    startDay,
    archived: false,
    icon,
    color,
    frame,
    context: habitContext,
    groupId: null,
    position,
    plans: [plan]
  };
  next.profile.habits.push(habit);
  return next;
}
function recordHabit(state, habitId, day, value, context) {
  const today = requireToday(context);
  const targetDay = parseDay(day);
  if (compareDay(targetDay, today) > 0) {
    throw new ValidationError("future_day");
  }
  const habit = findHabit(state, habitId);
  if (!habit) throw new ValidationError("habit_missing");
  if (habit.archived) throw new ValidationError("habit_archived");
  if (compareDay(targetDay, habit.startDay) < 0) {
    throw new ValidationError("before_start");
  }
  if (isRestOn(state.breaks, habitId, targetDay)) {
    throw new ValidationError("rest_day");
  }
  if (!scheduledOn(currentPlan(habit, targetDay), targetDay)) {
    throw new ValidationError("not_scheduled");
  }
  if (!isValidRecordValue(habit.kind, value)) {
    throw new ValidationError("invalid_value");
  }
  const next = cloneState(state);
  const record = next.days[targetDay] ?? { day: targetDay, entries: {} };
  record.entries[habitId] = value;
  next.days[targetDay] = record;
  return next;
}
function clearHabit(state, habitId, day) {
  const targetDay = parseDay(day);
  const habit = findHabit(state, habitId);
  if (!habit) throw new ValidationError("habit_missing");
  const next = cloneState(state);
  const record = next.days[targetDay];
  if (!record) return next;
  delete record.entries[habitId];
  if (Object.keys(record.entries).length === 0) {
    delete next.days[targetDay];
  } else {
    next.days[targetDay] = record;
  }
  return next;
}
function archiveHabit(state, habitId, archived = true) {
  const next = cloneState(state);
  const habit = findHabit(next, habitId);
  if (!habit) throw new ValidationError("habit_missing");
  habit.archived = archived;
  return next;
}
function deleteHabit(state, habitId) {
  const next = cloneState(state);
  const habit = findHabit(next, habitId);
  if (!habit) throw new ValidationError("habit_missing");
  next.profile.habits = next.profile.habits.filter((item) => item.id !== habitId);
  for (const [day, record] of Object.entries(next.days)) {
    delete record.entries[habitId];
    if (Object.keys(record.entries).length === 0) delete next.days[day];
  }
  next.breaks = next.breaks.filter((item) => item.habitId !== habitId);
  next.activity = next.activity.filter((item) => item.habitId !== habitId);
  next.notes = next.notes.map(
    (note) => note.habitId === habitId ? { ...note, habitId: null } : note
  );
  next.profile.habits.forEach((item, index) => {
    item.position = index;
  });
  return next;
}
function updateReminderPrefs(state, patch) {
  const next = cloneState(state);
  const prefs = next.profile.reminders;
  for (const key of ["once", "digest", "calendar"]) {
    if (patch[key] !== void 0 && typeof patch[key] !== "boolean") {
      throw new ValidationError("invalid_reminder_channel");
    }
  }
  if (patch.digestMinute !== void 0 && (!Number.isInteger(patch.digestMinute) || patch.digestMinute < 0 || patch.digestMinute > 1439)) {
    throw new ValidationError("invalid_digest_minute");
  }
  next.profile.reminders = { ...prefs, ...patch };
  return next;
}

// src/application/task-actions.ts
function uniqueId(state, id) {
  return !state.tasks.some((task) => task.id === id) && !state.profile.habits.some((habit) => habit.id === id) && !state.notes.some((note) => note.id === id);
}
function createTask(state, input, context) {
  const today = parseDay(context.today);
  const title = input.title.trim();
  if (!title || title.length > 100) throw new ValidationError("invalid_title");
  const resident = input.resident === true;
  const dueDay = input.dueDay ? parseDay(input.dueDay) : null;
  if (resident && dueDay) throw new ValidationError("resident_has_due");
  const id = (context.idFactory ?? defaultId)();
  if (!uniqueId(state, id)) throw new ValidationError("id_conflict");
  const next = cloneState(state);
  const task = {
    id,
    title,
    dueDay: resident ? null : dueDay,
    completedDay: null,
    resident,
    startDay: resident ? today : null,
    archived: false
  };
  next.tasks.push(task);
  return next;
}
function completeTask(state, taskId, done, day, context) {
  const today = parseDay(context.today);
  const targetDay = parseDay(day);
  if (compareDay(targetDay, today) > 0) throw new ValidationError("future_day");
  const task = state.tasks.find((item) => item.id === taskId);
  if (!task) throw new ValidationError("task_missing");
  if (task.archived) throw new ValidationError("task_archived");
  const next = cloneState(state);
  if (task.resident) {
    const ids = next.taskDays[targetDay] ?? [];
    const has = ids.includes(taskId);
    if (done && !has) next.taskDays[targetDay] = [...ids, taskId];
    if (!done && has) {
      const remaining = ids.filter((id) => id !== taskId);
      if (remaining.length) next.taskDays[targetDay] = remaining;
      else delete next.taskDays[targetDay];
    }
    return next;
  }
  const stored = next.tasks.find((item) => item.id === taskId);
  if (!stored) throw new ValidationError("task_missing");
  stored.completedDay = done ? targetDay : null;
  return next;
}
function archiveTask(state, taskId, archived = true) {
  const next = cloneState(state);
  const task = next.tasks.find((item) => item.id === taskId);
  if (!task) throw new ValidationError("task_missing");
  task.archived = archived;
  return next;
}
function deleteTask(state, taskId) {
  if (!state.tasks.some((task) => task.id === taskId)) {
    throw new ValidationError("task_missing");
  }
  const next = cloneState(state);
  next.tasks = next.tasks.filter((task) => task.id !== taskId);
  for (const [day, ids] of Object.entries(next.taskDays)) {
    const remaining = ids.filter((id) => id !== taskId);
    if (remaining.length) next.taskDays[day] = remaining;
    else delete next.taskDays[day];
  }
  return next;
}

// src/application/journal-actions.ts
function normalizeBody(body) {
  const value = body.trim();
  if (!value) throw new ValidationError("empty_note");
  if (value.length > 1e4) throw new ValidationError("note_too_long");
  return value;
}
function validHabit(state, habitId) {
  if (habitId === void 0 || habitId === null) return null;
  if (!state.profile.habits.some((habit) => habit.id === habitId)) {
    throw new ValidationError("habit_missing");
  }
  return habitId;
}
function uniqueId2(state, id) {
  return !state.notes.some((note) => note.id === id) && !state.tasks.some((task) => task.id === id) && !state.profile.habits.some((habit) => habit.id === id);
}
function createNote(state, input, context) {
  const today = parseDay(context.today);
  const day = input.day ? parseDay(input.day) : today;
  if (compareDay(day, today) > 0) throw new ValidationError("future_day");
  const body = normalizeBody(input.body);
  const habitId = validHabit(state, input.habitId);
  const id = (context.idFactory ?? defaultId)();
  if (!uniqueId2(state, id)) throw new ValidationError("id_conflict");
  const next = cloneState(state);
  next.notes.push({ id, body, day, habitId });
  return next;
}
function updateNote(state, noteId, input, context) {
  const today = parseDay(context.today);
  const next = cloneState(state);
  const note = next.notes.find((item) => item.id === noteId);
  if (!note) throw new ValidationError("note_missing");
  if (input.body !== void 0) note.body = normalizeBody(input.body);
  if (input.day !== void 0) {
    const day = parseDay(input.day);
    if (compareDay(day, today) > 0) throw new ValidationError("future_day");
    note.day = day;
  }
  if (input.habitId !== void 0) {
    note.habitId = validHabit(next, input.habitId);
  }
  return next;
}
function deleteNote(state, noteId) {
  if (!state.notes.some((note) => note.id === noteId)) {
    throw new ValidationError("note_missing");
  }
  const next = cloneState(state);
  next.notes = next.notes.filter((note) => note.id !== noteId);
  return next;
}
function filterNotes(state, query) {
  const text = (query.text ?? "").trim().toLowerCase();
  const month = query.month ?? null;
  if (month !== null && !/^\d{4}-\d{2}$/.test(month)) {
    throw new ValidationError("invalid_month");
  }
  const day = query.day ? parseDay(query.day) : null;
  const habitId = query.habitId ?? null;
  return state.notes.filter((note) => {
    if (month && !note.day.startsWith(`${month}-`)) return false;
    if (day && note.day !== day) return false;
    if (habitId && note.habitId !== habitId) return false;
    if (text && !note.body.toLowerCase().includes(text)) return false;
    return true;
  }).sort((a, b) => {
    const dayOrder = compareDay(b.day, a.day);
    return dayOrder !== 0 ? dayOrder : a.id.localeCompare(b.id);
  });
}

// cloud/functions/api/index.ts
import_wx_server_sdk.default.init({ env: import_wx_server_sdk.default.DYNAMIC_CURRENT_ENV });
var db = import_wx_server_sdk.default.database();
var COLLECTIONS = [
  "dp_days",
  "dp_profile",
  "dp_cards",
  "dp_tasks",
  "dp_task_days",
  "dp_notes",
  "dp_activity",
  "dp_breaks",
  "dp_events",
  "dp_jobs"
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
    const result = await db.collection(collection).where({ _openid: openid }).skip(skip).limit(size).get();
    rows.push(...result.data);
    if (result.data.length < size) break;
    if (rows.length > 2e4) throw new Error("too_many_rows");
  }
  return rows;
}
async function loadUser(openid, day) {
  const meta = await getDoc("dp_meta", openid);
  const revision = meta?.revision ?? 0;
  const generation = meta?.generation ?? 0;
  const deleted = meta?.deleted === true;
  const state = emptyState();
  if (!deleted) {
    const profileDoc = await getDoc("dp_profile", openid);
    if (profileDoc?.profile) state.profile = profileDoc.profile;
    for (const row of await listAll("dp_days", openid)) {
      state.days[row.day] = { day: row.day, entries: row.entries ?? {} };
    }
    for (const row of await listAll("dp_tasks", openid)) {
      if (row.task) state.tasks.push(row.task);
    }
    for (const row of await listAll("dp_task_days", openid)) {
      if (row.day) state.taskDays[row.day] = row.taskIds ?? [];
    }
    for (const row of await listAll("dp_notes", openid)) {
      if (row.note) state.notes.push(row.note);
    }
  }
  let card = null;
  if (!deleted && day) {
    try {
      const result = await db.collection("dp_cards").where({ _openid: openid, day }).limit(1).get();
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
    todayRecord: deleted ? null : state.days[day] ?? null
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
  const days = /* @__PURE__ */ new Set([...Object.keys(previous.taskDays), ...Object.keys(next.taskDays)]);
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
      meta = (await tx.collection("dp_meta").doc(openid).get()).data ?? null;
    } catch {
      meta = null;
    }
    if ((meta?.revision ?? 0) !== expected) {
      await tx.rollback();
      return { conflict: true, revision: meta?.revision ?? 0 };
    }
    await tx.collection("dp_profile").doc(openid).set({
      data: { _openid: openid, profile: next.profile, updatedAt: db.serverDate() }
    });
    for (const record of changedDays(previous, next)) {
      const id = `${openid}_${record.day}`;
      if (record.entries === null) {
        try {
          await tx.collection("dp_days").doc(id).remove();
        } catch {
        }
      } else {
        await tx.collection("dp_days").doc(id).set({
          data: {
            _openid: openid,
            day: record.day,
            entries: record.entries,
            updatedAt: db.serverDate()
          }
        });
      }
    }
    const taskDiff = changedTasks(previous, next);
    for (const task of taskDiff.changed) {
      await tx.collection("dp_tasks").doc(`${openid}_${task.id}`).set({
        data: { _openid: openid, task, updatedAt: db.serverDate() }
      });
    }
    for (const id of taskDiff.removed) {
      try {
        await tx.collection("dp_tasks").doc(`${openid}_${id}`).remove();
      } catch {
      }
    }
    for (const record of changedTaskDays(previous, next)) {
      const id = `${openid}_${record.day}`;
      if (record.taskIds === null) {
        try {
          await tx.collection("dp_task_days").doc(id).remove();
        } catch {
        }
      } else {
        await tx.collection("dp_task_days").doc(id).set({
          data: {
            _openid: openid,
            day: record.day,
            taskIds: record.taskIds,
            updatedAt: db.serverDate()
          }
        });
      }
    }
    const noteDiff = changedNotes(previous, next);
    for (const note of noteDiff.changed) {
      await tx.collection("dp_notes").doc(`${openid}_${note.id}`).set({
        data: { _openid: openid, note, updatedAt: db.serverDate() }
      });
    }
    for (const id of noteDiff.removed) {
      try {
        await tx.collection("dp_notes").doc(`${openid}_${id}`).remove();
      } catch {
      }
    }
    await tx.collection("dp_meta").doc(openid).set({
      data: {
        _openid: openid,
        schema: 1,
        revision: expected + 1,
        generation: meta?.generation ?? 0,
        deleted: false,
        updatedAt: db.serverDate()
      }
    });
    await tx.commit();
    return { revision: expected + 1 };
  } catch (error) {
    try {
      await tx.rollback();
    } catch {
    }
    throw error;
  }
}
async function removeAll(collection, openid) {
  for (; ; ) {
    let batch;
    try {
      batch = await db.collection(collection).where({ _openid: openid }).limit(100).get();
    } catch {
      return;
    }
    if (!batch?.data?.length) return;
    for (const row of batch.data) {
      try {
        await db.collection(collection).doc(row._id).remove();
      } catch {
      }
    }
    if (batch.data.length < 100) return;
  }
}
async function deleteAccount(openid, expected) {
  const meta = await getDoc("dp_meta", openid);
  const revision = meta?.revision ?? 0;
  if (meta?.deleted !== true && revision !== expected) {
    return { conflict: true, revision };
  }
  if (meta?.deleted !== true) {
    await db.collection("dp_meta").doc(openid).set({
      data: {
        _openid: openid,
        schema: 1,
        revision: revision + 1,
        generation: (meta?.generation ?? 0) + 1,
        deleted: true,
        updatedAt: db.serverDate()
      }
    });
  }
  for (const collection of COLLECTIONS) await removeAll(collection, openid);
  return { revision: revision + (meta?.deleted === true ? 0 : 1) };
}
function normalizeJobPayload(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  const result = {};
  for (const [key, item] of Object.entries(value)) {
    if (typeof item === "string" || typeof item === "number") result[key] = String(item);
  }
  return result;
}
async function createReminderJob(openid, event) {
  const kind = event?.kind;
  if (kind !== "once" && kind !== "digest") return fail("bad_reminder_kind");
  const templateId = String(event?.templateId ?? "").trim();
  if (!templateId) return fail("template_missing");
  const sendAt = Number(event?.sendAt);
  if (!Number.isFinite(sendAt) || sendAt < Date.now() - 6e4) {
    return fail("invalid_send_at");
  }
  let day;
  try {
    day = event?.day ? parseDay(event.day) : todayKey();
  } catch {
    return fail("invalid_day");
  }
  const jobId = `${openid}_${(0, import_node_crypto.randomUUID)()}`;
  await db.collection("dp_jobs").doc(jobId).set({
    data: {
      _openid: openid,
      id: jobId,
      kind,
      habitId: event?.habitId ? String(event.habitId) : null,
      day,
      sendAt: new Date(sendAt),
      status: "pending",
      templateId,
      page: typeof event?.page === "string" ? event.page : "",
      payload: normalizeJobPayload(event?.payload),
      createdAt: db.serverDate()
    }
  });
  return { ok: true, jobId };
}
async function reminderStatus(openid, event) {
  const day = event?.day ? parseDay(event.day) : todayKey();
  const result = await db.collection("dp_jobs").where({ _openid: openid, day }).limit(50).get();
  return {
    ok: true,
    jobs: result.data.map((row) => ({
      id: row.id,
      kind: row.kind,
      habitId: row.habitId ?? null,
      day: row.day,
      sendAt: row.sendAt instanceof Date ? row.sendAt.toISOString() : row.sendAt,
      status: row.status,
      templateId: row.templateId
    }))
  };
}
function contextFrom(event) {
  const day = event?.today;
  const today = day ? parseDay(day) : todayKey();
  return { today, idFactory: () => (0, import_node_crypto.randomUUID)() };
}
async function mutate(openid, event) {
  if (!event?.action || typeof event.action !== "string") return fail("bad_action");
  if (event.action === "deleteAccount") {
    const result2 = await deleteAccount(openid, Number(event.expectedRevision ?? -1));
    if (result2.conflict) return { ...fail("conflict"), revision: result2.revision };
    return { ok: true, revision: result2.revision };
  }
  const expected = Number(event.expectedRevision ?? -1);
  const loaded = await loadUser(openid, event.day);
  if (loaded.revision !== expected) {
    return { ...fail("conflict"), revision: loaded.revision };
  }
  const ctx = contextFrom(event);
  let next;
  try {
    switch (event.action) {
      case "createHabit":
        next = createHabit(loaded.state, event.input, ctx);
        break;
      case "recordHabit":
        next = recordHabit(
          loaded.state,
          String(event.habitId ?? ""),
          String(event.day ?? ""),
          Number(event.value),
          ctx
        );
        break;
      case "clearHabit":
        next = clearHabit(
          loaded.state,
          String(event.habitId ?? ""),
          String(event.day ?? "")
        );
        break;
      case "archiveHabit":
        next = archiveHabit(
          loaded.state,
          String(event.habitId ?? ""),
          event.archived !== false
        );
        break;
      case "deleteHabit":
        next = deleteHabit(loaded.state, String(event.habitId ?? ""));
        break;
      case "updateReminderPrefs":
        next = updateReminderPrefs(loaded.state, event.patch ?? {});
        break;
      case "createTask":
        next = createTask(loaded.state, event.input, ctx);
        break;
      case "completeTask":
        next = completeTask(
          loaded.state,
          String(event.taskId ?? ""),
          event.done === true,
          String(event.day ?? ""),
          ctx
        );
        break;
      case "archiveTask":
        next = archiveTask(
          loaded.state,
          String(event.taskId ?? ""),
          event.archived !== false
        );
        break;
      case "deleteTask":
        next = deleteTask(loaded.state, String(event.taskId ?? ""));
        break;
      case "createNote":
        next = createNote(loaded.state, event.input, ctx);
        break;
      case "updateNote":
        next = updateNote(
          loaded.state,
          String(event.noteId ?? ""),
          event.patch ?? {},
          ctx
        );
        break;
      case "deleteNote":
        next = deleteNote(loaded.state, String(event.noteId ?? ""));
        break;
      default:
        return fail("bad_action");
    }
  } catch (error) {
    if (error instanceof ValidationError) return fail(error.code);
    if (error?.message === "Invalid calendar date") return fail("invalid_day");
    return fail("invalid_input");
  }
  const result = await persist(openid, expected, loaded.state, next);
  if (result.conflict) return { ...fail("conflict"), revision: result.revision };
  return { ok: true, revision: result.revision };
}
async function main(event) {
  const { OPENID } = import_wx_server_sdk.default.getWXContext();
  if (!OPENID) return fail("unauthenticated");
  try {
    if (event?.action === "reminderStatus") {
      return await reminderStatus(OPENID, event);
    }
    if (event?.action === "createReminderJob") {
      return await createReminderJob(OPENID, event);
    }
    if (event?.action === "today") {
      const day = event?.day ? parseDay(event.day) : todayKey();
      const loaded = await loadUser(OPENID, day);
      return {
        ok: true,
        revision: loaded.revision,
        profile: loaded.profile,
        day: loaded.todayRecord,
        card: loaded.card
      };
    }
    if (event?.action === "tasks") {
      const loaded = await loadUser(OPENID, event?.day);
      return {
        ok: true,
        revision: loaded.revision,
        tasks: loaded.state.tasks,
        taskDays: loaded.state.taskDays
      };
    }
    if (event?.action === "notes") {
      const loaded = await loadUser(OPENID, event?.day);
      return {
        ok: true,
        revision: loaded.revision,
        notes: filterNotes(loaded.state, event?.query ?? {})
      };
    }
    return await mutate(OPENID, event);
  } catch (error) {
    if (error?.message === "conflict") return fail("conflict");
    return fail("cloud_error");
  }
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  main
});
