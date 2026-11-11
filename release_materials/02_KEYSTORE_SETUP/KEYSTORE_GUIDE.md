# Android 正式发布签名密钥（Keystore）指南

## 一、 为什么签名密钥至关重要？

在 Android 生态中，APK / AAB 签名是开发者的唯一数字身份证明：
1. **Google Play 校验身份**：只有使用正确密钥签名的 AAB 才能成功上传更新；
2. **防篡改与防冒充**：阻止黑客或第三方发布恶意同名替换包；
3. **不可逆性**：若丢失密钥且未启用 Google Play App Signing 密钥恢复流程，你将**永远无法再更新该应用**，只能更换包名重新上架，失去所有积累的用户与评价。

---

## 二、 密钥生成方式

我们已经在同级目录下准备了自动生成脚本 `generate_keystore.ps1`，你也可以直接手动运行标准 JDK `keytool` 命令。

### 方式 1：手动命令行执行

打开终端，确保系统已安装 JDK 17 并能在 PATH 中执行 `keytool`：

```powershell
keytool -genkey -v `
  -keystore release.jks `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias daypanel `
  -storetype JKS
```

**交互提示说明**：
- `Enter keystore password`: 输入密钥库密码（建议包含大小写字母与数字，至少 8 位）。
- `Re-enter new password`: 再次输入确认密码。
- `What is your first and last name?`: 开发者姓名/公司名（如 `DayPanel Author`）。
- `What is the name of your organizational unit?`: 部门名称（如 `Mobile` 或直接回车）。
- `What is the name of your organization?`: 组织机构名称（如 `DayPanel` 或直接回车）。
- `What is the name of your City or Locality?`: 城市（如 `Beijing` 或直接回车）。
- `What is the name of your State or Province?`: 省份（如 `Beijing` 或直接回车）。
- `What is the two-letter country code for this unit?`: 国家二字代码（如 `CN` 或 `US`）。
- 确认全部信息是否正确：输入 `y`。

执行完成后，当前目录下将生成 `release.jks` 文件。

---

### 方式 2：使用提供的自动化脚本

在同级目录下运行：
```powershell
powershell -ExecutionPolicy Bypass -File ./generate_keystore.ps1
```
脚本会自动检查 JDK 环境、提示输入密码，并直接在项目的 `.local/` 目录下创建 `release.jks` 以及同步更新 `.local/play-release.properties` 模板。

---

## 三、 Google Play App Signing（强烈推荐启用）

当你在 Google Play Console 首次上传 AAB 时，Google 会提示启用 **Play App Signing（由 Google 管理应用签名密钥）**：
1. **这是 Google Play 目前的默认且强制推荐机制**。
2. 此时你本地生成的 `release.jks` 实际上作为**上传密钥（Upload Key）**。
3. 即使以后本地机器损坏、重装或上传密钥不慎丢失，你仍然可以通过 Google Play Console 提交身份证明并向 Google 客服申请重置上传密钥，从而避免应用沦为废包。

---

## 四、 灾备与安全守则

1. **绝对不要提交到 Git 仓库**：
   - 项目根目录的 `.gitignore` 已经配置了排除 `.local/`、`*.jks`、`*.keystore` 以及私密配置；
   - 永远不要使用 `git add -f` 强制提交密钥。
2. **异地三副本备份**：
   - 备份 1：将 `release.jks` 和密码备份到个人离线加密 U 盘；
   - 备份 2：存入个人安全密码管理器（如 1Password、Bitwarden 的安全附件）；
   - 备份 3：加密保存在个人私有云盘中。
