# Windows 构建

Flutter 3.47.9 stable / Dart 3.13.7，JDK 17，Android SDK 36；当前 Flutter Android 工具链还要求 NDK 28.2.13676358。Flutter 版本取自官方 Windows stable 清单，下载脚本固定版本和 SHA-256。工具留在 ignored .local，不改全局设置。

1. 执行 `./scripts/bootstrap-flutter.ps1`。
2. 创建 `.local/toolchain.json`，填 `flutterSdk`（可用相对路径 `.local/sdk/flutter`）、`javaHome`（完整 JDK）、`androidSdk`（已有 SDK）。可复用本机其他工程的 JDK/SDK，但机器路径仅存在此 ignored 文件。
3. 执行 `./scripts/dev.ps1 pub`、`./scripts/dev.ps1 verify`。

`format` 格式化，`analyze` 静态检查，`test` 测试，`assemble` 构建 debug，`run -Extra '-d','设备ID'` 启动。默认没有 release 签名，不使用 debug 签名充当发布包。

脚本在子进程里使用项目 `.local/tool-settings` 保存 Flutter 设置，让所选 JDK 优先于主机 Android Studio JBR；不调用全局 `flutter config`。Gradle / Pub 缓存同样位于 `.local`。

桌面测试固定 `sqflite_common_ffi 2.3.6 + sqlite3 2.9.4`，二者须配套升级。App 使用 `sqflite` 的 Android 原生实现；这些测试包不作为产品桌面端。Native hooks 的更新需独立检查构建影响。

APK 位于 `build/app/outputs/flutter-apk/app-debug.apk`，应用 ID 与旧 DayPanel 分开。若提示 Android licenses，使用本机 SDK 的标准 sdkmanager 检查；不伪造许可文件。
