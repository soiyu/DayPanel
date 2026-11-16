import { compareDay, parseDay, type DayKey } from '../domain/day.ts';
import {
  cloneState,
  type SmallTask,
  type UserState,
} from '../domain/models.ts';
import { ValidationError, defaultId, type ActionContext } from './habit-actions.ts';

export interface CreateTaskInput {
  title: string;
  resident?: boolean;
  dueDay?: DayKey | null;
}

function uniqueId(state: UserState, id: string): boolean {
  return (
    !state.tasks.some((task) => task.id === id) &&
    !state.profile.habits.some((habit) => habit.id === id) &&
    !state.notes.some((note) => note.id === id)
  );
}

export function createTask(
  state: UserState,
  input: CreateTaskInput,
  context: ActionContext,
): UserState {
  const today = parseDay(context.today);
  const title = input.title.trim();
  if (!title || title.length > 100) throw new ValidationError('invalid_title');
  const resident = input.resident === true;
  const dueDay = input.dueDay ? parseDay(input.dueDay) : null;
  if (resident && dueDay) throw new ValidationError('resident_has_due');
  const id = (context.idFactory ?? defaultId)();
  if (!uniqueId(state, id)) throw new ValidationError('id_conflict');

  const next = cloneState(state);
  const task: SmallTask = {
    id,
    title,
    dueDay: resident ? null : dueDay,
    completedDay: null,
    resident,
    startDay: resident ? today : null,
    archived: false,
  };
  next.tasks.push(task);
  return next;
}

export function completeTask(
  state: UserState,
  taskId: string,
  done: boolean,
  day: DayKey,
  context: ActionContext,
): UserState {
  const today = parseDay(context.today);
  const targetDay = parseDay(day);
  if (compareDay(targetDay, today) > 0) throw new ValidationError('future_day');
  const task = state.tasks.find((item) => item.id === taskId);
  if (!task) throw new ValidationError('task_missing');
  if (task.archived) throw new ValidationError('task_archived');

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
  if (!stored) throw new ValidationError('task_missing');
  stored.completedDay = done ? targetDay : null;
  return next;
}

export function archiveTask(
  state: UserState,
  taskId: string,
  archived = true,
): UserState {
  const next = cloneState(state);
  const task = next.tasks.find((item) => item.id === taskId);
  if (!task) throw new ValidationError('task_missing');
  task.archived = archived;
  return next;
}

export function deleteTask(state: UserState, taskId: string): UserState {
  if (!state.tasks.some((task) => task.id === taskId)) {
    throw new ValidationError('task_missing');
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

export function taskDoneOn(
  task: SmallTask,
  taskDays: Record<DayKey, string[]>,
  day: DayKey,
): boolean {
  if (task.resident) return (taskDays[day] ?? []).includes(task.id);
  return task.completedDay === day;
}