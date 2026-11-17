<template>
  <view class="page" :class="themeClass">
    <view v-if="loading" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="error" class="state">
      <text class="state-title">{{ t('loadFailed') }}</text>
      <button class="primary" @tap="load"> {{ t('retry') }}</button>
    </view>

    <template v-else>
      <view class="hero">
        <text class="title">{{ day }}</text>
        <text class="hint">{{ t('dayHistory') }}</text>
      </view>

      <view class="card">
        <text class="section">{{ t('habitRecord') }}</text>
        <view v-if="habits.length === 0" class="empty">{{ t('noDayRecords') }}</view>
        <view v-for="item in habits" :key="item.habit.id" class="row">
          <view class="row-main">
            <text class="row-title">{{ item.habit.title }}</text>
            <text class="row-meta">{{ item.scheduled ? '计划内' : '计划外' }}</text>
          </view>
          <text class="row-value">
            {{ valueText(item) }}{{ isBackfilled(item.habit.id) ? ' · 补记' : '' }}
          </text>
        </view>
      </view>

      <view class="card">
        <text class="section">{{ t('taskRecord') }}</text>
        <view v-if="taskRows.length === 0" class="empty">{{ t('noDayRecords') }}</view>
        <view v-for="task in taskRows" :key="task.id" class="row">
          <text class="row-title">{{ task.title }}</text>
          <text class="row-value">{{ task.resident ? '常驻' : '一次性' }}</text>
        </view>
      </view>

      <view class="card">
        <text class="section">{{ t('noteRecord') }}</text>
        <view v-if="notes.length === 0" class="empty">{{ t('noDayRecords') }}</view>
        <view v-for="note in notes" :key="note.id" class="note">
          <text class="note-body">{{ note.body }}</text>
        </view>
      </view>

      <view v-if="card" class="card">
        <text class="section">{{ t('cardRecord') }}</text>
        <text class="card-line">{{ card.day }} · {{ evidenceTitles }}</text>
      </view>
    </template>
  </view>
</template>

<script setup lang="ts">
import { useThemeClass } from '../../composables/useTheme.ts';
import { computed, ref } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { todayKey, type DayKey } from '../../domain/day.ts';
import {
  currentPlan,
  isRestOn,
  scheduledOn,
  type Habit,
  type HabitBreak,
  type Note,
  type SmallTask,
} from '../../domain/models.ts';
import {
  WechatCloudGateway,
  type TodayView,
} from '../../data/wechat-gateway.ts';
import { useTodayStore } from '../../stores/today.ts';
import { evidenceOf } from '../../domain/achievement.ts';
import { countText, quantityText } from '../../domain/quantity.ts';

const store = useTodayStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);
const gateway = new WechatCloudGateway();
const day = ref<DayKey>(todayKey());
const loading = ref(true);
const error = ref(false);
const view = ref<TodayView | null>(null);
const notes = ref<Note[]>([]);
const tasks = ref<SmallTask[]>([]);
const taskDays = ref<Record<string, string[]>>({});

const breaks = computed<HabitBreak[]>(() => view.value?.breaks ?? []);
const habits = computed(() => {
  if (!view.value) return [];
  const entries = view.value.day?.entries ?? {};
  return view.value.profile.habits
    .filter((habit) => !habit.archived)
    .filter((habit) => entries[habit.id] !== undefined || scheduledFor(habit))
    .map((habit) => ({ habit, scheduled: scheduledFor(habit) }));
});

function scheduledFor(habit: Habit): boolean {
  if (!view.value) return false;
  return (
    day.value >= habit.startDay &&
    !isRestOn(breaks.value, habit.id, day.value) &&
    scheduledOn(currentPlan(habit, day.value), day.value)
  );
}

const taskRows = computed(() => {
  const ids = new Set(taskDays.value[day.value] ?? []);
  return tasks.value.filter(
    (task) =>
      (!task.resident && task.completedDay === day.value) || ids.has(task.id),
  );
});

const card = computed(() => view.value?.card ?? null);
const evidenceTitles = computed(() => {
  if (!card.value) return '';
  return evidenceOf(card.value)
    .map((item) => item.title)
    .join(' · ');
});

function isBackfilled(habitId: string): boolean {
  return view.value?.backfills.some(
    (item) => item.habitId === habitId && item.day === day.value,
  ) === true;
}

function valueText(item: { habit: Habit; scheduled: boolean }): string {
  const value = view.value?.day?.entries[item.habit.id];
  if (value === undefined) return '—';
  if (item.habit.kind === 'check') return '完成';
  if (item.habit.kind === 'count') return countText(value);
  return quantityText(value);
}

async function load(): Promise<void> {
  loading.value = true;
  error.value = false;
  try {
    view.value = await gateway.today(day.value);
    notes.value = await gateway.notes({ day: day.value });
    const taskView = await gateway.tasks();
    tasks.value = taskView.tasks;
    taskDays.value = taskView.taskDays;
  } catch {
    error.value = true;
  } finally {
    loading.value = false;
  }
}

onLoad(async (options: Record<string, string | undefined>) => {
  const value = options?.day;
  if (value) day.value = value;
  await load();
});
const themeClass = useThemeClass();
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 28rpx 24rpx 80rpx;
  box-sizing: border-box;
  background: var(--dp-bg);
}
.hero {
  margin-bottom: 18rpx;
}
.title {
  display: block;
  font-size: 42rpx;
  font-weight: 800;
}
.hint {
  display: block;
  margin-top: 4rpx;
  font-size: 23rpx;
  color: var(--dp-muted);
}
.state {
  min-height: 60vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16rpx;
  color: var(--dp-muted);
}
.state-title {
  font-size: 30rpx;
  font-weight: 700;
  color: var(--dp-ink);
}
.primary {
  background: var(--dp-accent);
  color: var(--dp-on-accent);
  border-radius: 999rpx;
  font-size: 25rpx;
  padding: 18rpx 26rpx;
  border: none;
}
.card {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 22rpx;
  padding: 18rpx 20rpx;
  margin-bottom: 14rpx;
}
.section {
  display: block;
  font-size: 23rpx;
  color: var(--dp-muted);
  margin-bottom: 10rpx;
}
.row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  min-height: 58rpx;
  gap: 16rpx;
  border-bottom: 1rpx solid var(--dp-soft);
}
.row:last-child {
  border-bottom: none;
}
.row-main {
  flex: 1;
  min-width: 0;
}
.row-title {
  display: block;
  font-size: 26rpx;
}
.row-meta {
  display: block;
  font-size: 20rpx;
  color: var(--dp-faint);
}
.row-value {
  font-size: 23rpx;
  color: var(--dp-accent-ink);
}
.empty {
  font-size: 23rpx;
  color: var(--dp-faint);
  padding: 10rpx 0;
}
.note {
  padding: 8rpx 0;
  border-bottom: 1rpx solid var(--dp-soft);
}
.note:last-child {
  border-bottom: none;
}
.note-body {
  font-size: 25rpx;
  line-height: 1.6;
  color: var(--dp-ink-3);
}
.card-line {
  font-size: 24rpx;
  color: var(--dp-muted);
}
</style>