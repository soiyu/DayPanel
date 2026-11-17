<template>
  <view class="page" :class="themeClass">
    <view class="hero">
      <text class="title">{{ t('timeline') }}</text>
      <text class="hint">{{ storeMonth }}</text>
    </view>

    <view class="month-nav">
      <button class="nav" @tap="changeMonth(-1)">‹</button>
      <picker mode="date" fields="month" :value="`${storeMonth}-01`" @change="onMonth">
        <view class="month-pill">{{ storeMonth }}</view>
      </picker>
      <button class="nav" @tap="changeMonth(1)">›</button>
    </view>

    <view v-if="loading" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="error" class="state">
      <text class="state-title">{{ t('loadFailed') }}</text>
      <button class="primary" @tap="load"> {{ t('retry') }}</button>
    </view>
    <view v-else-if="events.length === 0" class="state">
      <text class="state-title">{{ t('noTimeline') }}</text>
    </view>

    <view v-else class="list">
      <view v-for="event in events" :key="`${event.type}-${event.id}-${event.day}`" class="event">
        <view class="event-head">
          <text class="event-type">{{ typeLabel(event.type) }}</text>
          <text class="event-day" @tap="openDay(event.day)">{{ event.day }}</text>
        </view>
        <text class="event-title">{{ event.title }}{{ event.backfilled ? ' · 补记' : '' }}</text>
        <text v-if="event.type === 'habit' && event.value !== undefined" class="event-value">
          {{ valueText(event) }}
        </text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { useThemeClass } from '../../composables/useTheme.ts';
import { ref } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import { todayKey } from '../../domain/day.ts';
import type { TimelineEvent } from '../../data/wechat-gateway.ts';
import { WechatCloudGateway } from '../../data/wechat-gateway.ts';
import { useTodayStore } from '../../stores/today.ts';
import { countText, quantityText } from '../../domain/quantity.ts';
import { translate } from '../../i18n/index.ts';

const gateway = new WechatCloudGateway();
const today = useTodayStore();
const t = (key: Parameters<typeof translate>[1]) => translate('zh', key);

const storeMonth = ref(todayKey().slice(0, 7));
const events = ref<TimelineEvent[]>([]);
const loading = ref(false);
const error = ref(false);

async function load(): Promise<void> {
  loading.value = true;
  error.value = false;
  try {
    events.value = await gateway.timeline(storeMonth.value);
  } catch {
    error.value = true;
  } finally {
    loading.value = false;
  }
}

onShow(() => {
  void load();
});

function changeMonth(delta: number): void {
  const [year, month] = storeMonth.value.split('-').map(Number);
  const next = new Date(Date.UTC(year, month - 1 + delta, 1));
  storeMonth.value = `${next.getUTCFullYear()}-${String(next.getUTCMonth() + 1).padStart(2, '0')}`;
  void load();
}

function onMonth(event: any): void {
  storeMonth.value = String(event.detail.value).slice(0, 7);
  void load();
}

function typeLabel(type: TimelineEvent['type']): string {
  if (type === 'habit') return t('habitRecord');
  if (type === 'task') return t('taskRecord');
  if (type === 'note') return t('noteRecord');
  return t('cardRecord');
}

function valueText(event: TimelineEvent): string {
  if (event.value === undefined) return '';
  if (event.kind === 'check') return '完成';
  if (event.kind === 'count') return countText(event.value);
  return quantityText(event.value);
}

function openDay(day: string): void {
  uni.navigateTo({ url: `/pages/statistics/day?day=${encodeURIComponent(day)}` });
}
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
  margin-bottom: 16rpx;
}
.title {
  display: block;
  font-size: 48rpx;
  font-weight: 800;
}
.hint {
  display: block;
  margin-top: 4rpx;
  color: var(--dp-muted);
  font-size: 23rpx;
}
.month-nav {
  display: flex;
  align-items: center;
  gap: 12rpx;
  margin-bottom: 18rpx;
}
.nav {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 999rpx;
  font-size: 30rpx;
  padding: 10rpx 20rpx;
  color: var(--dp-ink-4);
}
.month-pill {
  flex: 1;
  text-align: center;
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 999rpx;
  padding: 12rpx 0;
  font-size: 24rpx;
  color: var(--dp-ink-4);
}
.state {
  min-height: 50vh;
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
.primary {
  background: var(--dp-accent);
  color: var(--dp-on-accent);
  border-radius: 999rpx;
  font-size: 25rpx;
  padding: 18rpx 26rpx;
  border: none;
}
.list {
  display: flex;
  flex-direction: column;
  gap: 12rpx;
}
.event {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 20rpx;
  padding: 16rpx 18rpx;
}
.event-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6rpx;
}
.event-type {
  font-size: 21rpx;
  color: var(--dp-violet);
  background: var(--dp-violet-soft);
  border-radius: 999rpx;
  padding: 3rpx 10rpx;
}
.event-day {
  font-size: 21rpx;
  color: var(--dp-muted);
}
.event-title {
  display: block;
  font-size: 26rpx;
  color: var(--dp-ink-2);
  line-height: 1.5;
}
.event-value {
  display: block;
  margin-top: 4rpx;
  font-size: 23rpx;
  color: var(--dp-accent-ink);
}
</style>