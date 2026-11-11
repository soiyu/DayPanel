# Google Play「数据安全 (Data Safety)」问卷填报对照表

在 Google Play Console 提交应用时，必须完成「应用内容 -> 数据安全」问卷。
由于 DayPanel 采用**纯本地离线（Local-First）**架构，填写非常简洁，按照以下对照勾选即可无障碍通过：

---

### 一、 数据收集与共享概览 (Data collection and security)

| 问卷题目 | 填报答案 | 解释说明 |
|---|---|---|
| **您的应用是否会收集或共享任何必需或可选的用户数据类型？** | **是 (Yes)** | 注意：因为集成了 Google Play Billing，Google 结算库会由 Google 处理购买历史，因此选「是」；业务数据本身不收集。 |
| **您的应用收集的所有用户数据是否都在传输过程中经过加密？** | **是 (Yes)** | Google Play 结算过程全程通过 HTTPS 加密传输。 |
| **您是否为用户提供了请求删除其数据的途径？** | **是 (Yes)** | 用户可在应用内清空数据，或通过卸载/清理 Android 应用存储永久删除数据。 |

---

### 二、 具体数据类型填报 (Data Types)

在数据类型列表中，逐项核对：

#### 1. 个人信息 (Personal Info)
- 姓名、电子邮件地址、电话号码等：全部勾选 **未收集 (Not collected)**。

#### 2. 财务信息 (Financial Info)
* **用户支付信息 (Purchase history / Payment info)**：
  - 勾选 **收集 (Collected)**。
  - 是否共享给第三方？勾选 **否 (No)**。
  - 是否以临时方式处理？勾选 **否 (No)**（因为本地需要缓存收据以支持离线识别已购状态）。
  - 数据收集是否是必需的？勾选 **可选 (Optional)**（仅在用户选择购买 Plus 时发生）。
  - 数据收集目的：勾选 **应用功能 (App functionality)** 与 **防欺诈/安全/合规 (Fraud prevention, security, and compliance)**。

#### 3. 健康与健身 (Health and fitness)
- 全部勾选 **未收集 (Not collected)**（饮水、跑步步数记录均保存在本地 SQLite，开发者服务端并未收集）。

#### 4. 消息/照片/音频/文件/日历 (Messages, Photos, Files, Calendar)
- 全部勾选 **未收集 (Not collected)**（日历是发送 Intent 草稿交由系统日历应用处理；导出备份是系统 SAF 框架直接落盘在用户手机本地，开发者并不收集）。

#### 5. 应用活动与诊断 (App activity & Diagnostics)
- 应用互动、故障崩溃日志、性能分析：全部勾选 **未收集 (Not collected)**（无任何 Firebase / Sentry / Google Analytics SDK）。

#### 6. 设备或其他 ID (Device or other IDs)
- 勾选 **未收集 (Not collected)**。

---

### 三、 常见审核提示应对

* **关于日历权限声明**：
  DayPanel 没有在 `AndroidManifest.xml` 中申请 `READ_CALENDAR` 或 `WRITE_CALENDAR` 权限，而是使用 Android 标准的 `Intent(Intent.ACTION_INSERT)` 调起系统日历编辑页供用户手动保存。因此不需要在 Play Console 申报敏感日历权限，也不需要提供录屏演示。
* **关于存储权限声明**：
  DayPanel 完全使用 Android 推荐的存储访问框架（SAF，系统自带文件选择器），不申请 `MANAGE_EXTERNAL_STORAGE` 或宽泛读写权限，合规无阻碍。
