<template>
  <view class="page">
    <view class="hero">
      <button class="year-button" @tap="changeYear(-1)">‹</button>
      <text class="title">{{ store.year }}</text>
      <button class="year-button" @tap="changeYear(1)">›</button>
    </view>
    <text class="hint">{{ t('yearNote') }}</text>

    <view v-if="store.loading && !store.data" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="store.error && !store.data" class="state">
      <text class="state-title">{{ t('loadFailed') }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>
    <view v-else-if="totalEntries === 0" class="state">
      <text class="state-title">{{ t('noYearRecords') }}</text>
    </view>

    <view v-else class="months">
      <view v-for="month in months" :key="month.label" class="month">
        <text class="month-label">{{ month.label }}</text>
        <view class="weekdays">
          <text v-for="day in weekdays" :key="day" class="weekday">{{ day }}</text>
        </view>
        <view class="days">
          <view
            v-for="(cell, index) in month.cells"
            :key="index"
            class="day"
            :class="[cell.day ? `level-${cell.level}` : 'blank', { card: cell.card }]"
            @tap="cell.day && openDay(cell.day)"
          >
            <text v-if="cell.day" class="day-number">{{ Number(cell.day.slice(8)) }}</text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import { useYearStore } from '../../stores/year.ts';
import { translate } from '../../i18n/index.ts';

const store = useYearStore();
const t = (key: Parameters<typeof translate>[1]) => translate('zh', key);
const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
const monthNames = [
  '一月', '二月', '三月', '四月', '五月', '六月',
  '七月', '八月', '九月', '十月', '十一月', '十二月',
];

const entryCounts = computed(() => {
  const map = new Map<string, number>();
  for (const record of store.data?.days ?? []) {
    map.set(record.day, Object.keys(record.entries).length);
  }
  return map;
});
const cardDays = computed(
  () => new Set((store.data?.cards ?? []).map((card) => card.day)),
);
const totalEntries = computed(() =>
  [...entryCounts.value.values()].reduce((sum, value) => sum + value, 0),
);

function levelFor(count: number): number {
  if (count <= 0) return 0;
  if (count === 1) return 1;
  if (count <= 3) return 2;
  if (count <= 5) return 3;
  return 4;
}

const months = computed(() =>
  monthNames.map((label, index) => {
    const monthIndex = index + 1;
    const first = new Date(Date.UTC(store.year, index, 1));
    const blanks = (first.getUTCDay() + 6) % 7;
    const daysInMonth = new Date(Date.UTC(store.year, monthIndex, 0)).getUTCDate();
    const cells: Array<{ day: string | null; level: number; card: boolean }> = [];
    for (let i = 0; i < blanks; i += 1) {
      cells.push({ day: null, level: 0, card: false });
    }
    for (let d = 1; d <= daysInMonth; d += 1) {
      const day = `${store.year}-${String(monthIndex).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
      cells.push({
        day,
        level: levelFor(entryCounts.value.get(day) ?? 0),
        card: cardDays.value.has(day),
      });
    }
    return { label, cells };
  }),
);

onShow(() => {
  void store.load();
});

function changeYear(delta: number): void {
  void store.load(store.year + delta);
}

function openDay(day: string): void {
  uni.navigateTo({ url: `/pages/statistics/day?day=${encodeURIComponent(day)}` });
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 28rpx 24rpx 80rpx;
  box-sizing: border-box;
  background: #f8fafc;
}
.hero {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 24rpx;
  margin-bottom: 8rpx;
}
.title {
  font-size: 52rpx;
  font-weight: 800;
  min-width: 160rpx;
  text-align: center;
}
.year-button {
  background: #fff;
  border: 1rpx solid #e2e8f0;
  border-radius: 999rpx;
  font-size: 32rpx;
  line-height: 1;
  padding: 12rpx 22rpx;
  color: #475569;
}
.hint {
  display: block;
  text-align: center;
  font-size: 22rpx;
  color: #94a3b8;
  margin-bottom: 20rpx;
}
.state {
  background: #fff;
  border: 1rpx solid #e2e8f0;
  border-radius: 26rpx;
  padding: 48rpx 30rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16rpx;
  color: #64748b;
}
.state-title {
  font-size: 30rpx;
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
.months {
  display: flex;
  flex-direction: column;
  gap: 14rpx;
}
.month {
  background: #fff;
  border: 1rpx solid #e2e8f0;
  border-radius: 22rpx;
  padding: 16rpx;
  box-shadow: 0 6rpx 18rpx rgba(15, 23, 42, 0.03);
}
.month-label {
  display: block;
  font-size: 24rpx;
  color: #475569;
  font-weight: 700;
  margin-bottom: 8rpx;
}
.weekdays,
.days {
  display: flex;
  flex-wrap: wrap;
}
.weekday {
  width: 14.2857%;
  text-align: center;
  font-size: 19rpx;
  color: #94a3b8;
  line-height: 30rpx;
}
.day {
  width: 14.2857%;
  height: 56rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}
.day-number {
  font-size: 20rpx;
  color: #64748b;
}
.day.level-1 { background: #e0f2fe; border-radius: 10rpx; }
.day.level-1 .day-number { color: #0369a1; }
.day.level-2 { background: #bae6fd; border-radius: 10rpx; }
.day.level-2 .day-number { color: #075985; }
.day.level-3 { background: #7dd3fc; border-radius: 10rpx; }
.day.level-3 .day-number { color: #0c4a6e; font-weight: 700; }
.day.level-4 { background: #38bdf8; border-radius: 10rpx; }
.day.level-4 .day-number { color: #fff; font-weight: 700; }
.day.card::after {
  content: '';
  position: absolute;
  right: 8rpx;
  bottom: 6rpx;
  width: 7rpx;
  height: 7rpx;
  border-radius: 50%;
  background: #7c3aed;
}
.blank {
  pointer-events: none;
}
</style>