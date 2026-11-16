import type { DayKey } from '../../domain/day.ts';

declare const wx: any;

export interface SubscriptionResult {
  accepted: boolean;
  reason?: string;
}

export class WechatSubscriptionAdapter {
  /**
   * Must be called from a user gesture. One accepted request grants exactly
   * one message for that template; "always allow" only skips the popup.
   */
  async request(templateId: string): Promise<SubscriptionResult> {
    try {
      const result = await wx.requestSubscribeMessage({ tmplIds: [templateId] });
      const accepted = result?.[templateId] === 'accept';
      return accepted
        ? { accepted: true }
        : { accepted: false, reason: result?.[templateId] ?? 'rejected' };
    } catch (error: any) {
      return { accepted: false, reason: error?.errMsg ?? 'subscribe_failed' };
    }
  }
}

export interface CalendarOnceEvent {
  title: string;
  startTime: number;
  endTime?: number;
  allDay?: boolean;
  alarm?: boolean;
  alarmOffset?: number;
  notes?: string;
  location?: string;
}

export interface CalendarRepeatEvent extends CalendarOnceEvent {
  repeatInterval?: 'day' | 'week' | 'month' | 'year';
  repeatEndTime?: number;
}

export class WechatCalendarAdapter {
  async hasPermission(): Promise<boolean> {
    try {
      const setting = await wx.getSetting();
      return setting?.authSetting?.['scope.addPhoneCalendar'] === true;
    } catch {
      return false;
    }
  }

  async authorize(): Promise<boolean> {
    try {
      await wx.authorize({ scope: 'scope.addPhoneCalendar' });
      return true;
    } catch {
      return false;
    }
  }

  async addOnce(event: CalendarOnceEvent): Promise<boolean> {
    try {
      await wx.addPhoneCalendar(event);
      return true;
    } catch {
      return false;
    }
  }

  async addRepeat(event: CalendarRepeatEvent): Promise<boolean> {
    try {
      await wx.addPhoneRepeatCalendar(event);
      return true;
    } catch {
      return false;
    }
  }
}

export type { DayKey };