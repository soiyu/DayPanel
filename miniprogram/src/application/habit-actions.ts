import {
  addDays,
  compareDay,
  daysSince,
  isDayKey,
  parseDay,
  todayKey,
  type DayKey,
} from '../domain/day.ts';
import {
  cloneState,
  currentPlan,
  emptyState,
  findHabit,
  isRestOn,
  isScheduled,
  scheduledOn,
  type Habit,
  type HabitContext,
  type HabitKind,
  type HabitPlan,
  type ScheduleKind,
  type UserState,
} from '../domain/models.ts';
import {
  isValidRecordValue,
  parseCount,
  parseQuantity,
} from '../domain/quantity.ts';

export class ValidationError extends Error {
  readonly code: string;

  constructor(code: string, message = code) {
    super(message);
    this.name = 'ValidationError';
    this.code = code;
  }
}

export interface CreateHabitInput {
  title: string;
  kind: HabitKind;
  target: number;
  unit?: string;
  schedule?: ScheduleKind;
  weekdays?: number;
  intervalDays?: number;
  weeklyGoal?: number;
  icon?: number;
  color?: string;
  frame?: string;
  context?: HabitContext;
  startDay?: DayKey;
}

export interface UpdateHabitInput {
  title?: string;
  target?: number;
  unit?: string;
  schedule?: ScheduleKind;
  weekdays?: number;
  intervalDays?: number;
  weeklyGoal?: number;
  icon?: number;
  color?: string;
  frame?: string;
  context?: HabitContext;
}

export type BreakKind = 'pause' | 'vacation' | 'skip';

export interface ActionContext {
  today: DayKey;
  idFactory?: () => string;
}

export interface ReminderPrefsPatch {
  once?: boolean;
  digest?: boolean;
  calendar?: boolean;
  digestMinute?: number;
}

const HABIT_COLORS = ['auto', 'blue', 'violet', 'peach', 'teal', 'rose'];
const HABIT_FRAMES = ['auto', 'soft', 'ring', 'plain'];
const HABIT_CONTEXTS: HabitContext[] = [
  'anytime',
  'morning',
  'daytime',
  'evening',
];

let fallbackCounter = 0;

export function defaultId(): string {
  const cryptoApi = globalThis.crypto as Crypto | undefined;
  if (cryptoApi?.randomUUID) return cryptoApi.randomUUID();
  fallbackCounter += 1;
  return `local-${Date.now().toString(36)}-${fallbackCounter.toString(36)}`;
}

function requireToday(context: ActionContext): DayKey {
  return parseDay(context.today);
}

function assertUniqueId(state: UserState, id: string): void {
  if (
    state.profile.habits.some((habit) => habit.id === id) ||
    state.tasks.some((task) => task.id === id) ||
    state.notes.some((note) => note.id === id)
  ) {
    throw new ValidationError('id_conflict');
  }
}

function validatePlan(
  kind: HabitKind,
  target: number,
  schedule: ScheduleKind,
  weekdays: number,
  intervalDays: number,
  weeklyGoal: number,
  unit: string,
): void {
  if (!Number.isSafeInteger(target) || target <= 0) {
    throw new ValidationError('invalid_target');
  }
  if (kind === 'check' && target !== 1000) {
    throw new ValidationError('invalid_check_target');
  }
  if (kind === 'count' && target % 1000 !== 0) {
    throw new ValidationError('invalid_count_target');
  }
  if (kind === 'check' && schedule === 'weeklyTotal') {
    throw new ValidationError('weekly_total_requires_numeric');
  }
  if (
    !['weekdays', 'interval', 'weekly', 'weeklyTotal'].includes(schedule)
  ) {
    throw new ValidationError('invalid_schedule');
  }
  if (!Number.isInteger(weekdays) || weekdays < 1 || weekdays > 127) {
    throw new ValidationError('invalid_weekdays');
  }
  if (!Number.isInteger(intervalDays) || intervalDays < 1 || intervalDays > 365) {
    throw new ValidationError('invalid_interval');
  }
  if (!Number.isInteger(weeklyGoal) || weeklyGoal < 1 || weeklyGoal > 7) {
    throw new ValidationError('invalid_weekly_goal');
  }
  if (unit.length > 12) throw new ValidationError('unit_too_long');
}

export function createHabit(
  state: UserState,
  input: CreateHabitInput,
  context: ActionContext,
): UserState {
  const today = requireToday(context);
  const id = (context.idFactory ?? defaultId)();
  assertUniqueId(state, id);

  const title = input.title.trim();
  if (!title || title.length > 100) {
    throw new ValidationError('invalid_title');
  }
  if (!['check', 'quantity', 'count'].includes(input.kind)) {
    throw new ValidationError('invalid_kind');
  }
  const startDay = parseDay(input.startDay ?? today);
  if (compareDay(startDay, today) > 0) {
    throw new ValidationError('start_day_in_future');
  }
  const unit = (input.unit ?? '').trim();
  const schedule = input.schedule ?? 'weekdays';
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
    unit,
  );

  const icon = input.icon ?? 0;
  if (!Number.isInteger(icon) || icon < 0 || icon >= 28) {
    throw new ValidationError('invalid_icon');
  }
  const color = input.color ?? 'auto';
  const frame = input.frame ?? 'auto';
  const habitContext = input.context ?? 'anytime';
  if (!HABIT_COLORS.includes(color)) throw new ValidationError('invalid_color');
  if (!HABIT_FRAMES.includes(frame)) throw new ValidationError('invalid_frame');
  if (!HABIT_CONTEXTS.includes(habitContext)) {
    throw new ValidationError('invalid_context');
  }

  const next = cloneState(state);
  const position =
    next.profile.habits.reduce((max, habit) => Math.max(max, habit.position), -1) +
    1;
  const plan: HabitPlan = {
    effectiveDay: startDay,
    target: input.target,
    unit,
    schedule,
    weekdays,
    intervalDays,
    weeklyGoal,
  };
  const habit: Habit = {
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
    plans: [plan],
  };
  next.profile.habits.push(habit);
  return next;
}

export function recordHabit(
  state: UserState,
  habitId: string,
  day: DayKey,
  value: number,
  context: ActionContext,
): UserState {
  const today = requireToday(context);
  const targetDay = parseDay(day);
  if (compareDay(targetDay, today) > 0) {
    throw new ValidationError('future_day');
  }
  const habit = findHabit(state, habitId);
  if (!habit) throw new ValidationError('habit_missing');
  if (habit.archived) throw new ValidationError('habit_archived');
  if (compareDay(targetDay, habit.startDay) < 0) {
    throw new ValidationError('before_start');
  }
  if (isRestOn(state.breaks, habitId, targetDay)) {
    throw new ValidationError('rest_day');
  }
  if (!scheduledOn(currentPlan(habit, targetDay), targetDay)) {
    throw new ValidationError('not_scheduled');
  }
  if (!isValidRecordValue(habit.kind, value)) {
    throw new ValidationError('invalid_value');
  }

  const next = cloneState(state);
  const record = next.days[targetDay] ?? { day: targetDay, entries: {} };
  record.entries[habitId] = value;
  next.days[targetDay] = record;
  return next;
}

export function clearHabit(
  state: UserState,
  habitId: string,
  day: DayKey,
): UserState {
  const targetDay = parseDay(day);
  const habit = findHabit(state, habitId);
  if (!habit) throw new ValidationError('habit_missing');
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

export function archiveHabit(
  state: UserState,
  habitId: string,
  archived = true,
): UserState {
  const next = cloneState(state);
  const habit = findHabit(next, habitId);
  if (!habit) throw new ValidationError('habit_missing');
  habit.archived = archived;
  return next;
}

export function deleteHabit(state: UserState, habitId: string): UserState {
  const next = cloneState(state);
  const habit = findHabit(next, habitId);
  if (!habit) throw new ValidationError('habit_missing');
  next.profile.habits = next.profile.habits.filter((item) => item.id !== habitId);
  for (const [day, record] of Object.entries(next.days)) {
    delete record.entries[habitId];
    if (Object.keys(record.entries).length === 0) delete next.days[day];
  }
  next.breaks = next.breaks.filter((item) => item.habitId !== habitId);
  next.activity = next.activity.filter((item) => item.habitId !== habitId);
  next.notes = next.notes.map((note) =>
    note.habitId === habitId ? { ...note, habitId: null } : note,
  );
  next.profile.habits.forEach((item, index) => {
    item.position = index;
  });
  return next;
}

export function updateReminderPrefs(
  state: UserState,
  patch: ReminderPrefsPatch,
): UserState {
  const next = cloneState(state);
  const prefs = next.profile.reminders;
  for (const key of ['once', 'digest', 'calendar'] as const) {
    if (patch[key] !== undefined && typeof patch[key] !== 'boolean') {
      throw new ValidationError('invalid_reminder_channel');
    }
  }
  if (
    patch.digestMinute !== undefined &&
    (!Number.isInteger(patch.digestMinute) ||
      patch.digestMinute < 0 ||
      patch.digestMinute > 1439)
  ) {
    throw new ValidationError('invalid_digest_minute');
  }
  next.profile.reminders = { ...prefs, ...patch };
  return next;
}

function sameRules(a: HabitPlan, b: HabitPlan): boolean {
  return (
    a.target === b.target &&
    a.unit === b.unit &&
    a.schedule === b.schedule &&
    a.weekdays === b.weekdays &&
    a.intervalDays === b.intervalDays &&
    a.weeklyGoal === b.weeklyGoal
  );
}

export function updateHabit(
  state: UserState,
  habitId: string,
  input: UpdateHabitInput,
  context: ActionContext,
): UserState {
  const today = requireToday(context);
  const next = cloneState(state);
  const habit = findHabit(next, habitId);
  if (!habit) throw new ValidationError('habit_missing');

  const hasPlanInput =
    input.target !== undefined ||
    input.unit !== undefined ||
    input.schedule !== undefined ||
    input.weekdays !== undefined ||
    input.intervalDays !== undefined ||
    input.weeklyGoal !== undefined;
  const current = currentPlan(habit, today);
  const target = input.target ?? current.target;
  const unit = (input.unit ?? current.unit).trim();
  const schedule = input.schedule ?? current.schedule;
  const weekdays = input.weekdays ?? current.weekdays;
  const intervalDays = input.intervalDays ?? current.intervalDays;
  const weeklyGoal = input.weeklyGoal ?? current.weeklyGoal;
  validatePlan(
    habit.kind,
    target,
    schedule,
    weekdays,
    intervalDays,
    weeklyGoal,
    unit,
  );

  if (input.title !== undefined) {
    const title = input.title.trim();
    if (!title || title.length > 100) throw new ValidationError('invalid_title');
    habit.title = title;
  }
  if (input.icon !== undefined) {
    if (!Number.isInteger(input.icon) || input.icon < 0 || input.icon >= 28) {
      throw new ValidationError('invalid_icon');
    }
    habit.icon = input.icon;
  }
  if (input.color !== undefined) {
    if (!HABIT_COLORS.includes(input.color)) throw new ValidationError('invalid_color');
    habit.color = input.color;
  }
  if (input.frame !== undefined) {
    if (!HABIT_FRAMES.includes(input.frame)) throw new ValidationError('invalid_frame');
    habit.frame = input.frame;
  }
  if (input.context !== undefined) {
    if (!HABIT_CONTEXTS.includes(input.context)) {
      throw new ValidationError('invalid_context');
    }
    habit.context = input.context;
  }

  if (!hasPlanInput) return next;

  const candidate: HabitPlan = {
    effectiveDay: current.effectiveDay,
    target,
    unit,
    schedule,
    weekdays,
    intervalDays,
    weeklyGoal,
  };
  const effectiveDay = addDays(today, 1);
  const existingFutureIndex = habit.plans.findIndex(
    (plan) => plan.effectiveDay === effectiveDay,
  );
  if (sameRules(candidate, current)) {
    // Reverting the pending values removes a redundant future version.
    if (existingFutureIndex >= 0) habit.plans.splice(existingFutureIndex, 1);
    return next;
  }
  const nextPlan: HabitPlan = { ...candidate, effectiveDay };
  if (existingFutureIndex >= 0) habit.plans[existingFutureIndex] = nextPlan;
  else habit.plans.push(nextPlan);
  habit.plans.sort((a, b) => compareDay(a.effectiveDay, b.effectiveDay));
  return next;
}

function overlaps(a: { startDay: DayKey; endDay: DayKey | null }, b: { startDay: DayKey; endDay: DayKey | null }): boolean {
  const aEnd = a.endDay ?? '2200-12-31';
  const bEnd = b.endDay ?? '2200-12-31';
  return compareDay(a.startDay, bEnd) <= 0 && compareDay(b.startDay, aEnd) <= 0;
}

export function startBreak(
  state: UserState,
  habitId: string,
  kind: BreakKind,
  startDay: DayKey,
  endDay: DayKey | null,
  context: ActionContext,
): UserState {
  const today = requireToday(context);
  const habit = findHabit(state, habitId);
  if (!habit) throw new ValidationError('habit_missing');
  const start = parseDay(startDay);
  if (compareDay(start, today) > 0) throw new ValidationError('future_day');
  if (kind === 'pause' && start !== today) {
    throw new ValidationError('pause_must_start_today');
  }
  if (kind === 'skip') {
    if (endDay !== null && parseDay(endDay) !== start) {
      throw new ValidationError('skip_single_day');
    }
    if (state.days[start]?.entries[habitId] !== undefined) {
      throw new ValidationError('skip_has_record');
    }
  }
  let end: DayKey | null = null;
  if (kind === 'vacation') {
    if (!endDay) throw new ValidationError('vacation_needs_end');
    end = parseDay(endDay);
    if (compareDay(end, start) < 0) throw new ValidationError('invalid_break_range');
    if (daysSince(end, start) > 365) throw new ValidationError('vacation_too_long');
  }
  if (kind === 'pause' && endDay) throw new ValidationError('invalid_break_range');
  if (kind === 'skip') end = start;
  const overlap = state.breaks.some(
    (item) =>
      item.habitId === habitId &&
      overlaps(
        { startDay: start, endDay: kind === 'skip' ? start : end },
        { startDay: item.startDay, endDay: item.endDay },
      ),
  );
  if (overlap) throw new ValidationError('break_overlap');
  const id = (context.idFactory ?? defaultId)();
  const breakItem = {
    id,
    habitId,
    startDay: start,
    endDay: kind === 'skip' ? start : end,
    kind,
  };
  const next = cloneState(state);
  next.breaks.push(breakItem);
  return next;
}

export function endBreak(
  state: UserState,
  breakId: string,
  endDay: DayKey,
  context: ActionContext,
): UserState {
  const today = requireToday(context);
  const end = parseDay(endDay);
  if (compareDay(end, today) > 0) throw new ValidationError('future_day');
  const next = cloneState(state);
  const item = next.breaks.find((entry) => entry.id === breakId);
  if (!item) throw new ValidationError('break_missing');
  if (item.kind !== 'pause') throw new ValidationError('not_pause');
  if (compareDay(end, item.startDay) < 0) throw new ValidationError('invalid_break_range');
  item.endDay = end;
  return next;
}

export function deleteBreak(state: UserState, breakId: string): UserState {
  const next = cloneState(state);
  const item = next.breaks.find((entry) => entry.id === breakId);
  if (!item) throw new ValidationError('break_missing');
  next.breaks = next.breaks.filter((entry) => entry.id !== breakId);
  return next;
}

export function deleteAccount(_state: UserState): UserState {
  return emptyState();
}

export function canRecord(
  state: UserState,
  habit: Habit,
  day: DayKey,
  today: DayKey,
): boolean {
  return (
    compareDay(day, today) <= 0 &&
    compareDay(day, habit.startDay) >= 0 &&
    isScheduled(state, habit, day)
  );
}

export function parseRecordInput(
  kind: HabitKind,
  input: string,
  mode: 'total' | 'delta' = 'total',
): number | null {
  if (kind === 'check') return input.trim() === '' ? 1000 : null;
  if (mode === 'delta') {
    if (kind === 'count') return parseCount(input);
    return parseQuantity(input);
  }
  return kind === 'quantity' ? parseQuantity(input) : parseCount(input);
}

export function todayForTest(now: Date): DayKey {
  return todayKey(now);
}

export function isKnownDay(value: string): boolean {
  return isDayKey(value);
}