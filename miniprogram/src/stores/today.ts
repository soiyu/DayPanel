import { computed, ref } from 'vue';
import { defineStore } from 'pinia';
import { todayKey, type DayKey } from '../domain/day.ts';
import {
  currentPlan,
  isRestOn,
  scheduledOn,
  type Habit,
} from '../domain/models.ts';
import type {
  BreakKind,
  CreateHabitInput,
  ReminderPrefsPatch,
  UpdateHabitInput,
} from '../application/habit-actions.ts';
import {
  GatewayError,
  WechatCloudGateway,
  type TodayView,
} from '../data/wechat-gateway.ts';
import { resolveLocale, translate, type Locale } from '../i18n/index.ts';

export const useTodayStore = defineStore('today', () => {
  const gateway = new WechatCloudGateway();
  const today = ref<DayKey>(todayKey());
  const view = ref<TodayView | null>(null);
  const loading = ref(false);
  const busy = ref(false);
  const error = ref<string | null>(null);

  const locale = computed<Locale>(() =>
    resolveLocale(view.value?.profile.settings.locale),
  );

  function tr(key: Parameters<typeof translate>[1], params?: Record<string, string | number>) {
    return translate(locale.value, key, params);
  }

  const planned = computed<Habit[]>(() => {
    const snapshot = view.value;
    if (!snapshot) return [];
    return snapshot.profile.habits
      .filter(
        (habit) =>
          !habit.archived &&
          habit.startDay <= today.value &&
          scheduledOn(currentPlan(habit, today.value), today.value),
      )
      .sort((a, b) => a.position - b.position);
  });

  const completedCount = computed(
    () => planned.value.filter((habit) => isDone(habit)).length,
  );
  const card = computed(() => view.value?.card ?? null);

  function habitById(habitId: string): Habit | null {
    return view.value?.profile.habits.find((habit) => habit.id === habitId) ?? null;
  }

  function restFor(habitId: string): boolean {
    return (
      view.value?.breaks.some(
        (item) =>
          item.habitId === habitId &&
          item.startDay <= today.value &&
          (item.endDay === null || item.endDay >= today.value),
      ) === true
    );
  }

  function valueOf(habitId: string): number | null {
    const entry = view.value?.day?.entries[habitId];
    return entry === undefined ? null : entry;
  }

  function isDone(habit: Habit): boolean {
    const value = valueOf(habit.id);
    if (value === null) return false;
    const plan = currentPlan(habit, today.value);
    return value >= plan.target;
  }

  async function load(force = false): Promise<void> {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    today.value = todayKey();
    try {
      view.value = await gateway.today(today.value);
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
    } finally {
      loading.value = false;
    }
  }

  async function refresh(): Promise<void> {
    await load(true);
  }

  async function mutate(
    action: (expectedRevision: number) => Promise<{ revision: number }>,
  ): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot || busy.value) return false;
    busy.value = true;
    error.value = null;
    try {
      await action(snapshot.revision);
      await load(true);
      return true;
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
      return false;
    } finally {
      busy.value = false;
    }
  }

  async function createHabit(input: CreateHabitInput): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot) return false;
    return mutate((revision) => gateway.createHabit(input, revision));
  }

  async function record(habitId: string, value: number): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot) return false;
    return mutate((revision) =>
      gateway.recordHabit(habitId, today.value, value, revision),
    );
  }

  async function recordOn(
    habitId: string,
    day: string,
    value: number,
  ): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot) return false;
    return mutate((revision) => gateway.recordHabit(habitId, day, value, revision));
  }

  function isBackfilled(habitId: string, day: string): boolean {
    return (
      view.value?.backfills.some(
        (item) => item.habitId === habitId && item.day === day,
      ) === true
    );
  }

  async function clear(habitId: string): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot) return false;
    return mutate((revision) =>
      gateway.clearHabit(habitId, today.value, revision),
    );
  }

  async function archive(habitId: string, archived = true): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot) return false;
    return mutate((revision) =>
      gateway.archiveHabit(habitId, archived, revision),
    );
  }

  async function removeHabit(habitId: string): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot) return false;
    return mutate((revision) => gateway.deleteHabit(habitId, revision));
  }

  async function updateReminders(patch: ReminderPrefsPatch): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot) return false;
    return mutate((revision) =>
      gateway.updateReminderPrefs(patch, revision),
    );
  }

  async function updateHabit(
    habitId: string,
    patch: UpdateHabitInput,
  ): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot) return false;
    return mutate((revision) => gateway.updateHabit(habitId, patch, revision));
  }

  async function startBreak(
    habitId: string,
    kind: BreakKind,
    startDay: DayKey,
    endDay: DayKey | null = null,
  ): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot) return false;
    return mutate((revision) =>
      gateway.startBreak(habitId, kind, startDay, endDay, revision),
    );
  }

  async function endBreak(breakId: string, endDay: DayKey): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot) return false;
    return mutate((revision) => gateway.endBreak(breakId, endDay, revision));
  }

  async function deleteBreak(breakId: string): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot) return false;
    return mutate((revision) => gateway.deleteBreak(breakId, revision));
  }

  async function deleteAccount(): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot || busy.value) return false;
    busy.value = true;
    error.value = null;
    try {
      await gateway.deleteAccount(snapshot.revision);
      view.value = null;
      return true;
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
      return false;
    } finally {
      busy.value = false;
    }
  }

  return {
    today,
    view,
    loading,
    busy,
    error,
    locale,
    tr,
    planned,
    completedCount,
    card,
    habitById,
    restFor,
    valueOf,
    isDone,
    load,
    refresh,
    createHabit,
    updateHabit,
    startBreak,
    endBreak,
    deleteBreak,
    record,
    recordOn,
    isBackfilled,
    clear,
    archive,
    removeHabit,
    updateReminders,
    deleteAccount,
  };
});