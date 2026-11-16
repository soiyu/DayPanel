import { compareDay, daysSince, parseDay, type DayKey } from './day.ts';
import {
  currentPlan,
  isRestOn,
  scheduledOn,
  type AchievementCard,
  type HabitKind,
  type UserState,
} from './models.ts';

export const CARD_ARTWORKS = 6;

export interface CardEvidenceItem {
  habitId: string;
  title: string;
  kind: HabitKind;
  target: number;
  unit: string;
  effectiveDay: DayKey;
}

/** Weekly goals are not a daily obligation and do not earn a daily card. */
function hasDailyObligation(state: UserState, habitId: string, day: DayKey): boolean {
  const habit = state.profile.habits.find((item) => item.id === habitId);
  if (!habit) return false;
  const plan = currentPlan(habit, day);
  return plan.schedule !== 'weekly' && plan.schedule !== 'weeklyTotal';
}

export function cardEvidence(
  state: UserState,
  day: DayKey,
): CardEvidenceItem[] | null {
  const targetDay = parseDay(day);
  const qualifying = state.profile.habits.filter(
    (habit) =>
      !habit.archived &&
      compareDay(targetDay, habit.startDay) >= 0 &&
      !isRestOn(state.breaks, habit.id, targetDay) &&
      scheduledOn(currentPlan(habit, targetDay), targetDay) &&
      hasDailyObligation(state, habit.id, targetDay),
  );
  if (qualifying.length === 0) return null;

  const evidence: CardEvidenceItem[] = [];
  for (const habit of qualifying) {
    const plan = currentPlan(habit, targetDay);
    const value = state.days[targetDay]?.entries[habit.id];
    if (value === undefined || value < plan.target) return null;
    evidence.push({
      habitId: habit.id,
      title: habit.title,
      kind: habit.kind,
      target: plan.target,
      unit: plan.unit,
      effectiveDay: plan.effectiveDay,
    });
  }
  return evidence;
}

export function artworkForDay(day: DayKey): number {
  return Math.abs(daysSince(day, '2026-01-01')) % CARD_ARTWORKS;
}

/**
 * Cards are immutable once earned. Undo, plan edits, archive or delete must not
 * remove them; only the explicit card collection can edit favorite/reflection.
 */
export function ensureCard(state: UserState, day: DayKey): UserState {
  if (state.cards.some((card) => card.day === day)) return state;
  const evidence = cardEvidence(state, day);
  if (!evidence) return state;
  const card: AchievementCard = {
    day,
    artwork: artworkForDay(day),
    favorite: false,
    reflection: '',
    evidence: JSON.stringify(evidence),
  };
  return { ...state, cards: [...state.cards, card] };
}

export function cardForDay(
  state: UserState,
  day: DayKey,
): AchievementCard | null {
  return state.cards.find((card) => card.day === day) ?? null;
}

export function evidenceOf(card: AchievementCard): CardEvidenceItem[] {
  try {
    return JSON.parse(card.evidence) as CardEvidenceItem[];
  } catch {
    return [];
  }
}

export function setCardFavorite(
  state: UserState,
  day: DayKey,
  favorite: boolean,
): UserState {
  const card = cardForDay(state, day);
  if (!card) throw new RangeError('Card missing');
  return {
    ...state,
    cards: state.cards.map((item) =>
      item.day === day ? { ...item, favorite } : item,
    ),
  };
}

export function saveCardReflection(
  state: UserState,
  day: DayKey,
  reflection: string,
): UserState {
  const card = cardForDay(state, day);
  if (!card) throw new RangeError('Card missing');
  const text = reflection.trim();
  if (text.length > 10_000) throw new RangeError('Reflection too long');
  return {
    ...state,
    cards: state.cards.map((item) =>
      item.day === day ? { ...item, reflection: text } : item,
    ),
  };
}
