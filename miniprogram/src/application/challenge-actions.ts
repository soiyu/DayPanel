import { addDays, compareDay, daysSince, parseDay, type DayKey } from '../domain/day.ts';
import {
  cloneState,
  currentPlan,
  isRestOn,
  scheduledOn,
  type Challenge,
  type UserState,
} from '../domain/models.ts';
import { ValidationError, defaultId, type ActionContext } from './habit-actions.ts';

export const CHALLENGE_LENGTHS = [21, 100] as const;
export type ChallengeLength = (typeof CHALLENGE_LENGTHS)[number];

export interface ChallengeProgress {
  challenge: Challenge;
  planned: number;
  completed: number;
  rate: number;
  status: Challenge['status'] | 'failed';
  todayDone: boolean;
}

function countPlanned(
  state: UserState,
  challenge: Challenge,
  until: DayKey,
): { planned: number; completed: number; todayDone: boolean } {
  const habit = state.profile.habits.find((item) => item.id === challenge.habitId);
  if (!habit) return { planned: 0, completed: 0, todayDone: false };
  let planned = 0;
  let completed = 0;
  let todayDone = false;
  const end = compareDay(until, challenge.endDay) > 0 ? challenge.endDay : until;
  for (let day = challenge.startDay; compareDay(day, end) <= 0; day = addDays(day, 1)) {
    if (compareDay(day, habit.startDay) < 0) continue;
    if (isRestOn(state.breaks, habit.id, day)) continue;
    const plan = currentPlan(habit, day);
    if (!scheduledOn(plan, day)) continue;
    planned += 1;
    const value = state.days[day]?.entries[habit.id];
    const achieved = value !== undefined && value >= plan.target;
    if (achieved) completed += 1;
    if (day === until) todayDone = achieved;
  }
  return { planned, completed, todayDone };
}

export function createChallenge(
  state: UserState,
  habitId: string,
  length: ChallengeLength,
  context: ActionContext,
): UserState {
  const today = parseDay(context.today);
  if (!CHALLENGE_LENGTHS.includes(length)) {
    throw new ValidationError('invalid_challenge_length');
  }
  const habit = state.profile.habits.find((item) => item.id === habitId);
  if (!habit) throw new ValidationError('habit_missing');
  if (habit.archived) throw new ValidationError('habit_archived');
  if (state.challenges.some((item) => item.habitId === habitId && item.status === 'active')) {
    throw new ValidationError('challenge_already_active');
  }
  const endDay = addDays(today, length - 1);
  const draft: Challenge = {
    id: (context.idFactory ?? defaultId)(),
    habitId,
    title: `${habit.title} · ${length} 天挑战`,
    startDay: today,
    endDay,
    targetDays: 0,
    status: 'active',
    createdAt: new Date().toISOString(),
  };
  const planned = countPlanned(state, draft, endDay).planned;
  if (planned === 0) throw new ValidationError('challenge_no_planned_days');
  draft.targetDays = planned;
  const next = cloneState(state);
  next.challenges.push(draft);
  return next;
}

export function challengeProgress(
  state: UserState,
  challenge: Challenge,
  today: DayKey,
): ChallengeProgress {
  const current = parseDay(today);
  const end = compareDay(current, challenge.endDay) > 0 ? challenge.endDay : current;
  const counts = countPlanned(state, challenge, end);
  const rate = challenge.targetDays === 0 ? 0 : counts.completed / challenge.targetDays;
  let status: ChallengeProgress['status'] = challenge.status;
  if (status === 'active') {
    if (counts.completed >= challenge.targetDays) status = 'completed';
    else if (compareDay(current, challenge.endDay) > 0) status = 'failed';
  }
  return {
    challenge: { ...challenge, status: status === 'failed' ? 'active' : status },
    planned: counts.planned,
    completed: counts.completed,
    rate,
    status,
    todayDone: counts.todayDone,
  };
}

export function abandonChallenge(state: UserState, challengeId: string): UserState {
  const next = cloneState(state);
  const item = next.challenges.find((challenge) => challenge.id === challengeId);
  if (!item) throw new ValidationError('challenge_missing');
  item.status = 'abandoned';
  return next;
}

export function challengeDaysLeft(challenge: Challenge, today: DayKey): number {
  return Math.max(0, daysSince(challenge.endDay, today) + 1);
}
