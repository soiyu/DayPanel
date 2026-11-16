import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  addDays,
  compareDay,
  daysSince,
  makeDay,
  mondayOf,
  parseDay,
  todayKey,
  weekday,
  weekdayBit,
} from '../src/domain/day.ts';
import {
  countText,
  parseCount,
  parseQuantity,
  quantityText,
} from '../src/domain/quantity.ts';
import {
  defaultReminderPrefs,
  scheduledOn,
  weekdayMask,
} from '../src/domain/models.ts';

test('day: canonical local dates and arithmetic across month ends', () => {
  assert.equal(makeDay(2026, 11, 16), '2026-11-16');
  assert.equal(addDays('2026-11-30', 1), '2026-12-01');
  assert.equal(addDays('2026-03-01', -1), '2026-02-28');
  assert.equal(addDays('2024-02-28', 1), '2024-02-29');
  assert.equal(daysSince('2026-11-16', '2026-11-01'), 15);
  assert.equal(compareDay('2026-11-16', '2026-11-17'), -1);
});

test('day: invalid calendar dates are rejected', () => {
  assert.throws(() => makeDay(2026, 2, 29), /Invalid calendar date/);
  assert.throws(() => parseDay('2026-02-29'), /Invalid calendar date/);
  assert.throws(() => parseDay('2026-13-01'), /Invalid calendar date/);
  assert.throws(() => parseDay('26-11-16'), /Invalid calendar date/);
});

test('day: ISO weekday and Monday anchor', () => {
  assert.equal(weekday('2026-11-16'), 1); // Monday
  assert.equal(weekday('2026-11-22'), 7); // Sunday
  assert.equal(mondayOf('2026-11-22'), '2026-11-16');
  assert.equal(weekdayBit('2026-11-16'), 1);
  assert.equal(weekdayMask([1, 3, 5]), 21);
});

test('quantity: exact thousandths, comma normalization, zero vs absent', () => {
  assert.equal(parseQuantity('1.5'), 1500);
  assert.equal(parseQuantity('1,5'), 1500);
  assert.equal(parseQuantity('1，5'), 1500);
  assert.equal(parseQuantity('0'), 0);
  assert.equal(parseQuantity('0.001'), 1);
  assert.equal(parseQuantity('999999999'), 999999999000);
  assert.equal(parseQuantity('1.2345'), null);
  assert.equal(parseQuantity('-1'), null);
  assert.equal(parseQuantity('1e3'), null);
  assert.equal(quantityText(1500), '1.5');
  assert.equal(quantityText(0), '0');
  assert.equal(quantityText(1001), '1.001');
});

test('count: integer counts only', () => {
  assert.equal(parseCount('3'), 3000);
  assert.equal(parseCount('0'), 0);
  assert.equal(parseCount('1.5'), null);
  assert.equal(countText(3000), '3');
  assert.throws(() => countText(1500), /Invalid count/);
});

test('schedule: weekdays, interval, weekly and weekly total', () => {
  const base = {
    effectiveDay: '2026-11-16' as const,
    target: 1000,
    unit: '',
    schedule: 'weekdays' as const,
    weekdays: weekdayMask([1, 3, 5]),
    intervalDays: 1,
    weeklyGoal: 3,
  };
  assert.equal(scheduledOn(base, '2026-11-16'), true);
  assert.equal(scheduledOn(base, '2026-11-17'), false);
  assert.equal(scheduledOn(base, '2026-11-18'), true);
  assert.equal(
    scheduledOn({ ...base, schedule: 'interval', intervalDays: 3 }, '2026-11-19'),
    true,
  );
  assert.equal(
    scheduledOn({ ...base, schedule: 'interval', intervalDays: 3 }, '2026-11-20'),
    false,
  );
  assert.equal(scheduledOn({ ...base, schedule: 'weekly' }, '2026-11-22'), true);
  assert.equal(
    scheduledOn({ ...base, schedule: 'weeklyTotal' }, '2026-11-22'),
    true,
  );
  assert.equal(scheduledOn(base, '2026-11-15'), false);
});

test('reminder defaults: three channels on at 21:00', () => {
  const prefs = defaultReminderPrefs();
  assert.equal(prefs.once, true);
  assert.equal(prefs.digest, true);
  assert.equal(prefs.calendar, true);
  assert.equal(prefs.digestMinute, 1260);
});

test('todayKey uses local calendar components', () => {
  const now = new Date(2026, 10, 16, 23, 30, 0); // local Nov 16
  assert.equal(todayKey(now), '2026-11-16');
});