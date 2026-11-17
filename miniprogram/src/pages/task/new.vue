<template>
  <view class="page" :class="themeClass">
    <view class="field">
      <text class="label">{{ t('title') }}</text>
      <input
        v-model="title"
        class="input"
        maxlength="100"
        placeholder="例如：取快递 / 浇花"
      />
    </view>

    <view class="field row">
      <view>
        <text class="label">{{ t('resident') }}</text>
        <text class="hint">常驻按天复用；空白日不算逾期。</text>
      </view>
      <switch :checked="resident" color="#2563eb" @change="onResident" />
    </view>

    <view v-if="!resident" class="field row">
      <view>
        <text class="label">{{ t('dueDate') }}</text>
        <text class="hint">{{ hasDue ? dueDay : t('noDueDate') }}</text>
      </view>
      <view class="date-actions">
        <switch :checked="hasDue" color="#2563eb" @change="onHasDue" />
        <picker
          v-if="hasDue"
          mode="date"
          :value="dueDay"
          start="2000-01-01"
          end="2100-12-31"
          @change="onDueChange"
        >
          <view class="date-pill">{{ dueDay }}</view>
        </picker>
      </view>
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
import { useThemeClass } from '../../composables/useTheme.ts';
import { ref } from 'vue';
import { todayKey } from '../../domain/day.ts';
import { useTasksStore } from '../../stores/tasks.ts';

const store = useTasksStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);

const title = ref('');
const resident = ref(false);
const hasDue = ref(false);
const dueDay = ref(todayKey());

function goBack(): void {
  uni.navigateBack();
}

function onResident(event: any): void {
  resident.value = event.detail.value === true;
  if (resident.value) hasDue.value = false;
}

function onHasDue(event: any): void {
  hasDue.value = event.detail.value === true;
}

function onDueChange(event: any): void {
  dueDay.value = String(event.detail.value);
}

async function save(): Promise<void> {
  if (store.busy) return;
  const name = title.value.trim();
  if (!name) {
    uni.showToast({ title: t('title'), icon: 'none' });
    return;
  }
  if (!store.view) await store.load();
  if (!store.view) {
    uni.showToast({ title: t('cloudRequired'), icon: 'none' });
    return;
  }
  const ok = await store.create({
    title: name,
    resident: resident.value,
    dueDay: resident.value || !hasDue.value ? null : dueDay.value,
  });
  if (!ok) {
    uni.showToast({ title: t('loadFailed'), icon: 'none' });
    return;
  }
  uni.showToast({ title: t('saved'), icon: 'success' });
  setTimeout(() => uni.navigateBack(), 300);
}
const themeClass = useThemeClass();
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx 140rpx;
  box-sizing: border-box;
  background: var(--dp-bg);
}
.field {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 22rpx 24rpx;
  margin-bottom: 18rpx;
}
.field.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20rpx;
}
.label {
  display: block;
  font-size: 24rpx;
  color: var(--dp-muted);
  margin-bottom: 10rpx;
}
.hint {
  display: block;
  font-size: 22rpx;
  color: var(--dp-faint);
  margin-top: 6rpx;
}
.input {
  min-height: 64rpx;
  font-size: 30rpx;
  color: var(--dp-ink);
}
.date-actions {
  display: flex;
  align-items: center;
  gap: 12rpx;
}
.date-pill {
  background: var(--dp-accent-soft);
  color: var(--dp-accent-ink);
  border-radius: 999rpx;
  padding: 12rpx 18rpx;
  font-size: 24rpx;
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