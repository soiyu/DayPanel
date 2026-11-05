# ADR 0001：独立 Flutter 产品，Android 首发

日期 2026-11-05，已按用户本轮明确指示执行。

- 新建独立 Flutter/Dart 工程；只生成 Android 平台目录。应用暂用 `app.daypanel.next`，debug 增加 `.debug`，可与旧原生 DayPanel 共存。发行前核定正式 ID。
- 领域和存储独立实现，使用一个版本化 SQLite 数据库。旧 Loop core、Android UI 和双库文件不直接当新库使用。
- 不复制或逐行翻译 Loop 的 GPL 实现、测试或图像资源。旧项目提供业务教训和迁移格式参考；以后若引入 GPL 代码，必须记录来源和重新评估分发。当前不据“重写”宣称已完成法律审查，也不替用户选最终开源许可证。
- 首版 Flutter 屏幕与规则可为未来平台复用；系统提醒与桌面组件仍经 Android 适配层实现，Flutter 不会自动解决这些能力。iOS 工程和适配不在本轮。
- 用户已撤销外部五人走查作为前置条件。直接交付可用功能，自动化测试、构建与设备验证是工程交付的一部分。
- 新项目功能权威为本仓库 docs/product/FEATURES.md，执行台账为 docs/development/BACKLOG.md。旧工程 v0.2 保留历史，不对新工程施加相同版本限制。
- 用户本轮追加决定优先：主对标小日常，整个专注模块排除，全功能免费。取消初稿中的场景执行、计时和 Pro/Billing 方案；功能对标见 XIAORICHANG-PARITY.md。
