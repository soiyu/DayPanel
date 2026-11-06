# DayPanel Flutter

新的 Flutter / Android 工程。功能以小日常为主对标，排除整个专注模块，所有功能免费，无广告、Pro、订阅或内购。现有原生 DayPanel/Loop 工程独立保留。

这是可构建运行的 Android 开发版，已交付「日常、小事、手记、我的」与 [UI 精修](docs/design/UI-POLISH.md)。M2 第一批新增完整文件备份/恢复/回退、情境与分组筛选、排序、间隔/周目标和计划版本历史，延续同一视觉体系。验证命令和实际设备证据见 [STATUS](docs/development/STATUS.md)。完整对标进度见任务表，不能把旧原生版本的能力算进此安装包。

FL11 已接入习惯提醒：详情设置 1–5 个本地时刻，提醒中心显示系统通知和准时权限，通知可去记录/稍后10分钟。达标、归档、删除或关闭后同步取消；重启/时间或时区变化重排。API28 与 API35 已完成限定范围验证。标准模式可能被系统节电延迟；强停后需重新打开。全部免费。

FL12 已接入常驻小事：新建时选择一次性/常驻；常驻项按需每天记录一次，没做不产生逾期，历史独立保留。支持按日期纠正、归档/恢复、完成历史与七日回顾，完整备份包含常驻记录。规则见 [ADR0004](docs/adr/0004-resident-tasks.md)。

FL13 已接入习惯关联日志、明确记录日期、月份/单日浏览与正文搜索。月份、习惯与关键词同时筛选，也可搜索全部月份；归档保留日志，删除习惯后日志解除关联并保留文字。规则见 [ADR0005](docs/adr/0005-associated-journal.md)，交互见 [JOURNAL](docs/design/JOURNAL.md)。

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
  data/            # SQLite v5，备份与 Android 桥接
  application/     # 操作协调、加载、错误与状态
  presentation/    # 四栏 UI、表单、详情、回顾、主题
  l10n/            # English / 简体中文 ARB 与生成代码
android/           # Android host、提醒调度；组件后续接入
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

本工程独立实现，不直接搬运或翻译 Loop 的 GPL 源码。数据迁移是后续任务；旧项目数据库不会自动导入。依赖和来源见 [NOTICE](NOTICE.md)，最终分发许可证仍待决定。产品定价已经确定为免费。

「我的 → 数据与备份」可导出包含所有当前用户表的 JSON 文件；恢复前预览，确认后完整替换，同时保留最近一次恢复前副本以供回退。使用 Android 系统文件选择器，无需存储权限。文件不加密、上限 8 MiB，不支持旧 Loop 文件或合并；卸载会删除本机数据库及恢复副本，请将导出文件保存在合适位置。

习惯支持每日/星期、每 N 天和每自然周 N 个达标日。修改已有目标/单位/频率从明天生效；周中启用的版本从生效日计首周，不跨版本凑次数。v1 升级可保留原数据，但无法重建升级前未保存的计划改动。备份 schema5 包含提醒、常驻日记录和日志关联，兼容 schema2/3/4；系统权限与闹钟运行态不转移。完整年度统计和桌面组件仍按后续计划推进。
