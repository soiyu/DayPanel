export const HABIT_ICON_COUNT = 28;

export function habitIconSrc(icon: number): string {
  const index = Math.max(0, Math.min(HABIT_ICON_COUNT - 1, Math.trunc(icon)));
  return `/static/habit_icons/${String(index).padStart(2, '0')}.png`;
}
