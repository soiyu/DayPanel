import { addDays, compareDay, weekday, type DayKey } from './day.ts';
import {
  currentPlan,
  isRestOn,
  scheduledOn,
  type Habit,
  type HabitKind,
  type UserState,
} from './models.ts';

export type InsightRange = 30 | 90 | 365;

export interface InsightOverall {
  planned: number;
  completed: number;
  rate: number;
  previousRate: number;
  delta: number;
}

export interface WeekdayInsight {
  weekday: number;
  planned: number;
  completed: number;
  rate: number;
}

export interface HabitInsight {
  habitId: string;
  title: string;
  kind: HabitKind;
  unit: string;
  target: number;
  planned: number;
  completed: number;
  rate: number;
  trend: number;
}

export interface MonthInsight {
  month: string;
  entries: number;
  activeDays: number;
}

export interface PairInsight {
  first: string;
  second: string;
  days: number;
}

export interface Insights {
  range: InsightRange;
  start: DayKey;
  end: DayKey;
  overall: InsightOverall;
  weekdays: WeekdayInsight[];
  habits: HabitInsight[];
  months: MonthInsight[];
  pairs: PairInsight[];
  journalNotes: number;
  cards: number;
  recordEvents: number;
}

interface Counts {
  planned: number;
  completed: number;
}

function isDailyObligation(habit: Habit, day: DayKey): boolean {
  const plan = currentPlan(habit, day);
  return plan.schedule !== 'weekly' && plan.schedule !== 'weeklyTotal';
}

function countRange(
  state: UserState,
  start: DayKey,
  end: DayKey,
): { overall: Counts; weekdays: Counts[]; byHabit: Map<string, Counts> } {
  const weekdays: Counts[] = Array.from({ length: 7 }, () => ({
    planned: 0,
    completed: 0,
  }));
  const overall: Counts = { planned: 0, completed: 0 };
  const byHabit = new Map<string, Counts>();

  for (let day = start; compareDay(day, end) <= 0; day = addDays(day, 1)) {
    const isoWeekday = weekday(day);

    for (const habit of state.profile.habits) {
      if (habit.archived) continue;
      if (compareDay(day, habit.startDay) < 0) continue;
      if (isRestOn(state.breaks, habit.id, day)) continue;
      if (!isDailyObligation(habit, day)) continue;
      const plan = currentPlan(habit, day);
      if (!scheduledOn(plan, day)) continue;

      const value = state.days[day]?.entries[habit.id];
      const achieved = value !== undefined && value >= plan.target;
      overall.planned += 1;
      weekdays[isoWeekday - 1].planned += 1;
      const h = byHabit.get(habit.id) ?? { planned: 0, completed: 0 };
      h.planned += 1;
      if (achieved) {
        overall.completed += 1;
        weekdays[isoWeekday - 1].completed += 1;
        h.completed += 1;
      }
      byHabit.set(habit.id, h);
    }
  }
  return { overall, weekdays, byHabit };
}

function rate(counts: Counts): number {
  return counts.planned === 0 ? 0 : counts.completed / counts.planned;
}

export function insights(
  state: UserState,
  requestedRange: InsightRange,
  today: DayKey,
): Insights {
  const range = requestedRange;
  if (![30, 90, 365].includes(range)) throw new RangeError('Invalid insight range');
  const end = addDays(today, -1);
  const start = addDays(end, -(range - 1));
  const previousEnd = addDays(start, -1);
  const previousStart = addDays(previousEnd, -(range - 1));

  const current = countRange(state, start, end);
  const previous = countRange(state, previousStart, previousEnd);

  const habits: HabitInsight[] = state.profile.habits
    .filter((habit) => !habit.archived)
    .sort((a, b) => a.position - b.position)
    .map((habit) => {
      const counts = current.byHabit.get(habit.id) ?? { planned: 0, completed: 0 };
      const prev = previous.byHabit.get(habit.id) ?? { planned: 0, completed: 0 };
      const plan = currentPlan(habit, today);
      return {
        habitId: habit.id,
        title: habit.title,
        kind: habit.kind,
        unit: plan.unit,
        target: plan.target,
        planned: counts.planned,
        completed: counts.completed,
        rate: rate(counts),
        trend: rate(counts) - rate(prev),
      };
    })
    .filter((habit) => habit.planned > 0);

  const pairCounts = new Map<string, number>();
  for (let day = start; compareDay(day, end) <= 0; day = addDays(day, 1)) {
    const achieved: string[] = [];
    for (const habit of state.profile.habits) {
      if (habit.archived) continue;
      if (compareDay(day, habit.startDay) < 0) continue;
      if (isRestOn(state.breaks, habit.id, day)) continue;
      if (!isDailyObligation(habit, day)) continue;
      const plan = currentPlan(habit, day);
      if (!scheduledOn(plan, day)) continue;
      const value = state.days[day]?.entries[habit.id];
      if (value !== undefined && value >= plan.target) achieved.push(habit.id);
    }
    achieved.sort();
    for (let i = 0; i < achieved.length; i += 1) {
      for (let j = i + 1; j < achieved.length; j += 1) {
        const key = `${achieved[i]}|${achieved[j]}`;
        pairCounts.set(key, (pairCounts.get(key) ?? 0) + 1);
      }
    }
  }
  const titles = new Map(state.profile.habits.map((habit) => [habit.id, habit.title]));
  const pairs = [...pairCounts.entries()]
    .filter(([, count]) => count >= 2)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([key, days]) => {
      const [first, second] = key.split('|');
      return {
        first: titles.get(first) ?? first,
        second: titles.get(second) ?? second,
        days,
      };
    });

  const monthMap = new Map<string, { entries: number; days: Set<string> }>();
  for (const [day, record] of Object.entries(state.days)) {
    if (compareDay(day, start) < 0 || compareDay(day, end) > 0) continue;
    if (!Object.keys(record.entries).length) continue;
    const month = day.slice(0, 7);
    const item = monthMap.get(month) ?? { entries: 0, days: new Set<string>() };
    item.entries += Object.keys(record.entries).length;
    item.days.add(day);
    monthMap.set(month, item);
  }
  const months = [...monthMap.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([month, item]) => ({
      month,
      entries: item.entries,
      activeDays: item.days.size,
    }));

  const journalNotes = state.notes.filter(
    (note) => compareDay(note.day, start) >= 0 && compareDay(note.day, end) <= 0,
  ).length;
  const cards = state.cards.filter(
    (card) => compareDay(card.day, start) >= 0 && compareDay(card.day, end) <= 0,
  ).length;
  const recordEvents = state.events.filter(
    (event) => compareDay(event.day, start) >= 0 && compareDay(event.day, end) <= 0,
  ).length;

  return {
    range,
    start,
    end,
    overall: {
      planned: current.overall.planned,
      completed: current.overall.completed,
      rate: rate(current.overall),
      previousRate: rate(previous.overall),
      delta: rate(current.overall) - rate(previous.overall),
    },
    weekdays: current.weekdays.map((counts, index) => ({
      weekday: index + 1,
      planned: counts.planned,
      completed: counts.completed,
      rate: rate(counts),
    })),
    habits,
    months,
    pairs,
    journalNotes,
    cards,
    recordEvents,
  };
}