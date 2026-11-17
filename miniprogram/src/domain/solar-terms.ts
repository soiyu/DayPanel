import { compareDay, type DayKey } from './day.ts';

export interface SolarTerm {
  name: string;
  day: DayKey;
  description: string;
}

// 2026 dates from published astronomical tables. Solar terms are display
// metadata only; they never drive completion, streaks or statistics.
const TERMS_2026: SolarTerm[] = [
  { name: '小寒', day: '2026-01-05', description: '寒气渐盛，注意保暖。' },
  { name: '大寒', day: '2026-01-20', description: '一年中最冷的时段。' },
  { name: '立春', day: '2026-02-04', description: '春气始建，新的循环开始。' },
  { name: '雨水', day: '2026-02-18', description: '降水渐多，草木萌动。' },
  { name: '惊蛰', day: '2026-03-05', description: '春雷始鸣，万物复苏。' },
  { name: '春分', day: '2026-03-20', description: '昼夜平分，春意正浓。' },
  { name: '清明', day: '2026-04-05', description: '气清景明，慎终追远。' },
  { name: '谷雨', day: '2026-04-20', description: '雨生百谷，播种时节。' },
  { name: '立夏', day: '2026-05-05', description: '夏季开始，万物繁茂。' },
  { name: '小满', day: '2026-05-21', description: '麦粒渐满，未至大满。' },
  { name: '芒种', day: '2026-06-05', description: '有芒作物播种、收获。' },
  { name: '夏至', day: '2026-06-21', description: '白昼最长，盛夏将至。' },
  { name: '小暑', day: '2026-07-07', description: '暑气渐盛，尚未极热。' },
  { name: '大暑', day: '2026-07-23', description: '一年中最热的时段。' },
  { name: '立秋', day: '2026-08-07', description: '秋意初现，暑热未退。' },
  { name: '处暑', day: '2026-08-23', description: '暑气至此而止。' },
  { name: '白露', day: '2026-09-07', description: '昼夜温差大，露凝而白。' },
  { name: '秋分', day: '2026-09-23', description: '昼夜再次平分，秋色渐深。' },
  { name: '寒露', day: '2026-10-08', description: '露气寒冷，将凝为霜。' },
  { name: '霜降', day: '2026-10-23', description: '天气渐冷，初霜出现。' },
  { name: '立冬', day: '2026-11-07', description: '冬季开始，万物收藏。' },
  { name: '小雪', day: '2026-11-22', description: '寒潮渐多，初雪将至。' },
  { name: '大雪', day: '2026-12-07', description: '仲冬时节，降雪增多。' },
  { name: '冬至', day: '2026-12-21', description: '白昼最短，数九开始。' },
];

export function solarTermsForYear(year: number): SolarTerm[] {
  return year === 2026 ? TERMS_2026 : [];
}

export function solarTermOn(day: DayKey): SolarTerm | null {
  return TERMS_2026.find((term) => compareDay(term.day, day) === 0) ?? null;
}

export function nextSolarTerm(day: DayKey): SolarTerm | null {
  return TERMS_2026.find((term) => compareDay(term.day, day) > 0) ?? null;
}

export function currentSolarTerm(day: DayKey): SolarTerm | null {
  let current: SolarTerm | null = null;
  for (const term of TERMS_2026) {
    if (compareDay(term.day, day) <= 0) current = term;
    else break;
  }
  return current;
}