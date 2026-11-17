import { test } from 'node:test';
import assert from 'node:assert/strict';
import { updateSettings } from '../src/application/settings-actions.ts';
import { emptyState } from '../src/domain/models.ts';

test('settings: theme, palette, font and frame persist through clone', () => {
  const state = updateSettings(emptyState(), {
    theme: 'dark',
    palette: 'coast',
    font: 'serif',
    iconFrame: 'ring',
    completionSound: true,
  });
  assert.equal(state.profile.settings.theme, 'dark');
  assert.equal(state.profile.settings.palette, 'coast');
  assert.equal(state.profile.settings.font, 'serif');
  assert.equal(state.profile.settings.iconFrame, 'ring');
  assert.equal(state.profile.settings.completionSound, true);
  // Original state is untouched.
  assert.equal(emptyState().profile.settings.theme, 'system');
});

test('settings: invalid enum and non-boolean values are rejected', () => {
  assert.throws(() => updateSettings(emptyState(), { theme: 'neon' as any }), /invalid_theme/);
  assert.throws(() => updateSettings(emptyState(), { palette: 'pink' as any }), /invalid_palette/);
  assert.throws(() => updateSettings(emptyState(), { completionHaptics: 'yes' as any }), /invalid_haptics/);
});
