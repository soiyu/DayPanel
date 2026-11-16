<template>
  <view v-if="enabled" class="ad-slot" aria-label="广告">
    <text class="ad-label">广告</text>
    <!-- v1 does not load an ad SDK or an <ad> component. Remote switch only. -->
    <text class="ad-body">广告位预留</text>
  </view>
</template>

<script setup lang="ts">
/**
 * v1 must not load ads. This component is a no-op by default; a later release
 * can enable it behind the 100 UV / 流量主 review gate.
 */
const enabled = false;
</script>

<style scoped>
.ad-slot {
  background: #f8fafc;
  border: 1rpx dashed #cbd5e1;
  border-radius: 20rpx;
  padding: 20rpx;
  margin: 20rpx 0;
}
.ad-label {
  font-size: 20rpx;
  color: #94a3b8;
  display: block;
  margin-bottom: 6rpx;
}
.ad-body {
  font-size: 24rpx;
  color: #64748b;
}
</style>