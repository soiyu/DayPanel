# DayPanel Flutter

新的 Flutter / Android 工程。功能以小日常为主对标，排除整个专注模块，所有功能免费，无广告、Pro、订阅或内购。现有原生 DayPanel/Loop 工程独立保留。

这是已可构建运行的基座开发版，交付「日常、小事、手记、我的」四栏和第一批真实本地功能。静态检查、19 项测试、Android debug 构建与 API 28 中文模拟器的创建/记录/强停重开已验证。完整对标进度见任务表，不能把旧原生版本的能力算进此安装包。

## 产品与任务

| 文档 | 内容 |
|---|---|
| [产品范围](docs/product/FEATURES.md) | 最新方向、当前切片、全部免费与专注排除 |
| [小日常逐项功能表](docs/product/XIAORICHANG-PARITY.md) | 40 项公开功能映射、Android/iOS 差异与待核细项 |
| [执行计划](docs/development/BACKLOG.md) | FL01–FL20、阶段与验收状态 |
| [当前状态](docs/development/STATUS.md) | 实际构建/测试/设备证据、未完成项 |
| [设计规范](docs/design/DESIGN.md) | 已定冷白/蓝/淡紫/暖橙风格和真实页面状态 |
| [平台决策](docs/adr/0001-flutter-android-first.md) | Flutter、Android、与旧 Loop 的边界、无走查前置 |
| [构建说明](docs/development/BUILD.md) | 项目本地工具链与命令 |

## 当前结构

```text
lib/
  domain/          # 日期、习惯、小事、手记、精确数量
  data/            # SQLite v1，独立存储
  application/     # 操作协调、加载、错误与状态
  presentation/    # 四栏 UI、表单、详情、回顾、主题
  l10n/            # English / 简体中文 ARB 与生成代码
android/           # Android host；后续提醒和组件适配
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

当前本地库暂无完整备份入口，卸载会移除数据；完整备份恢复列入 FL09。用户界面也明确说明，不能用习惯列表或七日回顾冒充完整小日常功能。
