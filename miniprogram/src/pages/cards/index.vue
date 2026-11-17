<template>
  <view class="page" :class="themeClass">
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
        <view class="art">
          <CardArt :artwork="card.artwork" />
          <view class="art-overlay">
            <text class="art-day">{{ card.day }}</text>
            <text class="art-mark">DayPanel</text>
          </view>
        </view>
        <view class="card-body">
          <text class="card-label">{{ t('cardEvidence') }}</text>
          <text class="card-titles">{{ evidenceTitles(card) }}</text>
          <text v-if="card.reflection" class="reflection">{{ card.reflection }}</text>
          <view class="card-actions">
            <button class="mini" :disabled="store.busy" @tap="toggleFavorite(card)">
              {{ card.favorite ? t('favoriteOn') : t('favorite') }}
            </button>
            <button class="mini" :disabled="store.busy" @tap="editReflection(card)">
              {{ t('reflection') }}
            </button>
            <button class="mini" @tap="share(card)">{{ t('sharePoster') }}</button>
          </view>
        </view>
      </view>
    </view>

    <canvas
      canvas-id="posterCanvas"
      class="poster-canvas"
      style="width: 600px; height: 800px;"
    />
  </view>
</template>

<script setup lang="ts">
import { useThemeClass } from '../../composables/useTheme.ts';
import { onShow } from '@dcloudio/uni-app';
import { useCardsStore } from '../../stores/cards.ts';
import { evidenceOf } from '../../domain/achievement.ts';
import type { AchievementCard } from '../../domain/models.ts';
import { useTodayStore } from '../../stores/today.ts';
import { shareCardPoster } from '../../platform/wechat/share-poster.ts';
import CardArt from '../../components/CardArt.vue';

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

function showModal(options: Record<string, unknown>): Promise<any> {
  return new Promise((resolve, reject) => {
    uni.showModal({
      ...options,
      success: resolve,
      fail: reject,
    } as any);
  });
}

async function toggleFavorite(card: AchievementCard): Promise<void> {
  const ok = await store.favorite(card);
  if (!ok) uni.showToast({ title: t('loadFailed'), icon: 'none' });
}

async function share(card: AchievementCard): Promise<void> {
  try {
    await shareCardPoster(card);
  } catch (error) {
    uni.showToast({ title: '分享图生成失败', icon: 'none' });
  }
}

async function editReflection(card: AchievementCard): Promise<void> {
  const result = await showModal({
    title: t('reflection'),
    content: card.reflection,
    editable: true,
    placeholderText: '写一点当时的想法…',
    confirmText: t('save'),
    cancelText: t('cancel'),
  });
  if (!result.confirm) return;
  const ok = await store.reflect(card, String(result.content ?? ''));
  if (!ok) uni.showToast({ title: t('loadFailed'), icon: 'none' });
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
  color: var(--dp-muted);
  line-height: 1.5;
}
.state {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 26rpx;
  padding: 48rpx 30rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16rpx;
  color: var(--dp-muted);
}
.state-title {
  font-size: 32rpx;
  font-weight: 700;
  color: var(--dp-ink);
}
.state-body {
  font-size: 24rpx;
  text-align: center;
  line-height: 1.6;
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
  gap: 18rpx;
}
.card {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 26rpx;
  overflow: hidden;
  box-shadow: 0 10rpx 30rpx var(--dp-shadow);
}
.art {
  position: relative;
  height: 260rpx;
  overflow: hidden;
}
.art-overlay {
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  padding: 22rpx;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  box-sizing: border-box;
}
.art-day {
  font-size: 22rpx;
  color: var(--dp-ink-3);
  font-weight: 700;
  letter-spacing: 1rpx;
}
.art-mark {
  font-size: 30rpx;
  color: var(--dp-ink);
  font-weight: 800;
  opacity: 0.55;
}
.card-body {
  padding: 20rpx 22rpx;
}
.card-label {
  display: block;
  font-size: 21rpx;
  color: var(--dp-faint);
  margin-bottom: 6rpx;
}
.card-titles {
  display: block;
  font-size: 24rpx;
  color: var(--dp-ink-3);
  line-height: 1.5;
}
.reflection {
  display: block;
  margin-top: 10rpx;
  font-size: 24rpx;
  color: var(--dp-muted);
  line-height: 1.6;
}
.card-actions {
  display: flex;
  gap: 10rpx;
  margin-top: 14rpx;
}
.poster-canvas {
  position: fixed;
  left: 0;
  top: 0;
  opacity: 0;
  z-index: -1;
  pointer-events: none;
}
.mini {
  flex: 1;
  background: var(--dp-bg);
  border: 1rpx solid var(--dp-line);
  border-radius: 999rpx;
  font-size: 22rpx;
  line-height: 1;
  padding: 14rpx 0;
  color: var(--dp-ink-4);
}
</style>