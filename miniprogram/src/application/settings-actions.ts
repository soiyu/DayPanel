import type { Settings, UserState } from '../domain/models.ts';
import { cloneState } from '../domain/models.ts';
import { ValidationError } from './habit-actions.ts';

export type SettingsPatch = Partial<Settings>;

const THEMES = ['system', 'light', 'dark'];
const LOCALES = ['system', 'zh', 'en'];
const PALETTES = ['blue', 'teal', 'violet', 'apricot', 'coast'];
const FONTS = ['system', 'serif'];
const FRAMES = ['soft', 'ring', 'plain'];

export function updateSettings(
  state: UserState,
  patch: SettingsPatch,
): UserState {
  const next = cloneState(state);
  const settings = { ...next.profile.settings };
  for (const [key, value] of Object.entries(patch)) {
    if (key === 'theme') {
      if (!THEMES.includes(String(value))) throw new ValidationError('invalid_theme');
      settings.theme = String(value) as Settings['theme'];
    } else if (key === 'locale') {
      if (!LOCALES.includes(String(value))) throw new ValidationError('invalid_locale');
      settings.locale = String(value) as Settings['locale'];
    } else if (key === 'palette') {
      if (!PALETTES.includes(String(value))) throw new ValidationError('invalid_palette');
      settings.palette = String(value) as Settings['palette'];
    } else if (key === 'font') {
      if (!FONTS.includes(String(value))) throw new ValidationError('invalid_font');
      settings.font = String(value) as Settings['font'];
    } else if (key === 'iconFrame') {
      if (!FRAMES.includes(String(value))) throw new ValidationError('invalid_frame');
      settings.iconFrame = String(value) as Settings['iconFrame'];
    } else if (key === 'completionSound') {
      if (typeof value !== 'boolean') throw new ValidationError('invalid_sound');
      settings.completionSound = value;
    } else if (key === 'completionHaptics') {
      if (typeof value !== 'boolean') throw new ValidationError('invalid_haptics');
      settings.completionHaptics = value;
    }
  }
  next.profile.settings = settings;
  return next;
}
