<template>
  <view class="page" :class="themeClass">
    <text class="title">{{ t('taskHistory') }}</text>

    <view v-if="store.loading && !store.view" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="store.error && !store.view" class="state">
      <text class="state-title">{{ t('loadFailed') }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>

    <view v-else-if="groups.length === 0" class="empty">
      <text class="empty-title">{{ t('noTaskHistory') }}</text>
    </view>

    <view v-else class="groups">
      <view v-for="group in groups" :key="group.day" class="group">
        <text class="date">{{ group.day }}</text>
        <view v-for="item in group.items" :key="item.key" class="item">
          <text class="item-title">{{ item.title }}</text>
          <text class="item-type">{{ item.resident ? t('residentTasks') : t('oneTimeTasks') }}</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { useThemeClass } from '../../composables/useTheme.ts';
import { computed } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import { useTasksStore } from '../../stores/tasks.ts';

const store = useTasksStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);

interface HistoryItem {
  key: string;
  title: string;
  resident: boolean;
}

interface HistoryGroup {
  day: string;
  items: HistoryItem[];
}

const groups = computed<HistoryGroup[]>(() => {
  if (!store.view) return [];
  const byDay = new Map<string, HistoryItem[]>();
  for (const task of store.view.tasks) {
    if (!task.resident && task.completedDay) {
      const list = byDay.get(task.completedDay) ?? [];
      list.push({ key: `one-${task.id}`, title: task.title, resident: false });
      byDay.set(task.completedDay, list);
    }
  }
  for (const [day, ids] of Object.entries(store.view.taskDays)) {
    for (const id of ids) {
      const task = store.view.tasks.find((item) => item.id === id);
      if (!task) continue;
      const list = byDay.get(day) ?? [];
      list.push({ key: `resident-${day}-${id}`, title: task.title, resident: true });
      byDay.set(day, list);
    }
  }
  return [...byDay.entries()]
    .map(([day, items]) => ({ day, items }))
    .sort((a, b) => b.day.localeCompare(a.day));
});

onShow(() => {
  void store.load();
});
const themeClass = useThemeClass();
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx 80rpx;
  box-sizing: border-box;
  background: var(--dp-bg);
}
.title {
  display: block;
  font-size: 44rpx;
  font-weight: 800;
  margin-bottom: 24rpx;
}
.state,
.empty {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 26rpx;
  padding: 48rpx 30rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16rpx;
  color: var(--dp-muted);
}
.state-title,
.empty-title {
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
.groups {
  display: flex;
  flex-direction: column;
  gap: 18rpx;
}
.group {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 20rpx 24rpx;
  box-shadow: 0 8rpx 24rpx var(--dp-shadow-soft);
}
.date {
  display: block;
  font-size: 23rpx;
  color: var(--dp-violet);
  margin-bottom: 10rpx;
}
.item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16rpx;
  min-height: 64rpx;
  border-bottom: 1rpx solid var(--dp-soft);
}
.item:last-child {
  border-bottom: none;
}
.item-title {
  font-size: 27rpx;
}
.item-type {
  font-size: 22rpx;
  color: var(--dp-faint);
}
</style>