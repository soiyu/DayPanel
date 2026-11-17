<template>
  <view class="page" :class="themeClass">
    <view v-if="!store.view && store.loading" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="!habit" class="state">
      <text class="state-title">{{ t('habitDetail') }}</text>
      <text class="state-body">{{ t('loadFailed') }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>

    <template v-else>
      <view class="hero">
        <view>
          <text class="eyebrow">{{ kindLabel(habit.kind) }}</text>
          <text class="title">{{ habit.title }}</text>
        </view>
        <button class="ghost" @tap="openEdit">{{ t('editHabit') }}</button>
      </view>

      <view class="card">
        <view class="row">
          <text class="row-title">{{ t('schedule') }}</text>
          <text class="row-value">{{ scheduleText }}</text>
        </view>
        <view class="row">
          <text class="row-title">{{ t('recordToday') }}</text>
          <text class="row-value">{{ valueText }}</text>
        </view>
        <view class="row">
          <text class="row-title">{{ t('resting') }}</text>
          <text class="row-value">{{ activeBreak ? t('resting') : '—' }}</text>
        </view>
        <text class="hint">{{ t('planFromTomorrow') }}</text>
      </view>

      <view class="actions">
        <button class="secondary" @tap="togglePause">
          {{ activeBreak ? t('resume') : t('pause') }}
        </button>
        <button class="secondary" :disabled="!!activeBreak" @tap="skipToday">
          {{ t('skipToday') }}
        </button>
        <button class="secondary" @tap="archiveHabit">{{ t('archive') }}</button>
        <button class="danger" @tap="deleteHabit">{{ t('deleteHabit') }}</button>
      </view>

      <text class="footnote">计划修改从明天生效；休息日不算完成/失败；归档保留历史。</text>
    </template>
  </view>
</template>

<script setup lang="ts">
import { useThemeClass } from '../../composables/useTheme.ts';
import { computed, ref } from 'vue';
import { onLoad, onShow } from '@dcloudio/uni-app';
import { useTodayStore } from '../../stores/today.ts';
import { currentPlan, type Habit } from '../../domain/models.ts';
import { countText, quantityText } from '../../domain/quantity.ts';

const store = useTodayStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);
const habitId = ref('');

const habit = computed<Habit | null>(() =>
  habitId.value ? store.habitById(habitId.value) : null,
);
const plan = computed(() =>
  habit.value ? currentPlan(habit.value, store.today) : null,
);
const activeBreak = computed(() => {
  if (!store.view) return null;
  return (
    store.view.breaks.find(
      (item) =>
        item.habitId === habitId.value &&
        item.startDay <= store.today &&
        (item.endDay === null || item.endDay >= store.today),
    ) ?? null
  );
});
const valueText = computed(() => {
  if (!habit.value) return '—';
  const value = store.valueOf(habit.value.id);
  if (value === null) return '—';
  if (habit.value.kind === 'check') return t('done');
  if (habit.value.kind === 'count') return countText(value);
  return quantityText(value);
});
const scheduleText = computed(() => {
  if (!plan.value) return '';
  if (plan.value.schedule === 'weekdays') {
    if (plan.value.weekdays === 127) return t('scheduleDaily');
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    const selected = names.filter((_, index) => plan.value!.weekdays & (1 << index));
    return `${t('scheduleWeekdays')}：周${selected.join('、')}`;
  }
  if (plan.value.schedule === 'interval') {
    return `${t('scheduleInterval')} ${plan.value.intervalDays}`;
  }
  if (plan.value.schedule === 'weekly') {
    return `${t('scheduleWeekly')} ${plan.value.weeklyGoal}`;
  }
  return t('scheduleWeeklyTotal');
});

onLoad((options: Record<string, string | undefined>) => {
  habitId.value = options?.id ?? '';
});

onShow(async () => {
  await store.load();
});

function kindLabel(kind: Habit['kind']): string {
  if (kind === 'check') return t('kindCheck');
  if (kind === 'count') return t('kindCount');
  return t('kindQuantity');
}

function openEdit(): void {
  uni.navigateTo({ url: `/pages/habit/edit?id=${encodeURIComponent(habitId.value)}` });
}

async function togglePause(): Promise<void> {
  if (!habit.value) return;
  if (activeBreak.value) {
    const ok = await store.endBreak(activeBreak.value.id, store.today);
    if (!ok) uni.showToast({ title: t('loadFailed'), icon: 'none' });
    return;
  }
  const ok = await store.startBreak(habit.value.id, 'pause', store.today, null);
  if (!ok) uni.showToast({ title: t('loadFailed'), icon: 'none' });
}

async function skipToday(): Promise<void> {
  if (!habit.value) return;
  const ok = await store.startBreak(habit.value.id, 'skip', store.today, store.today);
  if (!ok) uni.showToast({ title: '今天已有记录，不能跳过', icon: 'none' });
}

async function archiveHabit(): Promise<void> {
  if (!habit.value) return;
  const ok = await store.archive(habit.value.id);
  if (!ok) uni.showToast({ title: t('loadFailed'), icon: 'none' });
}

async function deleteHabit(): Promise<void> {
  if (!habit.value) return;
  const confirmed = await new Promise<any>((resolve) => {
    uni.showModal({
      title: t('deleteHabit'),
      content: `${habit.value!.title}\n删除后打卡记录一并删除；成就卡快照保留。`,
      confirmColor: '#be123c',
      success: resolve,
    });
  });
  if (!confirmed.confirm) return;
  const ok = await store.removeHabit(habit.value.id);
  if (!ok) {
    uni.showToast({ title: t('loadFailed'), icon: 'none' });
    return;
  }
  uni.navigateBack();
}
const themeClass = useThemeClass();
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx 80rpx;
  box-sizing: border-box;
  background: var(--dp-bg);
}
.state {
  min-height: 60vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 18rpx;
  color: var(--dp-muted);
}
.state-title {
  font-size: 34rpx;
  font-weight: 700;
  color: var(--dp-ink);
}
.state-body {
  font-size: 26rpx;
}
.hero {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16rpx;
  margin-bottom: 24rpx;
}
.eyebrow {
  display: block;
  font-size: 22rpx;
  color: var(--dp-muted);
  margin-bottom: 6rpx;
}
.title {
  display: block;
  font-size: 46rpx;
  font-weight: 800;
}
.ghost,
.primary,
.secondary,
.danger {
  border-radius: 999rpx;
  font-size: 25rpx;
  line-height: 1;
  padding: 18rpx 24rpx;
  border: none;
}
.ghost,
.secondary {
  background: var(--dp-accent-soft);
  color: var(--dp-accent-ink);
  font-weight: 700;
}
.primary {
  background: var(--dp-accent);
  color: var(--dp-on-accent);
  font-weight: 700;
}
.card {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 26rpx;
  padding: 10rpx 24rpx 20rpx;
  margin-bottom: 20rpx;
  box-shadow: 0 10rpx 30rpx var(--dp-shadow);
}
.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  min-height: 82rpx;
  border-bottom: 1rpx solid var(--dp-soft);
  gap: 20rpx;
}
.row-title {
  font-size: 27rpx;
  color: var(--dp-ink);
}
.row-value {
  font-size: 24rpx;
  color: var(--dp-muted);
  text-align: right;
}
.hint {
  display: block;
  margin-top: 16rpx;
  font-size: 22rpx;
  color: var(--dp-faint);
  line-height: 1.6;
}
.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 14rpx;
}
.actions > button {
  width: calc(50% - 7rpx);
  box-sizing: border-box;
}
.secondary {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  color: var(--dp-ink-3);
}
.danger {
  background: var(--dp-paper)1f2;
  color: var(--dp-rose);
  font-weight: 700;
}
.footnote {
  display: block;
  margin-top: 20rpx;
  font-size: 22rpx;
  color: var(--dp-faint);
  line-height: 1.6;
}
</style>