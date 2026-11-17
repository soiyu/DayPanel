import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  chinaDayInfo,
  isChinaHoliday,
  isChinaRestDay,
  isChinaWorkday,
} from '../src/domain/china-calendar.ts';
import {
  currentPlan,
  scheduledOn,
  weekdayMask,
} from '../src/domain/models.ts';
import {
  createHabit,
  updateHabit,
  type ActionContext,
} from '../src/application/habit-actions.ts';
import { emptyState } from '../src/domain/models.ts';

const TODAY = '2026-11-16'; // ordinary Monday

test('china calendar: 2026 holidays, makeup workdays and weekends', () => {
  assert.deepEqual(chinaDayInfo('2026-01-01'), { kind: 'holiday', name: '元旦' });
  assert.deepEqual(chinaDayInfo('2026-02-15'), { kind: 'holiday', name: '春节' });
  assert.deepEqual(chinaDayInfo('2026-02-14'), {
    kind: 'makeup_workday',
    name: '调休上班',
  });
  assert.equal(chinaDayInfo('2026-02-16').kind, 'holiday');
  assert.equal(chinaDayInfo('2026-05-09').kind, 'makeup_workday');
  assert.equal(chinaDayInfo('2026-10-10').kind, 'makeup_workday');
  assert.equal(chinaDayInfo('2026-11-16').kind, 'workday');
  assert.equal(chinaDayInfo('2026-11-21').kind, 'weekend');
  assert.equal(isChinaWorkday('2026-02-14'), true);
  assert.equal(isChinaRestDay('2026-02-14'), false);
  assert.equal(isChinaHoliday('2026-10-01'), true);
});

test('china calendar: workday/restday/holiday rules', () => {
  const base = {
    effectiveDay: '2026-01-01' as const,
    target: 1000,
    unit: '',
    schedule: 'weekdays' as const,
    weekdays: weekdayMask([1, 2, 3, 4, 5, 6, 7]),
    intervalDays: 1,
    weeklyGoal: 3,
  };
  assert.equal(scheduledOn({ ...base, calendarRule: 'workdays' }, '2026-01-01'), false);
  assert.equal(scheduledOn({ ...base, calendarRule: 'workdays' }, '2026-01-04'), true);
  assert.equal(scheduledOn({ ...base, calendarRule: 'workdays' }, '2026-02-14'), true);
  assert.equal(scheduledOn({ ...base, calendarRule: 'workdays' }, '2026-11-21'), false);
  assert.equal(scheduledOn({ ...base, calendarRule: 'restdays' }, '2026-01-01'), true);
  assert.equal(scheduledOn({ ...base, calendarRule: 'restdays' }, '2026-01-04'), false);
  assert.equal(scheduledOn({ ...base, calendarRule: 'restdays' }, '2026-11-21'), true);
  assert.equal(scheduledOn({ ...base, calendarRule: 'skip_holidays' }, '2026-01-01'), false);
  assert.equal(scheduledOn({ ...base, calendarRule: 'skip_holidays' }, '2026-01-04'), true);
});

test('habit plan: calendar rule is created and changes tomorrow', () => {
  const ctx: ActionContext = { today: TODAY, idFactory: () => 'h1' };
  const created = createHabit(
    emptyState(),
    {
      title: 'Workday water',
      kind: 'check',
      target: 1000,
      calendarRule: 'workdays',
    },
    ctx,
  );
  const plan = currentPlan(created.profile.habits[0], TODAY);
  assert.equal(plan.calendarRule, 'workdays');
  assert.equal(scheduledOn(plan, TODAY), true);
  assert.equal(scheduledOn(plan, '2026-11-21'), false);

  const changed = updateHabit(created, 'h1', { calendarRule: 'any' }, ctx);
  assert.equal(currentPlan(changed.profile.habits[0], TODAY).calendarRule, 'workdays');
  assert.equal(
    currentPlan(changed.profile.habits[0], '2026-11-17').calendarRule,
    'any',
  );
  assert.throws(
    () =>
      createHabit(
        emptyState(),
        { title: 'Bad', kind: 'check', target: 1000, calendarRule: 'nope' as any },
        ctx,
      ),
    /invalid_calendar_rule/,
  );
});
