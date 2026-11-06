# 当前执行状态

更新 2026-11-06。用户选择 Flutter，Android 首发，先基座/UI；随后明确小日常单一对标、排除专注、全功能免费。原生 DayPanel 是独立历史工程，未迁移或删除其内容。

当前已完成基座、UI01 精修、FL09/FL10、FL11 习惯提醒、FL12 常驻小事/完成历史、FL13 关联日志/月浏览/搜索、FL14 成就卡/收藏/心得/反馈和 FL15 打卡表/量化/年历/时间线。最新版本 SQLite v7，支持文件备份/恢复、习惯安排历史、提醒配置、独立常驻日记录、关联日志、成就卡与按日期归档履历；最新验证与限制见文末。此前版本描述和测试数字保留为历史。功能调研基于应用宝 Android 3.1.0 与 Apple 10.4.44 官方说明，原始响应在 ignored .local/research。细节未披露的能力保留待核标记。

## 已实现基座与 UI

- Flutter Android-only，独立身份 `app.daypanel.next.debug`；主包无广告、支付或分析 SDK。
- 日常日期条、当日安排、布尔/数值记录；历史补记和清除，未来/起始日前写入被拒绝。
- 习惯创建、改名/频率/目标/单位/图标、归档/恢复、确认删除与关联记录清理。
- 临时小事新增编辑/日期/清日期、收件箱/今日/逾期/未来/完成分组；完成日与计划日分开，重开保留原日。
- 手记文本新增编辑删除，记录实际创建日；不宣称已提供完整碎念搜索/月历/图片能力。
- 我的、管理习惯、七日回顾、英文/简中、系统/浅/深主题和语言持久化。回顾展示真实记录条数，零值也是记录，不混合单位、不计算未经版本化的历史完成率。
- 单 SQLite v1；真实空态、保存失败/重试、删除确认、忙碌期间阻止重复提交。数据暂仅本机，无完整备份/导入/云同步。

## 验证

命令在新项目根执行：

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 analyze
./scripts/dev.ps1 test
./scripts/dev.ps1 verify
```

最后一次 verify 的格式与静态检查通过（No issues found），19 项测试全部通过：4 项纯领域、8 项真实 SQLite 文件/事务、7 项 Flutter UI。覆盖首次创建/完成/重开，数量打开/取消不写入，小事与手记提交，中英×明暗 320dp/160% 文本、管理与详情页布局。没有使用 mock 持久化来冒充数据库。

初次测试发现桌面 SQLite 依赖不匹配与进度环无障碍数值格式问题，已修复。Windows 测试固定 sqflite_common_ffi 2.3.6 + sqlite3 2.9.4；实际 Android 用 sqflite。测试命中区域需等待滚动动画的用例已修正。19 项是限定范围，不代表 TalkBack/全部设备验收。

第一次构建使用 Flutter 自动发现的 Android Studio JBR，后已用项目本地 Flutter settings 固定 JDK 17。SDK 下载曾中断，续传后通过官方 SHA-256；NDK 下载改为官方分段下载并核对 SHA-1。中止的旧构建保留失败记录，不能算通过。Android 工具链需要 Build Tools 36/NDK 28.2.13676358；本机安装在已配置的项目 SDK 中。最终 APK 构建证据待补。

工具、截图、原始调研、测试日志留在 ignored .local；CI 文件已有，尚无远端运行。

## 最终交付证据

最终 `./scripts/dev.ps1 verify` 整体退出 0，日志 `.local/reports/verify-final.log`。格式 13 个文件无需改动，analyze 无问题，19 项测试通过；Android 增量构建 22.8 秒成功。此前首次依赖完整构建成功耗时 560.6 秒，主要为工具和依赖下载。Flutter 提示独立 Kotlin Gradle Plugin 在未来版本需迁移为 built-in Kotlin，当前固定工具链构建正常；升级前处理，不称“无构建警告”。

APK：`build/app/outputs/flutter-apk/app-debug.apk`，157216339 bytes；SHA-256 `7d7879f6d784bd1612941835472f8137a1aaf6fa147ad9ad5999fce9ff3e0afd`。包含 ARMv7/ARM64/x86_64 debug 支持，不是商店 release 包。

合并 Manifest：`app.daypanel.next.debug`、min 28、target 36、allowBackup=false；主 Activity 是新 namespace，桌面无假 Provider。debug INTERNET 为 Flutter 开发通信；无 Billing/广告/分析/账号能力。release 尚未签名/构建/审计，不把 debug 声明外推到发行包。

API 28 x86_64 模拟器 `emulator-5554` / 简中 / 1080×1920 / 420dpi / font_scale=1：

```powershell
& $adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
& $adb -s emulator-5554 shell am start -W -n app.daypanel.next.debug/app.daypanel.next.MainActivity
& $adb -s emulator-5554 shell am force-stop app.daypanel.next.debug
& $adb -s emulator-5554 shell am start -W -n app.daypanel.next.debug/app.daypanel.next.MainActivity
```

安装 Success、启动 Status: ok。通过实际界面新建 Read a page，完成后强停重开仍为 1/1；小事 Return the book 保存到未设日期；手记 A little progress today. 保存后可见。最终 UI 修正包覆盖安装后这三种数据仍在。系统同时列出旧 `app.daypanel.debug` 与新包，旧数据未清除。日志检查没有 AndroidRuntime/flutter 错误。

截图 `.local/reports/final-*-zh.png`，四页合图 `foundation-preview.png`；界面数据是通过测试操作添加，安装包不含预设样本。模拟器以旧 AVD 的 read-only/no-snapshot-save 副本运行，未向旧 AVD 持久化测试内容；关闭副本后测试安装可能消失，APK 可重装。未做实机、API 31+、实际 TalkBack、全部编辑删除/数量入口的设备人工矩阵；19 项自动化覆盖不是这些验收的替代。

## 后续工作

按 FL09–FL18 补完整备份、情境/分组/灵活频率、提醒、常驻小事、关联日志与搜索、成就卡、全年统计、组件和装扮，全部免费且不引入专注。历史计划版本仍未实现，当前日常的安排区按当前频率展示，回顾只计真实记录，不能称完整历史完成率。源代码、构建脚本与依赖锁文件准备首版 Git 记录，未推送远端。

## 2026-11-05 已有 UI 精修交付（UI01）

负责人认为主色正确，但界面单一、缺少细节、默认控件感明显。本轮按已选 Stitch 色调重做现有四栏、管理/详情/回顾和编辑/数量/主题/语言/操作/删除面板。设计与组件规范见 [UI-POLISH](../design/UI-POLISH.md)。

- 统一蓝/紫/暖橙的浅底、前景、深色映射；白色渐层卡、细边阴影和浮动导航，主操作有明确按下/禁用/忙碌语义。
- 日常压缩标题和概览，日期选中和今日圆点分开；习惯图标、完成态、数值条与操作各有层次。小事有真实状态摘要、日期标签；手记采用日期纸签；我的采用成组设置与当前选项。
- 表单统一字段标签、两种记录方式选择卡、星期按钮与图标选择。表单头部和字段可一起滚动，保存/取消固定在底部，键盘不遮住操作。
- 数量面板显示实际已记录值和当日总量输入；四档目标比例按两列排列，仅预填总量，保存后写入。取消不写入；不是桌面增量或新数量算法。
- 原生日期选择器仍使用 Flutter 内建日期逻辑与无障碍能力，统一主题/字体/圆角/日期选中样式。删除、主题/语言及更多操作使用统一底部面板。
- 回顾整合真实七日计数、柱形分布与逐日明细；不增加虚构完成率。四个标签使用独立 PageStorageKey，切换不串用滚动位置。

本轮没有改数据库结构、已有用户记录或产品范围；UI 自主核对和工程验收继续，不引入五人走查门槛，也不把这轮样式精修当作 FL17 完整个性化功能交付。

### 最终验证

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 verify
git diff --check
git diff --cached --check
```

最终日志 `.local/reports/ui-polish-complete.log`：格式 17 个 Dart 文件无变化、analyze `No issues found`、**23 项测试全部通过**、debug 构建成功（19.7 秒）。测试含此前 19 项，以及中英文 320dp/160% 字号 + 280dp 键盘的表单保存可达、预设取消不写入、标签独立滚动位置；原布局组扩展覆盖回顾和主题选择。中途定位并修正英文日期/摘要溢出、编辑头部挤占键盘空间及测试滚动定位，最终组无失败。既有 Kotlin Gradle 插件迁移提示仍存在。

最终 APK `build/app/outputs/flutter-apk/app-debug.apk`：174453374 bytes；SHA-256 `002ac785b07e46c60242df74a731cabce1d09f289fd1ae8fd5b373aed0cef9d3`。源身份/权限无变更。本次 APK 和源码覆盖旧基座外观，旧版历史哈希只作记录。

### 设备与视觉复核

API 28 `emulator-5554`，中文、1080×1920/420dpi。使用 `adb install -r` 覆盖安装，force-stop 后重新启动 `app.daypanel.next.debug/app.daypanel.next.MainActivity`，均为 Success/Status: ok。保留设备里既有 Read a page、he、小事与手记；通过实际页面核对四栏、编辑、日历、数量、更多操作/删除、回顾和深色主题。浅色状态栏图标对比修复，深色检查后恢复原浅色选择。

临时创建 UI QA water 验证 2000 ml 数量目标；选择 500 ml 后取消，列表仍是未记录；再次预填并保存才变为 500/2000。最后通过删除确认仅删除该临时习惯及记录，既有内容未删除。两列预填和提示位置的最终收尾在最后一轮 23 项测试和 APK 中，数量设备流程在此前同逻辑构建完成；四个主页与回顾截图重新采自最终 APK。

最终四页图 `.local/reports/ui-polish-overview.png`，单页 `polish-final-{daily,tasks,journal,mine,review}.png`；辅助界面 `polish-final-{editor,quantity,date,delete,theme,dark}.png` 为本轮对应检查时点，非全都最新微调帧。截图是设备真实数据，未向安装包加入展示数据。AndroidRuntime/flutter 错误日志检查为空。最终包在可见模拟器中打开，数据存在持久 AVD（本次非只读测试副本）。

限制：没有新增 API 31+、真机、TalkBack 手动或完整横屏/屏幕阅读器验收。测试通过不代表负责人已接受视觉效果；以实际界面反馈继续精修。未增加云/提醒/桌面组件/收费/专注功能。

## M2 第一批交付：FL09/FL10

用户要求做下一批、逻辑通顺、操作方便、UI 美观；期间追加“做完记录进度，然后关机”。本批范围与设计记录为 [ADR 0002](../adr/0002-plans-and-backup.md)、[M2-FLOWS](../design/M2-FLOWS.md)。不把整张小日常对标地图算作完成。

### 实际交付

- SQLite v2 原地迁移：分组、情境、排序、计划版本、数据世代和最近恢复前副本。v1 习惯/记录/任务/手记保持；无法还原迁移前未记录的目标/计划改动，详情明确提示。
- 每日/指定星期、每 N 天（1–365）、每周 N 个达标日（1–7）；自然周从周一开始。数量每天先与目标比较，每日达标只计一天；周中生效的版本从生效日计首周。按历史日期显示该版本的目标与单位。
- 编辑已有频率/目标/单位从明天生效；同日再次修改替换待生效版本，恢复原参数会移除冗余版本。详情显示生效日期和计划历史，当前日不误判新目标。
- 情境不限/早晨/白天/夜晚、分组新增改名删除、习惯所属与顺序。分组删除只解除归属；重排事务校验完整 ID 集合。日常筛选不改原数据或全局统计分母；周目标单独列为本周可记录。
- 我的→数据与备份：SAF 导出全部用户数据为有版本/校验和的 JSON，选择文件后预览真实条数和备份时间，确认替换；不合并，不支持旧 Loop 格式。
- 读事务产生一致逻辑快照；恢复在同一个 SQLite 事务保存旧数据副本、清理/插入、检查外键、增加世代。失败回滚；成功可回到最近恢复前副本。副本只留一次，不打包到新导出文件。
- 严格校验 8 MiB/100000 行、字段集合、枚举、日期、数字范围、重复 ID、外键与计划完整性。SHA-256 只代表完整性，不代表加密或真实性。
- 旧编辑/快记/排序/分组写入携带世代；恢复后的旧操作拒绝执行。控制器还检查实际存储世代，先刷新再让用户重试；恢复已提交但 UI 刷新失败有独立提示，不谎称数据库未改变。
- 新界面使用蓝/紫/暖橙和现有底部面板，最后将分组选择和筛选改为紧凑选项按钮。预览阶段不持续转圈，取消不显示失败。

### 最终命令和测试

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 verify
git diff --check
git diff --cached --check
```

最终 `.local/reports/m2-delivery.log`：28 个 Dart 文件格式无变化，analyze `No issues found`，**46 项测试通过**，Android debug 构建成功（18.0 秒）。46 = 原 23 + 计划/迁移 6 + 备份/世代 8 + 真实进程中断 3 + M2 UI 6。Kotlin Gradle 插件未来迁移提示仍存在；未称 lint/所有设备无警告。

进程中断测试在 Windows 的独立 Flutter 测试进程使用真实 AppStore 和 SQLite 文件：清空后、插入后、提交后由父进程强制结束子进程；重开验证得到完整旧数据或已提交新数据，恢复副本和世代也一致。另有三个事务异常注入点回滚测试。此证据不是 Android 整机断电/所有文件提供器测试。

UI 测试覆盖文件取消/无效文件不改数据、预览必须确认、恢复与回退后真实列表更新、导出全量、周目标编辑分区、分组创建、排序保存，以及中英 320dp/160% 深色的备份预览和排序。沿用此前表单键盘/主题/主页面回归。

### API 28 实际操作

中文可见模拟器 `emulator-5554`，1080×1920/420dpi，字号 1.0。覆盖安装前将关闭的进程数据库及 WAL 归档到 ignored `.local/reports/pre-m2-database.tar`；新包安装 Success、启动 Status: ok，旧 v1 实际升级成功。

1. 系统 SAF 导出到 Download，App 显示“备份已保存”；文件检查包含 2 习惯、2 计划、1 记录、2 小事、1 手记及设置。原始备份仅保存在 ignored 本机诊断/模拟器中。
2. 系统选择该文件，预览条数/替换说明正确；先取消，不改数据。
3. 临时新建 M2 test walk（每周 3 天、早晨）、M2 Health 分组并关联；上移保存后管理列表顺序正确。日常按早晨+分组筛选只显示测试习惯，全局每日分母仍为 2。
4. 真正恢复原导出后测试内容消失；回到恢复前副本后测试习惯、分组和顺序均返回。
5. 临时习惯周目标改 4 天，详情出现明天生效版本；今天仍为 3 天版本。随后只删除本轮测试习惯/分组，恢复原有内容和相对顺序。
6. 清理后再次导出，比对原有习惯业务字段、计划、记录、小事、手记和设置均一致；排序索引因重排/删除可能重新编号，不影响原有相对顺序。无删除旧原生工程或旧包数据。

最终包包含最后的紧凑筛选/分组选项、Unicode 分组重名规则和世代/刷新错误防护；最后覆盖安装后启动正常。SAF 往返及大部分人工路径在同数据逻辑的前一构建完成，最终样式/守卫在 46 项测试和最终构建覆盖；不重复宣称全部人工矩阵已在最终哈希逐项跑过。

最终 APK `build/app/outputs/flutter-apk/app-debug.apk`，174526607 bytes，SHA-256 `887d6538275cda7cb4022907e0faf3038388521027e0a661e7d4925c5b7b0cf4`。新包仍是 `app.daypanel.next.debug`；文件选择不新增存储权限。debug 为 Flutter 通信保留 INTERNET；无广告、Billing、专注或账号代码。相应 merged Manifest 已检查。

截图在 `.local/reports/m2-*.png`，最终筛选/备份页 `m2-final-filter.png`、`m2-final-backup.png`，计划历史/排序/周目标截图为本轮实际临时样本，样本已清理。无 AndroidRuntime/flutter 错误日志。真机、API 31+、TalkBack、第三方文件提供器、Android 进程终止/断电矩阵仍待后续验收。

### 交接与关机

下一批从 FL11 习惯提醒开始，核定多时刻/稍后与权限、取消、重启、时区；之后 FL12 常驻小事和 FL13 关联日志/月浏览/搜索。本轮完成进度记录、Git 提交与 APK 保存后按用户指示关机。关机前正常退出模拟器以保存持久 AVD；不推送远端。

## 2026-11-06 FL11 习惯提醒交付

用户要求“下一批任务，做完不用关机”，继续此前操作方便/逻辑正确/既定视觉方向。本轮实现仅 FL11，规则见 [ADR 0003](../adr/0003-habit-reminders.md)，界面见 [REMINDERS](../design/REMINDERS.md)。不启动此前关机脚本。

### 实现与边界

- 单习惯详情的提醒设置：开关、1–5 个不同本地时刻、修改/添加/移除、保存/取消；关闭保留时刻，归档显示暂停。我的新增提醒中心，系统通知权限、频道和准时权限状态来自 Android。
- SQLite v3 存储提醒及 revision；v1/v2 自动迁移。完整备份 schema3 包含提醒，仍可恢复 schema2 文件（无提醒）；权限、设备闹钟、稍后和投递去重记录不写入备份。
- Kotlin AlarmManager + 非导出 Receiver。触发时以事务读取现有数据库、当日计划、记录、目标和版本；仅用户配置的未达标计划投递。按每习惯下一次事件循环排程，支持本地时区/DST，不靠预排七天或 Flutter 进程常驻。
- Flutter 成功写入后同步调度；完成、周目标达标、关闭、归档/删除或数据恢复导致旧事件失效。native 调度失败单独显示，不误报用户数据保存失败。事件校验数据世代/revision/token；同日同一时刻去重，旧通知/稍后不可重复执行。
- 通知可去记录或稍后10分钟；去记录直接打开 Activity，布尔进入详情、数量进入快记。打开本身不写记录，过期日期/恢复前事件拒绝。稍后不跨午夜，一条习惯保持一条当前通知。
- API33+ 保存开启提醒时请求 POST_NOTIFICATIONS，拒绝保留配置且不排闹钟；系统设置可恢复。精确权限为可选 SCHEDULE_EXACT_ALARM，无权限使用标准模式；声音/震动通过系统频道。新增 RECEIVE_BOOT_COMPLETED/VIBRATE，无 USE_EXACT_ALARM、全屏/后台无限运行权限。
- BOOT_COMPLETED、包更新、时间/时区/语言变化与精确权限授权事件重排；前台恢复也重查。标准模式可能节电延迟，超过两小时或跨日的过期触发不补发。用户强行停止 App 后需重新打开；精确权限被撤销并杀进程后也要重开或等待受支持系统事件才重新注册标准闹钟，不声称可绕过系统规则。

### 最终检查

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 verify
./scripts/dev.ps1 native-test
```

`.local/reports/reminders-final.log`：analyze `No issues found`，**57 项 Dart/Flutter 测试通过**，debug APK 构建成功 19.7s，Kotlin JVM 单测 **8/8**。原有 46 项继续通过，新加7项提醒数据/备份/同步规则、4项提醒UI（拒绝保存/中英窄屏大字号/通知打开不写入）。`native-test` 另成功构建测试 APK，日志 reminders-native-final.log；既有 Kotlin Gradle 插件迁移告警仍在。

Kotlin JVM 覆盖未来时刻、当日完成、归档/关闭、日期/版本切换、周界限、间隔、DST缺失/重复小时、本地时区和跨日稍后。Android instrumentation 使用隔离测试文件与偏好、专用通知 ID；**API28、API35 各6项通过**，覆盖真实 NotificationManager、AlarmManager、去重/稍后、完成取消、归档、世代/revision/跨日失效与消费通知入口不写用户库。结果见 reminders-api28-final.log / reminders-api35-final.log。

最终 APK `build/app/outputs/flutter-apk/app-debug.apk`，174559234 bytes，SHA-256 `f43ad36d85aec36bea8ad86389d65257332f8bd79cab9fae00725f8f35f499e7`。两台模拟器均覆盖安装此最终包。合并 Manifest 核对 `app.daypanel.next.debug`、ReminderReceiver exported=false、上述四项权限，无广告/Billing。CI 增加 Kotlin JVM 单测，远端仍未运行。

### 实际系统验证

- API28 可见模拟器保留用户库。升级前停进程归档 `pre-reminders-db.tar`；新包升级成功。临时创建 Reminder QA、设置两分钟后的时刻并保存，系统 alarms 中真实出现精确事件。按 Home 并 `am kill` 后进程不在，到点仍出现中文通知，含去记录/10分钟后按钮。
- 真正点击10分钟后，通知消失，系统出现约10分钟后的事件；打开 App 不自动完成。随后在详情显式完成，稍后事件清空并改排次日；临时习惯最终通过删除确认移除，runtime 中 notices/scheduled/snoozes 均为空。
- API35 独立 AVD（本轮安装官方 default x86_64 镜像并校验 SHA-1）：真实系统授权弹窗点击拒绝，配置保留且无待触发提醒，界面显示系统通知未开启；再次主动允许后重排。未允许准时时 `dumpsys alarm` window=1h（标准模式），从系统设置允许后 window=0 / exactAllowReason=permission。
- API35 App 在后台被 `am kill` 后通过 `cmd alarm set-timezone Asia/Shanghai` 修改测试设备时区，保存的9:00重新对应当地9:00。真正 `adb reboot` 并解锁、未打开 App 时，闹钟由 BOOT_COMPLETED 重排。AVD 重启后系统自动时区回到原UTC，闹钟按当时系统时区解释，未宣称上海时区持久化。
- 精确撤销检查首次仅设置包 appop，uid allow 仍覆盖，未把该次算通过；随后设置 uid deny、重启 App，真实看到标准模式 window=1h，无崩溃。
- API35 在中途出现 emulator ColorBuffer/render context 故障导致掉线；以 swiftshader、无快照重新启动后继续，并在最终包上跑完6项原生测试。该问题属于环境记录，不是 DayPanel 全设备可靠性证据。专用API35测试App内容已清理并正常停止该模拟器，API28可见模拟器仍保留。
- API28 升级后关闭进程再归档 `post-reminders-db.tar`；独立本地校验通过：前库v2、后库v3，habits/plans/entries/tasks/notes/settings/habit_groups/runtime/recovery 逐表完全相同，新增 reminders 表为空。临时记录未混进用户数据，升级前后原数据未改变。校验日志 reminder-retention.log（额外1项，未混入57项统计）。

截图位于 `.local/reports/reminder-*.png`，包括配置面板、实际通知、API35授权/拒绝/精确设置、中文提醒中心。早期时间选择器截图在最终统一主题前拍摄；以最终已安装包为准。仪器与实际系统操作证据分别记录，不把Android28结果当作API35结果。

### 剩余项与交接

未覆盖厂商真机、全部Doze/长时间休眠、多时刻全天投递、Android34/36完整矩阵与实际TalkBack。标准提醒延迟是平台行为；应用不保证被强停后继续投递。FL11 标为实现与限定验收通过，发布 QA 继续跟踪这些边界。

下一批 FL12 常驻小事，先明确常驻与重复任务的不同规则；随后 FL13 关联日志/月浏览/搜索。全部免费，保持当前设计。此轮记录、提交和安装完成后保持电脑开机，不推送远端、不关机。

## 2026-11-06 FL12 常驻小事与完成历史

按“继续往下做”完成 FL12，沿用用户要求的操作顺畅、当前 UI 风格、全免费/无专注。本轮保持开机。规则与界面分别见 [ADR0004](../adr/0004-resident-tasks.md)、[RESIDENT-TASKS](../design/RESIDENT-TASKS.md)。这是 DayPanel 对常驻能力的具体设计，不声称小日常未公开细节已经逐项实测。

### 本批实现

- 新建小事选择一次性/常驻，创建后类型固定。普通任务仍按原日期/实际完成日处理，不重生、不自动改期；常驻不设到期日，一直可复用，每个当地日最多一条实际完成记录，空白日不算逾期或失败。
- 小事页增加独立常驻区、今天已做/未记录状态；常驻完成仍保留在原位置。摘要区分待处理的一次性事项与今天总完成记录，避免把全部常驻项算作欠账。
- 常驻详情支持日期选择、补记、单日撤销、真实完成历史、归档/恢复、永久删除确认；归档保留历史且禁止写入，删除级联清理记录。跨午夜旧当日按钮拒绝写入，恢复后的旧编辑受世代保护。
- 完成历史按日期汇总两类小事，可找到归档内容并纠正；过去的一次性完成从主列表移到历史入口。七日回顾的小事完成数含常驻日记录，习惯统计不受影响。
- SQLite4：tasks 新增默认一次性字段 resident/start_day/archived，task_entries 独立唯一 task_id/day；v1–v3 迁移。备份 schema4 纳入所有新字段/记录，兼容 schema2/3 和对应恢复副本；严格拒绝无效类型字段、日期、孤儿引用和重复日记录。
- Android 提醒 SnapshotReader 支持 v3/v4 共享的习惯/提醒结构，不因小事升级停止提醒。没有新增系统权限或通知功能。

### 验证结果

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 verify
./scripts/dev.ps1 native-test
git diff --check
git diff --cached --check
```

最终 `.local/reports/resident-final.log`：36 个 Dart 文件格式无变化，analyze `No issues found`，**74 项 Dart/Flutter 测试通过**，debug 构建成功13.7s；Kotlin JVM规则 **8/8**。新增17项 = 11项常驻存储/迁移/备份/日期规则 + 6项UI。覆盖重复完成幂等、跨日保留、不生成欠账、日期纠正、未来/创建前拒绝、归档与旧编辑、类型不变、schema2/3恢复回退、过期世代、汇总不混入习惯。UI验证中英×明暗320dp/160%、新建选择/完成/跨日、历史纠正/归档、删除取消。

初次旧备份转换测试发现动态 Map.addAll 字段类型异常，已改成明确字段赋值；最终两种旧备份有真实普通小事数据的恢复/回退均通过。已保留对过期按钮和异常写入的明确反馈，未隐藏失败用例。

原生测试APK构建成功；API28 安装最终主包与instrumentation包，`app.daypanel.next.reminders.ReminderEngineTest` **OK (6 tests)**，测试fixture现在使用SQLite4。日志 resident-native.log / resident-native-api28.log。本轮没有重跑API35设备矩阵，不以此前结果替代新证据。既有Gradle/Kotlin未来迁移告警仍在。

最终APK `build/app/outputs/flutter-apk/app-debug.apk`，174589379 bytes，SHA-256 `193e222504feae91d633fc09162b71387bdae4fb8e0a87681a0132a3ab2fe301`。应用身份和权限保持，非release商店包。

### 实际设备与数据保护

API28中文可见模拟器，1080×1920/420dpi/字号1.0。覆盖安装前将关闭进程的数据库和WAL归档到ignored `.local/reports/pre-resident-db.tar`；升级启动Success/Status: ok，已有任务保留。

通过真实UI创建 Resident QA，选择常驻后不显示安排日期。完成后卡片标今天已做；force-stop→重新启动仍保留。详情撤销后该日历史消失，再记完成恢复；归档后主列表隐藏，完成历史仍显示常驻及已归档标记；从历史进入详情取消归档，再通过明确“删除全部完成记录”确认删除本轮测试项。

清理后归档 post-resident-db.tar，并用真实SQLite校验：前库v3、后库v4，原 habits/plans/entries/notes/settings/habit_groups/reminders/runtime/recovery 逐表相同；tasks 原id/title/due_day/completed_day完全相同，新字段均默认一次性/未归档，task_entries为空。额外1项校验通过，日志 resident-retention.log，不计入74项统计。未改旧原生工程/旧包数据。

截图 `.local/reports/resident-{create,create-selected,live,completed,detail,archived,history,delete-confirm}.png` 来自最终APK的真实临时样本；样本已经清理，安装包无预置数据。跨日行为在可控时钟自动化验证，未修改用户模拟器时间冒充真实跨午夜观察。AndroidRuntime/flutter错误日志及最终启动另行检查。

### 交接

FL12 实现与限定验收通过；仍需真机/TalkBack/长列表性能与更多系统版本验证。不宣称零缺陷。下一批 FL13：习惯关联日志、按月浏览与搜索；本批不增加这些未实施入口。提交代码、记录进度后保持可见模拟器和电脑运行，不关机、不推送远端。

## 2026-11-06 FL13 习惯关联日志、按月浏览与搜索

完成本批真实功能，继续 Android/Flutter、小日常非专注范围、全部免费。先记录 [ADR0005](../adr/0005-associated-journal.md) 再实现；交互说明见 [JOURNAL](../design/JOURNAL.md)。本轮不关机、不推送。

### 实际实现

- 手记可独立存在，或关联一个当前/归档习惯；用户可编辑记录日期（1900年至今天）、关联与正文，同日可多篇。日志不创建打卡，不要求同日完成或在习惯开始日之后。取消、系统返回、关闭面板不保存本次编辑，保存失败保留输入。
- 习惯详情增加写日志、选定日的关联日志和全部日志页面；默认带入详情日期与习惯。所有编辑/删除接真实SQLite，跨恢复旧编辑、手记删除确认和习惯删除确认带generation保护。
- 手记默认本月；前后月、全部月份、定位单日/查看整月、全部/独立/任一习惯（含归档）筛选。正文为不区分英文大小写的连续子串匹配，空白关键词不限制，百分号/下划线不是通配符；月份、单日、习惯、正文取交集。清除筛选保留月份范围；搜索范围可见。保存后定位记录月份、清除其他筛选；标签切换保留条件，重启重置为本月。
- 归档保留关联与文字并允许继续写日志；永久删除习惯时ON DELETE SET NULL解除关联，文字/日期保留为独立手记，确认文案明确说明。删除手记只删这一篇。
- SQLite v5新增notes.habit_id和日期/习惯索引，旧v1–v4笔记的ID/正文/日期原样保留。备份schema5严格校验新增字段与引用，schema2/3/4以及旧恢复副本补空关联；恢复/回退保留世代与事务规则。SnapshotReader同步支持3..5，未知版本拒绝读取。
- 新界面复用components/theme的蓝色主操作、紫色日志表面、暖橙日期、纸签卡片和固定保存区。根据设备截图收紧搜索区，首屏可看到一篇正文；日期标签包含年份，跨年搜索也能明确分辨。中英文/明暗/窄屏大字号/键盘/无结果均已检查。

### 工程证据

项目根执行：

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 verify
./scripts/dev.ps1 native-test
git diff --check
git diff --cached --check
```

最终日志 `.local/reports/journal-final.log`：40个Dart文件格式无变化，analyze无问题，**97项Dart/Flutter测试通过**，Android debug APK构建成功（13.8秒）；Kotlin JVM规则**8/8**。新增23项 = 13项领域/真实SQLite/迁移/备份/世代 + 10项UI；原74项继续通过。覆盖v1–v4旧库、schema2/3/4旧备份及旧恢复副本、schema5关联恢复/回退、缺字段/非法引用/重复ID/非法日期拒绝、正文与组合筛选、归档可编辑/删除保文、删除取消、真实关闭重开、日期选择/取消/系统返回、旧世代拒绝以及中英×明暗320dp/160%字号+280dp键盘保存可达。

初次新增UI测试对底部面板误用pageBack和重复“删除”文字定位，已改用系统pop与确认动作定位；最终无失败。截图复核后缩短页头和提示，补年份显示；所有收尾代码纳入最终verify。原有Flutter Kotlin Gradle插件未来迁移提示、Gradle弃用提示仍存在；未声称无构建警告。没有升级工具链或修改全局Java/SDK。

`native-test`构建测试APK成功，日志journal-native.log。API28最终包上执行：

```powershell
& $adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
& $adb -s emulator-5554 install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
& $adb -s emulator-5554 shell am instrument -w -e class app.daypanel.next.reminders.ReminderEngineTest app.daypanel.next.debug.test/androidx.test.runner.AndroidJUnitRunner
```

**OK (7 tests)**，日志journal-native-api28-final.log；前6项提醒投递/稍后/取消/世代/日期回归，新增1项明确验证读取器接受3、4、5并拒绝6，且不写完成。测试使用隔离数据库/偏好和专用通知ID，没有清空用户库。本轮未重跑API35，既往API35证据不替代本批设备验收。

最终APK：`build/app/outputs/flutter-apk/app-debug.apk`，174616037 bytes；SHA-256 `a8af0ad74e10b2d6306efde9a9876cde26f23135c754ebdd0cde8316c5e8e4bb`。已覆盖安装到API28；包身份 `app.daypanel.next.debug` 与权限保持，未新增系统权限，非商店release包。

### API28实际操作与数据保留

实际设备为emulator-5554，API28、1080×1920/420dpi、字号1.0。覆盖安装前关闭进程并归档完整databases目录到ignored pre-journal-db.tar；安装Success、启动Status: ok。

通过真实UI建立临时JournalQA，详情打开关联日志；手记编辑面板也实际选择该习惯，输入FL13 tea memory并保存。首次尝试过早强停未等保存返回，不计作持久化通过；随后确认保存回到列表后force-stop→重开，日志和关联均保留。通过日期选择器移到10月31日，保存后自动跳到10月；正文tea与该习惯筛选命中1篇，切回11月显示无结果。归档后全部日志显示“已归档”并保留文字；删除习惯确认明确保文，删除后以“全部月份＋独立手记＋tea”仍能找到原文与日期。删除手记先取消仍保留，再明确确认移除本轮临时文字。

切换实际中英/明暗并截图后恢复原系统语言/主题。语言测试留下locale=system默认偏好，因升级前没有这行，仅清理这一条本轮生成的设置，其他原数据未改。最终用户库再归档到post-journal-db.tar；首次本地比较重用了解压目录中的旧WAL，改用新的独立解压目录后验证通过，未把该问题当作设备数据变化。

额外执行 `./scripts/dev.ps1 test -Extra '.local/journal_retention.dart'`，**1项通过**（不混入97项）；journal-retention-final.log确认前库v4、后库v5，habits/plans/entries/tasks/task_entries/settings/habit_groups/reminders/runtime/recovery逐表一致，notes原ID/正文/日期一致、新habit_id全空，foreign_key_check为空。临时习惯与手记已经清理，既有内容保留；旧原生工程和旧包未触碰。AndroidRuntime/flutter错误日志为空。

截图在ignored `.local/reports/journal-*.png`：最终阶段包含月浏览、搜索/筛选/无结果、编辑/改日期、归档日志、删除保文确认和解除关联，以及中英明暗。临时样本由真实UI录入，不进入安装包。日期年份显示的最后微调后另采delivery月页/编辑图；较早final-*截图保留对应测试时点，不宣称所有帧均来自最后一次构建。

### 交接与限制

FL13实现和限定验收通过。未验证厂商真机、实际TalkBack、全部横屏/屏幕阅读器组合、长列表/大文件性能以及API35/36本批完整矩阵；桌面SQLite备份/恢复覆盖不能替代所有Android文件提供器。本轮没有增加图片、附件、云、社交、AI或收费能力。下一批 **FL14 成就卡/收藏/卡背心得/反馈**，先定义解锁与取消/改计划边界、原创资源与声音开关。电脑和可见模拟器保持运行。

## 2026-11-06 FL14 成就卡、收藏、卡背心得与反馈

用户要求继续下一批，执行FL14。规则先落到 [ADR0006](../adr/0006-achievement-cards.md)，视觉与流程见 [ACHIEVEMENTS](../design/ACHIEVEMENTS.md)。全部免费，不增加专注/付费/云/社交；保持开机、不推送。

### 实际交付

- 当天至少一项未归档的每日/星期/间隔习惯，按当天有效计划全部达标后，每个当地日获得一张卡；周目标不算每日必做，分组/情境筛选不改变判定。当天保存从未达标到达标时，在同一事务重新核对并自动发卡；已完成的旧数据可主动领取当天卡，不补造历史卡。历史/未来、空计划和仅周目标不发卡；启动/归档/删除/恢复/改计划不会自动发卡。
- 已获得卡片永久保留当时完成快照，包括标题、类型、目标/单位、数值和计划生效日。撤销打卡、新增习惯、后续改计划、归档/删除习惯不会抹掉卡片、收藏或心得；删除习惯确认也明确这一点。它记录解锁时刻，不冒充之后持续达标。
- 我的→卡片册，全部/收藏筛选、日期、真实条数、心得摘要；详情可翻面、收藏/取消收藏、编辑/清空心得、查看完成快照。心得0–10000字，保存才写入；取消/系统返回保持原文。领取、收藏、心得携带generation，恢复后旧页面拒绝写入。日常卡片区放在习惯清单后，优先保留原有打卡操作。
- 六款原创CustomPainter卡面：晨光、根、河流、阶梯、窗、星群，按日期轮换，没有收费或随机稀有度。习惯完成状态与卡片正反面都有轻量动画，遵守系统减少动画。继续使用既定冷白/蓝/紫/暖橙和共享组件，中英文、明暗、窄屏大字号/键盘均覆盖。
- 完成声音/触感分别持久化，默认关闭。仅当天真实保存从未达标到达标后触发；重复相同值、清除、取消、补记、恢复、启动、打开卡片都不触发。声音为本地原创0.22秒PCM WAV（scripts/generate-feedback.ps1可复现），原生SoundPool使用系统提示音用途并尊重静音/勿扰/系统音量，触感遵守系统开关。后台不补播；平台失败不撤回保存，初始化失败也不阻止App启动。没有新增权限、第三方播放SDK或远程音频。
- SQLite6增加cards表；备份schema6包含卡片/收藏/心得/快照和反馈偏好，严格校验字段、枚举/数值、日期、快照重复/完整性；快照允许保留已删除习惯的原始信息。兼容v1–v5旧库及schema2–5/旧恢复副本，旧数据不自动生成卡。ReminderSnapshotReader同步支持3..6，拒绝未知7。

### 工程验证

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 verify
./scripts/dev.ps1 native-test
./scripts/dev.ps1 assemble
./scripts/dev.ps1 native-test
git diff --check
git diff --cached --check
```

`.local/reports/cards-verify.log`：47个Dart文件格式通过，analyze无问题，**125项Dart/Flutter测试通过**，debug构建18.1秒成功，Kotlin JVM **9/9**（原提醒8+新增静音/勿扰/零音量策略1）。新增28项 = 19项领域/SQLite/备份/反馈协调 + 9项UI；原97项继续通过。原生初始化失败保护收尾后单独assemble成功（14.8秒）、native-test成功，见cards-build-final.log / cards-native-final.log；Dart功能代码未再改变。

测试包括非空全部计划、周目标排除、目标版本/历史单位、重复保存/领取幂等、撤销/改名/归档/删除后卡片保留、记录与卡片原子提交（卡片插入失败时打卡回滚）、旧库无虚构卡片、schema2–5备份/旧恢复副本、schema6恢复/回退、三个故障阶段回滚、畸形快照拒绝、显式收藏/心得、平台反馈失败但记录已保存、旧世代拒绝。UI覆盖实际翻面/收藏筛选/心得保存清空取消返回、恢复中旧编辑、中英×明暗320dp/160%字号+280dp键盘、六款卡面、减少动画、反馈开关。首次UI回归因卡片区插在清单前导致原入口移出首屏，已调整到清单后，最终原有测试通过。

原生测试包安装后执行：

```powershell
& $adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
& $adb -s emulator-5554 install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
& $adb -s emulator-5554 shell am instrument -w -e class 'app.daypanel.next.reminders.ReminderEngineTest,app.daypanel.next.CompletionFeedbackDeviceTest' app.daypanel.next.debug.test/androidx.test.runner.AndroidJUnitRunner
```

最终API28 **OK (9 tests)**：提醒7项（含3..6可读/7拒绝），反馈2项（关闭不触发声音/触感，原创PCM资源可读），日志cards-native-api28-final.log。原有Kotlin Gradle插件未来迁移和Gradle弃用提示仍在，未升级全局Java/SDK。没有把API28结果当作本批API35/36验证。

最终APK：`build/app/outputs/flutter-apk/app-debug.apk`，174664595 bytes；SHA-256 `6c5350d2261a9453fd89e9b288f5fc5e5f3d442b6511e038e26b71e5da57fccb`。已覆盖安装到主用户，身份 `app.daypanel.next.debug` 与现有权限保持，非release商店包。

### 设备实测与数据保护

API28 emulator-5554、1080×1920/420dpi、字号1.0。安装前停进程归档主用户完整databases目录为pre-cards-db.tar，覆盖安装和启动成功。主用户原有数据没有用于凑“全完成”。

本次创建临时Android测试用户DayPanelFL14QA（id10），为其安装现有debug包并切换。首次切换尚未解锁时启动失败，不计作成功；解锁后正常打开独立空库。通过真实UI新建Read a page，完成后自动得到“向前一步”卡片；翻面、收藏、键盘输入A small step today.并保存。确认返回后force-stop→重开，卡片、收藏和心得仍在；收藏筛选显示1篇，取消收藏后出现收藏空态。

开启声音和触感后，撤销打卡，卡片与心得仍在，再达标没有多发卡。Android音频日志记录到本应用SoundPool、USAGE_ASSISTANCE_SONIFICATION和播放started事件（cards-audio-state.txt）；这证明系统播放请求执行，不能据此声称模拟器外放听感、真机响度或物理振动已经验收。设备截图覆盖中文浅色、英文深色，以及反馈默认关闭/开启、卡面/卡背/收藏空态/心得键盘；另外两种语言/明暗组合由自动化布局验证，文件为ignored `.local/reports/cards-*.png`。样本由UI创建，安装包不包含预置用户数据。

完成后切回主用户0，停止并删除本轮测试用户10，系统用户列表恢复仅主用户；主用户语言/外观/反馈偏好均未改。最终用户库归档post-cards-db.tar，在全新的本地解压目录比较，运行 `./scripts/dev.ps1 test -Extra '.local/cards_retention.dart'`，额外**1项通过**（不混入125项）。cards-retention.log确认前v5、后v6，habits/plans/entries/tasks/task_entries/notes/settings/habit_groups/reminders/runtime/recovery逐行一致，cards为空、foreign_key_check为空。原生检查使用隔离fixture，未清空用户库，旧原生包/旧项目未触碰。

### 交接与限制

FL14实现及限定验收通过。未完成厂商真机声学/触感体验、真实TalkBack手工、全部横屏/长列表性能、系统声音/勿扰全矩阵和API35/36本批回归；自动化/模拟器不能代表这些范围。原生初始化不可用与后台状态会安全跳过反馈，记录照常保存。下一批 **FL15 打卡表、量化统计、年度日历与时间线**，需要明确历史分母、连续性和单位聚合规则。电脑与可见模拟器保持运行，不关机、不推送远端。

## 2026-11-06 FL15 打卡表、量化统计、年度日历与时间线

用户要求继续，执行FL15。先记录 [ADR0007](../adr/0007-history-statistics.md)，再实现领域、存储及界面；设计见 [STATISTICS](../design/STATISTICS.md)。继续全部免费、Android-first、不引入专注。保持开机、不推送。

### 本批功能与规则

- 我的和七日回顾增加统计与历史入口，习惯详情可直达单习惯统计。打卡表按周显示习惯×日期，支持切周/日期定位/单习惯筛选（含归档），名称列固定、日期横向滑动；符号和读屏文字区分达标/未达标/未记录/未安排/弹性周目标/未知/未来。点格先打开明确日期的确认或数量面板，只有显式保存/清除写入；归档可读，未来与开始日前禁写，旧页面受generation保护。
- 单习惯7/30/365天统计：按日完成率为截至昨天已知活跃的计划达标日/应做日，今天未结束不进分母；当前/最长连续计划日限所选范围，休息日跳过，未知/归档/周目标打断。周目标另按完整周一至周日、同一计划与已知活跃履历统计完成率和连续周，部分周/进行中周不当失败，不混每日分母。
- 量化合计、记录日均值/日数和逐日柱形按历史单位分组；零值是真实记录，缺值不补零，不跨习惯/单位相加。均值以整数千分位四舍五入；日期明细保留对应版本目标与单位。柱形/记录可打开实际纠正入口。
- 年度日历显示全年真实习惯记录总数、12个月份记录数与所选月份日期分布，含零值；颜色表示记录数量而非完成率。支持年切换/日期定位/单习惯筛选，日期明细包含真实事件及未记录习惯，未来只读、闰日正确。
- 时间线按月份/单日及类型展示习惯记录、一次性实际完成日、常驻日记录、手记、成就卡，点开进入实际编辑/详情。不编造时分/操作审计，不继续显示已清除事实；独立成就卡仍保留。七日回顾原有计数规则保持。
- SQLite7增加habit_activity日期版本，归档/恢复写同一事务，同日最终状态覆盖、跨日保留，时钟回退到已存版本之前拒绝改变状态。旧v1–v6从升级当天建立已知基线，之前真实记录保留但履历未知、不推定失败；新习惯从开始日已知。备份schema7严格校验履历字段/日期/重复/引用/最终状态，兼容schema2–6和旧恢复副本；旧备份基线为备份时间的本地日期且不早于开始日。提醒读取器同步支持3..7、拒绝8。

### 最终工程验证

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 verify
./scripts/dev.ps1 native-test
git diff --check
git diff --cached --check
```

最终 `.local/reports/statistics-final.log`：52个Dart文件格式无变化，analyze无问题，**153项Flutter/Dart测试通过**，Android debug构建成功（72.8秒），Kotlin JVM **9/9**。本批新增28项 = 18项领域/SQLite/迁移/备份 + 10项UI，原125项继续通过。native-test成功，日志statistics-native-final.log；既有Flutter Kotlin插件迁移与Gradle弃用提示仍在，不称无警告。

规则测试覆盖截至昨天分母、今日不打断、休息日跳过、未知/归档/恢复界限、间隔锚点、历史目标、整周/周中改版/范围边缘、单位隔离与零值、闰年/年界、时间线类型与实际日期、归档履历持久化/同日幂等/时钟回退、v6迁移、schema2–6兼容/回退与畸形履历拒绝、恢复后旧写入拒绝。已有v1–v5迁移和恢复中断测试继续运行。UI验证布尔/数量显式纠正、取消、未来禁用、归档只读、旧数量面板、年历明细/闰日、时间线手记编辑和筛选空态，以及中英×明暗320dp/160%文字+280dp键盘。

初次解析/静态检查发现括号、字段推断与代码块问题，修复后进入测试；没有把失败运行记作通过。设备视觉复核发现横向滚动名称丢失，已固定名称列；收尾为打卡格和年历日期格补齐无障碍激活动作，重新verify全部通过。

API28最终APK和测试包上运行：

```powershell
& $adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
& $adb -s emulator-5554 install -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
& $adb -s emulator-5554 shell am instrument -w -e class 'app.daypanel.next.reminders.ReminderEngineTest,app.daypanel.next.CompletionFeedbackDeviceTest' app.daypanel.next.debug.test/androidx.test.runner.AndroidJUnitRunner
```

**OK (9 tests)**，statistics-native-api28-final.log；含提醒兼容3..7/拒绝8、通知与反馈回归。测试fixture独立，不清空用户库。没有重跑API35/36，既往结果不当本轮设备证据。

最终APK `build/app/outputs/flutter-apk/app-debug.apk`，174731527 bytes；SHA-256 `38e6d91ec5abf54f0ed3fcac1dc986b7a66e63905e0aa463262f898e23e9939c`。已覆盖安装主用户，包身份/权限不变，非商店release包。

### 实际设备及原数据保护

可见API28 emulator-5554，1080×1920/420dpi/字号1.0。先关闭主进程、归档databases到pre-statistics-db.tar，覆盖安装启动成功。创建临时Android用户DayPanelFL15QA（id11），独立空库通过真实UI新建Read a page，从打卡表确认完成；年历记录数为1，点11月6日可见实际打卡和获得卡片。从日期明细清除打卡后，该事实移除、卡片仍在，未记录习惯可继续纠正。

新建Water，目标2000 ml，真实输入250.001保存；打卡表显示已记录未达标，单习惯趋势显示合计250.001、记录日均值250.001、日数1，历史明细目标2000 ml。新建仅今天的习惯完成率显示没有已结束计划日，不把今天算失败。force-stop→重开后时间线仍显示250.001 ml与原卡片，布尔清除仍保留。截图复核并保存最终名称固定的打卡表、年历、日期明细、数量趋势和时间线，`.local/reports/statistics-final-{table,calendar,timeline}.png`、statistics-quantity-trend.png、statistics-day-history.png、statistics-cleared-day.png。样本由UI输入，安装包无预置用户数据。截图采于最终无障碍激活动作收尾前的同一视觉版本；收尾包重新通过完整verify、覆盖安装与API28原生9项检查。

模拟器期间多次自动锁屏，部分启动等待很久、界面dump短暂null；已解锁并重新读取界面后操作。早期命中旧坐标造成一次未保存的数量创建取消，不计作成功；后续逐步确认保存和实际250.001值。被锁屏覆盖的早期截图不作为交付证据。设备本轮主要为中文浅色，另外语言/明暗/窄屏组合由自动化检查，不能声称设备全矩阵完成。

结束时切回用户0，停止并删除临时用户11，系统仅剩主用户；主用户原记录/设置从未用于测试凑数。归档post-statistics-db.tar并用新目录校验，运行 `./scripts/dev.ps1 test -Extra '.local/statistics_retention.dart'`，额外**1项通过**（不计入153项）。statistics-retention.log确认前v6后v7，habits/plans/entries/tasks/task_entries/notes/settings/habit_groups/reminders/runtime/recovery/cards逐行一致；habit_activity只有每习惯一条2026-11-06基线、归档状态与原值一致，foreign_key_check为空。AndroidRuntime/flutter错误日志为空，主用户最终启动成功。旧原生项目/包未触碰。

### 交接

FL15实现与限定验收通过。未完成真机、真实TalkBack、全部横屏/长列表/大规模数据性能、API35/36本批矩阵；统计只依据当前保留的数据，已删除事实和升级前缺失的归档/计划历史无法重建。下一批 **FL16 习惯/待办桌面组件**，需明确冷启动、跨日、显式写入、数量直输与尺寸适配。电脑和可见模拟器保持运行，不推送、不关机。
