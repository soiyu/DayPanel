# DayPanel 发布与开源物料包 (Release & Distribution Materials)

本文件夹包含 DayPanel 走向公开开源（GitHub）与正式上架（Google Play）所需的全部配套资产、文档、配置与合规材料。

```text
release_materials/
├── 01_ACCOUNT_AND_STORE_GUIDE.md    # Google Play 账号注册、收款绑定、商品配置与封闭测试攻略
├── 02_KEYSTORE_SETUP/               # 密钥生成与管理
│   ├── KEYSTORE_GUIDE.md            # 密钥创建、安全存储与灾备指南
│   └── generate_keystore.ps1        # 一键交互式生成 release.jks 脚本
├── 03_STORE_METADATA/               # 商店 Listing 文本资产
│   ├── STORE_LISTING_en.md          # 英文版标题、简短描述、完整说明、发布记录 (Google Play 默认)
│   └── STORE_LISTING_zh.md          # 中文版标题、简短描述、完整说明、发布记录
├── 04_LEGAL_AND_PRIVACY/            # 法律与合规材料
│   ├── privacy_policy.html          # 开箱即用的响应式隐私政策静态网页 (可直接部署到 GitHub Pages)
│   └── DATA_SAFETY_FORM.md          # Google Play Console「数据安全」问卷逐题标准答案
└── 05_OPEN_SOURCE_STRATEGY.md       # GitHub 开源与 Plus 付费共存的技术方案与协议推荐
```

---

## 快速导航

1. **第一次上架 Play**：阅读 [`01_ACCOUNT_AND_STORE_GUIDE.md`](01_ACCOUNT_AND_STORE_GUIDE.md)。
2. **生成签名证书**：运行 [`02_KEYSTORE_SETUP/generate_keystore.ps1`](02_KEYSTORE_SETUP/generate_keystore.ps1)。
3. **部署隐私政策**：将 [`04_LEGAL_AND_PRIVACY/privacy_policy.html`](04_LEGAL_AND_PRIVACY/privacy_policy.html) 部署到 GitHub Pages 或自有服务器。
4. **准备开源 GitHub**：阅读 [`05_OPEN_SOURCE_STRATEGY.md`](05_OPEN_SOURCE_STRATEGY.md)。
