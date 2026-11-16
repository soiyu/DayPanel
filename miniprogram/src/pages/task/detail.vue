<template>
  <view class="page">
    <view v-if="!store.view && store.loading" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="!task" class="state">
      <text class="state-title">{{ t('taskDetail') }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>

    <template v-else>
      <view class="field">
        <text class="label">{{ t('title') }}</text>
        <input v-model="title" class="input" maxlength="100" />
      </view>

      <view v-if="!task.resident" class="field row">
        <view>
          <text class="label">{{ t('dueDate') }}</text>
          <text class="hint">{{ hasDue ? dueDay : t('noDueDate') }}</text>
        </view>
        <view class="date-actions">
          <switch :checked="hasDue" color="#2563eb" @change="onHasDue" />
          <picker v-if="hasDue" mode="date" :value="dueDay" @change="onDueChange">
            <view class="date-pill">{{ dueDay }}</view>
          </picker>
        </view>
      </view>

      <view class="field row">
        <text class="label">{{ t('todayDone') }}</text>
        <button class="action" @tap="toggle">
          {{ store.isDone(task) ? t('taskUndo') : t('taskDone') }}
        </button>
      </view>

      <view class="actions">
        <button class="secondary" @tap="archive">{{ t('archiveTask') }}</button>
        <button class="danger" @tap="remove">{{ t('deleteTask') }}</button>
      </view>

      <view class="footer">
        <button class="cancel" @tap="goBack">{{ t('cancel') }}</button>
        <button class="save" :disabled="store.busy" @tap="save">
          {{ store.busy ? t('saving') : t('save') }}
        </button>
      </view>
    </template>
  </view>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { onLoad, onShow } from '@dcloudio/uni-app';
import { useTasksStore } from '../../stores/tasks.ts';
import { todayKey } from '../../domain/day.ts';
import type { SmallTask } from '../../domain/models.ts';

const store = useTasksStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);
const taskId = ref('');
const title = ref('');
const hasDue = ref(false);
const dueDay = ref(todayKey());

const task = computed<SmallTask | null>(() =>
  store.view?.tasks.find((item) => item.id === taskId.value) ?? null,
);

onLoad((options: Record<string, string | undefined>) => {
  taskId.value = options?.id ?? '';
});

onShow(async () => {
  await store.load();
  if (!task.value) return;
  title.value = task.value.title;
  hasDue.value = task.value.dueDay !== null;
  dueDay.value = task.value.dueDay ?? todayKey();
});

function goBack(): void {
  uni.navigateBack();
}

function onHasDue(event: any): void {
  hasDue.value = event.detail.value === true;
}

function onDueChange(event: any): void {
  dueDay.value = String(event.detail.value);
}

async function save(): Promise<void> {
  if (!task.value || store.busy) return;
  const name = title.value.trim();
  if (!name) {
    uni.showToast({ title: t('title'), icon: 'none' });
    return;
  }
  const ok = await store.update(task.value, {
    title: name,
    dueDay: task.value.resident || !hasDue.value ? null : dueDay.value,
  });
  if (!ok) {
    uni.showToast({ title: t('loadFailed'), icon: 'none' });
    return;
  }
  uni.showToast({ title: t('saved'), icon: 'success' });
  setTimeout(() => uni.navigateBack(), 300);
}

async function toggle(): Promise<void> {
  if (!task.value) return;
  const ok = await store.toggle(task.value);
  if (!ok) uni.showToast({ title: t('loadFailed'), icon: 'none' });
}

async function archive(): Promise<void> {
  if (!task.value) return;
  const ok = await store.archive(task.value);
  if (!ok) uni.showToast({ title: t('loadFailed'), icon: 'none' });
  else uni.navigateBack();
}

async function remove(): Promise<void> {
  if (!task.value) return;
  const result = await new Promise<any>((resolve) => {
    uni.showModal({
      title: t('deleteTask'),
      content: task.value!.title,
      confirmColor: '#be123c',
      success: resolve,
    });
  });
  if (!result.confirm) return;
  const ok = await store.remove(task.value);
  if (!ok) uni.showToast({ title: t('loadFailed'), icon: 'none' });
  else uni.navigateBack();
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx 140rpx;
  box-sizing: border-box;
  background: #f8fafc;
}
.state {
  min-height: 60vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16rpx;
  color: #64748b;
}
.state-title {
  font-size: 32rpx;
  font-weight: 700;
  color: #0f172a;
}
.primary {
  background: #2563eb;
  color: #fff;
  border-radius: 999rpx;
  font-size: 25rpx;
  padding: 18rpx 26rpx;
  border: none;
}
.field {
  background: #fff;
  border: 1rpx solid #e2e8f0;
  border-radius: 24rpx;
  padding: 22rpx 24rpx;
  margin-bottom: 16rpx;
}
.field.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18rpx;
}
.label {
  display: block;
  font-size: 24rpx;
  color: #64748b;
  margin-bottom: 10rpx;
}
.hint {
  display: block;
  font-size: 22rpx;
  color: #94a3b8;
}
.input {
  min-height: 64rpx;
  font-size: 30rpx;
  color: #0f172a;
}
.date-actions {
  display: flex;
  align-items: center;
  gap: 10rpx;
}
.date-pill {
  background: #eff6ff;
  color: #1d4ed8;
  border-radius: 999rpx;
  padding: 12rpx 18rpx;
  font-size: 23rpx;
}
.action,
.secondary,
.danger {
  border-radius: 999rpx;
  font-size: 24rpx;
  line-height: 1;
  padding: 16rpx 22rpx;
  border: none;
}
.action {
  background: #eff6ff;
  color: #1d4ed8;
  font-weight: 700;
}
.actions {
  display: flex;
  gap: 12rpx;
  margin-top: 10rpx;
}
.actions > button {
  flex: 1;
}
.secondary {
  background: #fff;
  border: 1rpx solid #e2e8f0;
  color: #475569;
}
.danger {
  background: #fff1f2;
  color: #be123c;
  font-weight: 700;
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
