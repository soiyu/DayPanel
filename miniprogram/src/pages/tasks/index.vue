<template>
  <view class="page" :class="themeClass">
    <view class="hero">
      <view>
        <text class="eyebrow">{{ store.today }}</text>
        <text class="title">{{ t('tasks') }}</text>
      </view>
      <view class="hero-actions">
        <button class="ghost secondary-ghost" @tap="openHistory">{{ t('taskHistory') }}</button>
        <button class="ghost" @tap="openNewTask">{{ t('newTask') }}</button>
      </view>
    </view>

    <view v-if="store.loading && !store.view" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="store.error && !store.view" class="state">
      <text class="state-title">{{ t('loadFailed') }}</text>
      <text class="state-body">{{ errorText(store.error) }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>

    <template v-else-if="store.view">
      <view v-if="store.oneTime.length === 0 && store.resident.length === 0" class="empty">
        <text class="empty-title">{{ t('noTasksYet') }}</text>
        <text class="empty-body">{{ t('noTasksHelp') }}</text>
        <button class="primary" @tap="openNewTask">{{ t('newTask') }}</button>
      </view>

      <template v-else>
        <view v-if="store.oneTime.length" class="section">
          <text class="section-title">{{ t('oneTimeTasks') }}</text>
          <view
            v-for="task in store.oneTime"
            :key="task.id"
            class="task"
            :class="{ done: store.isDone(task) }"
            @tap="openTask(task)"
            @longpress="openActions(task)"
          >
            <view class="task-main">
              <text class="task-title">{{ task.title }}</text>
              <text class="task-meta">{{ task.dueDay ? task.dueDay : t('noDueDate') }}</text>
            </view>
            <button class="action" @tap.stop="toggle(task)">
              {{ store.isDone(task) ? t('taskUndo') : t('taskDone') }}
            </button>
          </view>
        </view>

        <view v-if="store.resident.length" class="section">
          <text class="section-title">{{ t('residentTasks') }}</text>
          <view
            v-for="task in store.resident"
            :key="task.id"
            class="task"
            :class="{ done: store.isDone(task) }"
            @tap="openTask(task)"
            @longpress="openActions(task)"
          >
            <view class="task-main">
              <text class="task-title">{{ task.title }}</text>
              <text class="task-meta">{{ t('resident') }}</text>
            </view>
            <button class="action" @tap.stop="toggle(task)">
              {{ store.isDone(task) ? t('taskUndo') : t('taskDone') }}
            </button>
          </view>
        </view>
      </template>
    </template>
  </view>
</template>

<script setup lang="ts">
import { useThemeClass } from '../../composables/useTheme.ts';
import { onShow } from '@dcloudio/uni-app';
import { useTasksStore } from '../../stores/tasks.ts';
import type { SmallTask } from '../../domain/models.ts';

const store = useTasksStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);

onShow(() => {
  void store.load();
});

function openNewTask(): void {
  uni.navigateTo({ url: '/pages/task/new' });
}

function openHistory(): void {
  uni.navigateTo({ url: '/pages/tasks/history' });
}

function openTask(task: SmallTask): void {
  uni.navigateTo({ url: `/pages/task/detail?id=${encodeURIComponent(task.id)}` });
}

function errorText(code: string | null): string {
  if (!code) return t('loadFailed');
  if (code === 'conflict') return '数据已更新，请刷新后重试';
  if (code === 'network' || code === 'cloud_unavailable') return t('cloudRequired');
  return `${t('loadFailed')} (${code})`;
}

async function toggle(task: SmallTask): Promise<void> {
  const ok = await store.toggle(task);
  if (!ok) uni.showToast({ title: errorText(store.error), icon: 'none' });
}

function openActions(task: SmallTask): void {
  uni.showActionSheet({
    itemList: [t('archiveTask'), t('deleteTask')],
    success: async (result) => {
      if (result.tapIndex === 0) {
        const ok = await store.archive(task);
        if (!ok) uni.showToast({ title: errorText(store.error), icon: 'none' });
      }
      if (result.tapIndex === 1) {
        const confirmed = await new Promise<any>((resolve) => {
          uni.showModal({
            title: t('deleteTask'),
            content: task.title,
            confirmColor: '#be123c',
            success: resolve,
          });
        });
        if (!confirmed.confirm) return;
        const ok = await store.remove(task);
        if (!ok) uni.showToast({ title: errorText(store.error), icon: 'none' });
      }
    },
  });
}
const themeClass = useThemeClass();
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx 80rpx;
  box-sizing: border-box;
}
.hero {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  margin-bottom: 28rpx;
}
.hero-actions {
  display: flex;
  gap: 10rpx;
}
.secondary-ghost {
  background: var(--dp-paper);
  color: var(--dp-ink-4);
  border: 1rpx solid var(--dp-line);
}
.eyebrow {
  display: block;
  font-size: 22rpx;
  color: var(--dp-muted);
  margin-bottom: 6rpx;
}
.title {
  display: block;
  font-size: 56rpx;
  font-weight: 800;
}
.ghost,
.primary,
.action {
  border-radius: 999rpx;
  font-size: 26rpx;
  line-height: 1;
  padding: 18rpx 26rpx;
  border: none;
}
.ghost {
  background: var(--dp-accent-soft);
  color: var(--dp-accent-ink);
  font-weight: 700;
}
.primary {
  background: var(--dp-accent);
  color: var(--dp-on-accent);
  font-weight: 700;
}
.state {
  min-height: 60vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 18rpx;
  color: var(--dp-muted);
}
.state-title {
  font-size: 34rpx;
  font-weight: 700;
  color: var(--dp-ink);
}
.state-body {
  max-width: 560rpx;
  text-align: center;
  line-height: 1.6;
  font-size: 26rpx;
}
.empty {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 28rpx;
  padding: 48rpx 32rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 18rpx;
}
.empty-title {
  font-size: 34rpx;
  font-weight: 800;
}
.empty-body {
  font-size: 26rpx;
  color: var(--dp-muted);
  text-align: center;
  line-height: 1.6;
}
.section {
  margin-bottom: 28rpx;
}
.section-title {
  display: block;
  font-size: 24rpx;
  color: var(--dp-muted);
  margin: 0 0 12rpx 4rpx;
}
.task {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 24rpx;
  display: flex;
  align-items: center;
  gap: 18rpx;
  margin-bottom: 14rpx;
  box-shadow: 0 8rpx 24rpx var(--dp-shadow-soft);
}
.task.done {
  opacity: 0.62;
}
.task-main {
  flex: 1;
  min-width: 0;
}
.task-title {
  display: block;
  font-size: 30rpx;
  font-weight: 700;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.task-meta {
  display: block;
  margin-top: 6rpx;
  font-size: 23rpx;
  color: var(--dp-muted);
}
.action {
  background: var(--dp-accent-soft);
  color: var(--dp-accent-ink);
  font-weight: 700;
  min-width: 120rpx;
}
</style>