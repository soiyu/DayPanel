<template>
  <view class="page" :class="themeClass">
    <view class="hero">
      <view>
        <text class="eyebrow">DayPanel</text>
        <text class="title">{{ t('journal') }}</text>
      </view>
      <button class="ghost" @tap="openNewNote">{{ t('writeNote') }}</button>
    </view>

    <view class="toolbar">
      <button class="month-button" @tap="store.previousMonth()">‹</button>
      <text class="month">{{ store.month }}</text>
      <button class="month-button" @tap="store.nextMonth()">›</button>
      <input
        v-model="search"
        class="search"
        :placeholder="t('searchNotes')"
        confirm-type="search"
        @confirm="onSearch"
      />
    </view>

    <view class="filter-row">
      <picker :range="filterOptions" :value="filterIndex" @change="onFilterChange">
        <view class="filter-pill">{{ filterOptions[filterIndex] }}</view>
      </picker>
    </view>

    <view v-if="store.loading && store.notes.length === 0" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="store.error && store.notes.length === 0" class="state">
      <text class="state-title">{{ t('loadFailed') }}</text>
      <text class="state-body">{{ errorText(store.error) }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>

    <view v-else-if="store.notes.length === 0" class="empty">
      <text class="empty-title">{{ t('noNotesYet') }}</text>
      <text class="empty-body">{{ t('noNotesHelp') }}</text>
      <button class="primary" @tap="openNewNote">{{ t('writeNote') }}</button>
    </view>

    <view v-else class="notes">
      <view
        v-for="note in store.notes"
        :key="note.id"
        class="note"
        @tap="openEdit(note.id)"
        @longpress="confirmDelete(note)"
      >
        <view class="note-head">
          <text class="note-date">{{ note.day }}</text>
          <text v-if="note.habitId" class="note-habit">
            {{ store.habitName(note.habitId) || '关联习惯' }}
          </text>
        </view>
        <text class="note-body">{{ note.body }}</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { useThemeClass } from '../../composables/useTheme.ts';
import { computed, ref } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import { useJournalStore } from '../../stores/journal.ts';
import type { Note } from '../../domain/models.ts';

const store = useJournalStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);
const search = ref(store.text);

const filterOptions = computed(() => [
  '全部关联',
  '不关联习惯',
  ...store.habits.map((habit) => habit.title),
]);
const filterIds = computed<(string | null)[]>(() => [
  null,
  '__none__',
  ...store.habits.map((habit) => habit.id),
]);
const filterIndex = computed(() =>
  Math.max(0, filterIds.value.indexOf(store.habitFilter)),
);

onShow(() => {
  void store.load();
  void store.loadHabits();
});

function onFilterChange(event: any): void {
  const index = Number(event.detail.value);
  store.setHabitFilter(filterIds.value[index] ?? null);
}

function openNewNote(): void {
  uni.navigateTo({ url: '/pages/journal/edit' });
}

function openEdit(id: string): void {
  uni.navigateTo({ url: `/pages/journal/edit?id=${encodeURIComponent(id)}` });
}

function onSearch(): void {
  store.setText(search.value);
}

function errorText(code: string | null): string {
  if (!code) return t('loadFailed');
  if (code === 'conflict') return '数据已更新，请刷新后重试';
  if (code === 'network' || code === 'cloud_unavailable') return t('cloudRequired');
  return `${t('loadFailed')} (${code})`;
}

async function confirmDelete(note: Note): Promise<void> {
  const result = await new Promise<any>((resolve) => {
    uni.showModal({
      title: t('deleteNote'),
      content: note.body,
      confirmColor: '#be123c',
      success: resolve,
    });
  });
  if (!result.confirm) return;
  const ok = await store.remove(note.id);
  if (!ok) uni.showToast({ title: errorText(store.error), icon: 'none' });
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
  margin-bottom: 24rpx;
}
.eyebrow {
  display: block;
  font-size: 22rpx;
  color: var(--dp-muted);
  letter-spacing: 2rpx;
  margin-bottom: 6rpx;
}
.title {
  display: block;
  font-size: 56rpx;
  font-weight: 800;
}
.ghost,
.primary {
  border-radius: 999rpx;
  font-size: 26rpx;
  line-height: 1;
  padding: 18rpx 26rpx;
  border: none;
}
.ghost {
  background: var(--dp-violet-soft);
  color: var(--dp-violet);
  font-weight: 700;
}
.primary {
  background: var(--dp-accent);
  color: var(--dp-on-accent);
  font-weight: 700;
}
.toolbar {
  display: flex;
  align-items: center;
  gap: 12rpx;
  margin-bottom: 24rpx;
}
.month-button {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 999rpx;
  font-size: 30rpx;
  line-height: 1;
  padding: 12rpx 18rpx;
  color: var(--dp-ink-4);
}
.month {
  font-size: 26rpx;
  font-weight: 700;
  min-width: 150rpx;
  text-align: center;
}
.filter-row {
  display: flex;
  margin-bottom: 20rpx;
}
.filter-pill {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 999rpx;
  padding: 10rpx 20rpx;
  font-size: 23rpx;
  color: var(--dp-ink-4);
}
.search {
  flex: 1;
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 999rpx;
  padding: 14rpx 22rpx;
  font-size: 24rpx;
  min-height: 44rpx;
}
.state,
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
.state {
  color: var(--dp-muted);
}
.state-title,
.empty-title {
  font-size: 34rpx;
  font-weight: 800;
  color: var(--dp-ink);
}
.state-body,
.empty-body {
  color: var(--dp-muted);
  font-size: 26rpx;
  text-align: center;
  line-height: 1.6;
}
.note {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 24rpx;
  margin-bottom: 14rpx;
  box-shadow: 0 8rpx 24rpx var(--dp-shadow-soft);
}
.note-head {
  display: flex;
  align-items: center;
  gap: 12rpx;
  margin-bottom: 10rpx;
}
.note-date {
  font-size: 23rpx;
  color: var(--dp-violet);
  background: var(--dp-violet-soft);
  border-radius: 999rpx;
  padding: 5rpx 12rpx;
}
.note-habit {
  font-size: 22rpx;
  color: var(--dp-muted);
}
.note-body {
  font-size: 28rpx;
  line-height: 1.7;
  color: var(--dp-ink-2);
  white-space: pre-wrap;
}
</style>