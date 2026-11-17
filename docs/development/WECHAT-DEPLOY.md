# 微信小程序部署清单（P1 当前代码）

本文只列当前代码能部署的 P1 范围；没有 AppID/CloudBase 环境时不能完成部署，也不能用本地数据冒充云端。

## 前置资料

- 小程序 AppID（个人主体；类目含工具/效率）
- 微信云开发环境 ID
- 微信开发者工具（Windows/macOS；Linux 服务器不能替代）
- 订阅消息模板 ID + 字段映射（提醒摘要/一次性；未提供则提醒页会显示“模板未配置”）
- 真实手机（iOS/Android 微信各一台）

## 1. 替换占位

- `src/manifest.json`：`appid` 从 `touristappid` 改为真实 AppID。
- `src/config.ts`：`CLOUD_ENV` 填 CloudBase 环境 ID；`REMINDER_TEMPLATE_ID` 填模板 ID（字段映射仍需在提醒云函数/页面补齐，当前页面不伪造发送）。
- 不要提交真实 AppID/环境 ID/密钥/模板私密配置到公共仓库时，按团队规范放环境配置。

## 2. 创建集合

在 CloudBase 控制台创建：

```text
dp_meta
dp_profile
dp_days
dp_tasks
dp_task_days
dp_notes
dp_cards
dp_activity
dp_breaks
dp_events
dp_jobs
dp_backfills
dp_challenges
dp_step_days
```

建议索引：

```text
dp_days:        _openid, day
dp_tasks:       _openid
dp_task_days:   _openid, day
dp_notes:       _openid, day
dp_cards:       _openid, day
dp_jobs:        _openid, day, status, sendAt
dp_backfills:   _openid, habitId, day
dp_challenges:  _openid, status
dp_step_days:  _openid, day
dp_meta:        _openid
dp_profile:     _openid
```

## 3. 权限规则

客户端只读自己的文档，禁止客户端写；所有写走云函数。控制台规则语法以当前版本为准，示例：

```json
{
  "read": "doc._openid == auth.openid",
  "write": false
}
```

云函数使用管理员身份写入，并从 `cloud.getWXContext().OPENID` 取身份；不要信任客户端传入的 openid。

## 4. 部署云函数

构建：

```bash
cd miniprogram
npm run build:cloud
npm run prepare:wechat
```

用微信开发者工具导入 `dist/build/mp-weixin`；`cloudfunctionRoot` 已指向 `cloudfunctions/`。

- `cloudfunctions/api`：右键“上传并部署：云端安装依赖”。
- `cloudfunctions/reminder`：同样部署；在云函数控制台确认定时触发器 `send-due-reminders`（每分钟）已生效。
- `api` 的 `deleteAccount` 可能超过默认超时；在控制台把超时调到 60 秒并观察批处理结果。
- `reminder` 需要 `subscribeMessage.send` 权限；模板字段必须与 `payload` 一致，否则会返回 47003。

## 5. 真机验收路径

1. 新建布尔习惯 → 今日完成 → 强停/重开 → 换一台同微信设备，仍能看到。
2. 新建数量/次数习惯 → 输入总量 → 取消不写、保存才写。
3. 新建一次性小事 → 完成/撤销；新建常驻小事 → 今天完成，空白日不产生欠账。
4. 新建手记 → 改日期/正文 → 月份/搜索 → 删除；过未来日期被拒绝。
5. 我的 → 注销账号 → 输入“注销” → 云函数删除业务集合；重进为空；部分失败可重试。
6. 提醒中心：三通道默认全开；日历授权/拒绝；摘要模板未配置时只显示状态，不伪造发送。
7. 断网：显示云端错误；不能写入；不得出现本地假数据。
8. 微信运动：授权/拒绝；`cloudID` 换取步数；步数习惯只填入今天；不得伪造步数。
9. 挑战：21/100 天；休息日不计失败；放弃保留记录；无押金/排行榜。
10. `npm run verify`：typecheck、测试、构建、云函数打包、包体审计全部通过。

## 当前未完成（不要宣称已验收）

- 真实 CloudBase 部署/索引/权限/事务设备验证。
- 订阅消息模板字段、一次性/摘要任务 UI 的完整发送。
- 系统日历写入具体习惯事件的 UI（当前适配器已有，页面未接）。
- 统计/年历/时间线/成就卡/洞察/外观页面。
- 广告：v1 不接，`AdSlot` 默认关闭。
- 整库导出/客服副本：按决定不做；单条记录删除保留。