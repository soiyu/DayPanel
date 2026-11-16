import { compareDay, parseDay, type DayKey } from '../domain/day.ts';
import {
  cloneState,
  type Note,
  type UserState,
} from '../domain/models.ts';
import { ValidationError, defaultId, type ActionContext } from './habit-actions.ts';

export interface CreateNoteInput {
  body: string;
  day?: DayKey;
  habitId?: string | null;
}

export interface UpdateNoteInput {
  body?: string;
  day?: DayKey;
  habitId?: string | null;
}

export interface NoteQuery {
  month?: string | null;
  day?: DayKey | null;
  habitId?: string | null;
  text?: string;
}

function normalizeBody(body: string): string {
  const value = body.trim();
  if (!value) throw new ValidationError('empty_note');
  if (value.length > 10_000) throw new ValidationError('note_too_long');
  return value;
}

function validHabit(state: UserState, habitId: string | null | undefined): string | null {
  if (habitId === undefined || habitId === null) return null;
  if (!state.profile.habits.some((habit) => habit.id === habitId)) {
    throw new ValidationError('habit_missing');
  }
  return habitId;
}

function uniqueId(state: UserState, id: string): boolean {
  return (
    !state.notes.some((note) => note.id === id) &&
    !state.tasks.some((task) => task.id === id) &&
    !state.profile.habits.some((habit) => habit.id === id)
  );
}

export function createNote(
  state: UserState,
  input: CreateNoteInput,
  context: ActionContext,
): UserState {
  const today = parseDay(context.today);
  const day = input.day ? parseDay(input.day) : today;
  if (compareDay(day, today) > 0) throw new ValidationError('future_day');
  const body = normalizeBody(input.body);
  const habitId = validHabit(state, input.habitId);
  const id = (context.idFactory ?? defaultId)();
  if (!uniqueId(state, id)) throw new ValidationError('id_conflict');

  const next = cloneState(state);
  next.notes.push({ id, body, day, habitId });
  return next;
}

export function updateNote(
  state: UserState,
  noteId: string,
  input: UpdateNoteInput,
  context: ActionContext,
): UserState {
  const today = parseDay(context.today);
  const next = cloneState(state);
  const note = next.notes.find((item) => item.id === noteId);
  if (!note) throw new ValidationError('note_missing');

  if (input.body !== undefined) note.body = normalizeBody(input.body);
  if (input.day !== undefined) {
    const day = parseDay(input.day);
    if (compareDay(day, today) > 0) throw new ValidationError('future_day');
    note.day = day;
  }
  if (input.habitId !== undefined) {
    note.habitId = validHabit(next, input.habitId);
  }
  return next;
}

export function deleteNote(state: UserState, noteId: string): UserState {
  if (!state.notes.some((note) => note.id === noteId)) {
    throw new ValidationError('note_missing');
  }
  const next = cloneState(state);
  next.notes = next.notes.filter((note) => note.id !== noteId);
  return next;
}

export function monthKey(day: DayKey): string {
  return parseDay(day).slice(0, 7);
}

export function filterNotes(state: UserState, query: NoteQuery): Note[] {
  const text = (query.text ?? '').trim().toLowerCase();
  const month = query.month ?? null;
  if (month !== null && !/^\d{4}-\d{2}$/.test(month)) {
    throw new ValidationError('invalid_month');
  }
  const day = query.day ? parseDay(query.day) : null;
  const habitId = query.habitId ?? null;

  return state.notes
    .filter((note) => {
      if (month && !note.day.startsWith(`${month}-`)) return false;
      if (day && note.day !== day) return false;
      if (habitId && note.habitId !== habitId) return false;
      if (text && !note.body.toLowerCase().includes(text)) return false;
      return true;
    })
    .sort((a, b) => {
      const dayOrder = compareDay(b.day, a.day);
      return dayOrder !== 0 ? dayOrder : a.id.localeCompare(b.id);
    });
}

export function noteMonthOptions(notes: Note[]): string[] {
  return [...new Set(notes.map((note) => monthKey(note.day)))].sort().reverse();
}