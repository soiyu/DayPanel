/**
 * Local calendar day helpers. A day is always a `YYYY-MM-DD` string and is
 * never derived from UTC timestamps; arithmetic uses UTC solely to avoid
 * DST/time-zone shifts while moving between calendar dates.
 */
export type DayKey = string;

const DAY_RE = /^(\d{4})-(\d{2})-(\d{2})$/;
const MS_PER_DAY = 86_400_000;

function pad(value: number, width = 2): string {
  return String(value).padStart(width, '0');
}

export function makeDay(year: number, month: number, day: number): DayKey {
  if (
    !Number.isInteger(year) ||
    !Number.isInteger(month) ||
    !Number.isInteger(day) ||
    year < 1900 ||
    year > 2200 ||
    month < 1 ||
    month > 12 ||
    day < 1 ||
    day > 31
  ) {
    throw new RangeError('Invalid calendar date');
  }
  const date = new Date(Date.UTC(year, month - 1, day));
  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    throw new RangeError('Invalid calendar date');
  }
  return `${pad(year, 4)}-${pad(month)}-${pad(day)}`;
}

export function parseDay(value: string): DayKey {
  const match = DAY_RE.exec(value);
  if (!match) throw new FormatException('Invalid calendar date');
  const [, y, m, d] = match;
  return makeDay(Number(y), Number(m), Number(d));
}

export function isDayKey(value: string): boolean {
  try {
    parseDay(value);
    return true;
  } catch {
    return false;
  }
}

export function todayKey(now: Date = new Date()): DayKey {
  return makeDay(now.getFullYear(), now.getMonth() + 1, now.getDate());
}

function utcMillis(day: DayKey): number {
  const match = DAY_RE.exec(day);
  if (!match) throw new FormatException('Invalid calendar date');
  return Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
}

export function addDays(day: DayKey, delta: number): DayKey {
  if (!Number.isInteger(delta)) throw new RangeError('Invalid day delta');
  const date = new Date(utcMillis(parseDay(day)) + delta * MS_PER_DAY);
  return makeDay(
    date.getUTCFullYear(),
    date.getUTCMonth() + 1,
    date.getUTCDate(),
  );
}

export function daysSince(day: DayKey, other: DayKey): number {
  return Math.round((utcMillis(parseDay(day)) - utcMillis(parseDay(other))) / MS_PER_DAY);
}

export function compareDay(a: DayKey, b: DayKey): number {
  const left = parseDay(a);
  const right = parseDay(b);
  return left < right ? -1 : left > right ? 1 : 0;
}

/** ISO weekday: Monday = 1, Sunday = 7. */
export function weekday(day: DayKey): number {
  const date = new Date(utcMillis(parseDay(day)));
  const sundayBased = date.getUTCDay(); // 0..6, Sunday = 0
  return sundayBased === 0 ? 7 : sundayBased;
}

export function mondayOf(day: DayKey): DayKey {
  return addDays(day, 1 - weekday(day));
}

export function weekdayBit(day: DayKey): number {
  return 1 << (weekday(day) - 1);
}

export class FormatException extends Error {
  constructor(message = 'Invalid calendar date') {
    super(message);
    this.name = 'FormatException';
  }
}