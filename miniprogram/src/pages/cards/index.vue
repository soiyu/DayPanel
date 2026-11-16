<template>
  <view class="page">
    <view class="hero">
      <text class="title">{{ t('cards') }}</text>
      <text class="hint">{{ t('noCardsHelp') }}</text>
    </view>

    <view v-if="store.loading && store.cards.length === 0" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="store.error && store.cards.length === 0" class="state">
      <text class="state-title">{{ t('loadFailed') }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>
    <view v-else-if="store.cards.length === 0" class="state">
      <text class="state-title">{{ t('noCards') }}</text>
      <text class="state-body">{{ t('noCardsHelp') }}</text>
    </view>

    <view v-else class="list">
      <view v-for="card in store.cards" :key="card.day" class="card">
        <view class="art" :class="`art-${card.artwork}`">
          <text class="art-day">{{ card.day }}</text>
          <text class="art-mark">DayPanel</text>
        </view>
        <view class="card-body">
          <text class="card-label">{{ t('cardEvidence') }}</text>
          <text class="card-titles">{{ evidenceTitles(card) }}</text>
          <text v-if="card.reflection" class="reflection">{{ card.reflection }}</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { onShow } from '@dcloudio/uni-app';
import { useCardsStore } from '../../stores/cards.ts';
import { evidenceOf } from '../../domain/achievement.ts';
import type { AchievementCard } from '../../domain/models.ts';
import { useTodayStore } from '../../stores/today.ts';

const store = useCardsStore();
const today = useTodayStore();
const t = (key: Parameters<typeof today.tr>[0]) => today.tr(key);

onShow(() => {
  void store.load();
});

function evidenceTitles(card: AchievementCard): string {
  return evidenceOf(card)
    .map((item) => item.title)
    .join(' · ');
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
  margin-bottom: 22rpx;
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
  color: #64748b;
  line-height: 1.5;
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
  font-size: 32rpx;
  font-weight: 700;
  color: #0f172a;
}
.state-body {
  font-size: 24rpx;
  text-align: center;
  line-height: 1.6;
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
  gap: 18rpx;
}
.card {
  background: #fff;
  border: 1rpx solid #e2e8f0;
  border-radius: 26rpx;
  overflow: hidden;
  box-shadow: 0 10rpx 30rpx rgba(15, 23, 42, 0.05);
}
.art {
  min-height: 220rpx;
  padding: 22rpx;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  box-sizing: border-box;
}
.art-0 { background: linear-gradient(135deg, #e0f2fe, #bfdbfe 55%, #c7d2fe); }
.art-1 { background: linear-gradient(135deg, #fef3c7, #fed7aa 55%, #fecdd3); }
.art-2 { background: linear-gradient(135deg, #ecfdf5, #bbf7d0 55%, #a7f3d0); }
.art-3 { background: linear-gradient(135deg, #f5f3ff, #ddd6fe 55%, #c4b5fd); }
.art-4 { background: linear-gradient(135deg, #fff1f2, #fecdd3 55%, #fbcfe8); }
.art-5 { background: linear-gradient(135deg, #f8fafc, #e2e8f0 55%, #cbd5e1); }
.art-day {
  font-size: 22rpx;
  color: #334155;
  font-weight: 700;
  letter-spacing: 1rpx;
}
.art-mark {
  font-size: 30rpx;
  color: #0f172a;
  font-weight: 800;
  opacity: 0.55;
}
.card-body {
  padding: 20rpx 22rpx;
}
.card-label {
  display: block;
  font-size: 21rpx;
  color: #94a3b8;
  margin-bottom: 6rpx;
}
.card-titles {
  display: block;
  font-size: 24rpx;
  color: #334155;
  line-height: 1.5;
}
.reflection {
  display: block;
  margin-top: 10rpx;
  font-size: 24rpx;
  color: #64748b;
  line-height: 1.6;
}
</style>