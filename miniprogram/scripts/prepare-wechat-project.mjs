import { cpSync, existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

const projectRoot = resolve('dist/build/mp-weixin');
const functionRoot = resolve('cloud/functions');
const target = resolve(projectRoot, 'cloudfunctions');

if (!existsSync(projectRoot)) {
  throw new Error('Build the mini program first (dist/build/mp-weixin missing)');
}

cpSync(functionRoot, target, {
  recursive: true,
  filter: (source) => !source.endsWith('.ts') && !source.includes('node_modules'),
});

const projectConfigPath = resolve(projectRoot, 'project.config.json');
const projectConfig = JSON.parse(readFileSync(projectConfigPath, 'utf8'));
projectConfig.cloudfunctionRoot = 'cloudfunctions/';
projectConfig.setting = {
  ...projectConfig.setting,
  urlCheck: false,
  es6: true,
  minified: true,
  postcss: true,
};
writeFileSync(projectConfigPath, `${JSON.stringify(projectConfig, null, 2)}\n`);
console.log('Prepared WeChat project:', projectConfigPath);
console.log('Cloud functions:', target);