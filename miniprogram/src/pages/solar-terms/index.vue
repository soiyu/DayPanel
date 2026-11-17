<template>
  <view class="page" :class="themeClass">
    <view class="hero">
      <text class="title">{{ t('solarTerms') }}</text>
      <text class="hint">{{ t('solarTermsNote') }}</text>
    </view>

    <view class="list">
      <view
        v-for="term in terms"
        :key="term.day"
        class="term"
        :class="{ today: term.day === today }"
      >
        <view class="term-date">
          <text class="date">{{ term.day.slice(5) }}</text>
          <text v-if="term.day === today" class="badge">今天</text>
        </view>
        <view class="term-main">
          <text class="name">{{ term.name }}</text>
          <text class="desc">{{ term.description }}</text>
        </view>
      </view>
    </view>
    <text v-if="terms.length === 0" class="empty">2026 年节气数据；其他年份待更新。</text>
  </view>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { todayKey } from '../../domain/day.ts';
import { solarTermsForYear } from '../../domain/solar-terms.ts';
import { useTodayStore } from '../../stores/today.ts';
import { useThemeClass } from '../../composables/useTheme.ts';

const store = useTodayStore();
const themeClass = useThemeClass();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);
const today = todayKey();
const terms = computed(() => solarTermsForYear(Number(today.slice(0, 4))));
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
  font-size: 48rpx;
  font-weight: 800;
  color: var(--dp-ink);
}
.hint {
  display: block;
  margin-top: 6rpx;
  font-size: 23rpx;
  color: var(--dp-muted);
}
.list {
  display: flex;
  flex-direction: column;
  gap: 10rpx;
}
.term {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 20rpx;
  padding: 18rpx 20rpx;
  display: flex;
  gap: 18rpx;
  align-items: center;
}
.term.today {
  border-color: var(--dp-accent);
  box-shadow: 0 0 0 2rpx var(--dp-accent-soft);
}
.term-date {
  width: 96rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4rpx;
}
.date {
  font-size: 22rpx;
  color: var(--dp-muted);
}
.badge {
  font-size: 18rpx;
  color: var(--dp-on-accent);
  background: var(--dp-accent);
  border-radius: 999rpx;
  padding: 2rpx 8rpx;
}
.term-main {
  flex: 1;
  min-width: 0;
}
.name {
  display: block;
  font-size: 28rpx;
  font-weight: 700;
  color: var(--dp-ink);
}
.desc {
  display: block;
  margin-top: 4rpx;
  font-size: 22rpx;
  color: var(--dp-muted);
  line-height: 1.5;
}
.empty {
  display: block;
  margin-top: 18rpx;
  font-size: 23rpx;
  color: var(--dp-faint);
}
</style>
