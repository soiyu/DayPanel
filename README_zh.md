# DayPanel

<p align="center">
  <strong>专注习惯、日常待办与心流手记</strong>
  <br>
  <em>工匠级打磨、隐私优先、本地离线的 Android 个人习惯追踪应用。</em>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README_zh.md">简体中文</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47.9-blue.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.13.7-blue.svg" alt="Dart">
  <img src="https://img.shields.io/badge/Android-API%2028--36-green.svg" alt="Android">
  <img src="https://img.shields.io/badge/隐私-100%25%20本地离线-emerald.svg" alt="本地优先">
  <img src="https://img.shields.io/badge/广告-零打扰-brightgreen.svg" alt="无广告">
  <img src="https://img.shields.io/badge/开源协议-GPL%20v3-orange.svg" alt="协议">
</p>

---

## ✨ 为什么选择 DayPanel？

市面上的大多数习惯养成应用往往充斥着强制云端注册、繁重的年费订阅、弹窗广告以及第三方隐私追踪。

**DayPanel** 秉持相反的产品哲学：
- **100% 本地优先**：所有数据均存储在手机本地 SQLite 数据库中。没有开发者中心服务器，绝不强制云端同步。
- **零广告 & 零追踪**：不集成任何第三方统计、广告或行为追踪 SDK。
- **清新现代的工匠设计**：温润清新的视觉配色、细腻的触感反馈与 6 款原创手绘插画。
- **真正的数据自主权**：完整的本地 JSON 数据备份与回滚恢复、清晰可读的 CSV 报表导出、以及对经典 Loop Habit Tracker 数据库导入的兼容支持——核心功能永久免费。

---

## 🚀 核心功能

### 1. 多元化习惯记录
* **布尔打卡**：日常习惯，一键标记完成。
* **数量与数值型习惯**：精准量化每日数值（如饮水 `ml`、阅读 `页`、跑步 `km`），提供**基于物理单位智能推荐的快捷步进按钮**（如 `+250 毫升`、`+10 页`）。
* **频次计数习惯**：快速记录练习次数与组数。
* **弹性排期**：支持每日、指定工作日/周末，或按自定义间隔天数（如每 3 天一次）。
* **假期与暂停模式**：生病或休息时合理暂停，绝不抹除历史连胜或污染统计。

### 2. 常驻小事与日常待办
* 明确区分一次性任务与随需常驻任务。
* **常驻小事**每天按需记录，不做不产生逾期未完成惩罚，告别心理负担。

### 3. 习惯关联手记
* 打卡时随手写下当日感悟与心得，可绑定特定习惯，也可作为独立日常随笔。
* 支持按月历快速翻阅与跨月份全局正文检索。

### 4. 365 天双层年度活跃热力图
* **全局年度热力图**：在统计中心以类似 GitHub 提交矩阵的形式，一览全年 365 天的坚持轨迹。
* **单习惯独立强度热力图**：直观反映单项习惯在过去一年的完成度与达成强度。
* 包含走势分析、完成率饼图与排期版本追溯。

### 5. 6 款原创手绘每日成就卡
* 当天目标全部达成后，即可解锁原创手绘成就卡片。
* 翻转卡片即可撰写感悟，导出高清分享卡面时**默认启用隐私打码**，保护习惯私密性。

### 6. 原生 Android 桌面小部件（Widgets）
* 在手机桌面上直接添加轻量高效的小部件。
* 布尔习惯与任务支持在桌面上直接打卡完成；数值习惯支持一键唤起快捷输入面板。

### 7. 可选 DayPanel Plus（一次性终身买断）
专为高级用户提供的 Google Play 一次性买断扩展（非订阅，无续费陷阱）：
* **组合式桌面面板**：在一个小部件内聚合多个习惯与小事，空间利用率大幅提升。
* **逐次明细记录**：为数值习惯记录具体时间戳、单次增量与备注（如上午 10:15 喝水 +250ml），支持单条编辑与纠错。
* **自然周累计总额目标**：支持设置每周总额度（如每周累计跑步 100km），与达标天数完全解耦。
* **周度/月度复盘长图导出**：一键生成全景式数据复盘海报，回顾周期成长。
* **专属原创视觉装扮**：解锁更多雅致主题配色与专属图标体系。

---

## 🏛️ 项目分层架构

```text
lib/
├── domain/          # 纯领域实体、时间计算、排期规则（零 Flutter 依赖）
├── data/            # SQLite v12 数据库、事务迁移引擎、Android 原生通信桥
├── application/     # 业务状态流转与操作调度
├── presentation/    # Flutter UI、组件库、CustomPainter（热力图）与主题配色
└── l10n/            # 国际化 ARB 资源（English 与 简体中文）
android/             # Android Host、小部件宿主、定时闹钟广播与 Google Play Billing
test/                # 领域计算、数据库迁移与界面自动化测试用例
release_materials/   # Google Play 上架物料、法律声明与密钥生成脚本
```

---

## 🛠️ 从源码构建运行

### 环境要求
* **Flutter SDK**: 3.47.x (Dart 3.13+)
* **JDK**: 17
* **Android SDK**: API 28 至 36

### 构建步骤
1. 克隆代码仓库：
   ```bash
   git clone https://github.com/soiyu/DayPanel.git
   cd DayPanel
   ```
2. 在 `.local/toolchain.json` 中配置机器工具链路径：
   ```json
   {
     "flutterSdk": "path/to/flutter",
     "javaHome": "path/to/jdk-17",
     "androidSdk": "path/to/android-sdk"
   }
   ```
3. 使用内置的自动化 PowerShell 工具执行检查与构建：
   ```powershell
   # 安装依赖并编译国际化语言包
   powershell -ExecutionPolicy Bypass -File ./scripts/dev.ps1 pub

   # 运行静态分析与完整自动化测试
   powershell -ExecutionPolicy Bypass -File ./scripts/dev.ps1 verify

   # 构建 Debug APK（自动开启 Plus 测试权益）
   powershell -ExecutionPolicy Bypass -File ./scripts/dev.ps1 assemble
   ```

*在 Debug 模式下，所有 Plus 功能均处于测试放行状态，方便开源社区开发者和贡献者完整体验与调试。*

---

## 📦 Google Play 上架与发行物料

发布 Release AAB 并上线 Google Play 所需的全部资产与指引均已归档在 [`release_materials/`](release_materials/README.md)：
- [开发者账号与 14 天测试指南](release_materials/01_ACCOUNT_AND_STORE_GUIDE.md)
- [自动化签名密钥生成工具](release_materials/02_KEYSTORE_SETUP/KEYSTORE_GUIDE.md)
- [双语商店 Listing 文案](release_materials/03_STORE_METADATA/)
- [可直接部署的隐私政策页面与数据安全填报对照表](release_materials/04_LEGAL_AND_PRIVACY/)
- [开源与商业化协同方案](release_materials/05_OPEN_SOURCE_STRATEGY.md)

---

## 📄 开源许可与知识产权说明

* **源代码**：遵循 [GNU General Public License v3 (GPLv3)](LICENSE) 协议开源。
* **商标与美术资产**：**DayPanel** 项目名称、Logo 图标以及原创手绘成就卡片版权归作者所有。未经明确授权，任何第三方不得擅自使用该品牌或美术资产上架分发商业衍生版本。
* **字体许可**：Noto Serif SC 字体遵循 [SIL Open Font License 1.1](assets/fonts/OFL-NotoSerifSC.txt)。
