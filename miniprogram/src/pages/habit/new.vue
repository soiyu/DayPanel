<template>
  <view class="page">
    <view class="field">
      <text class="label">{{ t('title') }}</text>
      <input
        v-model="title"
        class="input"
        maxlength="100"
        :placeholder="'例如：喝水 / Read a page'"
      />
    </view>

    <view class="field">
      <text class="label">{{ t('kind') }}</text>
      <picker
        :range="kindLabels"
        :value="kindIndex"
        @change="onKindChange"
      >
        <view class="picker">{{ kindLabels[kindIndex] }}</view>
      </picker>
    </view>

    <view v-if="kind !== 'check'" class="field">
      <text class="label">{{ t('target') }}</text>
      <input
        v-model="target"
        class="input"
        type="digit"
        :placeholder="kind === 'count' ? '3' : '1.5'"
      />
    </view>

    <view v-if="kind !== 'check'" class="field">
      <text class="label">{{ t('unit') }}</text>
      <input
        v-model="unit"
        class="input"
        maxlength="12"
        placeholder="ml / pages / 次"
      />
    </view>

    <view class="note">
      <text>提醒三通道默认开启；保存后仍需在提醒中心逐项授权。</text>
    </view>

    <view class="footer">
      <button class="cancel" @tap="goBack">{{ t('cancel') }}</button>
      <button class="save" :disabled="store.busy" @tap="save">
        {{ store.busy ? t('saving') : t('save') }}
      </button>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { useTodayStore } from '../../stores/today.ts';
import { parseCount, parseQuantity } from '../../domain/quantity.ts';
import type { HabitKind } from '../../domain/models.ts';

const store = useTodayStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);

const title = ref('');
const kind = ref<HabitKind>('check');
const target = ref('1');
const unit = ref('');

const kindOptions: HabitKind[] = ['check', 'quantity', 'count'];
const kindIndex = computed(() => kindOptions.indexOf(kind.value));
const kindLabels = computed(() => [
  t('kindCheck'),
  t('kindQuantity'),
  t('kindCount'),
]);

function onKindChange(event: any): void {
  const index = Number(event.detail.value);
  kind.value = kindOptions[index] ?? 'check';
  target.value = '1';
}

function goBack(): void {
  uni.navigateBack();
}

async function save(): Promise<void> {
  if (store.busy) return;
  const name = title.value.trim();
  if (!name) {
    uni.showToast({ title: t('title'), icon: 'none' });
    return;
  }
  let targetValue = 1000;
  if (kind.value !== 'check') {
    const parsed =
      kind.value === 'count' ? parseCount(target.value) : parseQuantity(target.value);
    if (parsed === null || parsed <= 0) {
      uni.showToast({ title: t('invalidInput'), icon: 'none' });
      return;
    }
    targetValue = parsed;
  }
  if (!store.view) {
    await store.load(true);
  }
  if (!store.view) {
    uni.showToast({ title: t('cloudRequired'), icon: 'none' });
    return;
  }
  const ok = await store.createHabit({
    title: name,
    kind: kind.value,
    target: targetValue,
    unit: unit.value.trim(),
    weekdays: 127,
  });
  if (!ok) {
    uni.showToast({ title: t('loadFailed'), icon: 'none' });
    return;
  }
  uni.showToast({ title: t('saved'), icon: 'success' });
  setTimeout(() => uni.navigateBack(), 300);
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx 140rpx;
  box-sizing: border-box;
  background: #f8fafc;
}
.field {
  background: #fff;
  border: 1rpx solid #e2e8f0;
  border-radius: 24rpx;
  padding: 22rpx 24rpx;
  margin-bottom: 18rpx;
}
.label {
  display: block;
  font-size: 24rpx;
  color: #64748b;
  margin-bottom: 12rpx;
}
.input,
.picker {
  min-height: 64rpx;
  font-size: 30rpx;
  color: #0f172a;
  line-height: 64rpx;
}
.note {
  font-size: 24rpx;
  color: #64748b;
  line-height: 1.6;
  padding: 8rpx 4rpx;
}
.footer {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  gap: 16rpx;
  padding: 20rpx 28rpx calc(20rpx + env(safe-area-inset-bottom));
  background: rgba(248, 250, 252, 0.96);
  border-top: 1rpx solid #e2e8f0;
}
.cancel,
.save {
  flex: 1;
  border-radius: 999rpx;
  font-size: 28rpx;
  line-height: 1;
  padding: 22rpx 0;
  border: none;
}
.cancel {
  background: #fff;
  color: #475569;
  border: 1rpx solid #e2e8f0;
}
.save {
  background: #2563eb;
  color: #fff;
  font-weight: 700;
}
</style>