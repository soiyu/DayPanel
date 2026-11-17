<template>
  <view class="page" :class="themeClass">
    <view v-if="!store.view && store.loading" class="state">
      <text>{{ t('loading') }}</text>
    </view>
    <view v-else-if="!habit" class="state">
      <text class="state-title">{{ t('editHabit') }}</text>
      <button class="primary" @tap="store.load()">{{ t('retry') }}</button>
    </view>

    <template v-else>
      <view class="field">
        <text class="label">{{ t('title') }}</text>
        <input v-model="title" class="input" maxlength="100" />
      </view>

      <view class="field">
        <text class="label">图标</text>
        <HabitIconPicker v-model="icon" />
      </view>

      <view v-if="habit.kind !== 'check'" class="field">
        <text class="label">{{ t('target') }}（{{ habit.kind === 'count' ? '次' : '数量' }}）</text>
        <input v-model="target" class="input" type="digit" />
      </view>

      <view v-if="habit.kind !== 'check'" class="field">
        <text class="label">{{ t('unit') }}</text>
        <input v-model="unit" class="input" maxlength="12" />
      </view>

      <view class="field">
        <text class="label">{{ t('calendarRule') }}</text>
        <picker :range="ruleLabels" :value="ruleIndex" @change="onRuleChange">
          <view class="picker">{{ ruleLabels[ruleIndex] }}</view>
        </picker>
      </view>

      <view class="field">
        <text class="label">{{ t('schedule') }}</text>
        <picker :range="scheduleLabels" :value="scheduleIndex" @change="onScheduleChange">
          <view class="picker">{{ scheduleLabels[scheduleIndex] }}</view>
        </picker>
      </view>

      <view v-if="schedule === 'weekdays'" class="field">
        <text class="label">{{ t('scheduleWeekdays') }}</text>
        <view class="weekdays">
          <view
            v-for="day in weekdays"
            :key="day.value"
            class="weekday"
            :class="{ on: selectedWeekdays.includes(day.value) }"
            @tap="toggleWeekday(day.value)"
          >
            {{ day.label }}
          </view>
        </view>
      </view>

      <view v-if="schedule === 'interval'" class="field">
        <text class="label">{{ t('intervalDays') }}</text>
        <input v-model="intervalDays" class="input" type="number" />
      </view>

      <view v-if="schedule === 'weekly'" class="field">
        <text class="label">{{ t('weeklyGoal') }}</text>
        <input v-model="weeklyGoal" class="input" type="number" />
      </view>

      <view class="note">{{ t('planFromTomorrow') }}</view>

      <view class="footer">
        <button class="cancel" @tap="goBack">{{ t('cancel') }}</button>
        <button class="save" :disabled="store.busy" @tap="save">
          {{ store.busy ? t('saving') : t('saveChanges') }}
        </button>
      </view>
    </template>
  </view>
</template>

<script setup lang="ts">
import { useThemeClass } from '../../composables/useTheme.ts';
import { computed, ref } from 'vue';
import { onLoad } from '@dcloudio/uni-app';
import { useTodayStore } from '../../stores/today.ts';
import { currentPlan, weekdayMask, type Habit, type ScheduleKind } from '../../domain/models.ts';
import { parseCount, parseQuantity } from '../../domain/quantity.ts';
import HabitIconPicker from '../../components/HabitIconPicker.vue';

const store = useTodayStore();
const t = (key: Parameters<typeof store.tr>[0]) => store.tr(key);
const habitId = ref('');

const title = ref('');
const icon = ref(0);
const target = ref('');
const unit = ref('');
const schedule = ref<ScheduleKind>('weekdays');
const selectedWeekdays = ref<number[]>([1, 2, 3, 4, 5, 6, 7]);
const intervalDays = ref('1');
const weeklyGoal = ref('3');
const calendarRule = ref<ScheduleRule>('any');

const weekdays = [
  { value: 1, label: '一' },
  { value: 2, label: '二' },
  { value: 3, label: '三' },
  { value: 4, label: '四' },
  { value: 5, label: '五' },
  { value: 6, label: '六' },
  { value: 7, label: '日' },
];

const scheduleKinds: ScheduleKind[] = [
  'weekdays',
  'interval',
  'weekly',
  'weeklyTotal',
];
const scheduleLabels = computed(() => [
  t('scheduleDaily'),
  t('scheduleInterval'),
  t('scheduleWeekly'),
  t('scheduleWeeklyTotal'),
]);
const scheduleIndex = computed(() => scheduleKinds.indexOf(schedule.value));
const ruleKinds: ScheduleRule[] = ['any', 'workdays', 'restdays', 'skip_holidays'];
const ruleLabels = computed(() => [
  t('ruleAny'),
  t('ruleWorkdays'),
  t('ruleRestdays'),
  t('ruleSkipHolidays'),
]);
const ruleIndex = computed(() => ruleKinds.indexOf(calendarRule.value));

const habit = computed<Habit | null>(() =>
  habitId.value ? store.habitById(habitId.value) : null,
);

onLoad(async (options: Record<string, string | undefined>) => {
  habitId.value = options?.id ?? '';
  if (!store.view) await store.load();
  const item = habit.value;
  if (!item) return;
  const plan = currentPlan(item, store.today);
  title.value = item.title;
  icon.value = item.icon;
  target.value =
    item.kind === 'count'
      ? String(plan.target / 1000)
      : item.kind === 'quantity'
        ? String(plan.target / 1000)
        : '';
  unit.value = plan.unit;
  schedule.value = plan.schedule;
  selectedWeekdays.value = weekdays
    .map((day) => day.value)
    .filter((value) => plan.weekdays & (1 << (value - 1)));
  intervalDays.value = String(plan.intervalDays);
  weeklyGoal.value = String(plan.weeklyGoal);
  calendarRule.value = plan.calendarRule ?? 'any';
});

function onScheduleChange(event: any): void {
  schedule.value = scheduleKinds[Number(event.detail.value)] ?? 'weekdays';
}

function onRuleChange(event: any): void {
  calendarRule.value = ruleKinds[Number(event.detail.value)] ?? 'any';
}

function toggleWeekday(value: number): void {
  selectedWeekdays.value = selectedWeekdays.value.includes(value)
    ? selectedWeekdays.value.filter((item) => item !== value)
    : [...selectedWeekdays.value, value].sort();
}

function goBack(): void {
  uni.navigateBack();
}

async function save(): Promise<void> {
  if (!habit.value || store.busy) return;
  const name = title.value.trim();
  if (!name) {
    uni.showToast({ title: t('title'), icon: 'none' });
    return;
  }
  let targetValue: number | undefined;
  if (habit.value.kind !== 'check') {
    const parsed =
      habit.value.kind === 'count'
        ? parseCount(target.value)
        : parseQuantity(target.value);
    if (parsed === null || parsed <= 0) {
      uni.showToast({ title: t('invalidInput'), icon: 'none' });
      return;
    }
    targetValue = parsed;
  }
  if (schedule.value === 'weekdays' && selectedWeekdays.value.length === 0) {
    uni.showToast({ title: t('scheduleWeekdays'), icon: 'none' });
    return;
  }
  const ok = await store.updateHabit(habit.value.id, {
    title: name,
    icon: icon.value,
    target: targetValue,
    unit: unit.value.trim(),
    schedule: schedule.value,
    weekdays:
      schedule.value === 'weekdays'
        ? weekdayMask(selectedWeekdays.value)
        : 127,
    intervalDays: Number(intervalDays.value),
    weeklyGoal: Number(weeklyGoal.value),
    calendarRule: calendarRule.value,
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
.field {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 22rpx 24rpx;
  margin-bottom: 18rpx;
}
.label {
  display: block;
  font-size: 24rpx;
  color: var(--dp-muted);
  margin-bottom: 10rpx;
}
.input,
.picker {
  min-height: 64rpx;
  font-size: 30rpx;
  line-height: 64rpx;
  color: var(--dp-ink);
}
.weekdays {
  display: flex;
  gap: 10rpx;
}
.weekday {
  flex: 1;
  text-align: center;
  border: 1rpx solid var(--dp-line);
  border-radius: 16rpx;
  padding: 14rpx 0;
  font-size: 25rpx;
  color: var(--dp-muted);
}
.weekday.on {
  background: var(--dp-accent);
  border-color: var(--dp-accent);
  color: var(--dp-on-accent);
  font-weight: 700;
}
.note {
  font-size: 23rpx;
  color: var(--dp-faint);
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