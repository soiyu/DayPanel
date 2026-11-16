import { computed, ref } from 'vue';
import { defineStore } from 'pinia';
import { todayKey, type DayKey } from '../domain/day.ts';
import type { SmallTask } from '../domain/models.ts';
import {
  GatewayError,
  WechatCloudGateway,
  type TasksView,
} from '../data/wechat-gateway.ts';
import { resolveLocale, translate, type Locale } from '../i18n/index.ts';
import type { CreateTaskInput } from '../application/task-actions.ts';

export const useTasksStore = defineStore('tasks', () => {
  const gateway = new WechatCloudGateway();
  const today = ref<DayKey>(todayKey());
  const view = ref<TasksView | null>(null);
  const loading = ref(false);
  const busy = ref(false);
  const error = ref<string | null>(null);

  const locale = computed<Locale>(() => resolveLocale('system'));
  const tr = (key: Parameters<typeof translate>[1]) =>
    translate(locale.value, key);

  function isDone(task: SmallTask, day = today.value): boolean {
    if (!view.value) return false;
    if (task.resident) {
      return (view.value.taskDays[day] ?? []).includes(task.id);
    }
    return task.completedDay === day;
  }

  const oneTime = computed(() =>
    (view.value?.tasks ?? [])
      .filter((task) => !task.resident && !task.archived)
      .sort((a, b) => {
        if (a.completedDay && !b.completedDay) return 1;
        if (!a.completedDay && b.completedDay) return -1;
        return (a.dueDay ?? '9999-12-31').localeCompare(
          b.dueDay ?? '9999-12-31',
        );
      }),
  );

  const resident = computed(() =>
    (view.value?.tasks ?? [])
      .filter((task) => task.resident && !task.archived)
      .sort((a, b) => a.title.localeCompare(b.title)),
  );

  const completedToday = computed(
    () =>
      oneTime.value.filter((task) => isDone(task)).length +
      resident.value.filter((task) => isDone(task)).length,
  );

  async function load(): Promise<void> {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    today.value = todayKey();
    try {
      view.value = await gateway.tasks();
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
    } finally {
      loading.value = false;
    }
  }

  async function mutate(
    action: (revision: number) => Promise<{ revision: number }>,
  ): Promise<boolean> {
    const snapshot = view.value;
    if (!snapshot || busy.value) return false;
    busy.value = true;
    error.value = null;
    try {
      await action(snapshot.revision);
      await load();
      return true;
    } catch (caught) {
      error.value = caught instanceof GatewayError ? caught.code : 'cloud_error';
      return false;
    } finally {
      busy.value = false;
    }
  }

  async function create(input: CreateTaskInput): Promise<boolean> {
    if (!view.value) return false;
    return mutate((revision) => gateway.createTask(input, revision));
  }

  async function toggle(task: SmallTask): Promise<boolean> {
    if (!view.value) return false;
    const done = isDone(task);
    return mutate((revision) =>
      gateway.completeTask(task.id, !done, today.value, revision),
    );
  }

  async function archive(task: SmallTask): Promise<boolean> {
    if (!view.value) return false;
    return mutate((revision) => gateway.archiveTask(task.id, true, revision));
  }

  async function update(
    task: SmallTask,
    patch: { title?: string; dueDay?: DayKey | null },
  ): Promise<boolean> {
    if (!view.value) return false;
    return mutate((revision) => gateway.updateTask(task.id, patch, revision));
  }

  async function remove(task: SmallTask): Promise<boolean> {
    if (!view.value) return false;
    return mutate((revision) => gateway.deleteTask(task.id, revision));
  }

  return {
    today,
    view,
    loading,
    busy,
    error,
    tr,
    oneTime,
    resident,
    completedToday,
    isDone,
    load,
    create,
    toggle,
    update,
    archive,
    remove,
  };
});