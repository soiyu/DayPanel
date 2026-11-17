<template>
  <view class="page" :class="themeClass">
    <view class="hero">
      <text class="title">{{ t('insightsTitle') }}</text>
      <text class="hint">{{ t('insightsNote') }}</text>
    </view>

    <view class="ranges">
      <view
        v-for="item in ranges"
        :key="item.value"
        class="range"
        :class="{ active: store.range === item.value }"
        @tap="select(item.value)"
      >
        {{ item.label }}
      </view>
    </view>

    <view v-if="store.loading && !store.data" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="store.error && !store.data" class="state">
      <text class="state-title">{{ t('loadFailed') }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>

    <template v-else-if="store.data">
      <view class="hero-card">
        <text class="hero-label">{{ t('overallRate') }}</text>
        <view class="hero-rate-row">
          <text class="hero-rate">{{ Math.round(store.data.overall.rate * 100) }}%</text>
          <text class="hero-delta" :class="{ down: store.data.overall.delta < 0 }">
            {{ store.data.overall.delta >= 0 ? '+' : '' }}{{ Math.round(store.data.overall.delta * 100) }}%
          </text>
        </view>
        <text class="hero-note">
          {{ store.data.start }} → {{ store.data.end }} · {{ t('vsPrevious') }}
        </text>
        <view class="hero-bar">
          <view class="hero-fill" :style="{ width: `${Math.round(store.data.overall.rate * 100)}%` }" />
        </view>
        <text class="hero-foot">
          {{ store.data.overall.completed }} / {{ store.data.overall.planned }}
        </text>
      </view>

      <view v-if="store.data.overall.planned === 0" class="empty">
        {{ t('insightsEmpty') }}
      </view>

      <view v-if="store.data.overall.planned > 0" class="card">
        <text class="section">{{ t('weekdayStrength') }}</text>
        <view v-for="day in store.data.weekdays" :key="day.weekday" class="weekday">
          <text class="weekday-name">{{ weekdayName(day.weekday) }}</text>
          <view class="weekday-bar">
            <view class="weekday-fill" :style="{ width: `${Math.round(day.rate * 100)}%` }" />
          </view>
          <text class="weekday-rate">{{ Math.round(day.rate * 100) }}%</text>
        </view>
      </view>

      <view v-if="store.data.habits.length" class="card">
        <text class="section">{{ t('habitTrend') }}</text>
        <view v-for="habit in store.data.habits" :key="habit.habitId" class="habit">
          <view class="habit-main">
            <text class="habit-name">{{ habit.title }}</text>
            <text class="habit-meta">{{ habit.completed }} / {{ habit.planned }}</text>
          </view>
          <text class="habit-rate">{{ Math.round(habit.rate * 100) }}%</text>
          <text class="habit-trend" :class="{ down: habit.trend < 0 }">
            {{ habit.trend >= 0 ? '↑' : '↓' }}{{ Math.abs(Math.round(habit.trend * 100)) }}
          </text>
        </view>
      </view>

      <view v-if="store.data.months.length" class="card">
        <text class="section">{{ t('monthlyTrend') }}</text>
        <view class="months">
          <view v-for="month in store.data.months" :key="month.month" class="month">
            <view class="month-bar">
              <view
                class="month-fill"
                :style="{ height: `${Math.max(8, Math.round((month.entries / maxMonthEntries) * 100))}%` }"
              />
            </view>
            <text class="month-label">{{ month.month.slice(5) }}</text>
            <text class="month-value">{{ month.entries }}</text>
          </view>
        </view>
      </view>

      <view v-if="store.data.pairs.length" class="card">
        <text class="section">{{ t('cooccurrence') }}</text>
        <view v-for="pair in store.data.pairs" :key="`${pair.first}-${pair.second}`" class="pair">
          <text class="pair-names">{{ pair.first }} × {{ pair.second }}</text>
          <text class="pair-days">{{ pair.days }} 天</text>
        </view>
      </view>

      <view class="card">
        <text class="section">{{ t('journalOverview') }}</text>
        <view class="overview">
          <view class="overview-item">
            <text class="overview-value">{{ store.data.journalNotes }}</text>
            <text class="overview-label">{{ t('journal') }}</text>
          </view>
          <view class="overview-item">
            <text class="overview-value">{{ store.data.cards }}</text>
            <text class="overview-label">{{ t('cards') }}</text>
          </view>
          <view class="overview-item">
            <text class="overview-value">{{ store.data.recordEvents }}</text>
            <text class="overview-label">事件</text>
          </view>
        </view>
      </view>
    </template>
  </view>
</template>

<script setup lang="ts">
import { useThemeClass } from '../../composables/useTheme.ts';
import { computed } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import { useInsightsStore } from '../../stores/insights.ts';
import { translate } from '../../i18n/index.ts';
import type { InsightRange } from '../../domain/insights.ts';

const store = useInsightsStore();
const t = (key: Parameters<typeof translate>[1]) => translate('zh', key);

const ranges: Array<{ value: InsightRange; label: string }> = [
  { value: 7, label: '7 天' },
  { value: 30, label: '30 天' },
  { value: 90, label: '90 天' },
  { value: 365, label: '365 天' },
];

const maxMonthEntries = computed(() =>
  Math.max(1, ...(store.data?.months.map((month) => month.entries) ?? [1])),
);

onShow(() => {
  void store.load();
});

function select(value: InsightRange): void {
  if (store.range === value) return;
  void store.load(value);
}

function weekdayName(day: number): string {
  return ['一', '二', '三', '四', '五', '六', '日'][day - 1] ?? '';
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
  font-size: 23rpx;
  color: var(--dp-muted);
  line-height: 1.5;
}
.ranges {
  display: flex;
  gap: 10rpx;
  margin-bottom: 20rpx;
}
.range {
  flex: 1;
  text-align: center;
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 999rpx;
  padding: 14rpx 0;
  font-size: 24rpx;
  color: var(--dp-muted);
}
.range.active {
  background: var(--dp-accent);
  border-color: var(--dp-accent);
  color: var(--dp-on-accent);
  font-weight: 700;
}
.state,
.empty {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 26rpx;
  padding: 42rpx 30rpx;
  text-align: center;
  color: var(--dp-muted);
  font-size: 25rpx;
}
.state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16rpx;
  min-height: 40vh;
  justify-content: center;
}
.state-title {
  font-size: 32rpx;
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
.hero-card,
.card {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 26rpx;
  padding: 24rpx;
  margin-bottom: 16rpx;
  box-shadow: 0 10rpx 30rpx var(--dp-shadow);
}
.hero-label {
  font-size: 23rpx;
  color: var(--dp-muted);
}
.hero-rate-row {
  display: flex;
  align-items: baseline;
  gap: 14rpx;
  margin-top: 6rpx;
}
.hero-rate {
  font-size: 58rpx;
  font-weight: 800;
  color: var(--dp-ink);
}
.hero-delta {
  font-size: 24rpx;
  color: var(--dp-teal);
  font-weight: 700;
}
.hero-delta.down,
.habit-trend.down {
  color: var(--dp-rose);
}
.hero-note {
  display: block;
  margin-top: 6rpx;
  font-size: 22rpx;
  color: var(--dp-faint);
}
.hero-bar {
  height: 10rpx;
  background: var(--dp-soft);
  border-radius: 999rpx;
  margin: 18rpx 0 8rpx;
  overflow: hidden;
}
.hero-fill {
  height: 100%;
  background: linear-gradient(90deg, #2563eb, #7c3aed);
}
.hero-foot {
  font-size: 22rpx;
  color: var(--dp-muted);
}
.section {
  display: block;
  font-size: 24rpx;
  color: var(--dp-muted);
  margin-bottom: 14rpx;
}
.weekday {
  display: flex;
  align-items: center;
  gap: 12rpx;
  margin-bottom: 10rpx;
}
.weekday-name {
  width: 30rpx;
  font-size: 23rpx;
  color: var(--dp-muted);
}
.weekday-bar {
  flex: 1;
  height: 10rpx;
  background: var(--dp-soft);
  border-radius: 999rpx;
  overflow: hidden;
}
.weekday-fill {
  height: 100%;
  background: #7c3aed;
}
.weekday-rate {
  width: 66rpx;
  text-align: right;
  font-size: 22rpx;
  color: var(--dp-muted);
}
.habit {
  display: flex;
  align-items: center;
  gap: 12rpx;
  min-height: 64rpx;
  border-bottom: 1rpx solid var(--dp-soft);
}
.habit:last-child {
  border-bottom: none;
}
.habit-main {
  flex: 1;
  min-width: 0;
}
.habit-name {
  display: block;
  font-size: 26rpx;
  font-weight: 600;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.habit-meta {
  display: block;
  margin-top: 3rpx;
  font-size: 21rpx;
  color: var(--dp-faint);
}
.habit-rate {
  font-size: 24rpx;
  font-weight: 700;
  color: var(--dp-accent-ink);
}
.habit-trend {
  width: 62rpx;
  text-align: right;
  font-size: 21rpx;
  color: var(--dp-teal);
}
.months {
  display: flex;
  align-items: flex-end;
  gap: 12rpx;
  height: 180rpx;
}
.month {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  height: 100%;
  justify-content: flex-end;
  gap: 6rpx;
}
.month-bar {
  width: 100%;
  height: 120rpx;
  display: flex;
  align-items: flex-end;
}
.month-fill {
  width: 100%;
  background: linear-gradient(180deg, #60a5fa, #2563eb);
  border-radius: 8rpx 8rpx 4rpx 4rpx;
  min-height: 8rpx;
}
.month-label {
  font-size: 20rpx;
  color: var(--dp-muted);
}
.month-value {
  font-size: 20rpx;
  color: var(--dp-faint);
}
.pair {
  display: flex;
  justify-content: space-between;
  min-height: 54rpx;
  align-items: center;
  border-bottom: 1rpx solid var(--dp-soft);
}
.pair:last-child {
  border-bottom: none;
}
.pair-names {
  font-size: 25rpx;
}
.pair-days {
  font-size: 22rpx;
  color: var(--dp-muted);
}
.overview {
  display: flex;
  gap: 20rpx;
}
.overview-item {
  flex: 1;
  background: var(--dp-bg);
  border-radius: 18rpx;
  padding: 18rpx;
  text-align: center;
}
.overview-value {
  display: block;
  font-size: 32rpx;
  font-weight: 800;
}
.overview-label {
  display: block;
  margin-top: 4rpx;
  font-size: 21rpx;
  color: var(--dp-faint);
}
</style>