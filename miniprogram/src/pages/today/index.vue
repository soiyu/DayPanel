<template>
  <view class="page">
    <view v-if="!store.view && store.loading" class="state">
      <text>{{ t('loading') }}</text>
    </view>

    <view v-else-if="!store.view && store.error" class="state">
      <text class="state-title">{{ t('loadFailed') }}</text>
      <text class="state-body">{{ errorText(store.error) }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>

    <template v-else-if="store.view">
      <view class="hero">
        <view>
          <text class="eyebrow">{{ store.today }}</text>
          <text class="title">{{ t('today') }}</text>
        </view>
        <button class="ghost" @tap="openNewHabit">{{ t('addHabit') }}</button>
      </view>

      <view class="progress-card">
        <view class="progress-row">
          <text class="progress-label">{{ t('todayProgress') }}</text>
          <text class="progress-count">{{ store.completedCount }} / {{ store.planned.length }}</text>
        </view>
        <view class="bar">
          <view
            class="bar-fill"
            :style="{ width: progressWidth }"
          />
        </view>
        <text class="hint">{{ t('reminderDefaults') }} · {{ store.tr('privacy') }}</text>
      </view>

      <view v-if="store.error" class="inline-error">
        <text>{{ errorText(store.error) }}</text>
        <button class="text-button" @tap="store.refresh()">{{ t('retry') }}</button>
      </view>

      <view v-if="store.planned.length === 0" class="empty">
        <text class="empty-title">{{ t('emptyHabits') }}</text>
        <text class="empty-body">{{ t('emptyHabitsHelp') }}</text>
        <button class="primary" @tap="openNewHabit">{{ t('addHabit') }}</button>
      </view>

      <view v-else class="habit-list">
        <view v-for="habit in store.planned" :key="habit.id" class="habit">
          <view class="habit-main">
            <text class="habit-title">{{ habit.title }}</text>
            <text class="habit-meta">
              {{ kindLabel(habit.kind) }}<template v-if="habit.kind !== 'check'"> · {{ targetText(habit) }}</template>
            </text>
          </view>
          <button
            class="action"
            :class="{ done: store.isDone(habit) }"
            :disabled="store.busy"
            @tap="onHabit(habit)"
          >
            {{ store.isDone(habit) ? t('done') : t('record') }}
          </button>
        </view>
      </view>
    </template>
  </view>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { onPullDownRefresh, onShow } from '@dcloudio/uni-app';
import { useTodayStore } from '../../stores/today.ts';
import { currentPlan, type Habit } from '../../domain/models.ts';
import { countText, parseCount, parseQuantity, quantityText } from '../../domain/quantity.ts';

const store = useTodayStore();

const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);

const progressWidth = computed(() => {
  const total = store.planned.length;
  if (!total) return '0%';
  return `${Math.round((store.completedCount / total) * 100)}%`;
});

onShow(() => {
  void store.load();
});

onPullDownRefresh(async () => {
  await store.refresh();
  uni.stopPullDownRefresh();
});

function openNewHabit(): void {
  uni.navigateTo({ url: '/pages/habit/new' });
}

function showModal(options: Record<string, unknown>): Promise<any> {
  return new Promise((resolve, reject) => {
    uni.showModal({
      ...options,
      success: resolve,
      fail: reject,
    } as any);
  });
}

function kindLabel(kind: Habit['kind']): string {
  if (kind === 'check') return t('kindCheck');
  if (kind === 'count') return t('kindCount');
  return t('kindQuantity');
}

function targetText(habit: Habit): string {
  const plan = currentPlan(habit, store.today);
  if (habit.kind === 'count') return `${countText(plan.target)} ${plan.unit}`.trim();
  return `${quantityText(plan.target)} ${plan.unit}`.trim();
}

async function onHabit(habit: Habit): Promise<void> {
  if (store.busy) return;
  if (habit.kind === 'check') {
    if (store.isDone(habit)) {
      const result = await showModal({
        title: habit.title,
        content: '取消今天的完成记录？',
        confirmText: '取消完成',
        cancelText: '保留',
      });
      if (result.confirm) await store.clear(habit.id);
      return;
    }
    const ok = await store.record(habit.id, 1000);
    if (!ok) uni.showToast({ title: errorText(store.error), icon: 'none' });
    return;
  }

  const plan = currentPlan(habit, store.today);
  const current = store.valueOf(habit.id);
  const result = await showModal({
    title: habit.title,
    content: t('quantityHint'),
    editable: true,
    placeholderText:
      habit.kind === 'count'
        ? `${countText(plan.target)} ${plan.unit}`.trim()
        : `${quantityText(plan.target)} ${plan.unit}`.trim(),
    confirmText: t('save'),
    cancelText: t('cancel'),
  });
  if (!result.confirm) return;
  const value =
    habit.kind === 'count'
      ? parseCount(String(result.content ?? ''))
      : parseQuantity(String(result.content ?? ''));
  if (value === null) {
    uni.showToast({ title: t('invalidInput'), icon: 'none' });
    return;
  }
  if (current !== null && value === current) return;
  const ok = await store.record(habit.id, value);
  if (!ok) uni.showToast({ title: errorText(store.error), icon: 'none' });
}

function errorText(code: string | null): string {
  if (!code) return t('loadFailed');
  if (code === 'conflict') return '数据已更新，请刷新后重试';
  if (code === 'network' || code === 'cloud_unavailable') return t('cloudRequired');
  return `${t('loadFailed')} (${code})`;
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx 80rpx;
  box-sizing: border-box;
}
.state {
  min-height: 70vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 20rpx;
  color: #64748b;
}
.state-title {
  font-size: 34rpx;
  font-weight: 700;
  color: #0f172a;
}
.state-body {
  max-width: 560rpx;
  text-align: center;
  line-height: 1.6;
  font-size: 26rpx;
}
.hero {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  margin-bottom: 28rpx;
}
.eyebrow {
  display: block;
  font-size: 22rpx;
  color: #64748b;
  letter-spacing: 1rpx;
  margin-bottom: 6rpx;
}
.title {
  display: block;
  font-size: 56rpx;
  font-weight: 800;
  letter-spacing: -1rpx;
  color: #0f172a;
}
.ghost,
.primary,
.action,
.text-button {
  border-radius: 999rpx;
  font-size: 26rpx;
  line-height: 1;
  padding: 18rpx 26rpx;
  border: none;
}
.ghost {
  background: #eff6ff;
  color: #1d4ed8;
  font-weight: 700;
}
.primary {
  background: #2563eb;
  color: #fff;
  font-weight: 700;
}
.progress-card {
  background: #fff;
  border: 1rpx solid #e2e8f0;
  border-radius: 28rpx;
  padding: 24rpx;
  box-shadow: 0 10rpx 30rpx rgba(15, 23, 42, 0.05);
  margin-bottom: 24rpx;
}
.progress-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}
.progress-label {
  font-size: 26rpx;
  color: #64748b;
}
.progress-count {
  font-size: 30rpx;
  font-weight: 800;
  color: #0f172a;
}
.bar {
  height: 10rpx;
  border-radius: 999rpx;
  background: #f1f5f9;
  margin: 18rpx 0 14rpx;
  overflow: hidden;
}
.bar-fill {
  height: 100%;
  background: linear-gradient(90deg, #2563eb, #7c3aed);
  border-radius: inherit;
}
.hint {
  font-size: 22rpx;
  color: #94a3b8;
}
.inline-error {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16rpx;
  background: #fff7ed;
  color: #9a431d;
  border-radius: 20rpx;
  padding: 18rpx 22rpx;
  font-size: 24rpx;
  margin-bottom: 20rpx;
}
.text-button {
  background: transparent;
  color: #9a431d;
  padding: 0;
}
.empty {
  background: #fff;
  border: 1rpx solid #e2e8f0;
  border-radius: 28rpx;
  padding: 48rpx 32rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 18rpx;
  box-shadow: 0 10rpx 30rpx rgba(15, 23, 42, 0.05);
}
.empty-title {
  font-size: 34rpx;
  font-weight: 800;
}
.empty-body {
  font-size: 26rpx;
  color: #64748b;
  text-align: center;
  line-height: 1.6;
}
.habit-list {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}
.habit {
  background: #fff;
  border: 1rpx solid #e2e8f0;
  border-radius: 24rpx;
  padding: 24rpx;
  display: flex;
  align-items: center;
  gap: 20rpx;
  box-shadow: 0 8rpx 24rpx rgba(15, 23, 42, 0.04);
}
.habit-main {
  flex: 1;
  min-width: 0;
}
.habit-title {
  display: block;
  font-size: 30rpx;
  font-weight: 700;
  color: #0f172a;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.habit-meta {
  display: block;
  margin-top: 8rpx;
  font-size: 24rpx;
  color: #64748b;
}
.action {
  background: #eff6ff;
  color: #1d4ed8;
  font-weight: 700;
  min-width: 120rpx;
}
.action.done {
  background: #ecfdf5;
  color: #047857;
}
</style>