import { computed } from 'vue';
import { useThemeStore } from '../stores/theme.ts';

export function useThemeClass() {
  const store = useThemeStore();
  return computed(() => store.themeClass);
}
