<template>
  <view class="page" :class="themeClass">
    <view class="hero">
      <text class="title">{{ t('reviewPoster') }}</text>
      <text class="hint">{{ t('reviewNote') }}</text>
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
    <view v-else-if="store.data" class="preview">
      <view class="summary">
        <text class="summary-rate">{{ Math.round(store.data.overall.rate * 100) }}%</text>
        <text class="summary-range">{{ store.data.start }} → {{ store.data.end }}</text>
        <text class="summary-note">
          {{ store.data.overall.completed }} / {{ store.data.overall.planned }} 项达标 ·
          {{ store.data.habits.length }} 个习惯
        </text>
      </view>
      <button class="primary wide" :disabled="sharing" @tap="share">
        {{ sharing ? t('loading') : t('generateReview') }}
      </button>
    </view>

    <canvas
      canvas-id="reviewPosterCanvas"
      class="poster-canvas"
      style="width: 600px; height: 900px;"
    />
  </view>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { onShareAppMessage, onShow } from '@dcloudio/uni-app';
import { useInsightsStore } from '../../stores/insights.ts';
import { useThemeClass } from '../../composables/useTheme.ts';
import { translate } from '../../i18n/index.ts';
import type { InsightRange } from '../../domain/insights.ts';
import { shareReviewPoster } from '../../platform/wechat/review-poster.ts';

const store = useInsightsStore();
const themeClass = useThemeClass();
const t = (key: Parameters<typeof translate>[1]) => translate('zh', key);
const sharing = ref(false);

const ranges: Array<{ value: InsightRange; label: string }> = [
  { value: 7, label: '近 7 天' },
  { value: 30, label: '近 30 天' },
];

onShow(() => {
  void store.load(7);
});

onShareAppMessage(() => ({
  title: 'DayPanel · 最近的真实记录',
  path: '/pages/review/index',
}));

function select(value: InsightRange): void {
  void store.load(value);
}

async function share(): Promise<void> {
  if (!store.data || sharing.value) return;
  sharing.value = true;
  try {
    await shareReviewPoster(store.data);
  } catch {
    uni.showToast({ title: '复盘长图生成失败', icon: 'none' });
  } finally {
    sharing.value = false;
  }
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
  margin-bottom: 18rpx;
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
.state {
  min-height: 50vh;
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
.primary.wide {
  width: 100%;
  margin-top: 20rpx;
  padding: 22rpx 0;
}
.preview {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 26rpx;
  padding: 24rpx;
}
.summary {
  display: flex;
  flex-direction: column;
  gap: 6rpx;
}
.summary-rate {
  font-size: 64rpx;
  font-weight: 800;
  color: var(--dp-accent);
}
.summary-range {
  font-size: 25rpx;
  color: var(--dp-ink);
}
.summary-note {
  font-size: 23rpx;
  color: var(--dp-muted);
}
.poster-canvas {
  position: fixed;
  left: 0;
  top: 0;
  opacity: 0;
  z-index: -1;
  pointer-events: none;
}
</style>
