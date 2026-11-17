<template>
  <view class="page" :class="themeClass">
    <view class="hero">
      <text class="title">{{ t('weRun') }}</text>
      <text class="hint">{{ t('weRunNote') }}</text>
    </view>

    <view class="section">
      <text class="section-title">{{ t('stepHabit') }}</text>
      <picker :range="habitOptions" :value="habitIndex" @change="onHabit">
        <view class="picker">{{ habitOptions[habitIndex] }}</view>
      </picker>
    </view>

    <button class="primary" :disabled="syncing" @tap="sync">
      {{ syncing ? t('loading') : t('syncSteps') }}
    </button>

    <view class="section">
      <text class="section-title">{{ t('recentSteps') }}</text>
      <view v-if="steps.length === 0" class="empty">{{ t('noSteps') }}</view>
      <view v-for="item in steps.slice(-7).reverse()" :key="item.day" class="row">
        <text class="day">{{ item.day }}</text>
        <text class="steps">{{ item.steps }}</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import { useTodayStore } from '../../stores/today.ts';
import { useThemeStore } from '../../stores/theme.ts';
import { useThemeClass } from '../../composables/useTheme.ts';
import { WechatCloudGateway } from '../../data/wechat-gateway.ts';
import { requestWeRunCloudID, WeRunError } from '../../platform/wechat/werun.ts';

const today = useTodayStore();
const theme = useThemeStore();
const themeClass = useThemeClass();
const gateway = new WechatCloudGateway();
const t = (key: Parameters<typeof today.tr>[0]) => today.tr(key);
const syncing = ref(false);
const steps = ref<Array<{ day: string; steps: number }>>([]);

const habits = computed(() =>
  (today.view?.profile.habits ?? []).filter((habit) => !habit.archived),
);
const habitOptions = computed(() => [
  t('noStepHabit'),
  ...habits.value.map((habit) => habit.title),
]);
const habitIds = computed<(string | null)[]>(() => [
  null,
  ...habits.value.map((habit) => habit.id),
]);
const habitIndex = computed(() => {
  const index = habitIds.value.indexOf(theme.settings.stepHabitId);
  return index >= 0 ? index : 0;
});

onShow(() => {
  void today.load();
  void theme.load();
});

function onHabit(event: any): void {
  const index = Number(event.detail.value);
  const id = habitIds.value[index] ?? null;
  theme.preview({ stepHabitId: id });
  void theme.savePreview();
}

async function sync(): Promise<void> {
  if (syncing.value) return;
  syncing.value = true;
  try {
    if (!today.view) await today.load();
    const cloudID = await requestWeRunCloudID();
    steps.value = await gateway.syncSteps(cloudID);
    const todaySteps = steps.value.find((item) => item.day === today.today)?.steps;
    if (todaySteps !== undefined && theme.settings.stepHabitId) {
      await today.record(theme.settings.stepHabitId, todaySteps * 1000);
    }
    uni.showToast({ title: t('stepSynced'), icon: 'success' });
  } catch (error) {
    uni.showToast({
      title: error instanceof WeRunError && error.code.includes('auth')
        ? t('stepDenied')
        : t('loadFailed'),
      icon: 'none',
    });
  } finally {
    syncing.value = false;
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
  margin-bottom: 20rpx;
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
.section {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 20rpx;
  margin-bottom: 16rpx;
}
.section-title {
  display: block;
  font-size: 23rpx;
  color: var(--dp-muted);
  margin-bottom: 10rpx;
}
.picker {
  min-height: 64rpx;
  line-height: 64rpx;
  font-size: 28rpx;
  color: var(--dp-ink);
}
.primary {
  background: var(--dp-accent);
  color: var(--dp-on-accent);
  border-radius: 999rpx;
  font-size: 26rpx;
  padding: 20rpx 0;
  border: none;
  width: 100%;
  margin-bottom: 18rpx;
}
.empty {
  font-size: 23rpx;
  color: var(--dp-faint);
}
.row {
  display: flex;
  justify-content: space-between;
  min-height: 56rpx;
  align-items: center;
  border-bottom: 1rpx solid var(--dp-soft);
}
.row:last-child {
  border-bottom: none;
}
.day {
  font-size: 24rpx;
  color: var(--dp-ink-4);
}
.steps {
  font-size: 25rpx;
  font-weight: 700;
  color: var(--dp-accent-ink);
}
</style>
