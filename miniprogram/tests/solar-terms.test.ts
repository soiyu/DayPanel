import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  currentSolarTerm,
  nextSolarTerm,
  solarTermOn,
  solarTermsForYear,
} from '../src/domain/solar-terms.ts';

test('solar terms: 2026 dates and lookup', () => {
  assert.equal(solarTermsForYear(2026).length, 24);
  assert.equal(solarTermOn('2026-11-07')?.name, '立冬');
  assert.equal(solarTermOn('2026-11-08'), null);
  assert.equal(currentSolarTerm('2026-11-17')?.name, '立冬');
  assert.equal(nextSolarTerm('2026-11-17')?.name, '小雪');
  assert.equal(solarTermsForYear(2027).length, 0);
});
