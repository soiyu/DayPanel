import { CLOUD_ENV, CLOUD_FUNCTION } from '../config.ts';
import { todayKey, type DayKey } from '../domain/day.ts';
import type {
  AchievementCard,
  DayRecord,
  Profile,
  ReminderPrefs,
  UserState,
} from '../domain/models.ts';
import type {
  CreateHabitInput,
  ReminderPrefsPatch,
} from '../application/habit-actions.ts';

export interface TodayView {
  revision: number;
  profile: Profile;
  day: DayRecord | null;
  card: AchievementCard | null;
}

export interface MutateResult {
  revision: number;
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
    }>('today', { day });
    return {
      revision: result.revision,
      profile: result.profile,
      day: result.day,
      card: result.card,
    };
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

  async deleteAccount(expectedRevision: number): Promise<MutateResult> {
    return call<MutateResult>('deleteAccount', { expectedRevision });
  }
}

export type { ReminderPrefs, UserState };