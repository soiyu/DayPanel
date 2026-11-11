# DayPanel 开源与商业化协同策略指南

很多独立开发者在将项目开源到 GitHub 时都会遇到一个核心疑问：
> **“如果我把代码开源到 GitHub 上，Google Play 上的 Plus 付费功能该怎么做？别人会不会直接拿代码免费用，甚至打包去卖钱？”**

本文档为你提供国际开源独立开发界（Indie Dev）成熟、合规且经过验证的商业与技术解决方案。

---

## 一、 开源与商业化共存的行业真相

像 **Bitwarden**（密码管理）、**Joplin**（云笔记）、**Aegis Authenticator**（2FA验证器）、**OsmAnd**（离线地图）、**Loop Habit Tracker**（习惯打卡）等，都是 GitHub 上数万 Star 的顶级开源项目，但它们同样在 Google Play / App Store 拥有极高的付费或打赏收益。

为什么？因为开源软件的商业逻辑不是卖“二进制代码的秘密”，而是：
1. **分发便利性**：99% 的普通用户不知道什么是 Git、Flutter 或 ADB，更不会为了省十几块钱去配编译环境。他们需要的是 Google Play 的**一键下载、后台静默自动更新与开箱即用**。
2. **信任感与自来水**：开源反而是极大的营销优势。在隐私敏感的今天，“开源且无广告、无云端追踪”是吸引高净值科技用户自发在 Twitter、Reddit、V2EX、即刻推荐的最强卖点。
3. **极客开发者豁免**：会自己拉代码编译安装的硬核用户，本身就属于开源社区贡献者群体；让他们免费自编译使用，可以换取社区 Bug 反馈、PR 贡献和口碑传播。

---

## 二、 三种落地技术架构方案对比

| 方案 | 架构模式 | 优势 | 劣势 | 推荐指数 |
|---|---|---|---|---|
| **方案 A：单仓库 + 凭证与环境隔离** *(当前仓库架构)* | 源码 100% 开源，Debug 构建全功能开放；正式 Play 购买依赖作者独有的签名证书与公钥。 | 维护成本最低，无需切分支，开发体验极佳。 | 懂技术的极客可以自己编译出全功能 Debug 包给自己用。 | ⭐⭐⭐⭐⭐ **（最推荐）** |
| **方案 B：Flavor 双变体（FOSS 版 vs Play 版）** | 区分 `foss` 和 `play` 两个构建变体，FOSS 版彻底移除 Google Play Billing 库。 | 符合 F-Droid 纯开源应用市场上架要求。 | 需要维护两套 Native 依赖和入口。 | ⭐⭐⭐⭐ |
| **方案 C：双仓库 Open-Core（核心开源 + 商业闭源）** | GitHub 仅公开纯免费的基础版；Plus 相关的 Native 支付与高级组件保留在私有 Git 仓库。 | 彻底杜绝第三方获取高级功能代码。 | 跨仓库代码合并与版本同步非常繁琐。 | ⭐⭐⭐ |

---

## 三、 方案 A 实施详解（当前推荐最佳实践）

当前 DayPanel 的代码已经原生支持此方案：

### 1. 代码防线与凭证隔离
- 所有的 Google Play 支付密钥、签名证书全都在 `.local/play-release.properties` 中，**该文件被 `.gitignore` 严格忽略，绝不上传 GitHub**。
- 开源在 GitHub 上的代码：
  - 任何人 Clone 代码运行：只能以 Debug 模式运行，界面明确标注为「测试权益」；
  - 任何人尝试编译 Release 包：因缺乏你的私钥和 Play 公钥，构建会自动被 `release-check.ps1` 拦截；即使强行打包，也无法通过 Google Play 的官方收据验签，无法在应用市场上架收费。

### 2. 开源协议（License）选择建议

开源并不等于“放弃版权”。建议采用 **GPLv3 (GNU General Public License v3)** 搭配 **商标与美术保留条款**：
- **GPLv3 传染性保护**：规定任何使用该代码的人，如果修改或发布衍生版本，也**必须开源全部代码**。这能够彻底阻止抄袭者或商业黑产把你的代码做成闭源套壳 App 去收割用户。
- **保护条款声明**：在开源仓库中明确声明：
  > “DayPanel 源码在 GPLv3 下开源。但是，‘DayPanel’ 品牌名称、应用 Logo、手绘卡片原画及商业发布权归原作者独家所有。未经许可，任何第三方不得使用本项目的名称与品牌资产在应用商店公开发行商业版本。”

---

## 四、 GitHub 仓库发布清单准备

当你准备将仓库推送到 GitHub 时，按照以下步骤操作：

1. **安全检查**：
   - 检查 `git status`，确保 `.local/` 目录没有被跟踪；
   - 确保没有提交过任何真实密钥、keystore、密码或私有 URL。
2. **文档置换**：
   - 项目根目录已提供国际化的 `README.md`（英文为主）与 `README_zh.md`（中文）；
   - 保留原有的开发与产品文档在 `docs/` 目录下；
3. **设置 GitHub 仓库描述**：
   - **Repository Name**: `daypanel`
   - **Description**: `Minimalist, offline-first habit tracker, daily task logger, and mindful journal with zero tracking. Built with Flutter for Android.`
   - **Topics**: `flutter`, `android`, `habit-tracker`, `offline-first`, `privacy-focused`, `material-design`, `dart`.
