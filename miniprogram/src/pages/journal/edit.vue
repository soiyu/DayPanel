<template>
  <view class="page">
    <view class="field">
      <text class="label">{{ t('noteBody') }}</text>
      <textarea
        v-model="body"
        class="textarea"
        maxlength="10000"
        placeholder="今天想记下什么？"
      />
    </view>

    <view class="field row">
      <view>
        <text class="label">{{ t('noteDate') }}</text>
        <text class="hint">{{ day }}</text>
      </view>
      <picker mode="date" :value="day" @change="onDayChange">
        <view class="date-pill">选择</view>
      </picker>
    </view>

    <view class="field">
      <text class="label">关联习惯（可选）</text>
      <picker :range="habitOptions" :value="habitIndex" @change="onHabitChange">
        <view class="picker">{{ habitOptions[habitIndex] }}</view>
      </picker>
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
import { onLoad } from '@dcloudio/uni-app';
import { todayKey } from '../../domain/day.ts';
import { useJournalStore } from '../../stores/journal.ts';

const store = useJournalStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);

const noteId = ref<string | null>(null);
const body = ref('');
const day = ref(todayKey());
const habitId = ref<string | null>(null);
const habitIndex = ref(0);

const habitOptions = computed(() => [
  '不关联习惯',
  ...store.habits.map((habit) => habit.title),
]);
const habitIds = computed<(string | null)[]>(() => [
  null,
  ...store.habits.map((habit) => habit.id),
]);

onLoad(async (options: Record<string, string | undefined>) => {
  await store.loadHabits();
  const id = options?.id;
  if (!id) return;
  noteId.value = id;
  const note = await store.loadNote(id);
  if (note) {
    body.value = note.body;
    day.value = note.day;
    habitId.value = note.habitId;
    const index = habitIds.value.indexOf(note.habitId);
    habitIndex.value = index >= 0 ? index : 0;
  }
});

function goBack(): void {
  uni.navigateBack();
}

function onDayChange(event: any): void {
  day.value = String(event.detail.value);
}

function onHabitChange(event: any): void {
  habitIndex.value = Number(event.detail.value);
  habitId.value = habitIds.value[habitIndex.value] ?? null;
}

async function save(): Promise<void> {
  if (store.busy) return;
  const value = body.value.trim();
  if (!value) {
    uni.showToast({ title: t('noteBody'), icon: 'none' });
    return;
  }
  if (!store.revision && !store.notes.length) await store.load();
  const ok = noteId.value
    ? await store.update(noteId.value, {
        body: value,
        day: day.value,
        habitId: habitId.value,
      })
    : await store.create({
        body: value,
        day: day.value,
        habitId: habitId.value,
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
.field.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20rpx;
}
.label {
  display: block;
  font-size: 24rpx;
  color: #64748b;
  margin-bottom: 10rpx;
}
.textarea {
  width: 100%;
  min-height: 320rpx;
  font-size: 28rpx;
  line-height: 1.7;
  color: #0f172a;
}
.hint {
  display: block;
  font-size: 23rpx;
  color: #94a3b8;
}
.date-pill {
  background: #f5f3ff;
  color: #6d28d9;
  border-radius: 999rpx;
  padding: 14rpx 20rpx;
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