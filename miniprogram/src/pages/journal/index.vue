<template>
  <view class="page">
    <view class="state">
      <text class="badge">P2</text>
      <text class="title">{{ t('journal') }}</text>
      <text class="body">{{ t('noNotesYet') }}</text>
    </view>
  </view>
</template>

<script setup lang="ts">
import { useTodayStore } from '../../stores/today.ts';

const store = useTodayStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx;
  box-sizing: border-box;
}
.state {
  background: #fff;
  border: 1rpx solid #e2e8f0;
  border-radius: 28rpx;
  padding: 60rpx 36rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 18rpx;
  box-shadow: 0 10rpx 30rpx rgba(15, 23, 42, 0.05);
}
.badge {
  font-size: 22rpx;
  color: #6d28d9;
  background: #f5f3ff;
  border-radius: 999rpx;
  padding: 6rpx 16rpx;
}
.title {
  font-size: 38rpx;
  font-weight: 800;
}
.body {
  color: #64748b;
  font-size: 26rpx;
  text-align: center;
  line-height: 1.6;
}
</style>