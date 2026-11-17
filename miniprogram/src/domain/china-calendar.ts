import { compareDay, weekday, type DayKey } from './day.ts';

export type CalendarDayKind =
  | 'workday'
  | 'weekend'
  | 'holiday'
  | 'makeup_workday';

export interface CalendarDayInfo {
  kind: CalendarDayKind;
  name: string | null;
}

interface HolidayRange {
  name: string;
  start: DayKey;
  end: DayKey;
}

// 国务院办公厅关于2026年部分节假日安排的通知（国办发明电〔2025〕7号）。
// Keep this table versioned; future years are added when the official notice is
// published. Unknown years fall back to weekends/workdays, never guesses.
const HOLIDAYS_2026: HolidayRange[] = [
  { name: '元旦', start: '2026-01-01', end: '2026-01-03' },
  { name: '春节', start: '2026-02-15', end: '2026-02-23' },
  { name: '清明节', start: '2026-04-04', end: '2026-04-06' },
  { name: '劳动节', start: '2026-05-01', end: '2026-05-05' },
  { name: '端午节', start: '2026-06-19', end: '2026-06-21' },
  { name: '中秋节', start: '2026-09-25', end: '2026-09-27' },
  { name: '国庆节', start: '2026-10-01', end: '2026-10-07' },
];

const MAKEUP_WORKDAYS_2026 = new Set([
  '2026-01-04',
  '2026-02-14',
  '2026-02-28',
  '2026-05-09',
  '2026-09-20',
  '2026-10-10',
]);

function inRange(day: DayKey, range: HolidayRange): boolean {
  return compareDay(day, range.start) >= 0 && compareDay(day, range.end) <= 0;
}

export function chinaDayInfo(day: DayKey): CalendarDayInfo {
  if (MAKEUP_WORKDAYS_2026.has(day)) {
    return { kind: 'makeup_workday', name: '调休上班' };
  }
  const holiday = HOLIDAYS_2026.find((range) => inRange(day, range));
  if (holiday) return { kind: 'holiday', name: holiday.name };
  const iso = weekday(day);
  if (iso >= 6) return { kind: 'weekend', name: null };
  return { kind: 'workday', name: null };
}

export function isChinaWorkday(day: DayKey): boolean {
  const kind = chinaDayInfo(day).kind;
  return kind === 'workday' || kind === 'makeup_workday';
}

export function isChinaRestDay(day: DayKey): boolean {
  const kind = chinaDayInfo(day).kind;
  return kind === 'weekend' || kind === 'holiday';
}

export function isChinaHoliday(day: DayKey): boolean {
  return chinaDayInfo(day).kind === 'holiday';
}