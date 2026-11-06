# 当前执行状态

更新 2026-11-07。用户选择 Flutter，Android 首发，先基座/UI；随后明确小日常单一对标、排除专注、全功能免费。原生 DayPanel 是独立历史工程，未迁移或删除其内容。

当前已完成基座、UI01 精修、FL09/FL10、FL11 习惯提醒、FL12 常驻小事/完成历史、FL13 关联日志/月浏览/搜索、FL14 成就卡/收藏/心得/反馈、FL15 打卡表/量化/年历/时间线、FL16 Android 桌面组件、FL17 免费外观/字体/习惯装扮和 FL18 旧习惯导入/离线换机。最新版本 SQLite v8，支持文件备份/恢复、习惯安排历史、提醒配置、独立常驻日记录、关联日志、成就卡与按日期归档履历；最新验证与限制见文末。此前版本描述和测试数字保留为历史。功能调研基于应用宝 Android 3.1.0 与 Apple 10.4.44 官方说明，原始响应在 ignored .local/research。细节未披露的能力保留待核标记。

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

## 2026-11-06 FL16 习惯与小事桌面组件

按用户明确授权直接实现。先记录 [ADR0008](../adr/0008-home-widgets.md) 与 [WIDGETS](../design/WIDGETS.md)，沿用已有冷白/蓝/淡紫样式。仅修改 Flutter 项目源码，旧 Loop 源码未复制、翻译或修改；全部免费，无专注/云/账号/广告/分析。

### 实现与边界

- 两个真实 RemoteViews Provider：每个 Launcher 实例选择一个习惯或一次性/常驻小事，可添加多实例、保存/取消、重新配置、移除、横纵缩放。设置按钮始终是独立点击区；配置页复用 AppCanvas/SoftPanel/SettingRow/AppAction，数量直接复用 QuantityEditor。我的提供实际添加说明。
- 完整本地日期、名称、实际数量/完成状态、日期对应目标、周目标进度、一次性实际完成日与常驻当日状态。归档只读、对象不存在/恢复后显示重新选择。中英/浅深使用 App 设置，系统模式遵循系统；窄尺寸年份与月日分行、大字号保留动作和完整语义描述。
- 布尔/任务设置显式完成值，重复请求不切换；已完成进入详情，桌面没有快捷撤销或增量。数量仅确认保存/清除后写入，取消/返回不写入。旧日期、旧配置、旧实例及旧 generation 拒绝；PendingIntent 身份包含实例/配置版本/世代/日期/动作，未将静态 extras 当物理点击 ID。未新增依赖值相等的撤销算法。
- Android 业务库只读，所有完成通过独立 :widgets Flutter Activity 调用现有 Dart 规则。AppController 全部写入在同一 SQLite 事务核对 generation，嵌套操作复用事务；加载也取得一致快照。数量/历史计划、常驻唯一日、卡片同事务解锁和提醒取消沿用已有实现。主 App 回到前台重新加载。独立进程避免 sqflite 单工作线程池跨引擎等待；配置、提醒运行态和刷新经私有同 UID Provider 在主进程统一管理，避免多进程偏好缓存分歧。
- WidgetActivity 单实例，未关闭表单再次点击不会替换输入对象；保存/取消后再打开另一组件。显式退出关闭独立数据库连接；主 Activity 的文件操作执行器随销毁释放。
- SQLite 仍 v7、备份仍 schema7，ReminderSnapshot 兼容 3..7 不变。实例绑定为设备私有状态，不进备份或恢复副本，不转移 Launcher ID；恢复/回退后必须重新选择。没有新用户字段需要迁移。
- 每次 App 成功操作/前台、配置/缩放、系统周期、午夜普通闹钟、开机、覆盖安装、日期/时间/时区/语言变化刷新。不申请额外通知/精确闹钟权限；Doze/厂商延迟和强停限制明确说明，不承诺锁屏组件。

### 工程证据

在项目根执行：

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 verify
./scripts/dev.ps1 native-test
./scripts/dev.ps1 assemble
```

最后完整 verify 为 `.local/reports/widgets-final.log`：56 个 Dart 文件格式无变化、analyze 无问题、**171 项 Flutter/Dart 通过**（原153 + 新18），debug 构建与 **12 项 Kotlin JVM 测试通过**（原9 + 新3）。最后一处原生 Activity 执行器释放后另跑 assemble（19.5秒）和 native-test（12秒）通过，日志 widgets-final-assemble.log / widgets-native-final.log。既有 Kotlin/Gradle 迁移弃用提示仍存在。

新增 Dart 测试覆盖重复显式完成/一张卡/一次反馈、数量不能盲完成和重复总量、常驻每日本地日唯一/空白无欠账、一次性完成日不被重复更新、旧日期/归档/删除、恢复回退旧世代、周目标不发每日卡、刷新失败保留成功记录、独立连接旧写入与事务异常回滚；配置保存/取消、数量直开/取消/保存、恢复后的旧面板、原生失效动作、中英×明暗 320dp/160%。

API28 最终 APK 和测试包覆盖安装（使用 --no-streaming 的最后一次安装 Success），执行：

```powershell
& $adb -s emulator-5554 install --no-streaming -r build/app/outputs/flutter-apk/app-debug.apk
& $adb -s emulator-5554 install --no-streaming -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
& $adb -s emulator-5554 shell am instrument --user 12 -w -e class 'app.daypanel.next.reminders.ReminderEngineTest,app.daypanel.next.CompletionFeedbackDeviceTest,app.daypanel.next.widgets.WidgetSnapshotTest,app.daypanel.next.widgets.WidgetLifecycleTest' app.daypanel.next.debug.test/androidx.test.runner.AndroidJUnitRunner
```

**OK (15 tests)**，widgets-native-api28-final.log，2.991秒。原有提醒7项/反馈2项继续通过，组件4项快照/身份 + 2项真实系统实例生命周期覆盖历史目标/单位/精确数量/日期/常驻/一次性、世代/主题/语言/未知库版本、PendingIntent实例/日期/动作/配置隔离、重新配置/删除/归档/恢复旧动作。生命周期测试强制只在非主用户运行，测试授权用完撤销；fixture数据库独立，不写用户业务库。

最终 APK `build/app/outputs/flutter-apk/app-debug.apk`，174751163 bytes，SHA-256 `46ef01de14833c37a5b76a33516a33d5b2baa6182d4e7c50580ebabd19ccda18`。合并 Manifest 核对 app.daypanel.next.debug、min28/target36、allowBackup=false；组件Activity可供Launcher启动，Provider/系统Receiver不导出，配置ContentProvider不导出并检查同UID，组件进程为:widgets。原有通知/开机/精确提醒/触感权限保留，未新增组件通知权限要求。

### 实际 Launcher 与数据保护

可见 API28 emulator-5554，1080×1920/420dpi。先关闭主用户进程并归档 `.local/reports/pre-widgets-db.tar`，覆盖安装保留数据；创建临时用户 DayPanelFL16QA（id12）执行真实界面操作，主用户记录不用于测试。通过UI新建 Read a page、Water（目标2000，本次设备输入单位为空）、Post a letter（一次性）、Stretch（常驻）；安装包没有演示内容。

真实 Launcher 长按→微件→选择 DayPanel 习惯/小事→选择内容→保存。布尔桌面完成后显示今天已完成，App可见一张成就卡；切换配置到数量前先验证取消保留原选择，确认保存才替换。数量点击直接输入，取消后仍无记录，保存250.001后桌面显示真实总量。常驻与一次性分别完成并显示今天已做/实际完成日；强停测试用户进程后桌面点击成功冷启动写入。主App恢复可读组件写入。

多个实例分别保存（习惯和任务），PendingIntent独立且配置未串用。实际拖动调整为两列宽，160%系统字号检查并截图；英文深色、中文浅色均有真实截图。由于较窄栏位原日期在字符中间断行，最终改为年份/月日两行；内容超长可省略但保留完整读屏描述与详情入口。

将模拟器时区从GMT切到Pacific/Kiritimati进入次日，常驻显示新日期与未记录，切回原时区恢复原日状态；全过程无新完成写入。打开数量面板后切到次日再保存，旧日期操作被拒绝，原250.001保留。另在测试用户桌面暂时关闭自动时间，把时刻设到23:59:48，20秒后实际00:00:08桌面日期/数量已切次日；测试后恢复原时刻、GMT与auto_time=1（auto_time_zone始终1），日志 widgets-midnight.log。未将短时前台测试算作长时间Doze验收。

本轮截图保存在 ignored `.local/reports/widgets-*.png`，包括配置、习惯完成、数量输入/取消后/保存、常驻/一次性、缩放把手/窄尺寸/160%字体、英文深色、次日/午夜和过期数量面板。不同截图按相应检查时点记录，不把早期画面当最终全部矩阵。

设备中途持续运行多小时后模拟器进程无响应（ADB/控制端口均超时），一次streamed测试包安装被中断；该次安装/重启不算通过。停止卡住的模拟器进程后额外保存其userdata qcow2到ignored widgets-avd-recovery，再用同一AVD、-no-snapshot启动。检查两用户数据库目录仍存在，归档widgets-after-emulator-recovery-u{0,12}.tar；系统安装中断使包暂不可用，--no-streaming覆盖重装后恢复，测试用户Launcher组件需重新添加。随后已重新跑最终15项原生测试。未清空、替换或直接修改主用户库。

`python .local/widgets_retention.py` 对原始归档和恢复后的主用户库逐表比较通过，v7与全部14表（含android_metadata）逐行一致，foreign_key_check为空；见 widgets-recovery-retention.log。此检查单列，不混入171测试。

正常 `adb shell reboot` 后连接重建、sys.boot_completed=1、uptime重新计数，切回测试用户无需打开主App即显示原组件与250.001；截图 widgets-final-reboot.png。最终两列/160%/英文深色截图 widgets-final-narrow-dark.png 明确显示年份/月日两行、完整数量和主动作，真实数量面板保存相同总量成功。Launcher拖到“移除”后配置文件变为空map，业务记录没有删除。

### 交接范围

FL16 实现及限定验收通过。尚未完成API35/36本批Launcher矩阵、厂商真机、真实TalkBack手工、长时间Doze/省电、极端字号/横屏/长名称全矩阵及大量组件性能；不称全设备无BUG。午夜/时区实测属于API28前台可见Launcher范围。组件单实例Activity保留当前未关闭表单，再次点击需先完成或取消当前输入。锁屏能力留给FL19按平台核验，不承诺iOS式能力。下一批 **FL17 免费主题、字体、图标、配色与边框**。不推送远端、不关机，最终保持可见模拟器运行。
收尾切回主用户0、停止并删除临时用户12，系统只剩主用户。主用户进程关闭后归档post-widgets-db.tar，`python .local/widgets_retention.py`再次逐表比对通过，日志widgets-retention-final.log；原2习惯/1记录/2小事/1手记/原偏好及其余表完全保留，外键检查为空。主用户最终启动Status: ok。删除组件后的旧Activity入口显示内容/日期已变并可返回，截图widgets-final-deleted-action.png，没有写入。

完成 `git diff --check` 与 `git diff --cached --check`，均通过。APK、数据库、截图、AVD恢复副本、工具链和日志均在ignored路径，未提交。最后正常重启后Android自动时区选择了America/New_York，结束前重新设为原GMT，保留auto_time/auto_time_zone原值1；主用户App语言/主题未改。电脑和可见模拟器保持运行。

## 2026-11-06 FL17 免费主题、字体、图标、配色与边框

用户“继续”承接FL16交接，执行FL17。先记录 [ADR0009](../adr/0009-personalization.md) 与 [PERSONALIZATION](../design/PERSONALIZATION.md)，沿用冷白/蓝/淡紫/暖橙。全部免费、本地离线，不新增账号/云/专注/广告/付费。旧Loop源码未修改或复制。

### 功能与规则

- 我的→外观变为真实预览页，提供系统/浅/深模式、晴空蓝/林间青/暮色紫、系统字体/书页体、柔和底/圆环/无边框默认图标样式。选择只改当前预览，固定保存一次事务应用，取消/返回不写入；恢复默认只先改变预览，需保存才生效。预览显示真实习惯与当天状态，无内容时明确标记排版样张，不添加假记录。保存错误可返回或重试，旧页面generation不匹配拒绝。
- 习惯编辑提供24个具名图标（前六个索引和含义保留）、自动及蓝/紫/橙/青/玫瑰配色、跟随默认及三种边框；图标/颜色/边框和输入名称即时预览，原保存/取消保持。习惯列表、管理、提醒列表及数量颜色使用真实装扮；状态继续有文字/图形，不仅靠颜色。装扮保存不创建计划版本、不写完成、不重新发卡；目标/频率/单位仍明天生效。
- 三主题共用颜色层次，主操作渐层白字最低4.5:1经测试，深色有独立映射，回顾紫与日期橙语义保持。系统文字缩放及减少动画未禁用。字体随App应用到正文/标题/按钮，不依赖运行时联网。
- 书页体为未修改Noto Serif SC可变字体，来自google/fonts固定commit `8b0a1d0f5983c89bc2b93f1b5fb55f9e252744b5`，25,125,512 bytes，SHA-256 `050080d9255a86808f2945bffac582b31ef32bc36411ce29563b4961670c66f9`。源文件、来源、完整OFL1.1在assets/fonts，NOTICE补充说明，App许可证注册Noto Serif SC条目。APK实际检查确认FontManifest、字体和OFL都已打包。图标为Flutter已有Material Icons（Apache2），Android组件使用同一字体的24个glyph，无Loop/竞品资源。
- SQLite8在habits新增color/frame，旧库默认auto，icon原值不变；settings增加palette/font/icon_frame。备份schema8严格校验枚举/图标0..23/字段，旧schema2–7补自动装扮，未知值拒绝。导出、导入、恢复前副本和回退全链路包含；旧设置缺失时沿用原默认。ReminderSnapshot同步3..8（拒绝9），WidgetSnapshot支持7..8（拒绝9），避免升级后提醒/组件失效。
- 桌面主操作随App主题，较大尺寸显示习惯图标/装饰，窄小尺寸优先保留日期/状态/动作；组件字体遵循Android系统，外观页明确说明。App保存之后按既有流程刷新，冷进程仍读同一真实库。没有新增权限或Launcher图标切换。

### 工程验证

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 verify
./scripts/dev.ps1 native-test
```

最终 `.local/reports/fl17-final.log`：60个Dart文件格式无变化、analyze无问题、**193项Flutter/Dart通过**（原171+新22），debug构建24.4秒成功，Kotlin JVM **12/12**。native-test成功，日志fl17-native-final.log（6秒）。已有Kotlin/Gradle弃用迁移提示仍存在，不称无警告。

新增13项规则/SQLite/备份/颜色对比测试与9项UI测试：默认与未知设置回落、原子保存/旧世代、全部装扮有效范围/非法输入拒绝、v7→v8原字段保留、装扮编辑保持计划/记录/卡片、schema8严格校验及回退、schema2–7和旧恢复副本兼容、三主题×明暗主动作及正文对比、预览取消/返回/重置不写、保存刷新组件、恢复后旧外观页拒绝、真实图标选择保存、24具名语义、中英×明暗320dp/160%书页体布局。原事务中断恢复、提醒、常驻、日志、卡片、统计、组件测试继续通过。

首次迁移回归失败原因是两项旧测试用当前库降version但没有删除本批新增列，已修复为真实旧结构；新UI测试曾因异步滚动等待/屏外位置失败，改用实际底部面板及可达定位后通过，没有删除失败用例或把中途运行记作成功。设备复核发现习惯名称预览没有随文本输入即时更新，修复后重新完整verify。

最终APK `build/app/outputs/flutter-apk/app-debug.apk`，174784029 bytes，SHA-256 `db148c67f3092e0cad90fc0a06a5be32df2402040faf417d44c31315bab81467`，--no-streaming覆盖安装Success。包身份仍app.daypanel.next.debug，API/权限/组件导出边界无变动。APK不是商店release包。

API28最终APK/测试包运行：

```powershell
& $adb -s emulator-5554 install --no-streaming -r build/app/outputs/flutter-apk/app-debug.apk
& $adb -s emulator-5554 install --no-streaming -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
& $adb -s emulator-5554 shell am instrument --user 10 -w -e class 'app.daypanel.next.reminders.ReminderEngineTest,app.daypanel.next.CompletionFeedbackDeviceTest,app.daypanel.next.widgets.WidgetSnapshotTest,app.daypanel.next.widgets.WidgetLifecycleTest' app.daypanel.next.debug.test/androidx.test.runner.AndroidJUnitRunner
```

**OK (16 tests)**，4.636秒，fl17-native-api28-final.log。含原15项回归及新增v8装扮/主题/边框读取、24glyph绘制；提醒3..8可读/拒绝9、组件7/8/未知版本及实例隔离继续通过。原生fixture独立，不写用户业务库，生命周期测试只在临时用户运行。

### 实际设备与限制

API28可见emulator-5554，1080×1920/420dpi。先关闭主用户进程归档pre-appearance-db.tar，再覆盖安装。创建隔离用户DayPanelFL17QA（id10），空库实际预览林间青+书页体+圆环后取消；关闭进程归档fl17-cancel-db.tar读取settings为空，取消确实不落库。

UI新建Read a page，选择阅读图标、玫瑰色、圆环后保存；列表显示对应装扮且未记录。外观保存林间青/书页体/默认圆环，全App应用，强停重开保留。实际Launcher添加习惯组件并配置，主按钮变青；拖动增大尺寸后显示玫瑰圆环阅读图标，字体仍是系统。切换暮色紫/深色/English后，App和组件同步；最终覆盖包再次保留选择，桌面完成动作成功更新为Completed today。

设备截图 `.local/reports/fl17-*.png`：appearance-initial、serif-preview、habit-style、daily-teal-serif、widget-large、appearance-dark-en、final-widget-dark等。截图来自实际界面，样本均由UI创建，不向产品预置数据。首批截图与最终名称预览即时更新修复视觉等价；最终包的原生16项重新运行。中英四组合窄屏/大字号为自动化证据，设备主要中文浅色/英文深色。设备UI查询偶尔null，等待稳定后重读；一次误触联系人组件立即取消，未授权或修改联系人。

尚未完成本批API35/36、厂商真机、真实TalkBack手工、完整横屏/极端长名、字体大规模列表性能和长期后台矩阵。桌面自定义字体不受支持且已说明；不宣称全设备无BUG。下一批 **FL18 旧数据导入与Android离线数据方案**，需要先核定可验证的旧格式与恢复边界，不擅自引入云或订阅。电脑和可见模拟器保持运行，不推送远端。
收尾从App开源许可页实际打开Noto Serif SC，完整版权与OFL1.1可读，截图fl17-font-license.png。切回主用户0，关闭进程归档post-appearance-db.tar，`python .local/appearance_retention.py`逐表核对通过（fl17-retention-final.log）：全部14表原字段逐行一致，v7→v8仅habits增加auto颜色/边框，foreign_key_check为空；2习惯/1记录/2小事/1手记/原偏好与其他历史保持。此额外检查不混入193项。临时用户10已停止删除，系统仅主用户；主用户最终启动Status: ok，未更改其语言/主题或真实记录。

`git diff --check`、`git diff --cached --check`通过。字体与许可属于正式资源提交；SDK/APK/数据库/截图/日志/个人路径均不提交。最终错误日志无AndroidRuntime/flutter错误，未推送，电脑及可见模拟器继续运行。

## 2026-11-06 FL18 旧习惯导入与Android离线换机

用户“继续”承接FL17，执行FL18。先写 [ADR0010](../adr/0010-legacy-import.md)、[LEGACY-IMPORT](../design/LEGACY-IMPORT.md) 与 [格式边界](LEGACY-FORMAT.md)。仅修改Flutter项目；旧原生工程只读核对字段/枚举/导出结构，无GPL实现/测试文件复制或翻译。全部免费，无云/账号/专注/收费。

### 实现与明确边界

- 数据与备份增加独立Loop旧习惯导入入口，支持已核定SQLite user_version21–25的Habits/Repetitions（含23 question、24 uuid、25 notes）。SAF读入上限8MiB，唯一私有暂存目录只读打开，检查头/版本/quick_check/表列/数据类型/1000习惯和50000记录限制/文本/日期/唯一键/引用；视图、触发器、虚拟表、损坏/未知版拒绝。源文件不升级、不写入，临时副本结束清理，进程中断遗留副本过期再清理。不是任意SQLite/CSV/ZIP导入器。
- 只取原始Repetitions：布尔2手动完成→1000、0明确未完成→0；1自动覆盖/-1未知不生成完成；3跳过保留为关联手记。数值0、1、2、3是实际0/0.001/0.002/0.003，整数千分位保留；目标按Double精度读取后BigDecimal表示并在Dart严格转千分位，不四舍五入超精度值。至多目标、超长名称/单位或不支持的目标逐项标原因不可选，合法子集可追加。
- UTC午夜编码按UTC年月日取日期键，不按设备时区移日；非午夜/未来/范围外/重复/失联/非法记录整文件拒绝。起始日使用最早原始记录，无记录取导入日，明确不代表原创建日。保留原名称/归档/顺序/原值，描述/问题/频率目标说明和逐日备注写已有notes，旧跳过事实保文。旧提醒/派生得分/配色/旧扩展小事场景不迁移。
- 每天频率保留；其他滚动n/d必须逐项明确选择每天/自然周N达标日/间隔N日，不能自动将Loop滚动频率当自然周。间隔锚点从导入当天开始。旧计划/目标变化/归档历史未知，只从导入日建立habit_activity基线，之前记录可看但不计失败/连续；旧数值使用导出时单位，界面说明限制。
- 预览支持选中/取消、已存在、不支持、原频率/目标/记录/跳过/备注计数，差异确认勾选，滚动频率无默认猜测。固定取消/追加，全部重复时无写入动作。UUID哈希命名空间化，无UUID旧文件用id/名称/类型哈希并说明改名去重限制。事务再次检查身份；已有项跳过不覆盖不合并，重新导入不会重写本机修改，删除后可重导且保留旧解除关联手记。
- 追加从提交时一致快照合成，保留已有所有用户表、设置和卡片；沿用SQLite事务恢复协议保存完整导入前副本、写入追加结果、增加generation。失败/进程终止全回滚；导入不发卡/不播反馈，不自动开启旧提醒。成功后刷新App/提醒/组件，旧页面/组件失效。最近副本回退明确替换后续改动；回退页也缓存副本的generation，不能拿过期副本覆盖更新后的数据。
- SQLite8/备份schema8保持，无新表。来源说明/备注使用已有notes并进入完整导出/恢复副本。Android数据方案为手动导出完整JSON→USB/文件传输→新设备预览恢复→重新设置权限/组件；不提供自动备份或云同步，不承诺其他平台能力。

### 最终工程验证

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 verify
./scripts/dev.ps1 native-test
```

`.local/reports/fl18-final.log`：66个Dart文件格式无变化、analyze无问题、**223项Flutter/Dart通过**（原193+新增30），debug构建24.3秒成功，Kotlin JVM **12/12**。native-test成功，fl18-native-final.log（5秒）。新增17项纯规则/SQLite、9项UI、3项导入进程终止和1项旧回退页世代回归；原193项继续通过。既有Kotlin/Gradle迁移弃用提示仍在。

测试覆盖编码差异/精确目标/UTC日/合法版本/非法引用与重复/未来/非午夜/超界、归档顺序/身份隔离、选择子集、保留已有小事手记设置、来源与备注、未知历史不进失败分母、间隔锚点/周目标、去重/重导/旧手记ID避冲突、旧世代与跨日、事务三阶段异常回滚、缓存回退副本过期、中英×明暗320dp/160%动作可达。实际子进程在清空阶段、插入后、提交后被终止，重开数据库分别保持完整旧/新数据和恢复副本，不只模拟throw。

中途失败如实记录：界面测试因惰性列表的向上/向下定位及屏外点击失败，改为实际滚动并核对可点击后通过。API28发现Cursor.getString读取REAL目标会丢失小数（2000.001读成2000），改为getDouble→BigDecimal，保留原生回归。既有组件生命周期测试的异步revokebind未等待完成，可能覆盖下一个用例的授权，修复为读完命令结果后再继续；产品授权逻辑未改。修复后完整测试重新通过。

最终APK `build/app/outputs/flutter-apk/app-debug.apk`，174825158 bytes，SHA-256 `b35ce0d866284bb7a06017f0848bb7e33512029eb0954196183bf06f1ccfca22`，最终--no-streaming覆盖安装Success。身份/权限/Manifest无变更，仍app.daypanel.next.debug，非商店release包。

API28最终包验证：

```powershell
& $adb -s emulator-5554 install --no-streaming -r build/app/outputs/flutter-apk/app-debug.apk
& $adb -s emulator-5554 install --no-streaming -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
& $adb -s emulator-5554 shell am instrument --user 11 -w -e class 'app.daypanel.next.reminders.ReminderEngineTest,app.daypanel.next.CompletionFeedbackDeviceTest,app.daypanel.next.widgets.WidgetSnapshotTest,app.daypanel.next.widgets.WidgetLifecycleTest,app.daypanel.next.importing.LegacyReaderTest' app.daypanel.next.debug.test/androidx.test.runner.AndroidJUnitRunner
```

**OK (20 tests)**，13.357秒，fl18-native-api28-final.log。原16项加4项旧库读取测试，覆盖21–25版本、2000.001目标、250001记录、源文件不改、暂存清理、坏头/截断/未知版/上限/超长文本/视图/触发器/错误字段类型拒绝。全部fixture独立，未用主用户库做写入测试。

### 实际设备与数据保护

API28可见emulator-5554，1080×1920/420dpi。主进程关闭后归档pre-import-db.tar，覆盖安装；临时Android用户DayPanelFL18QA（id11）新建Keep this task。合成Loop-demo.db/Invalid.db仅放测试用户Download，通过真实SAF选择。坏文件显示拒绝；有效文件预览3项，取消先不导入。再次选入，Old reading原2/3选择每自然周2日，Old water目标2000 ml、含250.001和显式0，Old limit至多目标不可选，勾选差异后追加成功。

实际App小事仍显示Keep this task，手记显示来源说明及关联；关闭测试进程归档fl18-imported-db.tar，`python .local/fl18_import_check.py`通过：2习惯/3真实记录/5手记/1原小事/0卡片，数量250001与0准确，恢复副本包含原小事且无导入习惯。UI回退预览显示0习惯/1小事，确认后归档fl18-rollback-db.tar，`python .local/fl18_rollback_check.py`通过，导入事实全移除、原小事保留、generation=2。两项检查单列，不混入223项。

合成源数据库导入前后逐字节一致，SHA-256 `25291317f18623d4aea7e9950340d6ad40684a077990512b7d5f812a3831002e`。真实用户数据、旧原生App库均未用于导入试验；上游旧库只读查看格式，测试数据库为本项目自行生成，安装包没有演示数据。

截图 `.local/reports/fl18-*.png` 包含坏文件、中文预览/安排/不支持项、导入成功、来源手记、回退预览、英文深色预览。界面查询偶有null，等待后重读，未把失败查询算成功。设备中文浅色/英文深色，另外组合和320dp/160%由自动化验证，不称完整设备矩阵。

### 交接

FL18限定范围实现及验收通过。只支持已核定Loop21–25数据库，不支持CSV/双库ZIP/旧扩展小事场景/至多目标；旧历史与导出缺失信息无法重建。API35/36本批、厂商真机/真实TalkBack/长时间中断与电源故障/最大数据性能/其他SAF提供器仍待验收。下一批 **FL19 系统回归**，按实际设备补API、Launcher、提醒、无障碍和数据矩阵，不把这些缺口自动标完成。电脑和可见模拟器保持运行，不推送、不关机。
收尾切回用户0，停止并删除临时用户11，清理本轮/data/local/tmp合成文件，系统仅主用户。关闭主进程归档post-import-db.tar，`python .local/import_retention.py`逐表比对通过（fl18-retention-final.log）：SQLite8及全部14表原字段逐行一致，foreign_key_check为空，原2习惯/1记录/2小事/1手记/偏好完全保留。主用户最终启动Status: ok。检查单列，不混入223项。

`git diff --check`与`git diff --cached --check`通过。SDK/APK/数据库/截图/本机路径及日志均不提交；仅提交代码、文档、合成测试。电脑和可见模拟器继续运行，未推送远端。

## 2026-11-07 UI02 新功能界面重构与 FL19 系统回归

用户明确指出新功能UI很差、要求优化并做下一步。本轮同时推进UI02和FL19，未进入FL20发布。设计判断和范围见[UI02-REFINEMENT](../design/UI02-REFINEMENT.md)，系统结果见[SYSTEM-REGRESSION](SYSTEM-REGRESSION.md)。不将“完美”当未经验证的结论，保留真机/手工读屏/厂商限制。

### UI实际变化

- 外观由同权的大色块按钮改为低强调明暗选择、真实主题样卡、字体字形样卡和边框图标预览。真实习惯预览更紧凑，默认重置移到工具栏，保存/取消固定。习惯装扮配色为有具名语义的色样，边框直接预览，24图标和真实持久化保持。
- 数据与备份首屏直接显示导出/恢复/旧习惯导入三个操作行，重要操作有图标与简短用途。完整副本回退独立呈现，离线换机/文件说明可展开，覆盖后果仍在确认流程。恢复预览时不再在背后持续显示无关加载动画。
- 旧习惯导入拆成选文件→选内容→确认三步。选择页优先条目名称、类型、记录数/原频率，需要新安排的项有明显入口；跳过/未知/备注计数按需展开。最终页汇总所选习惯和真实记录数，完整差异/回退说明及勾选确认后才写入。上一步与系统返回可改选择，改变选择/安排清除旧确认；失败滚回消息位置，成功提供返回数据页入口。
- 统计改为一行图标导航（短标签+完整语义名称），数据表提前，口径说明移到数据后可展开；名称固定/日期横滑和显式纠正保持。提醒中心压缩重复介绍，权限动作与状态相邻；手记筛选换为较轻的选项，不再堆积主动作按钮。组件配置减少重复标题、显示真实选中预览；原生内容顶部排列并保留底部动作。
- Launcher尺寸判断修复：竖屏使用minWidth/maxHeight、横屏使用maxWidth/minHeight，避免大竖屏组件误按横屏最小高度隐藏图标/说明。没有更改组件写入规则或PendingIntent身份。
- 新增ChoiceSurface/QuietChoice/ResponsiveChoices/ActionTile/DetailDisclosure/EditorFooter/SectionHeading，将选择、说明、主要提交区别呈现。保留冷白/蓝/淡紫/暖橙以及主题/字体，控件48dp目标、英文和大字号换行；真实入口和业务规则不减少。SQLite8/schema8及产品免费/离线范围不变。

### 工程检查与环境问题

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 verify
./scripts/dev.ps1 native-test
./scripts/dev.ps1 assemble
```

最终完整verify `.local/reports/ui02-final.log`：68个Dart文件格式无变化、analyze无问题、**227项Flutter/Dart通过**（原223+4项可访问性），debug构建24.3秒成功，Kotlin JVM **12/12**。新增4项中英×明暗页面48dp点击区/具名操作检查；原外观、导入、恢复、统计、数量、历史、卡片、提醒、组件、进程终止恢复继续通过。三步流程测试更新为确认后写入，没有删除安全断言。最终原生尺寸修复后assemble21.6秒成功；原生测试时序修正后native-test再次成功，日志ui02-native-final.log。既有Kotlin/Gradle弃用提示保留。

本机C盘TEMP满导致一次测试编译复制失败，之后多模拟器与全测试并发耗尽提交内存导致Dart/辅助模拟器退出，这些运行不算通过。`scripts/dev.ps1`现仅在当前项目进程设置TEMP/TMP到ignored `.local/tmp`，verify并发2；不改全局Java/SDK/系统设置，不自动清理系统目录。尝试删除本轮失败临时目录被工具策略拒绝，未执行删除；改用项目临时路径完成验证。辅助模拟器串行运行，主API28可见环境保留。新增可访问性测试初次因未await异步匹配导致语义句柄未释放，修复后真实断言通过。

独立规模测试 `./scripts/dev.ps1 test -Extra '--concurrency=1','.local/fl19_scale_test.dart'`：100习惯/36,500记录，读取8245ms、导出9156ms、恢复18096ms、备份2,425,475bytes，外键/恢复副本/记录数正确，**1项通过**，fl19-scale-final.log。此为Windows FFI冷环境测量，不是手机UI性能验收，不混入227项。首次默认30秒超时及一次诊断脚本编辑错误不计通过，大数据性能仍列后续。

最终APK `build/app/outputs/flutter-apk/app-debug.apk`，174861005 bytes，SHA-256 `a3f73e005f95e29b35d1639cb93143c115e961bfd16e5270712bb04a4b6436f4`。已覆盖安装，包身份/Manifest权限未变化，非商店release包。只提交源码/测试/文档，SDK/镜像/APK/数据库/截图/个人路径均不提交。

### 模拟器与真实界面证据

API28 emulator-5554、API35 emulator-5556、API36 emulator-5558。API36使用官方default x86_64 r02镜像，下载大小844217077 bytes，SHA1 `829c076e8ff448a336097ae25a355b495ba36e2c`核对后解压到本项目ignored目录；下载曾分段重试，未跳过校验。未修改旧工程源码。

原生测试安装后执行：

```powershell
& $adb -s <device> install --no-streaming -r build/app/outputs/flutter-apk/app-debug.apk
& $adb -s <device> install --no-streaming -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
& $adb -s <device> shell am instrument --user <qaUser> -w -e class 'app.daypanel.next.reminders.ReminderEngineTest,app.daypanel.next.CompletionFeedbackDeviceTest,app.daypanel.next.widgets.WidgetSnapshotTest,app.daypanel.next.widgets.WidgetLifecycleTest,app.daypanel.next.importing.LegacyReaderTest' app.daypanel.next.debug.test/androidx.test.runner.AndroidJUnitRunner
```

API28用户13最终 **OK(20)**，15.870秒，fl19-api28-final.log。API35用户10最终 **OK(20)**，32.608秒，fl19-api35-final.log，提醒7项有实际执行标记；最后用与API28/36相同的最终APK及测试包重新安装验证。API36用户10最终 **OK(20)**，23.681秒，fl19-api36-final.log，包含通知达标取消、去记录/稍后、重排、世代、组件多实例/过期动作、旧库读取完整性等。不是全部系统状态的穷举。

API35首次提醒用例因权限授给错误用户而assumption跳过，未当通过；测试改为`pm grant --user 当前用户`并读完结果，之后全组实际执行。API36通知取消立即读activeNotifications偶发读到旧状态，测试新增最多5秒等待真实通知服务状态，再断言出现/消失；再次全20项通过，无产品写入规则变化。

API28使用临时用户13从真实SAF选合成旧备份，走完新的三步导入、安排选择、最终确认与成功返回；真实内容保留在测试用户，安装包无演示数据。截图检查外观样卡/色样、数据操作行、导入选择/确认、统计表，实际主题选择/保存正常。最终核心页面图 `.local/reports/ui02-overview.png`，各页ui02-appearance-final.png、ui02-data-first.png、ui02-import-final.png、ui02-statistics-final.png，字体/边框细节ui02-appearance-fonts.png；不同截图按实际时点采集，未用示意图代替设备截图。

API35真实新建Read a page，Launcher长按→Widgets→DayPanel→配置选择→保存→桌面Complete→Completed today通过，截图fl19-api35-widget-config.png/fl19-api35-widget-home.png/fl19-api35-completed.png。新测试用户user_setup_complete=0导致Home键不响应，先确认并完成隔离用户初始化后继续；未改主用户。辅助环境遇到System UI无响应弹窗选择等待后恢复，部分后续启动时辅助模拟器退出，软件渲染重试与未完成矩阵保留，不当App崩溃已定位或全设备通过。

### 数据与交接

开始前关闭API28主用户进程归档pre-ui02-db.tar，结束切回0、删除用户13，再归档post-ui02-db.tar。`python .local/ui02_retention.py`逐表比较通过：SQLite8、全部14表原字段逐行一致，foreign_key_check为空，原2习惯/1记录/2小事/1手记/设置与历史保持。主用户最终启动Status: ok。此核对单列不混入227项。

UI02实现和上述限定工程/设备范围通过，用户尚未重新确认视觉满意度，不宣称完美。FL19仍进行中：真机、真正TalkBack手工、API35/36完整权限拒绝/授权与长时间Doze、所有Launcher缩放与横屏/字体极限、大数据手机性能、锁屏平台能力仍开放；下一步继续这些回归及问题修复，不自动推进发布。电脑与API28可见模拟器保持运行，不推送远端。

API36改用1024MiB、swiftshader并禁用Vulkan后，系统启动完成；当前用户10等待System UI弹窗恢复后，主Activity启动Status: ok，实际进入外观、选择Dark/Evening violet，截图fl19-api36-appearance-dark.png可读且无溢出。随后保存/提醒页检查时辅助模拟器再次退出，提醒权限拒绝/授权全流程和Launcher手工未验收，不把这些失败命令当通过。原生20项已经独立通过，软件模拟环境稳定性仍是本机限制。

最终清理日志fl19-cleanup.log确认API36与API35均切回主用户、停止并删除本轮用户10，然后关闭辅助模拟器；API35清理前再次安装最终APK/测试包并跑全20项通过。只保留API28可见模拟器运行，当前用户0，错误日志ui02-final-errors.log无AndroidRuntime/flutter错误。`git diff --check`和`git diff --cached --check`通过，未推送、未关机。

## 2026-11-07 UX01 休息安排与成就卡图片

用户同意提升体验，本批范围为暂停/休假/单日跳过及卡片图片保存/系统分享；FL19仍开放，不进入发布。先记录ADR0011及REST-AND-SHARE，沿用UI02组件和冷白/蓝/淡紫/暖橙。无收费、云、账号或发送消息操作，不修改旧原生工程。

### 规则与实现

- 习惯详情/日常休息状态提供真实入口：从今天暂停直到手动恢复、当天/未来开始的休假最多365日、无记录的今天或过去日期单日跳过。取消确认不写；明确恢复/取消不切换，历史范围保留，过去跳过可取消。重叠/创建日前/未来跳过/归档新增/时钟回退拒绝；旧页面generation保护，结束检查原id/起止/kind。
- SQLite9新增habit_breaks，迁移只加空表/索引；schema9严格校验字段、日期、引用、枚举、重叠、重复与跳过已有记录，兼容schema2–8补空表。恢复前副本、事务恢复/回退和旧习惯追加均包含新表；删除习惯级联休息，归档保留。ReminderSnapshot支持3..9、WidgetSnapshot7..9，拒绝未知版本10。
- 休息日期拒绝新打卡/数量写入，旧组件动作同样经事务检查；实际原记录/计划/卡片不擦除。每日分母排除休息，连续性中性跳过；受影响周不考核完整周目标，不修改周目标，归档/未知历史/部分范围仍不当合格周。数量趋势/时间线保留实际事实。提醒休息期间取消/到期恢复，组件显示明确状态并进入详情。
- 休息设置本身不发卡，至少一个非休息义务实际达标才能按原规则解锁；全部休息不发卡，历史补记不发卡。已获卡在恢复计划/撤销后保持。
- 成就卡详情可预览PNG、保存图片或打开Android系统分享。名称/心得默认关闭；最多6项名称加剩余计数，心得摘录最多280字、仅改输出，不改原文。海报包含实际获得日期、原创卡面、标题与完成习惯数，无App按钮/系统栏。窄屏标题换行，输出随尺寸降低倍率保持4096×16000边界；页面/存储generation在输出前检查。
- 图片保存走SAF、取消不提示成功；分享仅打开目标选择、不声称已发送。私有缓存下shared-cards使用不导出的FileProvider、临时只读URI授权，校验PNG/大小/尺寸、过期清理；缓存不进备份，无存储权限。合并Manifest核对provider authority为app.daypanel.next.debug.card-images、exported=false，原debug网络/提醒权限不变。
- 当前休息以“休息安排与记录”呈现，恢复主动作独立。修复AppAction缺少独立语义容器导致Android把卡片说明与按钮合并的问题；恢复按钮现在有独立名称/点击区。沿用主题/组件，英文计数正确处理单复数，不宣称UI完美。

### 工程与设备验证

准确工程命令：

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 verify
./scripts/dev.ps1 native-test
./scripts/dev.ps1 test -Extra '--concurrency=2','test/rest_share_ui_test.dart','test/rest_days_test.dart'
./scripts/dev.ps1 assemble
./scripts/dev.ps1 analyze
git diff --check
git diff --cached --check
```

完整verify日志ux01-verified.log：75个Dart文件格式无变化、analyze无问题、**249 Flutter/Dart通过**，debug构建通过，Kotlin JVM **13/13**（ReminderRules9、WidgetDisplay3、Feedback1）。本批新增22项：规则/真实SQLite11、UI11，覆盖暂停/休假边界/跳过、历史统计与归档交集、卡片、旧组件/世代、备份严格校验/回退/迁移、确认取消、输出隐私/摘录不改原文、独立按钮语义及中英×明暗320dp/160%/键盘布局。既有恢复中断/提醒/小事/日志/组件/导入全套通过。

最终可达性小修及中文用词后，针对本批22项再次通过，ux01-focused-final.log。最后英文单复数生成、format、assemble成功24.2秒，ux01-build-final.log；最终analyze见ux01-analyze-final.log。native-test构建成功7秒，ux01-native-verified.log。既有Kotlin/Gradle/Impeller迁移提示仍存在。中途四项大字号溢出失败已修成Wrap后通过；一项新测试缺少SemanticsAction导入导致analyze失败，修复后全249通过，不把失败运行计为验收。

最终APK：build/app/outputs/flutter-apk/app-debug.apk，**174898583 bytes**，SHA-256 **7b04e89c9763626bbcd01606637a27a043845f11196089e5fd908b4822255b0b**，已--no-streaming覆盖安装。非release包。

API28 emulator-5554实际执行：

```powershell
& $adb -s emulator-5554 install --no-streaming -r build/app/outputs/flutter-apk/app-debug.apk
& $adb -s emulator-5554 install --no-streaming -r build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
& $adb -s emulator-5554 shell am instrument --user 14 -w -e class 'app.daypanel.next.reminders.ReminderEngineTest,app.daypanel.next.CompletionFeedbackDeviceTest,app.daypanel.next.widgets.WidgetSnapshotTest,app.daypanel.next.widgets.WidgetLifecycleTest,app.daypanel.next.importing.LegacyReaderTest,app.daypanel.next.CardImageDeviceTest' app.daypanel.next.debug.test/androidx.test.runner.AndroidJUnitRunner
```

最终 **OK(24 tests)**，15.396秒，ux01-api28-final.log。含暂停取消/恢复提醒、v9休息与到期组件快照、PNG字节/私有URI只读授权/拒绝非图片；原提醒/组件实例生命周期/旧库读取回归继续通过。

设备真实操作全部在临时Android用户14 DayPanelUX01QA进行，界面创建Read a page与Evening walk（安装包无演示数据）。完成暂停取消/保存/恢复、实际日期范围休假保存/提前结束、单日跳过与取消。跳过第二项后日常应做变为1项，完成第一项正常得1张卡；后来恢复第二项仍保留卡。覆盖安装冷启动后跳过状态/记录/卡片保留。

分享页实际默认隐藏名称/心得，SAF取消后无成功提示，随后保存PNG成功；选择名称/输入摘录后再次导出，回卡背仍无原心得。系统分享面板实际出现短信/蓝牙目标，取消退出，没有发送。英文深色/160%字号预览与SAF导出成功；最终中文修词后再次保存并显示“图片已保存”。实际PNG已拉回检查：ux01-card-export.png 1115×1131、ux01-card-personal.png 1115×1416（早期中文“件小事”随后改为“个习惯”）；最终ux01-card-final.png与ux01-share-final.png对应最终中文，ux01-card-dark-large.png/ux01-share-dark-large-final.png是英文计数单复数修词前的布局证据。ux01-rest-final.png显示独立恢复按钮与最终标题，汇总ux01-overview.png。所有图片/日志在ignored .local/reports，不提交。

uiautomator个别次空root重试后正常；一次黑屏为休眠，唤醒后恢复。ADB普通shell无法读取次用户外部目录，使用模拟器root只读拉取/data/media/14文件，无App新增权限；此限制不当图片保存失败。未在主用户创建测试记录。ux01-device-errors.log无AndroidRuntime/flutter错误。

### 数据保留与交接

安装前关闭主用户进程归档pre-ux01-db.tar，最终主用户启动迁移v8→v9后关闭进程归档post-ux01-db.tar。`python .local/ux01_retention.py`逐表比较通过：原14表逐行完全一致（2习惯/1记录/2小事/1手记/原设置/计划/归档履历），新增habit_breaks空，foreign_key_check为空；ux01-retention-final.log。最终切回0、停止并删除14，系统只剩主用户；主Activity启动Status: ok。没有清库/覆盖主用户记录，原语言和主题保持。

本批实现及上述范围验收完成；FL19仍需厂商真机、真正TalkBack手工、本批API35/36分享和休息矩阵、第三方接收App/文件提供器、长时间Doze、Launcher休息到期全矩阵和手机大数据性能，不称全设备无BUG。下一步继续FL19系统回归及发现问题修复；应用锁/手记附件等仍未承诺，不自行扩范围。电脑及可见API28模拟器保持运行，不推送远端。
