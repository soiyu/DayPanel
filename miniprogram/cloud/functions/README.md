# CloudBase functions

Build from the repository root:

```bash
cd miniprogram
npm run build:cloud
npm run prepare:wechat
```

Generated WeChat project: `dist/build/mp-weixin` (import into WeChat DevTools).
Cloud functions are copied to `dist/build/mp-weixin/cloudfunctions/` and
`project.config.json` points `cloudfunctionRoot` there.

## api

P1 actions: `today`, `tasks`, `notes`, `createHabit`, `recordHabit`,
`clearHabit`, `archiveHabit`, `deleteHabit`, `updateReminderPrefs`,
`createTask`, `completeTask`, `archiveTask`, `deleteTask`, `createNote`,
`updateNote`, `deleteNote`, `reminderStatus`, `createReminderJob`,
`deleteAccount`.

- Uses `cloud.getWXContext().OPENID`; never trusts a client openid.
- Collections: `dp_meta`, `dp_profile`, `dp_days`, `dp_tasks`, `dp_task_days`,
  `dp_notes`, `dp_jobs`.
- Writes profile/day/task/task-day/note rows and increments
  `dp_meta.revision` in a transaction.
- P1 currently loads the whole profile/day/task/note state inside one action;
  this is intentionally small-scale and must be split into page-level reads
  before larger datasets.
- Account deletion keeps a tombstone in `dp_meta` (`deleted: true`) and removes
  business collections in batches; retries are allowed when the tombstone
  exists.

The function requires the `wx-server-sdk` dependency from its own
`package.json`; the bundle externalizes it.

## reminder

Scheduled sender for `dp_jobs` with status `pending` and `sendAt <= now`:

- `config.json` declares a one-minute timer trigger.
- Calls `cloud.openapi.subscribeMessage.send`.
- Marks `sent`, `invalid` (43101/47003), or `failed`.
- One accepted authorization = one message; there is no long-term subscription
  for ordinary tool mini programs.

The template id and payload field mapping still need the real MP template; the
client reminder page therefore does not fake a send when the template is
missing.