<template>
  <view class="page" :class="themeClass">
    <view v-if="!store.view && store.loading" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="!habit" class="state">
      <text class="state-title">{{ t('backfill') }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>

    <template v-else>
      <view class="hero">
        <text class="title">{{ t('backfill') }}</text>
        <text class="hint">{{ t('backfillNote') }}</text>
      </view>

      <view class="card">
        <text class="label">{{ habit.title }}</text>
        <picker
          mode="date"
          :value="day"
          :start="minDay"
          :end="maxDay"
          @change="onDay"
        >
          <view class="picker">{{ day }}</view>
        </picker>
      </view>

      <view v-if="habit.kind !== 'check'" class="card">
        <text class="label">
          {{ habit.kind === 'count' ? '次数' : '数量' }}
        </text>
        <input v-model="value" class="input" type="digit" placeholder="输入当天总量" />
        <text class="unit">{{ unit }}</text>
      </view>

      <view class="footer">
        <button class="cancel" @tap="goBack">{{ t('cancel') }}</button>
        <button class="save" :disabled="store.busy" @tap="save">
          {{ store.busy ? t('saving') : t('backfill') }}
        </button>
      </view>
    </template>
  </view>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { useTodayStore } from '../../stores/today.ts';
import { useThemeClass } from '../../composables/useTheme.ts';
import { addDays, todayKey, type DayKey } from '../../domain/day.ts';
import { currentPlan } from '../../domain/models.ts';
import { countText, parseCount, parseQuantity, quantityText } from '../../domain/quantity.ts';

const store = useTodayStore();
const themeClass = useThemeClass();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);
const habitId = ref('');
const today = todayKey();
const maxDay = addDays(today, -1);
const minDay = addDays(today, -7);
const day = ref<DayKey>(maxDay);
const value = ref('');

const habit = computed(() =>
  habitId.value ? store.habitById(habitId.value) : null,
);
const unit = computed(() => {
  if (!habit.value) return '';
  return currentPlan(habit.value, day.value).unit;
});

onLoad(async (options: Record<string, string | undefined>) => {
  habitId.value = options?.id ?? '';
  await store.load();
  const item = habit.value;
  if (!item || item.kind === 'check') return;
  const plan = currentPlan(item, day.value);
  value.value = item.kind === 'count'
    ? String(plan.target / 1000)
    : quantityText(plan.target);
});

function onDay(event: any): void {
  day.value = String(event.detail.value);
}

function goBack(): void {
  uni.navigateBack();
}

async function save(): Promise<void> {
  if (!habit.value || store.busy) return;
  let parsed = 1000;
  if (habit.value.kind !== 'check') {
    parsed =
      habit.value.kind === 'count'
        ? parseCount(value.value)
        : parseQuantity(value.value);
    if (parsed === null) {
      uni.showToast({ title: t('invalidInput'), icon: 'none' });
      return;
    }
  }
  const ok = await store.recordOn(habit.value.id, day.value, parsed);
  if (!ok) {
    uni.showToast({ title: t('backfillTooOld'), icon: 'none' });
    return;
  }
  uni.showToast({ title: t('backfillSaved'), icon: 'success' });
  setTimeout(() => uni.navigateBack(), 300);
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx 140rpx;
  box-sizing: border-box;
  background: var(--dp-bg);
}
.state {
  min-height: 60vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16rpx;
  color: var(--dp-muted);
}
.state-title {
  font-size: 32rpx;
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
.hero {
  margin-bottom: 18rpx;
}
.title {
  display: block;
  font-size: 46rpx;
  font-weight: 800;
  color: var(--dp-ink);
}
.hint {
  display: block;
  margin-top: 6rpx;
  font-size: 23rpx;
  color: var(--dp-muted);
  line-height: 1.5;
}
.card {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 22rpx;
  margin-bottom: 16rpx;
}
.label {
  display: block;
  font-size: 24rpx;
  color: var(--dp-muted);
  margin-bottom: 10rpx;
}
.picker,
.input {
  min-height: 64rpx;
  font-size: 30rpx;
  color: var(--dp-ink);
  line-height: 64rpx;
}
.unit {
  display: block;
  margin-top: 6rpx;
  font-size: 22rpx;
  color: var(--dp-faint);
}
.footer {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  gap: 16rpx;
  padding: 20rpx 28rpx calc(20rpx + env(safe-area-inset-bottom));
  background: var(--dp-bg-translucent);
  border-top: 1rpx solid var(--dp-line);
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
  background: var(--dp-paper);
  color: var(--dp-ink-4);
  border: 1rpx solid var(--dp-line);
}
.save {
  background: var(--dp-accent);
  color: var(--dp-on-accent);
  font-weight: 700;
}
</style>
