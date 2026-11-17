import { computed, ref } from 'vue';
import { defineStore } from 'pinia';
import { defaultProfile, type Settings } from '../domain/models.ts';
import { WechatCloudGateway } from '../data/wechat-gateway.ts';

const ACCENTS: Record<string, { accent: string; soft: string; ink: string }> = {
  blue: { accent: '#2563eb', soft: '#eff6ff', ink: '#1d4ed8' },
  teal: { accent: '#0d7e73', soft: '#f0fdfa', ink: '#0f766e' },
  violet: { accent: '#7c3aed', soft: '#f5f3ff', ink: '#6d28d9' },
  apricot: { accent: '#a34d27', soft: '#fff7ed', ink: '#9a431d' },
  coast: { accent: '#0b7187', soft: '#e6f5f6', ink: '#086f83' },
};

export const useThemeStore = defineStore('theme', () => {
  const gateway = new WechatCloudGateway();
  const settings = ref<Settings>({ ...defaultProfile().settings });
  const revision = ref(0);
  const systemDark = ref(false);
  const loaded = ref(false);

  const dark = computed(
    () =>
      settings.value.theme === 'dark' ||
      (settings.value.theme === 'system' && systemDark.value),
  );
  const themeClass = computed(
    () =>
      `${dark.value ? 'theme-dark' : 'theme-light'} palette-${settings.value.palette} font-${settings.value.font} frame-${settings.value.iconFrame}`,
  );

  function readSystem(): void {
    try {
      const info = uni.getSystemInfoSync();
      systemDark.value = info?.theme === 'dark';
    } catch {
      systemDark.value = false;
    }
  }

  function applyNative(): void {
    const accent = ACCENTS[settings.value.palette] ?? ACCENTS.blue;
    try {
      uni.setNavigationBarColor({
        frontColor: dark.value ? '#ffffff' : '#000000',
        backgroundColor: dark.value ? '#0a0f1d' : '#f8fafc',
      });
      uni.setTabBarStyle({
        color: dark.value ? '#94a3b8' : '#64748b',
        selectedColor: accent.accent,
        backgroundColor: dark.value ? '#161f30' : '#ffffff',
        borderStyle: 'white',
      });
      uni.setBackgroundColor({
        backgroundColor: dark.value ? '#0a0f1d' : '#f8fafc',
      });
    } catch {
      // Native chrome is best-effort; the page-level CSS class still applies.
    }
  }

  async function load(): Promise<void> {
    readSystem();
    try {
      const result = await gateway.settings();
      settings.value = result.settings;
      revision.value = result.revision;
      loaded.value = true;
    } catch {
      loaded.value = false;
    }
    applyNative();
  }

  async function update(patch: Partial<Settings>): Promise<boolean> {
    try {
      await gateway.updateSettings(patch, revision.value);
      settings.value = { ...settings.value, ...patch };
      revision.value += 1;
      applyNative();
      return true;
    } catch {
      return false;
    }
  }

  if (typeof wx !== 'undefined' && typeof wx.onThemeChange === 'function') {
    wx.onThemeChange((event: any) => {
      systemDark.value = event?.theme === 'dark';
      applyNative();
    });
  }

  return { settings, revision, loaded, dark, themeClass, load, update, applyNative };
});
