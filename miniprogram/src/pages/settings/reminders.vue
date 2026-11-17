<template>
  <view class="page" :class="themeClass">
    <view class="hero">
      <text class="title">{{ t('reminderCenter') }}</text>
      <text class="hint">{{ t('reminderDefaults') }}</text>
    </view>

    <view v-if="!store.view && store.loading" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="!store.view" class="state">
      <text class="state-title">{{ t('loadFailed') }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>

    <template v-else>
      <view class="card">
        <view class="row">
          <view class="row-main">
            <text class="row-title">{{ t('reminderCalendar') }}</text>
            <text class="row-note">{{ calendarGranted ? t('calendarGranted') : t('needsAuthorization') }}</text>
          </view>
          <switch
            :checked="prefs.calendar"
            color="#2563eb"
            @change="toggle('calendar', $event)"
          />
        </view>
        <button class="secondary" :disabled="!prefs.calendar || calendarGranted" @tap="authorizeCalendar">
          {{ calendarGranted ? t('calendarGranted') : t('calendarAuthorize') }}
        </button>
      </view>

      <view class="card">
        <view class="row">
          <view class="row-main">
            <text class="row-title">{{ t('reminderDigest') }}</text>
            <text class="row-note">{{ digestMinuteText }} · {{ t('needsAuthorization') }}</text>
          </view>
          <switch
            :checked="prefs.digest"
            color="#2563eb"
            @change="toggle('digest', $event)"
          />
        </view>
        <text class="hint-block">{{ t('templateMissing') }}</text>
      </view>

      <view class="card">
        <view class="row">
          <view class="row-main">
            <text class="row-title">{{ t('reminderOnce') }}</text>
            <text class="row-note">{{ t('needsAuthorization') }}</text>
          </view>
          <switch
            :checked="prefs.once"
            color="#2563eb"
            @change="toggle('once', $event)"
          />
        </view>
        <text class="hint-block">{{ t('templateMissing') }}</text>
      </view>

      <view class="job-card">
        <text class="section-title">{{ t('jobsToday') }}</text>
        <view v-if="jobs.length === 0" class="job-empty">{{ t('noJobs') }}</view>
        <view v-for="job in jobs" :key="job.id" class="job">
          <text class="job-kind">{{ job.kind === 'digest' ? t('reminderDigest') : t('reminderOnce') }}</text>
          <text class="job-status">{{ jobStatus(job.status) }}</text>
        </view>
      </view>

      <text class="footnote">{{ t('reminderLimits') }}</text>
    </template>
  </view>
</template>

<script setup lang="ts">
import { useThemeClass } from '../../composables/useTheme.ts';
import { computed, ref } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import { useTodayStore } from '../../stores/today.ts';
import { defaultReminderPrefs, digestTimeText } from '../../application/reminder-policy.ts';
import {
  WechatCalendarAdapter,
} from '../../platform/wechat/reminder.ts';
import {
  WechatCloudGateway,
  type ReminderJobView,
} from '../../data/wechat-gateway.ts';

const store = useTodayStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);
const gateway = new WechatCloudGateway();
const calendar = new WechatCalendarAdapter();

const prefs = computed(
  () => store.view?.profile.reminders ?? defaultReminderPrefs(),
);
const digestMinuteText = computed(() => digestTimeText(prefs.value.digestMinute));
const calendarGranted = ref(false);
const jobs = ref<ReminderJobView[]>([]);

onShow(async () => {
  await store.load();
  calendarGranted.value = await calendar.hasPermission();
  if (store.view) {
    try {
      jobs.value = await gateway.reminderStatus(store.today);
    } catch {
      jobs.value = [];
    }
  }
});

function jobStatus(status: ReminderJobView['status']): string {
  if (status === 'pending') return '待发送';
  if (status === 'sent') return '已发送';
  if (status === 'invalid') return '已失效';
  return '发送失败';
}

async function toggle(
  channel: 'once' | 'digest' | 'calendar',
  event: any,
): Promise<void> {
  const value = event?.detail?.value === true;
  const ok = await store.updateReminders({ [channel]: value });
  if (!ok) uni.showToast({ title: t('loadFailed'), icon: 'none' });
}

async function authorizeCalendar(): Promise<void> {
  const ok = await calendar.authorize();
  calendarGranted.value = ok;
  uni.showToast({
    title: ok ? t('calendarGranted') : t('needsAuthorization'),
    icon: 'none',
  });
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
  margin-bottom: 24rpx;
}
.title {
  display: block;
  font-size: 48rpx;
  font-weight: 800;
}
.hint {
  display: block;
  margin-top: 8rpx;
  font-size: 23rpx;
  color: var(--dp-muted);
}
.state {
  min-height: 50vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 18rpx;
  color: var(--dp-muted);
}
.state-title {
  font-size: 32rpx;
  font-weight: 700;
  color: var(--dp-ink);
}
.primary,
.secondary {
  border-radius: 999rpx;
  font-size: 24rpx;
  line-height: 1;
  padding: 18rpx 24rpx;
  border: none;
}
.primary {
  background: var(--dp-accent);
  color: var(--dp-on-accent);
  font-weight: 700;
}
.secondary {
  background: var(--dp-accent-soft);
  color: var(--dp-accent-ink);
  margin-top: 16rpx;
  width: 100%;
}
.secondary[disabled] {
  opacity: 0.45;
}
.card,
.job-card {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 24rpx;
  margin-bottom: 16rpx;
  box-shadow: 0 8rpx 24rpx var(--dp-shadow-soft);
}
.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16rpx;
}
.row-main {
  flex: 1;
  min-width: 0;
}
.row-title {
  display: block;
  font-size: 28rpx;
  font-weight: 700;
}
.row-note {
  display: block;
  margin-top: 6rpx;
  font-size: 23rpx;
  color: var(--dp-muted);
}
.hint-block {
  display: block;
  margin-top: 14rpx;
  font-size: 22rpx;
  color: #b45309;
  line-height: 1.5;
}
.section-title {
  display: block;
  font-size: 24rpx;
  color: var(--dp-muted);
  margin-bottom: 12rpx;
}
.job-empty {
  font-size: 24rpx;
  color: var(--dp-faint);
}
.job {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12rpx 0;
  border-bottom: 1rpx solid var(--dp-soft);
}
.job:last-child {
  border-bottom: none;
}
.job-kind {
  font-size: 25rpx;
}
.job-status {
  font-size: 23rpx;
  color: var(--dp-muted);
}
.footnote {
  display: block;
  font-size: 22rpx;
  color: var(--dp-faint);
  line-height: 1.6;
  padding: 8rpx 4rpx;
}
</style>