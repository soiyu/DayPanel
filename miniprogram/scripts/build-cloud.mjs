import { build } from 'esbuild';

const targets = [
  ['cloud/functions/api/index.ts', 'cloud/functions/api/index.js'],
  ['cloud/functions/reminder/index.ts', 'cloud/functions/reminder/index.js'],
];

for (const [entry, outfile] of targets) {
  await build({
    entryPoints: [entry],
    bundle: true,
    platform: 'node',
    format: 'cjs',
    target: 'node18',
    outfile,
    external: ['wx-server-sdk'],
    logLevel: 'info',
    legalComments: 'none',
  });
}