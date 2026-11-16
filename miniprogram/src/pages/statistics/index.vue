<template>
  <view class="page">
    <view class="hero">
      <text class="title">{{ t('statistics') }}</text>
      <text class="hint">{{ t('statsNote') }}</text>
    </view>

    <view class="ranges">
      <view
        v-for="range in ranges"
        :key="range.days"
        class="range"
        :class="{ active: store.rangeDays === range.days }"
        @tap="selectRange(range.days)"
      >
        {{ t(range.label) }}
      </view>
    </view>

    <view v-if="store.loading && store.stats.length === 0" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="store.error && store.stats.length === 0" class="state">
      <text class="state-title">{{ t('loadFailed') }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>

    <view v-else-if="store.stats.length === 0" class="state">
      <text class="state-title">{{ t('noStats') }}</text>
    </view>

    <view v-else class="list">
      <view v-for="stat in store.stats" :key="stat.habitId" class="card">
        <view class="card-head">
          <view class="card-main">
            <text class="name">{{ stat.title }}</text>
            <text class="target">{{ targetText(stat) }}</text>
          </view>
          <text class="rate">{{ Math.round(stat.rate * 100) }}%</text>
        </view>
        <view class="bar">
          <view class="bar-fill" :style="{ width: `${Math.round(stat.rate * 100)}%` }" />
        </view>
        <view class="metrics">
          <view class="metric">
            <text class="metric-value">{{ stat.completed }} / {{ stat.planned }}</text>
            <text class="metric-label">{{ t('completedDays') }} / {{ t('plannedDays') }}</text>
          </view>
          <view class="metric">
            <text class="metric-value">{{ stat.streak }}</text>
            <text class="metric-label">{{ t('streakDays') }}</text>
          </view>
          <view v-if="stat.kind !== 'check'" class="metric">
            <text class="metric-value">{{ totalText(stat) }}</text>
            <text class="metric-label">累计</text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { onShow } from '@dcloudio/uni-app';
import { useStatsStore } from '../../stores/stats.ts';
import type { HabitStat } from '../../domain/stats.ts';
import { countText, quantityText } from '../../domain/quantity.ts';
import { translate } from '../../i18n/index.ts';

const store = useStatsStore();
const t = (key: Parameters<typeof translate>[1]) => translate('zh', key);

const ranges = [
  { days: 7, label: 'statsRange7' as const },
  { days: 30, label: 'statsRange30' as const },
  { days: 365, label: 'statsRange365' as const },
];

onShow(() => {
  void store.load();
});

function selectRange(days: number): void {
  if (store.rangeDays === days) return;
  void store.load(days);
}

function targetText(stat: HabitStat): string {
  if (stat.kind === 'check') return '完成一次';
  if (stat.kind === 'count') return `${countText(stat.target)} ${stat.unit}`.trim();
  return `${quantityText(stat.target)} ${stat.unit}`.trim();
}

function totalText(stat: HabitStat): string {
  if (stat.kind === 'count') return countText(stat.totalValue);
  return quantityText(stat.totalValue);
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx 80rpx;
  box-sizing: border-box;
  background: #f8fafc;
}
.hero {
  margin-bottom: 20rpx;
}
.title {
  display: block;
  font-size: 50rpx;
  font-weight: 800;
}
.hint {
  display: block;
  margin-top: 8rpx;
  color: #64748b;
  font-size: 23rpx;
  line-height: 1.5;
}
.ranges {
  display: flex;
  gap: 10rpx;
  margin-bottom: 22rpx;
}
.range {
  flex: 1;
  text-align: center;
  background: #fff;
  border: 1rpx solid #e2e8f0;
  border-radius: 999rpx;
  padding: 14rpx 0;
  font-size: 24rpx;
  color: #64748b;
}
.range.active {
  background: #2563eb;
  border-color: #2563eb;
  color: #fff;
  font-weight: 700;
}
.state {
  min-height: 50vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16rpx;
  color: #64748b;
}
.state-title {
  font-size: 32rpx;
  font-weight: 700;
  color: #0f172a;
}
.primary {
  background: #2563eb;
  color: #fff;
  border-radius: 999rpx;
  font-size: 25rpx;
  padding: 18rpx 26rpx;
  border: none;
}
.list {
  display: flex;
  flex-direction: column;
  gap: 14rpx;
}
.card {
  background: #fff;
  border: 1rpx solid #e2e8f0;
  border-radius: 24rpx;
  padding: 22rpx;
  box-shadow: 0 8rpx 24rpx rgba(15, 23, 42, 0.04);
}
.card-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16rpx;
}
.card-main {
  flex: 1;
  min-width: 0;
}
.name {
  display: block;
  font-size: 29rpx;
  font-weight: 700;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.target {
  display: block;
  margin-top: 5rpx;
  font-size: 22rpx;
  color: #64748b;
}
.rate {
  font-size: 30rpx;
  font-weight: 800;
  color: #1d4ed8;
}
.bar {
  height: 8rpx;
  background: #f1f5f9;
  border-radius: 999rpx;
  margin: 16rpx 0;
  overflow: hidden;
}
.bar-fill {
  height: 100%;
  background: linear-gradient(90deg, #2563eb, #7c3aed);
}
.metrics {
  display: flex;
  gap: 24rpx;
}
.metric {
  display: flex;
  flex-direction: column;
  gap: 4rpx;
}
.metric-value {
  font-size: 26rpx;
  font-weight: 700;
}
.metric-label {
  font-size: 21rpx;
  color: #94a3b8;
}
</style>