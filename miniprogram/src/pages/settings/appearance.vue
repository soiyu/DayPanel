<template>
  <view class="page" :class="themeClass">
    <view class="hero">
      <text class="title">{{ t('appearance') }}</text>
      <text class="hint">{{ t('appearanceNote') }}</text>
    </view>

    <view class="section">
      <text class="section-title">{{ t('themeMode') }}</text>
      <view class="options">
        <view
          v-for="option in modes"
          :key="option.value"
          class="option"
          :class="{ active: theme.settings.theme === option.value }"
          @tap="setTheme(option.value)"
        >
          {{ t(option.label) }}
        </view>
      </view>
    </view>

    <view class="section">
      <text class="section-title">{{ t('palette') }}</text>
      <view class="palettes">
        <view
          v-for="option in palettes"
          :key="option.value"
          class="palette"
          :class="{ active: theme.settings.palette === option.value }"
          @tap="setPalette(option.value)"
        >
          <view class="swatch" :style="{ background: option.color }" />
          <text class="palette-label">{{ t(option.label) }}</text>
        </view>
      </view>
    </view>

    <view class="section">
      <text class="section-title">{{ t('fontStyle') }}</text>
      <view class="options">
        <view
          v-for="option in fonts"
          :key="option.value"
          class="option"
          :class="{ active: theme.settings.font === option.value }"
          @tap="setFont(option.value)"
        >
          {{ t(option.label) }}
        </view>
      </view>
    </view>

    <view class="section">
      <text class="section-title">{{ t('iconFrame') }}</text>
      <view class="options">
        <view
          v-for="option in frames"
          :key="option.value"
          class="option"
          :class="{ active: theme.settings.iconFrame === option.value }"
          @tap="setFrame(option.value)"
        >
          {{ t(option.label) }}
        </view>
      </view>
    </view>

    <text class="footnote">{{ t('appearancePartial') }}</text>
  </view>
</template>

<script setup lang="ts">
import { useThemeStore } from '../../stores/theme.ts';
import { useThemeClass } from '../../composables/useTheme.ts';
import { translate } from '../../i18n/index.ts';
import type { Settings } from '../../domain/models.ts';

const theme = useThemeStore();
const themeClass = useThemeClass();
const t = (key: Parameters<typeof translate>[1]) => translate('zh', key);

const modes: Array<{ value: Settings['theme']; label: string }> = [
  { value: 'system', label: 'themeSystem' },
  { value: 'light', label: 'themeLight' },
  { value: 'dark', label: 'themeDark' },
];
const palettes: Array<{ value: Settings['palette']; label: string; color: string }> = [
  { value: 'blue', label: 'paletteBlue', color: '#2563eb' },
  { value: 'teal', label: 'paletteTeal', color: '#0d7e73' },
  { value: 'violet', label: 'paletteViolet', color: '#7c3aed' },
  { value: 'apricot', label: 'paletteApricot', color: '#a34d27' },
  { value: 'coast', label: 'paletteCoast', color: '#0b7187' },
];
const fonts: Array<{ value: Settings['font']; label: string }> = [
  { value: 'system', label: 'fontSystem' },
  { value: 'serif', label: 'fontSerif' },
];
const frames: Array<{ value: Settings['iconFrame']; label: string }> = [
  { value: 'soft', label: 'frameSoft' },
  { value: 'ring', label: 'frameRing' },
  { value: 'plain', label: 'framePlain' },
];

async function save(patch: Partial<Settings>): Promise<void> {
  const ok = await theme.update(patch);
  uni.showToast({
    title: ok ? t('appearanceSaved') : t('appearanceFailed'),
    icon: 'none',
  });
}

function setTheme(value: Settings['theme']): void {
  void save({ theme: value });
}
function setPalette(value: Settings['palette']): void {
  void save({ palette: value });
}
function setFont(value: Settings['font']): void {
  void save({ font: value });
}
function setFrame(value: Settings['iconFrame']): void {
  void save({ iconFrame: value });
}
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 32rpx 28rpx 80rpx;
  box-sizing: border-box;
  background: var(--dp-bg);
}
.hero {
  margin-bottom: 22rpx;
}
.title {
  display: block;
  font-size: 50rpx;
  font-weight: 800;
  color: var(--dp-ink);
}
.hint {
  display: block;
  margin-top: 8rpx;
  font-size: 23rpx;
  color: var(--dp-muted);
  line-height: 1.5;
}
.section {
  background: var(--dp-paper);
  border: 1rpx solid var(--dp-line);
  border-radius: 24rpx;
  padding: 22rpx;
  margin-bottom: 16rpx;
}
.section-title {
  display: block;
  font-size: 24rpx;
  color: var(--dp-muted);
  margin-bottom: 14rpx;
}
.options {
  display: flex;
  gap: 10rpx;
}
.option {
  flex: 1;
  text-align: center;
  border: 1rpx solid var(--dp-line);
  border-radius: 999rpx;
  padding: 14rpx 4rpx;
  font-size: 23rpx;
  color: var(--dp-ink-4);
}
.option.active {
  background: var(--dp-accent);
  border-color: var(--dp-accent);
  color: var(--dp-on-accent);
  font-weight: 700;
}
.palettes {
  display: flex;
  flex-wrap: wrap;
  gap: 14rpx;
}
.palette {
  width: calc(20% - 12rpx);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6rpx;
  padding: 8rpx 0;
  border-radius: 18rpx;
}
.palette.active {
  background: var(--dp-soft);
}
.swatch {
  width: 52rpx;
  height: 52rpx;
  border-radius: 50%;
}
.palette-label {
  font-size: 19rpx;
  color: var(--dp-muted);
  text-align: center;
}
.footnote {
  display: block;
  font-size: 22rpx;
  color: var(--dp-faint);
  line-height: 1.6;
  padding: 8rpx 4rpx;
}
</style>
