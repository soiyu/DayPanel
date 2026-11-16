import { build } from 'esbuild';

await build({
  entryPoints: ['cloud/functions/api/index.ts'],
  bundle: true,
  platform: 'node',
  format: 'cjs',
  target: 'node18',
  outfile: 'cloud/functions/api/index.js',
  external: ['wx-server-sdk'],
  logLevel: 'info',
  legalComments: 'none',
});