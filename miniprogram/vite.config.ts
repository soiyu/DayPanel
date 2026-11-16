import { defineConfig } from 'vite';
import uniPlugin from '@dcloudio/vite-plugin-uni';

// The plugin is published as CommonJS; Vite's config loader may hand back the
// module namespace instead of the function. Normalize both shapes.
const uni = typeof uniPlugin === 'function'
  ? uniPlugin
  : (uniPlugin as unknown as { default: typeof uniPlugin }).default;

export default defineConfig({
  plugins: [uni()],
});