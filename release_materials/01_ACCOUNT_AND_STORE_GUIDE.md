# Google Play 开发者账号与上架全流程详尽指南

本文档为 DayPanel 发布到 Google Play 的完整实操手册，涵盖账号注册、商户收款、内购商品配置、合规问卷以及新账号封闭测试要求。

---

## 一、 开发者账号注册与身份认证

### 1. 账号类型选择
Google Play 提供两种开发者账号类型：
* **个人账号（Personal）**：
  - 注册费：\$25 美元（一次性支付，需 Visa / MasterCard / 双币信用卡）。
  - **重要注意事项（2023年11月13日后新规）**：新注册的个人账号在申请上线**生产环境（Production）**前，**必须进行至少 14 天且至少 12 名封闭测试人员（Closed Testers）连续参与测试**并通过审核。
* **组织/企业账号（Organization）**：
  - 需要提供 DUNS（邓白氏编码）、企业营业执照、官方企业域名邮箱。
  - **优势**：没有 14 天 12 人的强制封闭测试要求，审核后可直接发布到生产环境。

### 2. 注册步骤
1. 使用专属的 Google 账号访问 [Google Play Console](https://play.google.com/console/signup)。
2. 开启 Google 账号的两步验证（2-Step Verification）。
3. 按照向导填写开发者名称（用于商店前端对外展示，如 `DayPanel Studio`）、联系邮箱、电话号码。
4. 支付 \$25 注册费并完成身份验证（个人需上传身份证/护照，企业需上传公司证照及法人身份证明）。通常 1~2 个工作日通过。

---

## 二、 开通 Google Payments 商家收款账户（Merchant Account）

DayPanel Plus 是一次性内购商品，需要开通商户账户才能在 Google Play 定价与收款：

1. 登录 Google Play Console，点击左下角 **设置 (Settings) -> 开发者账号 (Developer account) -> 付款资料 (Payment profile)**。
2. 点击「设置商家账户（Set up a merchant account）」。
3. 填写商业实体名称、注册国家/地区、营业地址、主联系人。
4. 绑定收款银行账户（境外电汇卡，或支持收取美元的国内银行账户/万里汇/PingPong等跨境收款服务提供的虚拟美国银行账户）。
5. 填写 W-8BEN 税务表格（中国大陆开发者通常享受中美税收协定优惠，免除或减免部分预扣税）。

---

## 三、 创建应用与获取结算公钥（Licensing Key）

### 1. 创建应用
1. 在 Play Console 首页点击 **创建应用 (Create app)**。
2. 填写基本信息：
   - **应用名称**：`DayPanel: Habits & Daily Log`（或 `DayPanel 日常`）
   - **默认语言**：`English (United States)` 或 `Chinese (Simplified)`
   - **应用或游戏**：`应用 (App)`
   - **免费或付费**：`免费 (Free)`（核心应用完全免费，高级功能通过内购解锁）
3. 勾选同意开发者计划政策与美国出口法律，点击右下角「创建应用」。

### 2. 获取 Base64 结算公钥（非常重要）
代码中用于防篡改校验订单的公钥需在此获取：
1. 进入应用后，在左侧菜单滑动到最底部的 **创收 (Monetize) -> 创收设置 (Monetization setup)**。
2. 找到 **许可 (Licensing)** 区域，复制长字符串：
   `Base64-encoded RSA public key`。
3. 将此公钥粘贴保存，稍后填入 `.local/play-release.properties` 的 `billingPublicKey`。

---

## 四、 创建 Plus 内购商品（In-App Product）

DayPanel 采用 Google Play 官方推荐的**非消耗型一次性买断商品**：

1. 左侧菜单进入 **创收 (Monetize) -> 应用内商品 (In-app products)**。
2. 点击右上角 **创建商品 (Create product)**：
   - **商品 ID (Product ID)**：`daypanel_plus`（必须与代码 `BuildConfig.PLUS_PRODUCT_ID` 严格一致，全小写，下划线）。
   - **商品名称**：`DayPanel Plus 终身买断`（英文：`DayPanel Plus Lifetime Unlock`）。
   - **说明**：`一次性解锁组合桌面组件、逐次记录明细、自然周累计目标、复盘长图导出与专属配色。`
3. **设置价格**：
   - 点击「设置价格 (Set price)」，基准货币可设为 USD \$2.99 或 CNY ¥18.00。
   - 点击「更新汇率」，Play Console 会自动换算全球 170+ 国家/地区的本地化货币价格（含当地增值税/消费税）。
4. 点击「保存」-> 点击「**激活 (Activate)**」。

---

## 五、 设置许可测试人员（免扣费真机测试）

在正式上线前，你需要用自己的 Google 账号测试真实的购买弹窗，但不需要扣真实的银行卡钱：

1. 进入 Play Console -> 左侧菜单底部的 **设置 (Settings) -> 许可测试 (License testing)**。
2. 在「许可测试人员」列表中，添加你的 Google 账号邮箱（Gmail）。
3. 许可响应选择 **`RESPOND_NORMALLY`**（正常返回测试订单）。
4. 此时，该 Gmail 账号在真机上测试购买时，Google Play 弹出的收银台会显示「测试卡，此交易不会产生费用」，但代码会收到完整的真实购买收据与签名，用于完美验证本地验签与解锁逻辑。

---

## 六、 应对新个人账号「14天 12人封闭测试」全攻略

如果你的账号是新个人账号，Google 要求必须通过封闭测试才能申请生产上线：

### 1. 规则要点
- 必须在 **封闭测试（Closed Testing）** 轨道创建测试轨道（例如 Alpha 轨道）。
- 邀请至少 **12 名测试人员**（通过 Google Group 邮箱列表或独立的 Gmail 邀请列表）。
- 所有测试人员必须接受网页邀请（Opt-in），通过 Google Play 内部链接下载安装应用。
- 应用在测试人员设备上保持安装与测试状态至少 **连续 14 天**。

### 2. 高效合规操作流程
1. **组建测试人员群**：
   - 在 Google Groups 创建一个群组（例如 `daypanel-testers@googlegroups.com`），设为成员可加入。
   - 在国内/海外开发者互助社群、V2EX、即刻、Reddit（r/AndroidClosedTesting）招募互测伙伴（通常 1~2 天即可集齐 20+ 人）。
2. **在 Play Console 关联群组**：
   - 进入 **测试 (Testing) -> 封闭测试 (Closed testing)** -> 创建测试版。
   - 上传构建好的 `app-release.aab`。
   - 在「测试人员」标签页勾选刚刚创建的 Google 群组。
   - 复制 Opt-in 网页邀请链接（形如 `https://play.google.com/apps/testing/app.daypanel.next`）发送给测试人员。
3. **满 14 天后申请正式发布**：
   - 满 14 天后，Play Console 控制台主页会点亮「申请正式版访问权限（Apply for production access）」按钮。
   - 填写简短问卷（说明这是一个本地优先的日常习惯追踪器，封闭测试期间修复了哪些用户反馈，如小部件尺寸适配、日历提醒文本优化等）。
   - Google 团队通常在 2~5 个工作日内批准正式版发布权限。
