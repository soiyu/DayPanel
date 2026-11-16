import { addDays, compareDay, type DayKey } from './day.ts';
import {
  currentPlan,
  isRestOn,
  scheduledOn,
  type Habit,
  type HabitKind,
  type UserState,
} from './models.ts';

export interface HabitStat {
  habitId: string;
  title: string;
  kind: HabitKind;
  target: number;
  unit: string;
  planFrom: DayKey;
  planned: number;
  completed: number;
  rate: number;
  streak: number;
  totalValue: number;
  rangeStart: DayKey;
  rangeEnd: DayKey;
}

/**
 * Stats use the plan effective on each historical day and exclude rest days.
 * The current (unfinished) day is not in the denominator. Today's plan is
 * exposed only as a label; historical units are not silently merged.
 */
export function habitStats(
  state: UserState,
  rangeDays: number,
  today: DayKey,
): HabitStat[] {
  if (!Number.isInteger(rangeDays) || rangeDays < 1 || rangeDays > 365) {
    throw new RangeError('Invalid stats range');
  }
  const end = addDays(today, -1);
  const start = addDays(end, -(rangeDays - 1));

  return state.profile.habits
    .filter((habit) => !habit.archived)
    .sort((a, b) => a.position - b.position)
    .map((habit) => statsForHabit(state, habit, start, end, today));
}

function statsForHabit(
  state: UserState,
  habit: Habit,
  start: DayKey,
  end: DayKey,
  today: DayKey,
): HabitStat {
  let planned = 0;
  let completed = 0;
  let totalValue = 0;
  let streak = 0;
  let streakOpen = true;

  for (let day = start; compareDay(day, end) <= 0; day = addDays(day, 1)) {
    if (compareDay(day, habit.startDay) < 0) continue;
    if (isRestOn(state.breaks, habit.id, day)) continue;
    const plan = currentPlan(habit, day);
    if (!scheduledOn(plan, day)) continue;
    planned += 1;
    const value = state.days[day]?.entries[habit.id];
    const achieved = value !== undefined && value >= plan.target;
    if (value !== undefined) totalValue += value;
    if (achieved) completed += 1;
  }

  for (let day = end; compareDay(day, start) >= 0; day = addDays(day, -1)) {
    if (compareDay(day, habit.startDay) < 0) break;
    if (isRestOn(state.breaks, habit.id, day)) continue;
    const plan = currentPlan(habit, day);
    if (!scheduledOn(plan, day)) continue;
    const value = state.days[day]?.entries[habit.id];
    if (value !== undefined && value >= plan.target) {
      if (streakOpen) streak += 1;
    } else {
      streakOpen = false;
    }
  }

  const plan = currentPlan(habit, today);
  return {
    habitId: habit.id,
    title: habit.title,
    kind: habit.kind,
    target: plan.target,
    unit: plan.unit,
    planFrom: plan.effectiveDay,
    planned,
    completed,
    rate: planned === 0 ? 0 : completed / planned,
    streak,
    totalValue,
    rangeStart: start,
    rangeEnd: end,
  };
}