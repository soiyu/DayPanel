<template>
  <view class="picker">
    <view
      v-for="index in 28"
      :key="index"
      class="cell"
      :class="{ active: modelValue === index - 1 }"
      @tap="$emit('update:modelValue', index - 1)"
    >
      <image class="icon" :src="habitIconSrc(index - 1)" mode="aspectFit" />
    </view>
  </view>
</template>

<script setup lang="ts">
import { habitIconSrc } from '../domain/icons.ts';

defineProps<{ modelValue: number }>();
defineEmits<{ 'update:modelValue': [value: number] }>();
</script>

<style scoped>
.picker {
  display: flex;
  flex-wrap: wrap;
  gap: 10rpx;
}
.cell {
  width: calc(14.2857% - 9rpx);
  aspect-ratio: 1;
  border: 1rpx solid var(--dp-line);
  border-radius: 16rpx;
  box-sizing: border-box;
  padding: 4rpx;
  background: var(--dp-paper);
}
.cell.active {
  border: 2rpx solid var(--dp-accent);
  background: var(--dp-accent-soft);
}
.icon {
  width: 100%;
  height: 100%;
}
</style>
