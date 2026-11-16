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

P1 actions: `today`, `createHabit`, `recordHabit`, `clearHabit`,
`archiveHabit`, `deleteHabit`, `updateReminderPrefs`, `deleteAccount`.

- Uses `cloud.getWXContext().OPENID`; never trusts a client openid.
- Collections: `dp_meta`, `dp_profile`, `dp_days`, plus empty placeholders for
  P2 collections.
- Writes profile/day rows and increments `dp_meta.revision` in a transaction.
- Account deletion keeps a tombstone in `dp_meta` (`deleted: true`) and removes
  business collections; retries are allowed when the tombstone exists.

The function requires the `wx-server-sdk` dependency from its own
`package.json`; the bundle externalizes it. Subscription reminder jobs and the
scheduled sender are P2, not implemented here yet.