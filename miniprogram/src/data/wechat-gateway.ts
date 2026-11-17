import { CLOUD_ENV, CLOUD_FUNCTION } from '../config.ts';
import { todayKey, type DayKey } from '../domain/day.ts';
import type {
  AchievementCard,
  DayRecord,
  Profile,
  Backfill,
  HabitBreak,
  Note,
  ReminderPrefs,
  SmallTask,
  UserState,
} from '../domain/models.ts';
import type {
  BreakKind,
  CreateHabitInput,
  ReminderPrefsPatch,
  UpdateHabitInput,
} from '../application/habit-actions.ts';
import type {
  CreateNoteInput,
  NoteQuery,
  UpdateNoteInput,
} from '../application/journal-actions.ts';
import type { HabitStat } from '../domain/stats.ts';
import type { SettingsPatch } from '../application/settings-actions.ts';
import type { Insights, InsightRange } from '../domain/insights.ts';

export interface TodayView {
  revision: number;
  profile: Profile;
  day: DayRecord | null;
  card: AchievementCard | null;
  breaks: HabitBreak[];
  backfills: Backfill[];
}

export interface MutateResult {
  revision: number;
}

export interface TasksView {
  revision: number;
  tasks: SmallTask[];
  taskDays: Record<string, string[]>;
}

export interface NotesView {
  revision: number;
  notes: Note[];
}

export interface CardsView {
  revision: number;
  cards: AchievementCard[];
}

export interface YearView {
  revision: number;
  year: number;
  days: DayRecord[];
  cards: AchievementCard[];
}

export interface TimelineEvent {
  type: 'habit' | 'task' | 'note' | 'card';
  day: DayKey;
  id: string;
  title: string;
  value?: number;
  kind?: string;
  resident?: boolean;
  backfilled?: boolean;
}

export interface ReminderJobView {
  id: string;
  kind: 'once' | 'digest';
  habitId: string | null;
  day: DayKey;
  sendAt: string;
  status: 'pending' | 'sent' | 'invalid' | 'failed';
  templateId: string;
}

export interface CreateReminderJobInput {
  kind: 'once' | 'digest';
  habitId?: string | null;
  day: DayKey;
  sendAt: number;
  templateId: string;
  page: string;
  payload: Record<string, string | number>;
}

export class GatewayError extends Error {
  readonly code: string;

  constructor(code: string, message = code) {
    super(message);
    this.name = 'GatewayError';
    this.code = code;
  }
}

export interface CloudGateway {
  today(day: DayKey): Promise<TodayView>;
  tasks(): Promise<TasksView>;
  notes(query: NoteQuery): Promise<NotesView>;
  reminderStatus(day: DayKey): Promise<ReminderJobView[]>;
  stats(rangeDays: number): Promise<HabitStat[]>;
  cards(): Promise<CardsView>;
  insights(range: InsightRange): Promise<Insights>;
  settings(): Promise<{ revision: number; settings: Profile['settings'] }>;
  updateSettings(
    patch: SettingsPatch,
    expectedRevision: number,
  ): Promise<MutateResult>;
  year(year: number): Promise<YearView>;
  timeline(month: string): Promise<TimelineEvent[]>;
  favoriteCard(
    day: DayKey,
    favorite: boolean,
    expectedRevision: number,
  ): Promise<MutateResult>;
  saveReflection(
    day: DayKey,
    reflection: string,
    expectedRevision: number,
  ): Promise<MutateResult>;
  createReminderJob(input: CreateReminderJobInput): Promise<{ jobId: string }>;
  createHabit(input: CreateHabitInput, expectedRevision: number): Promise<MutateResult>;
  recordHabit(
    habitId: string,
    day: DayKey,
    value: number,
    expectedRevision: number,
  ): Promise<MutateResult>;
  clearHabit(
    habitId: string,
    day: DayKey,
    expectedRevision: number,
  ): Promise<MutateResult>;
  archiveHabit(
    habitId: string,
    archived: boolean,
    expectedRevision: number,
  ): Promise<MutateResult>;
  deleteHabit(habitId: string, expectedRevision: number): Promise<MutateResult>;
  updateReminderPrefs(
    patch: ReminderPrefsPatch,
    expectedRevision: number,
  ): Promise<MutateResult>;
  createTask(
    input: { title: string; resident?: boolean; dueDay?: DayKey | null },
    expectedRevision: number,
  ): Promise<MutateResult>;
  completeTask(
    taskId: string,
    done: boolean,
    day: DayKey,
    expectedRevision: number,
  ): Promise<MutateResult>;
  archiveTask(
    taskId: string,
    archived: boolean,
    expectedRevision: number,
  ): Promise<MutateResult>;
  deleteTask(taskId: string, expectedRevision: number): Promise<MutateResult>;
  updateTask(
    taskId: string,
    patch: { title?: string; dueDay?: DayKey | null },
    expectedRevision: number,
  ): Promise<MutateResult>;
  createNote(input: CreateNoteInput, expectedRevision: number): Promise<MutateResult>;
  updateNote(
    noteId: string,
    patch: UpdateNoteInput,
    expectedRevision: number,
  ): Promise<MutateResult>;
  deleteNote(noteId: string, expectedRevision: number): Promise<MutateResult>;
  deleteAccount(expectedRevision: number): Promise<MutateResult>;
}

let initialized = false;

function ensureCloud(): void {
  if (initialized) return;
  if (!wx?.cloud?.callFunction) {
    throw new GatewayError('cloud_unavailable');
  }
  wx.cloud.init({
    env: CLOUD_ENV || undefined,
    traceUser: false,
  });
  initialized = true;
}

async function call<T>(action: string, payload: Record<string, unknown>): Promise<T> {
  ensureCloud();
  let response: any;
  try {
    response = await wx.cloud.callFunction({
      name: CLOUD_FUNCTION,
      data: { action, today: todayKey(), ...payload },
    });
  } catch {
    throw new GatewayError('network');
  }
  const result = response?.result;
  if (!result || result.ok !== true) {
    throw new GatewayError(
      typeof result?.error === 'string' ? result.error : 'cloud_error',
    );
  }
  return result as T;
}

export class WechatCloudGateway implements CloudGateway {
  async today(day: DayKey): Promise<TodayView> {
    const result = await call<{
      revision: number;
      profile: Profile;
      day: DayRecord | null;
      card: AchievementCard | null;
      breaks: HabitBreak[];
      backfills: Backfill[];
    }>('today', { day });
    return {
      revision: result.revision,
      profile: result.profile,
      day: result.day,
      card: result.card,
      breaks: result.breaks ?? [],
      backfills: result.backfills ?? [],
    };
  }

  async tasks(): Promise<TasksView> {
    const result = await call<{
      revision: number;
      tasks: SmallTask[];
      taskDays: Record<string, string[]>;
    }>('tasks', {});
    return {
      revision: result.revision,
      tasks: result.tasks,
      taskDays: result.taskDays,
    };
  }

  async createTask(
    input: { title: string; resident?: boolean; dueDay?: DayKey | null },
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('createTask', { input, expectedRevision });
  }

  async completeTask(
    taskId: string,
    done: boolean,
    day: DayKey,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('completeTask', {
      taskId,
      done,
      day,
      expectedRevision,
    });
  }

  async archiveTask(
    taskId: string,
    archived: boolean,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('archiveTask', {
      taskId,
      archived,
      expectedRevision,
    });
  }

  async updateTask(
    taskId: string,
    patch: { title?: string; dueDay?: DayKey | null },
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('updateTask', { taskId, patch, expectedRevision });
  }

  async deleteTask(taskId: string, expectedRevision: number): Promise<MutateResult> {
    return call<MutateResult>('deleteTask', { taskId, expectedRevision });
  }

  async favoriteCard(
    day: DayKey,
    favorite: boolean,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('favoriteCard', {
      day,
      favorite,
      expectedRevision,
    });
  }

  async saveReflection(
    day: DayKey,
    reflection: string,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('saveReflection', {
      day,
      reflection,
      expectedRevision,
    });
  }

  async settings(): Promise<{ revision: number; settings: Profile['settings'] }> {
    const result = await call<{
      revision: number;
      settings: Profile['settings'];
    }>('settings', {});
    return { revision: result.revision, settings: result.settings };
  }

  async updateSettings(
    patch: SettingsPatch,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('updateSettings', { patch, expectedRevision });
  }

  async year(year: number): Promise<YearView> {
    const result = await call<{
      revision: number;
      year: number;
      days: DayRecord[];
      cards: AchievementCard[];
    }>('year', { year });
    return result;
  }

  async timeline(month: string): Promise<TimelineEvent[]> {
    const result = await call<{ events: TimelineEvent[] }>('timeline', { month });
    return result.events;
  }

  async insights(range: InsightRange): Promise<Insights> {
    const result = await call<{ insights: Insights }>('insights', { range });
    return result.insights;
  }

  async cards(): Promise<CardsView> {
    const result = await call<{ revision: number; cards: AchievementCard[] }>(
      'cards',
      {},
    );
    return { revision: result.revision, cards: result.cards };
  }

  async stats(rangeDays: number): Promise<HabitStat[]> {
    const result = await call<{ stats: HabitStat[] }>('stats', { rangeDays });
    return result.stats;
  }

  async reminderStatus(day: DayKey): Promise<ReminderJobView[]> {
    const result = await call<{ jobs: ReminderJobView[] }>('reminderStatus', {
      day,
    });
    return result.jobs;
  }

  async createReminderJob(
    input: CreateReminderJobInput,
  ): Promise<{ jobId: string }> {
    const result = await call<{ jobId: string }>('createReminderJob', { ...input });
    return { jobId: result.jobId };
  }

  async notes(query: NoteQuery): Promise<NotesView> {
    const result = await call<{ revision: number; notes: Note[] }>('notes', {
      query,
    });
    return { revision: result.revision, notes: result.notes };
  }

  async createNote(
    input: CreateNoteInput,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('createNote', { input, expectedRevision });
  }

  async updateNote(
    noteId: string,
    patch: UpdateNoteInput,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('updateNote', { noteId, patch, expectedRevision });
  }

  async deleteNote(
    noteId: string,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('deleteNote', { noteId, expectedRevision });
  }

  async createHabit(
    input: CreateHabitInput,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('createHabit', { input, expectedRevision });
  }

  async recordHabit(
    habitId: string,
    day: DayKey,
    value: number,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('recordHabit', {
      habitId,
      day,
      value,
      expectedRevision,
    });
  }

  async clearHabit(
    habitId: string,
    day: DayKey,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('clearHabit', {
      habitId,
      day,
      expectedRevision,
    });
  }

  async archiveHabit(
    habitId: string,
    archived: boolean,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('archiveHabit', {
      habitId,
      archived,
      expectedRevision,
    });
  }

  async deleteHabit(habitId: string, expectedRevision: number): Promise<MutateResult> {
    return call<MutateResult>('deleteHabit', { habitId, expectedRevision });
  }

  async updateReminderPrefs(
    patch: ReminderPrefsPatch,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('updateReminderPrefs', { patch, expectedRevision });
  }

  async updateHabit(
    habitId: string,
    patch: UpdateHabitInput,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('updateHabit', {
      habitId,
      patch,
      expectedRevision,
    });
  }

  async startBreak(
    habitId: string,
    kind: BreakKind,
    startDay: DayKey,
    endDay: DayKey | null,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('startBreak', {
      habitId,
      kind,
      startDay,
      endDay,
      expectedRevision,
    });
  }

  async endBreak(
    breakId: string,
    endDay: DayKey,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('endBreak', { breakId, endDay, expectedRevision });
  }

  async deleteBreak(
    breakId: string,
    expectedRevision: number,
  ): Promise<MutateResult> {
    return call<MutateResult>('deleteBreak', { breakId, expectedRevision });
  }

  async deleteAccount(expectedRevision: number): Promise<MutateResult> {
    return call<MutateResult>('deleteAccount', { expectedRevision });
  }
}

export type { ReminderPrefs, UserState };