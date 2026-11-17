import {
  compareDay,
  daysSince,
  mondayOf,
  weekdayBit,
  type DayKey,
} from './day.ts';
import { countText, quantityText } from './quantity.ts';
import { chinaDayInfo } from './china-calendar.ts';

export type HabitKind = 'check' | 'quantity' | 'count';
export type ScheduleKind = 'weekdays' | 'interval' | 'weekly' | 'weeklyTotal';
export type ScheduleRule = 'any' | 'workdays' | 'restdays' | 'skip_holidays';
export type HabitContext = 'anytime' | 'morning' | 'daytime' | 'evening';
export type ReminderChannel = 'once' | 'digest' | 'calendar';

export interface HabitGroup {
  id: string;
  name: string;
  position: number;
}

export interface HabitPlan {
  effectiveDay: DayKey;
  target: number;
  unit: string;
  schedule: ScheduleKind;
  weekdays: number;
  intervalDays: number;
  weeklyGoal: number;
  calendarRule?: ScheduleRule;
}

export interface Habit {
  id: string;
  title: string;
  kind: HabitKind;
  startDay: DayKey;
  archived: boolean;
  icon: number;
  color: string;
  frame: string;
  context: HabitContext;
  groupId: string | null;
  position: number;
  plans: HabitPlan[];
}

export interface DayRecord {
  day: DayKey;
  entries: Record<string, number>;
}

export interface SmallTask {
  id: string;
  title: string;
  dueDay: DayKey | null;
  completedDay: DayKey | null;
  resident: boolean;
  startDay: DayKey | null;
  archived: boolean;
}

export interface Note {
  id: string;
  body: string;
  day: DayKey;
  habitId: string | null;
}

export interface AchievementCard {
  day: DayKey;
  artwork: number;
  favorite: boolean;
  reflection: string;
  evidence: string;
}

export interface HabitActivity {
  habitId: string;
  day: DayKey;
  archived: boolean;
}

export interface HabitBreak {
  id: string;
  habitId: string;
  startDay: DayKey;
  endDay: DayKey | null;
  kind: 'pause' | 'vacation' | 'skip';
}

export interface Challenge {
  id: string;
  habitId: string;
  title: string;
  startDay: DayKey;
  endDay: DayKey;
  targetDays: number;
  status: 'active' | 'completed' | 'abandoned';
  createdAt: string;
}

export interface Backfill {
  habitId: string;
  day: DayKey;
  recordedAt: string;
}

export interface RecordEvent {
  id: string;
  habitId: string;
  day: DayKey;
  value: number;
  minute: number | null;
  note: string;
  kind: 'baseline' | 'record' | 'adjustment';
  revision: number;
  deleted: boolean;
}

export interface ReminderJob {
  id: string;
  kind: 'once' | 'digest';
  habitId: string | null;
  sendAtMinute: number;
  day: DayKey;
  status: 'pending' | 'sent' | 'invalid' | 'failed';
  templateId: string;
  page: string;
  payload: Record<string, string>;
  createdAt: string;
}

export interface ReminderPrefs {
  once: boolean;
  digest: boolean;
  calendar: boolean;
  digestMinute: number;
}

export interface Settings {
  locale: 'system' | 'zh' | 'en';
  theme: 'system' | 'light' | 'dark';
  palette: 'blue' | 'teal' | 'violet' | 'apricot' | 'coast';
  font: 'system' | 'serif';
  iconFrame: 'soft' | 'ring' | 'plain';
  completionSound: boolean;
  completionHaptics: boolean;
  elderMode: boolean;
  stepHabitId: string | null;
}

export interface Profile {
  habits: Habit[];
  groups: HabitGroup[];
  settings: Settings;
  reminders: ReminderPrefs;
}

export interface UserState {
  profile: Profile;
  days: Record<DayKey, DayRecord>;
  tasks: SmallTask[];
  taskDays: Record<DayKey, string[]>;
  notes: Note[];
  cards: AchievementCard[];
  activity: HabitActivity[];
  breaks: HabitBreak[];
  events: RecordEvent[];
  backfills: Backfill[];
  challenges: Challenge[];
  jobs: ReminderJob[];
}

const DEFAULT_SETTINGS: Settings = {
  locale: 'system',
  theme: 'system',
  palette: 'blue',
  font: 'system',
  iconFrame: 'soft',
  completionSound: false,
  completionHaptics: false,
  elderMode: false,
  stepHabitId: null,
};

/**
 * Three reminder channels are on by default. "On" is a preference, not an
 * authorization: each channel still needs its own WeChat/system grant.
 */
export function defaultReminderPrefs(): ReminderPrefs {
  return {
    once: true,
    digest: true,
    calendar: true,
    digestMinute: 21 * 60,
  };
}

export function defaultProfile(): Profile {
  return {
    habits: [],
    groups: [],
    settings: { ...DEFAULT_SETTINGS },
    reminders: defaultReminderPrefs(),
  };
}

export function emptyState(): UserState {
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
    backfills: [],
    challenges: [],
    jobs: [],
  };
}

export function cloneState(state: UserState): UserState {
  // State is plain JSON data. structuredClone is used when available; the
  // fallback keeps the same behavior in older mini-program runtimes.
  if (typeof structuredClone === 'function') return structuredClone(state);
  return JSON.parse(JSON.stringify(state)) as UserState;
}

export function findHabit(state: UserState, id: string): Habit | null {
  return state.profile.habits.find((habit) => habit.id === id) ?? null;
}

export function currentPlan(habit: Habit, day: DayKey): HabitPlan {
  const plans = [...habit.plans].sort((a, b) =>
    compareDay(a.effectiveDay, b.effectiveDay),
  );
  let current = plans[0];
  if (!current) throw new Error('Habit has no plan');
  for (const plan of plans) {
    if (compareDay(plan.effectiveDay, day) <= 0) current = plan;
  }
  return current;
}

export function scheduledOn(plan: HabitPlan, day: DayKey): boolean {
  if (compareDay(day, plan.effectiveDay) < 0) return false;
  const base = (() => {
    switch (plan.schedule) {
      case 'weekdays':
        return (plan.weekdays & weekdayBit(day)) !== 0;
      case 'interval':
        return daysSince(day, plan.effectiveDay) % plan.intervalDays === 0;
      case 'weekly':
      case 'weeklyTotal':
        return true;
    }
  })();
  if (!base) return false;
  const kind = chinaDayInfo(day).kind;
  switch (plan.calendarRule ?? 'any') {
    case 'any':
      return true;
    case 'skip_holidays':
      return kind !== 'holiday';
    case 'workdays':
      return kind === 'workday' || kind === 'makeup_workday';
    case 'restdays':
      return kind === 'weekend' || kind === 'holiday';
  }
}

export function isRestOn(
  breaks: HabitBreak[],
  habitId: string,
  day: DayKey,
): boolean {
  return breaks.some(
    (item) =>
      item.habitId === habitId &&
      compareDay(day, item.startDay) >= 0 &&
      (item.endDay === null || compareDay(day, item.endDay) <= 0),
  );
}

export function isScheduled(
  state: UserState,
  habit: Habit,
  day: DayKey,
): boolean {
  return (
    !habit.archived &&
    compareDay(day, habit.startDay) >= 0 &&
    !isRestOn(state.breaks, habit.id, day) &&
    scheduledOn(currentPlan(habit, day), day)
  );
}

export function weekdayMask(days: number[]): number {
  let mask = 0;
  for (const day of days) {
    if (!Number.isInteger(day) || day < 1 || day > 7) {
      throw new RangeError('Invalid weekday');
    }
    mask |= 1 << (day - 1);
  }
  return mask;
}

export function weekOf(day: DayKey): DayKey {
  return mondayOf(day);
}

export function planTargetText(habit: Habit, day: DayKey): string {
  const plan = currentPlan(habit, day);
  if (habit.kind === 'check') return '1';
  if (habit.kind === 'count') return countText(plan.target);
  return quantityText(plan.target);
}