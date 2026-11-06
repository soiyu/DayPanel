# DayPanel Flutter

新的 Flutter / Android 工程。功能以小日常为主对标，排除整个专注模块，所有功能免费，无广告、Pro、订阅或内购。现有原生 DayPanel/Loop 工程独立保留。

这是可构建运行的 Android 开发版，已交付「日常、小事、手记、我的」与 [UI 精修](docs/design/UI-POLISH.md)。M2 第一批新增完整文件备份/恢复/回退、情境与分组筛选、排序、间隔/周目标和计划版本历史，延续同一视觉体系。验证命令和实际设备证据见 [STATUS](docs/development/STATUS.md)。完整对标进度见任务表，不能把旧原生版本的能力算进此安装包。

FL11 已接入习惯提醒：详情设置 1–5 个本地时刻，提醒中心显示系统通知和准时权限，通知可去记录/稍后10分钟。达标、归档、删除或关闭后同步取消；重启/时间或时区变化重排。API28 与 API35 已完成限定范围验证。标准模式可能被系统节电延迟；强停后需重新打开。全部免费。

FL12 已接入常驻小事：新建时选择一次性/常驻；常驻项按需每天记录一次，没做不产生逾期，历史独立保留。支持按日期纠正、归档/恢复、完成历史与七日回顾，完整备份包含常驻记录。规则见 [ADR0004](docs/adr/0004-resident-tasks.md)。

FL13 已接入习惯关联日志、明确记录日期、月份/单日浏览与正文搜索。月份、习惯与关键词同时筛选，也可搜索全部月份；归档保留日志，删除习惯后日志解除关联并保留文字。规则见 [ADR0005](docs/adr/0005-associated-journal.md)，交互见 [JOURNAL](docs/design/JOURNAL.md)。

FL14 已接入每日成就卡、六款原创卡面、收藏与卡背心得。达成当天全部按日计划后自动解锁，也可主动领取；已获得卡片在撤销打卡或以后改计划后保留。声音/触感分别可关，默认关闭。规则见 [ADR0006](docs/adr/0006-achievement-cards.md)，交互见 [ACHIEVEMENTS](docs/design/ACHIEVEMENTS.md)。

FL15 已接入打卡表、单习惯完成率/连续性与数量趋势、年度记录日历、跨类型时间线。指标使用历史计划，数量分单位；归档履历从升级当天起保存，之前未知日期不算失败。规则见 [ADR0007](docs/adr/0007-history-statistics.md)，界面见 [STATISTICS](docs/design/STATISTICS.md)。

FL16 已接入真实 Android 习惯/小事桌面组件：长按桌面添加，选择内容后保存；每个实例独立绑定，可缩放、重新配置和移除。布尔/小事设置明确完成值，数量直接打开总量输入，取消不写入。冷进程、跨日/时区、重启和覆盖安装会刷新；系统节电可能延迟，强停后重新打开。中英明暗跟随 App 设置；组件不需要通知权限、不承诺锁屏能力。规则见 [ADR0008](docs/adr/0008-home-widgets.md)，流程见 [WIDGETS](docs/design/WIDGETS.md)。

FL17 已接入免费外观预览：三种主题、系统/浅/深模式、系统字体与离线书页体、默认图标边框。习惯支持24个有文字名称的图标、独立配色与边框，保存前可预览，取消不写入。SQLite8/备份schema8包含装扮，兼容schema2–7；装扮不改变计划、记录或成就卡。桌面主题和大尺寸习惯图标同步更新，组件文字仍采用Android系统字体。见 [ADR0009](docs/adr/0009-personalization.md) 和 [PERSONALIZATION](docs/design/PERSONALIZATION.md)。

FL18 已接入 Loop 21–25版习惯数据库备份导入：只读检查、逐项预览、选择后追加，已有内容保留；原滚动频率需要明确选择新安排。真实日期/数量/备注保留，自动覆盖不算完成，历史计划未知不计失败；已有身份跳过，导入前保留完整回退副本。Android换机采用用户主动导出/传输/恢复完整JSON文件，无云同步。范围与流程见 [ADR0010](docs/adr/0010-legacy-import.md)、[LEGACY-IMPORT](docs/design/LEGACY-IMPORT.md)。

UI02 按新的视觉反馈重构外观、备份、旧习惯导入、统计导航、提醒介绍、手记筛选和组件配置。主题/字体/边框采用可视化选项，导入分为选文件、选内容、确认三步；说明按需展开，核心数据和操作优先。设计与系统验证见 [UI02](docs/design/UI02-REFINEMENT.md) 和 [FL19矩阵](docs/development/SYSTEM-REGRESSION.md)。

## 产品与任务

| 文档 | 内容 |
|---|---|
| [产品范围](docs/product/FEATURES.md) | 最新方向、当前切片、全部免费与专注排除 |
| [小日常逐项功能表](docs/product/XIAORICHANG-PARITY.md) | 40 项公开功能映射、Android/iOS 差异与待核细项 |
| [执行计划](docs/development/BACKLOG.md) | FL01–FL20、阶段与验收状态 |
| [当前状态](docs/development/STATUS.md) | 实际构建/测试/设备证据、未完成项 |
| [设计规范](docs/design/DESIGN.md) | 已定冷白/蓝/淡紫/暖橙风格和真实页面状态 |
| [平台决策](docs/adr/0001-flutter-android-first.md) | Flutter、Android、与旧 Loop 的边界、无走查前置 |
| [安排与备份规则](docs/adr/0002-plans-and-backup.md) / [M2 操作设计](docs/design/M2-FLOWS.md) | 计划明天生效、每周目标、备份预览与事务回退 |
| [提醒规则](docs/adr/0003-habit-reminders.md) / [提醒交互](docs/design/REMINDERS.md) | 本地时刻、权限、通知去记录/稍后、取消与重排 |
| [常驻小事规则](docs/adr/0004-resident-tasks.md) / [操作设计](docs/design/RESIDENT-TASKS.md) | 一次性与常驻、日期历史、纠正与归档 |
| [日志规则](docs/adr/0005-associated-journal.md) / [操作设计](docs/design/JOURNAL.md) | 可选关联、可编辑日期、月浏览/搜索、删除保文 |
| [构建说明](docs/development/BUILD.md) | 项目本地工具链与命令 |

## 当前结构

```text
lib/
  domain/          # 日期、习惯、小事、手记、精确数量
  data/            # SQLite v8，备份与 Android 桥接
  application/     # 操作协调、加载、错误与状态
  presentation/    # 四栏 UI、表单、详情、回顾、主题
  l10n/            # English / 简体中文 ARB 与生成代码
android/           # Android host、提醒调度与习惯/小事桌面组件
test/              # 领域、真实 SQLite、界面测试
docs/              # 产品、设计、决策和交付台账
scripts/           # PowerShell 工具入口
.local/            # SDK、机器配置和诊断（Git 忽略）
```

## 开发

Flutter 3.47.9 / Dart 3.13.7、JDK 17、Android SDK 36。配置 `.local/toolchain.json` 后：

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 verify
./scripts/dev.ps1 run -Extra '-d','设备ID'
```

无 iOS/Web/Desktop 目标。debug 包使用独立身份，避免覆盖旧 DayPanel。APK 在 ignored `build/app/outputs/flutter-apk/app-debug.apk`，不提交二进制或数据库。

## 数据与来源

本工程独立实现，不直接搬运或翻译 Loop 的 GPL 源码。数据迁移是后续任务；旧项目数据库不会自动读取；可手动选择支持的Loop习惯数据库备份预览导入。依赖和来源见 [NOTICE](NOTICE.md)，最终分发许可证仍待决定。产品定价已经确定为免费。

「我的 → 数据与备份」可导出包含所有当前用户表的 JSON 文件；恢复前预览，确认后完整替换，同时保留最近一次恢复前副本以供回退。使用 Android 系统文件选择器，无需存储权限。文件不加密、上限 8 MiB，完整恢复不支持合并；Loop习惯.db使用独立导入入口；卸载会删除本机数据库及恢复副本，请将导出文件保存在合适位置。

习惯支持每日/星期、每 N 天和每自然周 N 个达标日。修改已有目标/单位/频率从明天生效；周中启用的版本从生效日计首周，不跨版本凑次数。v1 升级可保留原数据，但无法重建升级前未保存的计划改动。备份 schema8 包含提醒、常驻日记录、日志关联、成就卡/心得/收藏、反馈设置和习惯归档履历，兼容 schema2/3/4/5/6/7；系统权限与闹钟运行态不转移。桌面组件选择是设备本地状态，不随备份转移；恢复或回退后重新配置已有组件。
