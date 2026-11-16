# 微信小程序版（uni-app）设计总结

2026-11-16。分支 `feat/wechat-miniprogram`，基线 `main` 24292a4。本文是设计先行稿：只定义目标、边界、架构、数据契约、页面与分期，不代表已开始实现。

决策记录见 [ADR0017](../adr/0017-wechat-mini-program.md)。执行清单见 [WECHAT-BACKLOG](../development/WECHAT-BACKLOG.md)。

## 0. 一句话结论

**可行，但不是“把 Flutter 搬过去”**：用 uni-app 重做一套微信小程序客户端，复用领域规则和 schema12 备份契约；用微信虚拟支付、系统日历、聊天文件/分享、相册和震动替代 Google Play、AlarmManager、SAF、系统分享和 SoundPool。桌面组件、后台本地通知、Loop 数据库直接导入三项必须明确降级或放弃。

## 1. 目标与非目标

### 目标

- 微信小程序内完成 DayPanel 的免费核心闭环：习惯（布尔/数量/次数）、频率与历史计划、休息、小事/常驻、手记、成就卡、统计、回顾、外观、备份/恢复/CSV、提醒（系统日历）。
- 保留产品原则：本地优先、无广告、无分析、无强制账号、无习惯云同步；数据访问、导出和纠正不收费。
- Plus 能力按现有边界保留；支付改用微信生态，权益按微信身份恢复。
- Android 与小程序可互相导入 schema12 备份，形成可验证的换端路径。
- 视觉延续冷白、浅蓝、淡紫、暖橙、大圆角、轻盈层次；针对小程序导航、胶囊、键盘和安全区重新设计，不逐像素复制 Flutter。

### 非目标（v1）

- iOS 原生 App、Web、桌面端；uni-app 的多端能力不承诺同步交付。
- 习惯数据云同步、账号体系、多人协作、AI、广告、分析 SDK。
- Android 桌面组件的等价物；截至 2026-11-16 未发现微信小程序公开的可编程桌面组件 API，只有用户手动添加桌面快捷方式/浮窗。
- 后台本地通知、精确闹钟、通知“稍后 10 分钟”、通知点击直接写完成。
- 小程序端解析 Loop `.db`；Loop 迁移只经 Android 客户端中转。
- 与 Google Play 已购权益互通；两个商店是独立交易与独立权益。
- 24 MB Noto Serif SC 字体直接打包；v1 用系统字体，书页体作为可选在线子集。
- v1 以手机微信为主；iPad/PC 保证能打开，不做平板双栏/键鼠专属交互的验收承诺。

## 2. 为什么不能直接复用 Flutter

| 约束 | Flutter/Android | 微信小程序 |
|---|---|---|
| 渲染 | Flutter engine / CanvasKit | WebView 系 WXML/WXSS，无 Flutter Widget |
| 数据 | sqflite + SQLite v12 | 无 SQLite；本地文件/缓存/云数据库 |
| 后台 | Activity、Service、AlarmManager | 无后台常驻；切后台很快挂起 |
| 通知 | NotificationManager | 订阅消息（服务端下发，需授权）或系统日历 |
| 桌面 | RemoteViews/AppWidget | 无公开的可编程桌面组件 API；仅用户手动加桌面/浮窗 |
| 支付 | Google Play Billing | 小程序虚拟支付 |
| 文件 | SAF/ContentProvider | `wx.chooseMessageFile`/`wx.shareFileMessage`/用户目录 |
| 分享 | 系统分享 Intent | 微信转发、分享图片菜单、朋友圈 |
| 日历 | `ACTION_INSERT` | `wx.addPhoneCalendar`/`wx.addPhoneRepeatCalendar` |
| 身份 | 无账号；Play 购买 | `wx.login` → `openid`（仅支付/权益需要） |

结论：UI 和平台层必须重写；`lib/domain` 的规则可以逐条移植到纯 TypeScript；`lib/data` 的 SQLite 语义要改造成文档存储，但表形和备份 schema 保留。

## 3. 微信/Google 能力替换矩阵

状态标记：**等价** = 可完整替代；**受限** = 可用但交互/能力不同；**不可替代** = 必须降级或移除。

| 现有能力 | 微信生态替代 | 状态 | 设计与边界 |
|---|---|---|---|
| Google Play 分发/更新 | 微信小程序平台发布、审核、分阶段发布 | 等价 | 需主体、备案、类目、隐私指引；更新由微信审核后生效 |
| Google Play 一次性买断 | 小程序虚拟支付（`short_series_goods` 道具直购）+ 服务端权益 | 受限 | 虚拟商品必须走小程序虚拟支付，不能外跳普通微信支付/H5/App；iOS 需 Apple 小程序合作伙伴计划（公开报道 15% 分成），开通情况以 MP 后台为准 |
| Play 购买恢复 | `wx.login` 取 `openid`，服务端按 openid 恢复权益 | 受限 | 只恢复微信账号内权益；不跨 Google Play；清除小程序缓存不丢权益，但需联网刷新 |
| Android 桌面组件（单事项/组合） | 应用内“今日组合面板”+ 手动桌面快捷方式/浮窗 | 不可替代 | 没有公开的可编程桌面组件 API；组合面板仍是 Plus，但只能打开小程序操作，不能从桌面直接写完成 |
| 桌面直接完成/数量弹窗 | 无 | 不可替代 | 不伪造“桌面打卡”；所有写入在小程序前台完成 |
| AlarmManager 本地提醒 | 系统日历事件 + 闹钟 | 受限 | `wx.addPhoneCalendar`/`addPhoneRepeatCalendar` 需用户授权 `scope.addPhoneCalendar`；每次写入由系统日历确认；不保证厂商日历提醒；无 API 删除/更新已写事件，不能当双向同步 |
| 1–5 个提醒时刻 | 每个时刻写一个日历事件 | 受限 | 修改提醒=重新写入新副本，旧副本需用户到系统日历删除；界面要明确“副本”语义 |
| 通知“去记录/稍后 10 分钟” | 无 | 不可替代 | 系统日历通知不回调小程序；不实现稍后 |
| 订阅消息（可选） | 一次性订阅消息 + 云函数定时发送 | 受限 | 长期订阅只对政务/医疗/交通/金融/教育等少量类目开放，习惯工具不在内；一次性授权一条对应一条，无法替代每日多时刻提醒；不进入 v1 默认 |
| 系统日历 `ACTION_INSERT` | `wx.addPhoneCalendar`/`addPhoneRepeatCalendar` | 等价偏受限 | 固定每天/每周可重复；每 N 天、弹性周目标只能写单次或按用户选择的具体日期写，不捏造每日义务 |
| SAF 导出/导入 | 用户目录写文件 + `wx.shareFileMessage`；`wx.chooseMessageFile` 导入 | 等价偏受限 | 本地用户文件与缓存合计上限 200 MB（以当前文档为准）；导入从聊天文件选择；备份大小仍按 8 MiB 上限 |
| CSV 导出 | 生成 CSV 文件 → 分享到聊天/文件传输助手 | 等价 | 保留真实字段、类型、单位，不合并不同单位 |
| 系统分享 PNG/卡片 | `wx.showShareImageMenu`、`onShareAppMessage`、`saveImageToPhotosAlbum` | 受限 | 分享目标是微信好友/朋友圈/收藏/下载，不是任意系统 App；相册保存要 `scope.writePhotosAlbum` 授权 |
| SoundPool 完成音效 | `InnerAudioContext` 播放本地短音频 | 受限 | 尊重静音/音量；无法完全读取系统勿扰状态；默认关闭 |
| 触感反馈 | `wx.vibrateShort({type})` | 受限 | 系统/机型可能忽略；默认关闭；失败不撤回记录 |
| SQLite v12 | JSON 文档存储（表形同 schema12） | 受限 | 无 SQL/触发器；用应用层校验、generation/revision、原子文件写和恢复副本维持一致性 |
| Loop `.db` 导入 | Android 客户端先导入 Loop，再导出 schema12 JSON | 不可替代 | 小程序端不解析 SQLite；不承诺 Loop 直导 |
| 24 MB Noto Serif SC | v1 系统字体；可选 CDN 子集 + `wx.loadFontFace` | 受限 | 主包 2 MB/总包 20 MB，24 MB 字体不可打包；字体需下载域名白名单和许可；v1 不做 |
| Android 深链/通知打开 | 小程序码/场景值/页面 query；订阅消息可带页面路径 | 受限 | 系统日历事件不能打开小程序；无通知回调 |
| 系统主题/语言 | `darkmode`/`theme.json` + `wx.onThemeChange`；自定义 i18n | 等价偏受限 | 小程序无 Flutter `MaterialLocalizations`；日期/星期/文案自己维护中英 |
| 系统字体缩放 | 微信字体设置 + 应用内大字号档 | 受限 | 需 320 px/1.6 倍人工矩阵；不能假设所有机型自动缩放 |
| Google Play 隐私/Data Safety | 小程序隐私保护指引 + 备案 + API 声明 | 等价偏受限 | 需逐项声明相册、文件、日历、支付、震动等；无广告/分析仍保持 |

> 平台规则会变化。表中“微信文档”以 2026-11-16 查阅为准，发布前必须按当时 MP 后台和审核口径复核；尤其是虚拟支付、iOS 分成、日历权限和订阅消息类目。

## 4. 总体架构

### 4.1 仓库形态

保持 Flutter 工程不动，在根目录新增独立小程序工程：

```text
DayPanel/
├── lib/                         # 现有 Flutter，保持
├── android/                     # 现有 Android，保持
├── miniprogram/                 # 新增 uni-app 微信小程序
│   ├── package.json
│   ├── vite.config.ts
│   ├── tsconfig.json
│   ├── src/
│   │   ├── main.ts
│   │   ├── App.vue
│   │   ├── pages.json           # 4 个 tab + 分包
│   │   ├── manifest.json        # 微信 AppID/权限声明
│   │   ├── uni.scss
│   │   ├── pages/               # 主包：today/tasks/journal/mine
│   │   ├── packages/            # 分包：habit/task/journal 详情、统计、卡片、设置
│   │   ├── components/          # 通用视觉组件
│   │   ├── domain/              # 纯 TS 领域规则，零 wx 依赖
│   │   ├── data/                # 文档存储、备份、CSV、迁移、校验
│   │   ├── stores/              # Pinia 应用状态/动作
│   │   ├── platform/            # 微信适配器 + 测试 mock
│   │   ├── i18n/                # zh/en 文案与日期格式
│   │   ├── styles/              # 主题 tokens/暗色/字体比例
│   │   └── static/              # 图标、卡片资源、短音效
│   ├── tests/                   # Vitest：domain/data/store/组件
│   ├── scripts/                 # 包体审计、ARB 同步检查
│   └── cloud/                   # 可选：CloudBase 权益/订阅函数，不存习惯数据
└── docs/                        # 本文、ADR、台账
```

### 4.2 分层与依赖规则

```text
presentation (pages/components)
        ↓
application (Pinia stores/actions)
        ↓
domain (pure rules)        data (document store/backup)
        ↓                         ↓
platform ports (interfaces) ← wechat adapters / mocks
```

- `domain/` 不 import `wx`、Vue、Pinia；可在 Node/Vitest 直接跑。
- `data/` 只依赖 domain + platform 的 `FileSystem`/`Hash`/`Clock`/`Id` 端口。
- `stores/` 负责“读快照 → 校验 generation → 执行领域操作 → 持久化 → 重新载入 → 通知页面”。
- `pages/` 不直接读写文件；只调用 store action。
- `platform/wechat/` 是唯一允许出现 `wx.*` 的地方；测试用 `platform/mock/`。
- 页面通过 `onShow` 刷新日期/存储状态；不依赖后台定时器。

### 4.3 技术选型

| 项 | 选择 | 理由 |
|---|---|---|
| 框架 | uni-app Vue 3 + Vite + TypeScript | 用户指定；CLI 构建，避免 HBuilderX 依赖 |
| 状态 | Pinia | 小、类型友好、与 Vue 3 一致 |
| 路由 | uni-app `pages.json` + 分包 | 控制主包 2 MB；tab 页留主包 |
| 样式 | SCSS + CSS 变量/主题 class | 延续 Flutter 的调色板与明暗模式 |
| 组件 | 自研轻组件，不引入重 UI 库 | 控制包体、视觉一致、无障碍可控 |
| 测试 | Vitest + `@vue/test-utils`（按需） | Node 端可跑；不依赖微信 IDE |
| 构建 | `uni build -p mp-weixin` | 生成微信小程序 dist；CI 可审计包体 |
| 日期 | 自研 `Day`/格式化，不引入 moment/dayjs | 日期是本地日历日，避免时区/体积问题 |
| 哈希 | 自研小体积 SHA-256 或原生文件摘要 | 备份校验；优先纯 TS 可测 |
| 可选云 | 微信云开发（CloudBase） | `openid`、虚拟支付签名、一次性订阅；不存习惯内容 |

最低基础库按 **2.16.1** 设计（`wx.shareFileMessage` 的最低版本）；日历、分享图片、文件分享、支付分别用 `wx.canIUse` 能力检测。低版本微信禁用对应入口并提示升级，不把“按钮存在”当成能力可用。

## 5. 数据与存储设计

### 5.1 表形契约

小程序内存状态直接采用备份 schema12 的表形，字段名保持 snake_case：

```text
habit_groups, habits, plans, entries, tasks, task_entries, notes,
settings, reminders, cards, habit_activity, habit_breaks, record_events
```

外加仅本机的 `runtime`（generation/revision）和 `recovery`（恢复前快照）。`item_revisions` 不进入业务备份，由应用层维护。

这样做的收益：

- 备份编码/解码与 Android 完全同构，跨端迁移不需要第三套模型。
- 领域模型可以从行对象构造，测试夹具与 Flutter 一致。
- 恢复校验可以复用现有规则（字段集合、枚举、日期、数量、外键、重复 ID、计划完整性）。

### 5.2 本地文件布局

```text
${wx.env.USER_DATA_PATH}/daypanel/
├── state.0.json          # 双槽之一
├── state.1.json          # 双槽之一
├── state.manifest.json   # {slot, seq, checksum, savedAt}
├── recovery.json         # 最近一次恢复前备份（可选回退）
└── exports/              # 用户触发的临时导出文件
```

- 业务状态只写本地文件，不写 `wx.setStorage`（10 MB 限制且非事务）。
- 文件读写使用异步 API；8 MiB 级别的序列化/校验/导入期间显示 busy，禁止重复操作，避免长时间阻塞 UI。
- `wx.setStorage` 只存 UI 偏好：首次引导、字体档、最近导出提示、上次打开页等，不进备份。
- 本地用户文件与缓存合计上限按 200 MB 设计（当前微信文档口径）；双槽 + 恢复副本仍远低于上限。
- 单份业务状态和备份都遵守 8 MiB 上限；超过时阻止写入并引导导出/清理，不能静默截断。

### 5.3 原子写协议

每次写操作：

1. 复制当前表快照，执行领域变更和校验（唯一键、外键、枚举、日期、数量、计划版本）。
2. 递增 `runtime.revision`；恢复时递增 `generation`；维护对象修订号。
3. 序列化 payload（表 + runtime），计算 SHA-256，写入**非活动槽**的临时文件。
4. 回读校验 JSON/checksum/大小。
5. 原子更新 `state.manifest.json` 指向新槽和 seq。
6. 校验通过后才替换内存状态；失败保留旧状态并返回错误。

启动时：

1. 读 manifest，校验活动槽；失败则尝试另一槽。
2. 两槽都坏时，提示“存储损坏”，提供从备份恢复，不自动造假数据。
3. 校验 schema/字段/外键；恢复 `recovery.json` 仅在用户明确选择时使用。

这样不存在“写到一半数据库坏了”的 SQLite 事务，但用双槽 + manifest 达到同等的崩溃一致性；代价是每次写要序列化整份状态。按 DayPanel 的数据量（8 MiB 上限）和每日操作频率，先采用全量快照；若实测大库写入超过约 150 ms，再增加 append-only 事件日志优化，不提前复杂化。

### 5.4 并发与陈旧页面

- 所有写入走 store 的单写队列；`busy` 期间拒绝重复提交，和 Flutter 的 `AppController.run` 一致。
- 每个页面打开时记录 `generation` 和对象 `revision`；保存前核对，恢复/删除后旧页面拒绝写入并提示刷新。
- 没有 SQL 触发器，`item_revisions` 在应用层 `touch(kind,id)`；`runtime.revision` 在每次变更后递增。
- 单 JS 线程不等于无竞态：异步文件写、页面返回、两次点击仍会交错，必须显式串行化。

### 5.5 备份、恢复与迁移

- 备份格式保持 `daypanel-backup` v1 / schema12：外层 `format/version/sha256/payload`，payload 含 `schema/created_at/tables`。
- 导出：生成文件 → `wx.shareFileMessage` 发到聊天/文件传输助手；同时保留在 `exports/`，显示“最近导出时间”。
- 导入：`wx.chooseMessageFile` 选择 JSON → 预览真实表计数和时间 → 二次确认 → 先写 `recovery.json` → 替换 → `generation+1`。
- 失败回滚：校验/写入失败不改变当前状态；成功后可用“回到恢复前副本”撤销一次。
- Android → 小程序：Android 导出 schema12 JSON，发到微信文件传输助手，小程序导入。
- 小程序 → Android：小程序导出 schema12 JSON，Android 恢复；必须用真实 Android 构建做双向夹具测试。
- Loop `.db`：不在小程序端支持；Android 先导入 Loop，再导出 JSON。
- 设备本地状态（提醒副本、桌面绑定、UI 偏好）不进入备份；恢复后提示重新写日历。

### 5.6 领域规则移植清单

| Dart 模块 | TS 模块 | 关键不变量 |
|---|---|---|
| `models.dart` | `domain/models.ts` | 本地日历日、`YYYY-MM-DD`、数量千分位、三种习惯类型 |
| `appearance.dart` | `domain/appearance.ts` | 5 套调色板、3 种边框、28 图标、字体枚举 |
| `habit_break.dart` | `domain/habit-break.ts` | 暂停/休假/跳过；休息不算完成/失败 |
| `activity.dart` | `domain/activity.ts` | 归档履历；未知历史不算失败 |
| `journal.dart` | `domain/journal.ts` | 月份/单日/习惯/正文交集；大小写不敏感子串 |
| `achievement.dart` | `domain/achievement.ts` | 每天最多一张；快照保留；撤销/改计划不抹卡 |
| `statistics.dart` | `domain/statistics.ts` | 截至昨天分母、历史计划、单位隔离、完整周 |
| `insights.dart` | `domain/insights.ts` | 30/90/365 天、环比、星期、连续、周目标、共现 |
| `record_event.dart` | `domain/record-event.ts` | 逐次明细、baseline、revision、删除标记 |
| `backup.dart` | `domain/backup.ts` | schema2–12 严格读取、8 MiB、SHA-256、畸形拒绝 |
| `csv_export.dart` | `domain/csv-export.ts` | 真实字段/类型/单位，零值与缺值区分 |
| `legacy_import.dart` | 不移植 | 由 Android 完成 Loop 导入 |
| `reminder.dart` | `domain/reminder.ts` | 1–5 个时刻、去重、0–1439 分钟 |

## 6. 功能范围与分期

### 6.1 P0 设计（本轮）

- 分支、ADR、设计、执行清单。
- 能力矩阵、风险、待确认项。
- 不写业务代码，不装依赖，不跑重构建。

### 6.2 P1 基座与首个纵切

- uni-app CLI 工程、TS 严格模式、Vitest、包体审计脚本。
- 主题 tokens、四 tab 壳、通用组件、i18n 框架（zh/en）。
- `Day`/数量/频率/计划领域；本地双槽存储；备份 codec。
- **真实纵切**：首次启动空态 → 新建布尔习惯 → 今天完成 → 杀进程重开仍存在 → 导出/导入 JSON 往返。
- 验收：typecheck、Vitest、`uni build` 主包 ≤2 MB、状态文件重开一致、无假数据。

### 6.3 P2 免费核心对齐

- 习惯：三种记录、创建/编辑/归档/删除、频率（每日/星期/每 N 天/周 N 个达标日/周累计）、历史计划、休息、分组/情境/排序、历史纠正。
- 小事：一次性/常驻、完成日与计划日、历史、归档、删除、按日常驻记录。
- 手记：关联习惯、日期、月份/单日/习惯/正文筛选、归档保留、删除解除关联。
- 卡片：每日一张、六款原创卡面、收藏、卡背心得、隐私默认、分享/保存 PNG。
- 统计：周打卡表、单习惯完成率/连续、数量趋势、年历、时间线、单日历史。
- 回顾：七日真实计数、空态、语言/主题。
- 外观：5 调色板（2 个 Plus 锁定）、3 主题、3 边框、28 图标、系统/浅/深。
- 反馈：声音/触感默认关闭，失败不撤回保存。
- 备份：导出/导入/预览/恢复前副本/回滚；CSV；最近导出提示。
- 提醒：配置 1–5 个时刻；明确“写入系统日历副本”，处理授权拒绝、无日历处理器、旧副本不自动删除。
- 验收：中英、明暗、320 px/1.6 倍、键盘、空态、失败重试；真实文件往返。

### 6.4 P3 微信生态与 Plus

- 虚拟支付：商品配置、服务端下单/签名/回调/查询、openid 权益、恢复、待支付/取消/失败/退款状态；debug 仅测试权益，release 不伪造。
- Plus：组合面板、逐次明细/纠错、自然周累计、复盘长图、深度洞察、额外装扮。
- 组合面板：选择 1–4 个真实对象、排序、尺寸适配（应用内）；不做桌面直接操作。
- 复盘海报：Canvas 2D 绘制，默认隐藏名称/心得；`showShareImageMenu`/相册保存。
- 日历：固定星期/每日可重复；间隔/弹性周目标按 API 能力写单次；不声称自动同步。
- 可选：一次性订阅消息（仅当用户明确接受“每条都授权”并接受最小云函数时）。
- 验收：支付沙箱、权益恢复、换微信账号、断网、退款/客服文案；海报像素级检查；日历真机授权/拒绝/厂商差异。

### 6.5 P4 硬化与发布

- 无障碍、性能、包体、低端 Android、弱网、缓存清理、数据损坏恢复。
- 隐私保护指引、API 声明、备案、类目、虚拟支付资质、客服/退款。
- 微信开发者工具预览/真机/体验版/审核；Android/iOS 微信各至少一台。
- 发布说明明确：无桌面组件、无后台本地通知、Loop 需 Android 中转、Plus 权益不跨商店。

## 7. 页面与交互设计

### 7.1 页面地图

主包（tabBar 四页，必须首屏可用）：

| 路由 | 内容 |
|---|---|
| `pages/today/index` | 日期条、每日/周目标/休息/计划外记录、完成进度、成就卡、洞察入口 |
| `pages/tasks/index` | 一次性待办、常驻区、完成历史入口 |
| `pages/journal/index` | 月份/筛选/搜索、手记列表、写手记 |
| `pages/mine/index` | 习惯管理、外观、提醒、数据、组合面板、Plus、卡片、统计、洞察、复盘、语言、隐私 |

分包（按需加载）：

| 分包 | 页面 |
|---|---|
| `packages/habit` | 习惯详情、创建/编辑、管理/排序、休息、日志、单习惯统计、计划历史 |
| `packages/task` | 小事详情、完成历史、日期纠正 |
| `packages/journal` | 手记编辑、日期选择、关联选择 |
| `packages/review` | 统计、年历、时间线、单日历史、卡片册/详情/指南、周月复盘 |
| `packages/settings` | 外观、提醒、反馈、备份/恢复、导入预览、组合面板、Plus、隐私/支持 |
| `packages/onboarding` | 首次引导/空态帮助/快捷方式说明 |

tabBar 用原生 tabBar（4 项、主题色、图标）；子页用原生导航栏，标题由 `pages.json`/`wx.setNavigationBarTitle` 设置。原生导航栏避开右上胶囊，减少自定义导航在刘海/PC 上的适配风险；视觉重点放在卡片、色调和留白。

### 7.2 关键交互

- **日期**：顶部 7 天横条 + 日期选择器；`Day` 只做本地日历日；未来/开始日前禁止写入；历史纠正显式提示。
- **习惯卡**：图标 + 标题 + 真实值/目标 + 主操作（布尔一键；数量/次数打开输入确认）；长名称省略但 `aria-label` 保留全称。
- **数量输入**：`input type="digit"`，千分位解析；显示“本次量/当天总量”选择；保存前不写；取消不写；重复提交由 busy 拦截。
- **频率**：每日/指定星期/每 N 天/每周 N 个达标日/周累计；编辑从明天生效；历史显示对应版本。
- **底部面板**：自定义 `AppSheet`（overlay + 安全区 + 键盘避让），不依赖第三方 UI 库；删除用 `wx.showModal` 二次确认。
- **列表**：页面级滚动；手记/时间线分页加载（20–50 条/页）；365 格热力图用 flex 行列而非 CSS Grid，避免基础库差异。
- **分享**：页面实现 `onShareAppMessage`；卡片/海报用 `wx.showShareImageMenu`；保存相册走授权；分享文案默认脱敏。
- **提醒**：习惯详情/提醒中心配置时刻；保存后展示“写入手机日历”按钮；授权拒绝时保留配置但不排程；旧副本需用户自行删除；不显示“已准时提醒”的假状态。
- **Plus**：锁定态直接跳 Plus 页；购买/恢复/待支付/取消/失败/退款分别有文案；权益未确认时数据仍可查看/导出/纠正。
- **空态**：按原因区分“没有习惯/今天无安排/筛选无结果/休息/无记录”；提供真实下一步，不放演示数据。

### 7.3 小程序 UI 约束

- 页面栈最多 10 层；详情页尽量 `navigateTo` 一层，统计/设置用 `redirectTo` 或返回，避免深栈。
- `tabBar` 页面不能用 query 传参；跨页状态用 Pinia；`switchTab` 前清理临时编辑状态。
- 键盘：表单底部按钮用 `adjust-position`/`cursor-spacing`；保存区不被键盘遮挡；底部面板高度不超过可视区。
- 安全区：`env(safe-area-inset-bottom)`；原生 tabBar 已处理，悬浮按钮再留白。
- 暗色：`darkmode: true` + `theme.json` 管原生导航/tabBar；页面用主题 class；监听 `wx.onThemeChange` 更新系统模式。
- 字号：`rpx` 布局 + `fontScale` class；读取/尊重微信字体设置；提供“标准/大”两档；测试 320 px 与 1.6 倍。
- 动效：默认轻量；尊重减少动画设置；不做长时背景动画。
- 无障碍：`aria-role`/`aria-label`/`aria-checked`；状态不只靠颜色；热力图/图表提供文字摘要；点击区 ≥48 px。

### 7.4 视觉延续

- 冷白底 `#F8FAFC`、纸白卡 `#FFFFFF`、主蓝 `#2563EB`、紫 `#6D28D9`、暖橙 `#C2410C`、青 `#047857`；深色底按调色板变化，正文 `#F1F5F9`、次要 `#94A3B8`。
- 24 px 大圆角、细边 `#E2E8F0`、轻阴影、浮动卡片层次；主操作只留一处强强调。
- 五种调色板与 28 个原创习惯图标沿用；Noto Serif SC 不打包，v1 用系统衬线/无衬线切换的降级方案。
- 六款成就卡面用 Canvas 2D/预生成 PNG 重绘，保持原创构图；不复用第三方插画。

## 8. 关键功能设计

### 8.1 Plus 支付与权益

- 商品：一个非消耗型“Plus 终身解锁”，对应 Android 的 6 项高级能力；不设订阅、不设抽卡。
- 客户端：`wx.login` 取 code → 云函数换 `openid`；创建订单拿 `signData`/`paySig` → `wx.requestVirtualPayment`；成功后查权益；启动/前台恢复时刷新。
- 服务端：只保存 `openid`、商品、订单号、金额、状态、时间；不保存习惯、手记、成就卡内容。回调/查询必须幂等，防重复发货；退款/撤销要能降级但保留用户数据访问。
- 签名：按微信虚拟支付文档使用 `paySig = HMAC-SHA256(appKey, uri + '&' + signData)` 等；密钥只放服务端，绝不进小程序包。
- iOS：若 AppID 未开通 iOS 虚拟支付/Apple 小程序合作伙伴计划，iOS 隐藏购买入口并说明“暂不可用”，不能引导外部支付；Android 与 iOS 价格可因分成不同而不同，但商品文案要一致。
- 无服务端/无资质时：只发免费核心版；debug 构建可用测试权益做完整验收，release 不得静默解锁。
- 恢复购买：同一微信 `openid` 自动恢复；换微信号/换主体不保证；不承诺与 Google Play 权益互通。

### 8.2 系统日历提醒

- 输入：习惯、1–5 个本地时刻、当前计划（星期/间隔/周目标）、标题/描述（默认不含隐私内容）。
- 映射：
  - 固定每天：`addPhoneRepeatCalendar`，每天重复，`alarm: true`，`alarmOffset` 按用户选择。
  - 固定星期：对每个选中星期写一个每周重复事件，最多 7 个。
  - 每 N 天：写下一次单次事件；不伪造系统不支持的 RRULE；界面说明“仅下一次，需重新写入”。
  - 周目标/弹性目标：写用户明确选择的单次安排，不生成每日义务。
- 授权：`scope.addPhoneCalendar`；拒绝时保留配置，显示“未授权，未写入日历”，提供设置入口；不反复弹窗骚扰。
- 时间：应用只保存本地时刻分钟；写入系统日历使用本地时间戳，跨时区/夏令时由系统日历解释；不自行换算历史时区。
- 编辑/删除：无稳定事件 ID，不能程序化更新/删除；文案明确“独立副本”；提供“重新写入”并提示到系统日历删除旧事件。
- 无日历应用/厂商不支持：捕获失败并给出可理解提示；不把失败算作提醒已生效。
- 与 Plus 日历关系：现有 Plus 的“加入日历”在 Android 是 Plus；小程序端把日历作为基础提醒替代，产品文案需确认是否仍作为 Plus 权益，避免同一能力两套收费口径。

### 8.3 备份、恢复与文件

- 导出文件命名 `daypanel-backup-YYYYMMDD-HHmm.json`；CSV `daypanel-export-YYYYMMDD-HHmm.csv`；海报 `daypanel-card-YYYYMMDD.png`。
- 分享前检查文件大小和内容；用户取消分享不等于导出失败，文件仍保留在 `exports/`，显示最近导出时间。
- 导入先预览：备份时间、schema、各表条数、是否覆盖；确认后才替换；失败不改变当前数据。
- 恢复前副本只保留最近一次；回退成功后清除，避免无限占用。
- 隐私：备份/CSV 是明文，分享到聊天即离开应用沙箱；界面明确提示，不自动上传、不自动发送。
- 缓存清理/删除小程序会清空本地数据；首次引导和“我的”页提示定期导出；不承诺云恢复。

### 8.4 卡片、海报与分享

- 卡片：六款 Canvas 2D/预生成 PNG 卡面按日期轮换；正面显示真实完成快照，背面心得；收藏筛选；默认隐藏习惯名称/心得，分享前可编辑 280 字摘录。
- 海报：周/月可选模块（完成率、习惯、手记、事件），不同单位分开；Canvas 2D 按 devicePixelRatio 绘制，导出 PNG；大列表先聚合，避免一次性画太多文本。
- 分享：`wx.showShareImageMenu` 可发好友/朋友圈/收藏/下载；`saveImageToPhotosAlbum` 需授权；`onShareAppMessage` 用于页面转发；不自动发群、不诱导分享。
- 失败：画布/相册/分享失败分别提示；不把取消当成功。

### 8.5 统计与洞察

- 移植 `statistics.dart`/`insights.dart` 的纯计算；页面只做展示。
- 分母、休息、归档、未知历史、单位隔离、完整周等规则不变；没有数据不编造图表。
- 热力图：365 天 × 习惯/全局；用 flex 行（7 行 × 53 列）或 Canvas；每格有 `aria-label` 与文字摘要。
- 年历/时间线分页；数量趋势按历史单位分组；不同单位不相加。
- 深度洞察 Plus 锁定；锁定态只展示能力说明，不泄露/伪造数据。

### 8.6 外观与字体

- 5 调色板：blue/teal/violet/apricot/coast；apricot/coast 为 Plus。
- 3 主题模式：system/light/dark；3 边框：soft/ring/plain；28 图标；习惯单独配色。
- 字体：v1 系统字体；`serif` 选项降级为系统衬线（iOS 宋体/Android Noto Serif 可用性不一）或在后续用 CDN 子集 + `wx.loadFontFace`；不把 24 MB TTF 打进包。
- 外观预览/取消不写入；恢复后旧页面用 generation 保护。

## 9. 非功能设计

### 9.1 包体与性能

- 主包目标 ≤1.6 MB，硬上限 2 MB；总包目标 ≤8 MB，硬上限 20 MB（按当前微信文档，发布前复核）。
- 图标压缩/按需 2x；字体不进包；统计/设置/卡片/复盘进分包；主包只留四 tab 和核心组件。
- 不在主包引入大型图表库/UI 库/日期库；Canvas 自绘。
- 冷启动：先渲染壳，再异步加载状态；状态 ≤8 MB 时目标 <1.5 s（中端机实测）。
- 列表分页；避免一次渲染上千节点；长文搜索在内存索引或分批扫描。
- 构建/测试在 2C4G 服务器上串行执行；`NODE_OPTIONS=--max-old-space-size=1536`，不跑微信 IDE/模拟器/全量 Flutter 测试。

### 9.2 隐私与安全

- 习惯/手记/卡片数据只在本机文件；不上传、不分析、不广告。
- 仅以下数据可能离开设备：用户主动分享的文件/图片、系统日历副本、虚拟支付订单/openid、可选订阅的 openid/时间。
- 不读取通讯录/位置/麦克风/相机；不申请无关权限。
- 备份明文；导入严格校验，拒绝畸形/超大/未知 schema；不执行备份中的任何代码/路径。
- 用户文本用 WXML 文本节点渲染，不用 `rich-text` 注入；搜索不做正则注入。
- 支付密钥只在服务端；客户端不存 appKey/私钥；订单校验幂等。
- 隐私指引逐项声明 API：日历、相册、文件选择/分享、支付、震动、剪贴板（如使用）。

### 9.3 国际化与日期

- 端口 `app_en.arb`/`app_zh.arb`（约 734 个 key）到 `src/i18n`；保留 key 语义，脚本检查两边 key 集合一致。
- `locale`: system/en/zh；system 取微信/系统语言，失败回退 zh。
- 日期格式化自研：`yMMMd`、星期、月份、ISO `YYYY-MM-DD`；不用 `Intl` 假设。
- 数量格式：整数千分位 + 最多 3 位小数；`，`/`,` 归一化为小数点；拒绝科学计数/负值/超长。
- 文案中的“提醒/日历/组件/分享”按小程序真实能力改写，不沿用 Android 的“通知/桌面组件/系统分享”。

### 9.4 可测试性

- 领域函数纯函数；固定时钟；固定 ID/哈希注入。
- 存储测试用内存 FS 模拟双槽/manifest/崩溃点；断言“旧状态或新状态，不出现半写”。
- 备份测试用 Android schema12 脱敏夹具，做 encode→decode→restore→export 往返；断言字段/类型/顺序不漂移。
- 组件测试只覆盖表单/空态/权限拒绝等关键交互；真机矩阵单独记录。
- 包体脚本解析 dist，主包/分包/总包超限即失败。

## 10. 验证与发布

### 10.1 服务器可做

```bash
# 在 miniprogram/ 内，按实施阶段执行；本轮不执行
pnpm typecheck
pnpm test
pnpm build:mp-weixin
pnpm audit:size
```

- TypeScript 严格检查、Vitest、构建、包体审计、静态资源检查。
- 不运行微信开发者工具（无 Linux 官方版）、Android 模拟器、Flutter 全量测试、支付真实交易。
- 构建失败/超限必须记录，不把“能编译”当“可发布”。

### 10.2 必须在图形界面/真机完成

- 微信开发者工具预览、体验版、真机调试；iOS/Android 微信各一台。
- 日历：授权/拒绝、系统日历确认、重复规则、厂商日历差异、删除旧副本。
- 分享：好友/朋友圈/收藏/相册保存/取消；隐私脱敏。
- 文件：聊天文件导入、导出到文件传输助手、Android 恢复小程序备份。
- 支付：沙箱下单/取消/失败/恢复/退款；iOS 可用性；真实商户只做一次小额验证。
- 无障碍：TalkBack/微信读屏、字体放大、对比度、键盘。
- 审核：备案、类目、隐私指引、API 声明、虚拟支付资质。

### 10.3 发布门禁

- 主包/分包/总包达标；无 24 MB 字体；无未使用的大依赖。
- 备份双向夹具通过；无演示数据；无假购买/假提醒。
- 隐私指引与实际 API 一致；客服/退款入口可用。
- 发布说明明确降级项；不宣称“与 Android 完全一致”。

## 11. 风险与待确认

| 风险/决策 | 影响 | 建议 |
|---|---|---|
| 主体与虚拟支付资质 | Plus 能否收费、iOS 能否上架 | 先确认个人/个体户/企业；无资质则先发免费核心版 |
| iOS 虚拟支付/Apple 15% | 价格、审核、可用性 | 后台确认 AppID 是否开通；未开通则 iOS 隐藏购买，不外跳 |
| 无桌面组件 | 原有卖点缺失 | 应用内组合面板 + 手动桌面/浮窗引导；文案不暗示桌面打卡 |
| 无后台本地通知 | 提醒体验下降 | 系统日历副本为主；可选一次性订阅只作补充 |
| 日历不可更新/删除 | 改提醒会留旧事件 | 明确“副本”语义、提供重新写入说明；不承诺自动同步 |
| 缓存清理丢数据 | 用户数据风险 | 首次引导/定期导出提示；不承诺云恢复 |
| Loop DB 不能直导 | 老用户迁移 | Android 中转 JSON；文档写清 |
| 24 MB 字体 | 包体超限 | 系统字体；后续 CDN 子集 + 下载域名白名单 |
| 包体 2 MB/20 MB | 功能塞不下 | 分包、压缩图标、无重 UI 库、字体不进包 |
| 备份兼容漂移 | 跨端恢复失败 | 以 schema12 为契约，双向夹具 + 字段级校验 |
| GPLv3/品牌/插画 | 发布/许可风险 | 发布前做许可与商标审查；不复制第三方资源 |
| 用户文本分享/公开传播 | 内容安全审核/举报风险 | v1 不做公开社区；分享仅用户主动发到聊天，默认脱敏；如需公开传播再评估 `msgSecCheck` 等能力 |
| 2C4G 服务器 | 构建/测试受限 | 串行、限量、只跑 CLI；真机在用户机器 |
| 微信审核/备案 | 上线时间 | 预留 2–4 周外部等待；先体验版 |

### 需要负责人确认

1. 小程序主体与虚拟支付资质；Plus 是否首发收费，还是先免费核心版。
2. iOS 是否申请 Apple 小程序合作伙伴计划；若否，iOS 是否接受“仅查看/记录，不能购买 Plus”。
3. 是否接受系统日历副本替代本地通知；若不接受，是否接受一次性订阅消息 + 最小云函数。
4. 是否接受“无桌面组件”的降级，组合面板只做应用内。
5. Loop 老用户是否接受“Android 先导入再导出 JSON”的迁移路径。
6. 小程序名称/品牌/插画/GPL 发布边界；是否需要同步准备小程序备案材料。
7. 是否允许使用微信云开发保存 `openid`、订单、权益（不存习惯内容）。

## 12. 工作量与下一步

按一名熟悉 Vue/uni-app 的开发者、复用现有规则与测试思路估算（不含微信审核/备案等待）：

| 阶段 | 内容 | 估算 |
|---|---|---|
| P1 | 工程、领域、存储、首个纵切、i18n/主题壳 | 5–7 人日 |
| P2 | 免费核心全量对齐 + 备份/日历/分享 | 12–16 人日 |
| P3 | Plus、虚拟支付、权益、海报、洞察、组合面板 | 8–12 人日 |
| P4 | 无障碍/性能/包体/隐私/真机/审核 | 6–8 人日 |
| 合计 |  | **31–43 人日**（约 6–9 周单人） |

下一步建议：先由负责人确认第 11 节 7 个决策，再开 P1。P1 的第一个可验收纵切必须是“真实创建→完成→重开→备份往返”，不接受先用假数据搭 UI。

## 13. 外部依据（2026-11-16 查阅）

- 小程序虚拟支付（企业/个体户）：<https://developers.weixin.qq.com/miniprogram/dev/platform-capabilities/business-capabilities/virtual-payment.html>
- 小程序虚拟支付（个人）：<https://developers.weixin.qq.com/miniprogram/dev/platform-capabilities/business-capabilities/virtual-payment/person.html>
- 订阅消息：<https://developers.weixin.qq.com/miniprogram/dev/framework/open-ability/subscribe-message.html>
- 长期订阅类目限制（官方社区答复）：<https://developers.weixin.qq.com/community/minihome/doc/00086075f2cc3038b1d3fe1d966400>
- 文件系统：<https://developers.weixin.qq.com/miniprogram/dev/framework/ability/file-system.html>
- 分包加载：<https://developers.weixin.qq.com/miniprogram/dev/framework/subpackages.html>
- 系统日历：<https://developers.weixin.qq.com/miniprogram/dev/api/device/calendar/wx.addPhoneCalendar.html>、<https://developers.weixin.qq.com/miniprogram/dev/api/device/calendar/wx.addPhoneRepeatCalendar.html>
- 分享图片：<https://developers.weixin.qq.com/miniprogram/dev/api/share/wx.showShareImageMenu.html>
- 分享文件：<https://developers.weixin.qq.com/miniprogram/dev/api/share/wx.shareFileMessage.html>
- 深色模式：<https://developers.weixin.qq.com/miniprogram/dev/framework/ability/darkmode.html>
- 无障碍：<https://developers.weixin.qq.com/miniprogram/design/accessibility.html>
- 自定义字体（uni-app）：<https://uniapp.dcloud.net.cn/api/ui/font>
- iOS 虚拟支付/Apple 小程序合作伙伴计划公开报道：<https://www.ithome.com/0/897/349.htm>、<https://www.thepaper.cn/newsDetail_forward_31959387>
- 个人虚拟支付开放报道（CloudBase，2026-11）：<https://cloudbase.cloud.tencent.com/blog/2026/11/06/virtual-payment-person>

> 以上为外部平台资料，政策以微信公众平台/MP 后台和审核结果为准；不作为已开通或已审核通过的证据。