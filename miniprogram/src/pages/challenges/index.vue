<template>
  <view class="page" :class="themeClass">
    <view class="hero">
      <view>
        <text class="title">{{ t('challenges') }}</text>
        <text class="hint">{{ t('challengeNote') }}</text>
      </view>
      <button class="ghost" @tap="startCreate">{{ t('newChallenge') }}</button>
    </view>

    <view v-if="store.loading && store.items.length === 0" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="store.error && store.items.length === 0" class="state">
      <text class="state-title">{{ t('loadFailed') }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>
    <view v-else-if="store.items.length === 0" class="state">
      <text class="state-title">{{ t('noChallenges') }}</text>
      <text class="state-body">{{ t('challengeNote') }}</text>
    </view>

    <template v-else>
      <text class="section">{{ t('activeChallenges') }}</text>
      <view v-for="item in active" :key="item.challenge.id" class="card">
        <view class="card-head">
          <view class="card-main">
            <text class="name">{{ item.challenge.title }}</text>
            <text class="meta">
              {{ item.completed }} / {{ item.challenge.targetDays }} ·
              {{ t('daysLeft') }} {{ daysLeft(item.challenge) }}
            </text>
          </view>
          <text class="rate">{{ Math.round(item.rate * 100) }}%</text>
        </view>
        <view class="bar">
          <view class="bar-fill" :style="{ width: `${Math.round(item.rate * 100)}%` }" />
        </view>
        <button class="mini" @tap="abandon(item.challenge.id)">{{ t('abandonChallenge') }}</button>
      </view>

      <template v-if="finished.length">
        <text class="section">{{ t('finishedChallenges') }}</text>
        <view v-for="item in finished" :key="item.challenge.id" class="card">
          <view class="card-head">
            <view class="card-main">
              <text class="name">{{ item.challenge.title }}</text>
              <text class="meta">{{ item.completed }} / {{ item.challenge.targetDays }}</text>
            </view>
            <text class="status" :class="{ failed: item.status === 'failed' }">
              {{ item.status === 'completed' ? t('challengeDone') : t('challengeFailed') }}
            </text>
          </view>
        </view>
      </template>
    </template>
  </view>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { onShareAppMessage, onShow } from '@dcloudio/uni-app';
import { useChallengesStore } from '../../stores/challenges.ts';
import { useTodayStore } from '../../stores/today.ts';
import { useThemeClass } from '../../composables/useTheme.ts';
import { daysSince } from '../../domain/day.ts';
import type { ChallengeLength, ChallengeProgress } from '../../application/challenge-actions.ts';

const store = useChallengesStore();
const today = useTodayStore();
const themeClass = useThemeClass();
const t = (key: Parameters<typeof today.tr>[0]) => today.tr(key);

const active = computed(() =>
  store.items.filter(
    (item) => item.challenge.status === 'active' && item.status === 'active',
  ),
);
const finished = computed(() =>
  store.items.filter(
    (item) =>
      item.challenge.status !== 'active' ||
      item.status === 'failed' ||
      item.status === 'completed',
  ),
);

onShow(() => {
  void today.load();
  void store.load();
});

onShareAppMessage(() => ({
  title: 'DayPanel · 我的挑战',
  path: '/pages/challenges/index',
}));

function daysLeft(challenge: ChallengeProgress['challenge']): number {
  return Math.max(0, daysSince(challenge.endDay, today.today) + 1);
}

async function startCreate(): Promise<void> {
  const habits = today.view?.profile.habits.filter((habit) => !habit.archived) ?? [];
  if (habits.length === 0) {
    uni.showToast({ title: '先创建一个习惯', icon: 'none' });
    return;
  }
  const habitChoice = await new Promise<any>((resolve) => {
    uni.showActionSheet({
      itemList: habits.map((habit) => habit.title),
      success: resolve,
      fail: resolve,
    });
  });
  if (!habitChoice?.tapIndex && habitChoice?.tapIndex !== 0) return;
  const habit = habits[habitChoice.tapIndex];
  if (!habit) return;
  const lengthChoice = await new Promise<any>((resolve) => {
    uni.showActionSheet({
      itemList: [t('challenge21'), t('challenge100')],
      success: resolve,
      fail: resolve,
    });
  });
  if (!lengthChoice?.tapIndex && lengthChoice?.tapIndex !== 0) return;
  const length: ChallengeLength = lengthChoice.tapIndex === 0 ? 21 : 100;
  if (!store.revision) await store.load();
  const ok = await store.create(habit.id, length);
  if (!ok) uni.showToast({ title: t('loadFailed'), icon: 'none' });
}

async function abandon(id: string): Promise<void> {
  const result = await new Promise<any>((resolve) => {
    uni.showModal({
      title: t('abandonChallenge'),
      content: '挑战记录会保留，已生成的记录不删除。',
      confirmColor: '#be123c',
      success: resolve,
    });
  });
  if (!result.confirm) return;
  const ok = await store.abandon(id);
  if (!ok) uni.showToast({ title: t('loadFailed'), icon: 'none' });
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx 80rpx;
  box-sizing: border-box;
  background: var(--dp-bg);
}
.hero {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16rpx;
  margin-bottom: 20rpx;
}
.title {
  display: block;
  font-size: 48rpx;
  font-weight: 800;
  color: var(--dp-ink);
}
.hint {
  display: block;
  margin-top: 6rpx;
  font-size: 22rpx;
  color: var(--dp-muted);
  line-height: 1.5;
}
.ghost,
.primary,
.mini {
  border-radius: 999rpx;
  font-size: 24rpx;
  line-height: 1;
  padding: 16rpx 22rpx;
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
}
.state {
  min-height: 40vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 14rpx;
  color: var(--dp-muted);
}
.state-title {
  font-size: 30rpx;
  font-weight: 700;
  color: var(--dp-ink);
}
.state-body {
  font-size: 23rpx;
  text-align: center;
}
.section {
  display: block;
  font-size: 23rpx;
  color: var(--dp-muted);
  margin: 18rpx 0 10rpx;
}
.card {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 22rpx;
  margin-bottom: 14rpx;
}
.card-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16rpx;
}
.card-main {
  flex: 1;
  min-width: 0;
}
.name {
  display: block;
  font-size: 28rpx;
  font-weight: 700;
  color: var(--dp-ink);
}
.meta {
  display: block;
  margin-top: 4rpx;
  font-size: 22rpx;
  color: var(--dp-muted);
}
.rate {
  font-size: 28rpx;
  font-weight: 800;
  color: var(--dp-accent);
}
.status {
  font-size: 22rpx;
  color: var(--dp-teal);
}
.status.failed {
  color: var(--dp-muted);
}
.bar {
  height: 8rpx;
  background: var(--dp-soft);
  border-radius: 999rpx;
  margin: 16rpx 0;
  overflow: hidden;
}
.bar-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--dp-accent), var(--dp-violet));
}
.mini {
  background: var(--dp-soft);
  color: var(--dp-muted);
  width: 100%;
}
</style>