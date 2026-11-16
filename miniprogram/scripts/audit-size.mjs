import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';

const root = resolve('dist/build/mp-weixin');
if (!existsSync(root)) {
  throw new Error('dist/build/mp-weixin missing; run build:mp-weixin first');
}

function directorySize(path, skip = new Set()) {
  let total = 0;
  for (const entry of readdirSync(path, { withFileTypes: true })) {
    if (skip.has(entry.name)) continue;
    const full = join(path, entry.name);
    if (entry.isDirectory()) total += directorySize(full, skip);
    else total += statSync(full).size;
  }
  return total;
}

const app = JSON.parse(readFileSync(join(root, 'app.json'), 'utf8'));
const subRoots = new Set((app.subPackages ?? []).map((item) => item.root));
const total = directorySize(root, new Set(['cloudfunctions']));
const main = directorySize(root, new Set(['cloudfunctions', ...subRoots]));
const mb = (bytes) => `${(bytes / 1024 / 1024).toFixed(2)} MB`;

console.log(`main package: ${mb(main)}`);
console.log(`total package: ${mb(total)}`);
console.log(`subpackages: ${[...subRoots].join(', ') || '(none)'}`);

const MAIN_LIMIT = 2 * 1024 * 1024;
const TOTAL_LIMIT = 20 * 1024 * 1024;
if (main > MAIN_LIMIT) throw new Error('main package exceeds 2 MB');
if (total > TOTAL_LIMIT) throw new Error('total package exceeds 20 MB');
console.log('package size: OK');