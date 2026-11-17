<template>
  <view class="page" :class="themeClass">
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
        <view
          v-for="habit in store.planned"
          :key="habit.id"
          class="habit"
          @tap="openHabit(habit)"
          @longpress="openHabitActions(habit)"
        >
          <view class="habit-icon-wrap">
            <image class="habit-icon" :src="habitIconSrc(habit.icon)" mode="aspectFit" />
          </view>
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
            @tap.stop="onHabit(habit)"
          >
            {{ store.isDone(habit) ? t('done') : t('record') }}
          </button>
        </view>
      </view>

      <view v-if="store.card" class="earned-card" @tap="openCards">
        <view class="earned-art">
          <CardArt :artwork="store.card.artwork" compact />
        </view>
        <view class="earned-body">
          <text class="earned-title">{{ t('todayCard') }}</text>
          <text class="earned-note">{{ store.card.day }} · {{ t('cards') }} ›</text>
        </view>
      </view>
    </template>
  </view>
</template>

<script setup lang="ts">
import { useThemeClass } from '../../composables/useTheme.ts';
import { computed } from 'vue';
import { onPullDownRefresh, onShow } from '@dcloudio/uni-app';
import { useTodayStore } from '../../stores/today.ts';
import { currentPlan, type Habit } from '../../domain/models.ts';
import { countText, parseCount, parseQuantity, quantityText } from '../../domain/quantity.ts';
import CardArt from '../../components/CardArt.vue';
import { habitIconSrc } from '../../domain/icons.ts';

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

function openHabit(habit: Habit): void {
  uni.navigateTo({ url: `/pages/habit/detail?id=${encodeURIComponent(habit.id)}` });
}

function openCards(): void {
  uni.navigateTo({ url: '/pages/cards/index' });
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

function openHabitActions(habit: Habit): void {
  uni.showActionSheet({
    itemList: [t('archiveHabit'), t('deleteHabit')],
    success: async (result) => {
      if (result.tapIndex === 0) {
        const ok = await store.archive(habit.id);
        if (!ok) uni.showToast({ title: errorText(store.error), icon: 'none' });
      }
      if (result.tapIndex === 1) {
        const confirmed = await showModal({
          title: t('deleteHabit'),
          content: habit.title,
          confirmColor: '#be123c',
        });
        if (!confirmed.confirm) return;
        const ok = await store.removeHabit(habit.id);
        if (!ok) uni.showToast({ title: errorText(store.error), icon: 'none' });
      }
    },
  });
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
const themeClass = useThemeClass();
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
  color: var(--dp-muted);
}
.state-title {
  font-size: 34rpx;
  font-weight: 700;
  color: var(--dp-ink);
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
  color: var(--dp-muted);
  letter-spacing: 1rpx;
  margin-bottom: 6rpx;
}
.title {
  display: block;
  font-size: 56rpx;
  font-weight: 800;
  letter-spacing: -1rpx;
  color: var(--dp-ink);
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
  background: var(--dp-accent-soft);
  color: var(--dp-accent-ink);
  font-weight: 700;
}
.primary {
  background: var(--dp-accent);
  color: var(--dp-on-accent);
  font-weight: 700;
}
.progress-card {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 28rpx;
  padding: 24rpx;
  box-shadow: 0 10rpx 30rpx var(--dp-shadow);
  margin-bottom: 24rpx;
}
.progress-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}
.progress-label {
  font-size: 26rpx;
  color: var(--dp-muted);
}
.progress-count {
  font-size: 30rpx;
  font-weight: 800;
  color: var(--dp-ink);
}
.bar {
  height: 10rpx;
  border-radius: 999rpx;
  background: var(--dp-soft);
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
  color: var(--dp-faint);
}
.inline-error {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16rpx;
  background: var(--dp-paper)7ed;
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
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 28rpx;
  padding: 48rpx 32rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 18rpx;
  box-shadow: 0 10rpx 30rpx var(--dp-shadow);
}
.empty-title {
  font-size: 34rpx;
  font-weight: 800;
}
.empty-body {
  font-size: 26rpx;
  color: var(--dp-muted);
  text-align: center;
  line-height: 1.6;
}
.habit-list {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}
.habit {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 24rpx;
  display: flex;
  align-items: center;
  gap: 20rpx;
  box-shadow: 0 8rpx 24rpx var(--dp-shadow-soft);
}
.habit-icon-wrap {
  width: 76rpx;
  height: 76rpx;
  border-radius: var(--dp-icon-radius);
  border: var(--dp-icon-border);
  overflow: hidden;
  flex: 0 0 76rpx;
  box-sizing: border-box;
}
.habit-icon {
  width: 100%;
  height: 100%;
}
.habit-main {
  flex: 1;
  min-width: 0;
}
.habit-title {
  display: block;
  font-size: 30rpx;
  font-weight: 700;
  color: var(--dp-ink);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.habit-meta {
  display: block;
  margin-top: 8rpx;
  font-size: 24rpx;
  color: var(--dp-muted);
}
.action {
  background: var(--dp-accent-soft);
  color: var(--dp-accent-ink);
  font-weight: 700;
  min-width: 120rpx;
}
.action.done {
  background: var(--dp-teal-soft);
  color: var(--dp-teal);
}
.earned-card {
  display: flex;
  gap: 18rpx;
  align-items: center;
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 16rpx;
  margin-top: 18rpx;
}
.earned-art {
  width: 92rpx;
  height: 92rpx;
  border-radius: 18rpx;
  overflow: hidden;
}
.earned-body {
  flex: 1;
}
.earned-title {
  display: block;
  font-size: 27rpx;
  font-weight: 700;
}
.earned-note {
  display: block;
  margin-top: 6rpx;
  font-size: 22rpx;
  color: var(--dp-muted);
}
</style>