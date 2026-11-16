export type Locale = 'zh' | 'en';

type Messages = Record<string, string>;

const zh: Messages = {
  appName: 'DayPanel',
  today: '日常',
  tasks: '小事',
  journal: '手记',
  mine: '我的',
  loading: '正在从云端加载…',
  loadFailed: '云端加载失败',
  retry: '重试',
  emptyHabits: '还没有习惯',
  emptyHabitsHelp: '先创建一个今天可以完成的小习惯。',
  addHabit: '新建习惯',
  newHabit: '新建习惯',
  title: '名称',
  kind: '记录方式',
  kindCheck: '完成一次',
  kindQuantity: '按数量',
  kindCount: '按次数',
  target: '目标',
  unit: '单位',
  save: '保存',
  cancel: '取消',
  saving: '保存中…',
  saved: '已保存',
  record: '记录',
  done: '已完成',
  todayProgress: '今日进度',
  quantityHint: '输入今天总量',
  invalidInput: '请输入有效数字',
  cloudRequired: '需要网络连接云端',
  deleteAccount: '注销账号',
  deleteAccountHelp: '删除该微信账号下的全部云端数据，不可恢复。',
  deleteAccountConfirm: '确认注销',
  deleteAccountWarning: '注销后不可恢复。系统日历中的副本需自行删除，已发送的订阅消息不可撤回。',
  deleteAccountFailed: '注销未完成，请重试',
  privacy: '隐私与数据',
  privacyTitle: '隐私与数据',
  privacyBody: '数据存储在微信云开发（腾讯云），开发者可通过云控制台访问，不是端到端加密。不提供整库导出/副本。',
  noTasksYet: '小事将在 P2 接入云端。',
  noNotesYet: '手记将在 P2 接入云端。',
  p2Pending: '此页尚未接入云端动作',
  reminderDefaults: '提醒默认全开',
};

const en: Messages = {
  appName: 'DayPanel',
  today: 'Today',
  tasks: 'Tasks',
  journal: 'Journal',
  mine: 'Mine',
  loading: 'Loading from cloud…',
  loadFailed: 'Cloud load failed',
  retry: 'Retry',
  emptyHabits: 'No habits yet',
  emptyHabitsHelp: 'Create a small habit you can complete today.',
  addHabit: 'New habit',
  newHabit: 'New habit',
  title: 'Title',
  kind: 'Recording mode',
  kindCheck: 'Check once',
  kindQuantity: 'Quantity',
  kindCount: 'Count',
  target: 'Target',
  unit: 'Unit',
  save: 'Save',
  cancel: 'Cancel',
  saving: 'Saving…',
  saved: 'Saved',
  record: 'Record',
  done: 'Done',
  todayProgress: 'Today',
  quantityHint: 'Total for today',
  invalidInput: 'Enter a valid number',
  cloudRequired: 'Network required to reach cloud',
  deleteAccount: 'Delete account',
  deleteAccountHelp: 'Delete all cloud data for this WeChat account. This cannot be undone.',
  deleteAccountConfirm: 'Delete account',
  deleteAccountWarning: 'This cannot be undone. Calendar copies must be removed manually; sent subscription messages cannot be recalled.',
  deleteAccountFailed: 'Deletion not completed; retry',
  privacy: 'Privacy & data',
  privacyTitle: 'Privacy & data',
  privacyBody: 'Data is stored in WeChat CloudBase (Tencent Cloud). The developer can access it through the console; it is not end-to-end encrypted. No whole-database export or copy is offered.',
  noTasksYet: 'Tasks will be connected in P2.',
  noNotesYet: 'Journal will be connected in P2.',
  p2Pending: 'This page is not connected to cloud actions yet',
  reminderDefaults: 'All three reminder channels default on',
};

const tables: Record<Locale, Messages> = { zh, en };

export function resolveLocale(setting: string | undefined): Locale {
  if (setting === 'en') return 'en';
  if (setting === 'zh') return 'zh';
  // `system` is intentionally conservative in P1; WeChat language detection
  // is added with the i18n pass. Chinese is the safe product default.
  return 'zh';
}

export function translate(
  locale: Locale,
  key: keyof typeof zh,
  params?: Record<string, string | number>,
): string {
  let value = tables[locale][key] ?? tables.zh[key] ?? String(key);
  for (const [name, replacement] of Object.entries(params ?? {})) {
    value = value.replaceAll(`{${name}}`, String(replacement));
  }
  return value;
}