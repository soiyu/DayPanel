import type { DayKey } from '../domain/day.ts';
import {
  defaultReminderPrefs,
  type ReminderPrefs,
} from '../domain/models.ts';

export { defaultReminderPrefs };

export type ReminderChannel = 'once' | 'digest' | 'calendar';
export type ChannelStatus =
  | 'off'
  | 'needs_authorization'
  | 'active'
  | 'blocked';

export interface ReminderAuth {
  /** One-shot subscription is granted per job, not once forever. */
  once: boolean;
  /** The local day for which a daily digest message was authorized. */
  digestDay: DayKey | null;
  /** Whether the system-calendar scope is granted on this device. */
  calendar: boolean;
}

export function defaultReminderAuth(): ReminderAuth {
  return { once: false, digestDay: null, calendar: false };
}

export function channelStatus(
  channel: ReminderChannel,
  prefs: ReminderPrefs,
  auth: ReminderAuth,
  today: DayKey,
): ChannelStatus {
  if (!prefs[channel]) return 'off';
  if (channel === 'digest') {
    return auth.digestDay === today ? 'active' : 'needs_authorization';
  }
  if (channel === 'calendar') {
    return auth.calendar ? 'active' : 'needs_authorization';
  }
  return auth.once ? 'active' : 'needs_authorization';
}

export function enabledChannelCount(prefs: ReminderPrefs): number {
  return [prefs.once, prefs.digest, prefs.calendar].filter(Boolean).length;
}

/** Three channels are all on by default; warn before writing duplicates. */
export function duplicateWarning(prefs: ReminderPrefs): boolean {
  return enabledChannelCount(prefs) > 1;
}

export function validDigestMinute(value: number): boolean {
  return Number.isInteger(value) && value >= 0 && value <= 1439;
}

export function digestTimeText(minute: number): string {
  if (!validDigestMinute(minute)) throw new RangeError('Invalid digest minute');
  const hh = String(Math.floor(minute / 60)).padStart(2, '0');
  const mm = String(minute % 60).padStart(2, '0');
  return `${hh}:${mm}`;
}

export interface ReminderStatusView {
  once: ChannelStatus;
  digest: ChannelStatus;
  calendar: ChannelStatus;
  digestMinute: number;
  digestTime: string;
  duplicateWarning: boolean;
}

export function reminderStatus(
  prefs: ReminderPrefs,
  auth: ReminderAuth,
  today: DayKey,
): ReminderStatusView {
  if (!validDigestMinute(prefs.digestMinute)) {
    throw new RangeError('Invalid digest minute');
  }
  return {
    once: channelStatus('once', prefs, auth, today),
    digest: channelStatus('digest', prefs, auth, today),
    calendar: channelStatus('calendar', prefs, auth, today),
    digestMinute: prefs.digestMinute,
    digestTime: digestTimeText(prefs.digestMinute),
    duplicateWarning: duplicateWarning(prefs),
  };
}