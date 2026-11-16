import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  channelStatus,
  defaultReminderAuth,
  defaultReminderPrefs,
  digestTimeText,
  duplicateWarning,
  enabledChannelCount,
  reminderStatus,
  validDigestMinute,
} from '../src/application/reminder-policy.ts';

const TODAY = '2026-11-16';

test('reminder policy: three channels default on, 21:00 digest', () => {
  const prefs = defaultReminderPrefs();
  assert.equal(prefs.once, true);
  assert.equal(prefs.digest, true);
  assert.equal(prefs.calendar, true);
  assert.equal(prefs.digestMinute, 1260);
  assert.equal(enabledChannelCount(prefs), 3);
  assert.equal(duplicateWarning(prefs), true);
  assert.equal(digestTimeText(prefs.digestMinute), '21:00');
});

test('reminder policy: defaults are preferences, not authorizations', () => {
  const prefs = defaultReminderPrefs();
  const auth = defaultReminderAuth();
  const status = reminderStatus(prefs, auth, TODAY);
  assert.equal(status.once, 'needs_authorization');
  assert.equal(status.digest, 'needs_authorization');
  assert.equal(status.calendar, 'needs_authorization');
  assert.equal(status.digestTime, '21:00');
  assert.equal(status.duplicateWarning, true);
});

test('reminder policy: digest authorization is only valid for the same local day', () => {
  const prefs = defaultReminderPrefs();
  const auth = { ...defaultReminderAuth(), digestDay: TODAY };
  assert.equal(channelStatus('digest', prefs, auth, TODAY), 'active');
  assert.equal(channelStatus('digest', prefs, auth, '2026-11-17'), 'needs_authorization');
});

test('reminder policy: calendar and once statuses switch on their own grants', () => {
  const prefs = defaultReminderPrefs();
  const calendar = { ...defaultReminderAuth(), calendar: true };
  assert.equal(channelStatus('calendar', prefs, calendar, TODAY), 'active');
  assert.equal(channelStatus('once', prefs, calendar, TODAY), 'needs_authorization');

  const once = { ...defaultReminderAuth(), once: true };
  assert.equal(channelStatus('once', prefs, once, TODAY), 'active');
  assert.equal(channelStatus('calendar', prefs, once, TODAY), 'needs_authorization');
});

test('reminder policy: turning a channel off changes status but keeps defaults elsewhere', () => {
  const prefs = { ...defaultReminderPrefs(), calendar: false };
  assert.equal(channelStatus('calendar', prefs, defaultReminderAuth(), TODAY), 'off');
  assert.equal(duplicateWarning(prefs), true);
  assert.equal(duplicateWarning({ ...prefs, digest: false }), false);
});

test('reminder policy: digest minute bounds are validated', () => {
  assert.equal(validDigestMinute(0), true);
  assert.equal(validDigestMinute(1439), true);
  assert.equal(validDigestMinute(1440), false);
  assert.equal(validDigestMinute(21.5), false);
  assert.throws(() => digestTimeText(1440), /Invalid digest minute/);
});