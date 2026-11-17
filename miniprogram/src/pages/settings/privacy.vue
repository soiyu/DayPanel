<template>
  <view class="page" :class="themeClass">
    <text class="title">{{ t('privacyTitle') }}</text>
    <text class="body">{{ t('privacyBody') }}</text>
    <view class="items">
      <text class="item">· 数据存储在微信云开发（腾讯云）</text>
      <text class="item">· 开发者可通过云控制台访问，不是端到端加密</text>
      <text class="item">· 不提供整库导出/副本</text>
      <text class="item">· 可在中国大陆微信内使用</text>
      <text class="item">· 注销入口在“我的 → 注销账号”</text>
    </view>
    <button class="back" @tap="goBack">返回</button>
  </view>
</template>

<script setup lang="ts">
import { useThemeClass } from '../../composables/useTheme.ts';
import { useTodayStore } from '../../stores/today.ts';

const store = useTodayStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);

function goBack(): void {
  uni.navigateBack();
}
const themeClass = useThemeClass();
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 36rpx 28rpx;
  box-sizing: border-box;
  background: var(--dp-bg);
}
.title {
  display: block;
  font-size: 42rpx;
  font-weight: 800;
  margin-bottom: 18rpx;
}
.body {
  display: block;
  font-size: 26rpx;
  line-height: 1.8;
  color: var(--dp-ink-4);
}
.items {
  margin: 24rpx 0;
  display: flex;
  flex-direction: column;
  gap: 10rpx;
}
.item {
  font-size: 24rpx;
  color: var(--dp-muted);
  line-height: 1.6;
}
.back {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 999rpx;
  color: var(--dp-ink-4);
  font-size: 26rpx;
  padding: 18rpx 0;
}
</style>