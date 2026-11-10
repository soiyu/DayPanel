# QA02 全功能与UI自测记录

**日期：2026-11-10。本轮修复与可执行自测已完成；真机、自然跨日和未覆盖分支保持待验。**

本轮按145项真实使用路径执行功能与UI自查。原清单应用基线为UI05 `a76f05d`，当前修复起点为RT01 `e142de8`。完整测试数量、设备片段数或截图数量均不等于145条人工路径全部通过。本报告不作“全145通过”的结论，也不预填用户真机结果。

## 版本与证据边界

|层级|本报告采用的证据|可以说明什么|不能替代什么|
|---|---|---|---|
|纯领域/SQLite/控制器|本次fresh测试日志、真实内存或文件SQLite|规则、事务、查询与数据保护断言|完整UI操作、手机后台或自然时间经过|
|Widget操作|点击/输入/滚动/取消/保存/返回及数据断言|指定App路径在测试环境可执行|Android系统选择器、通知权限、Launcher及用户理解|
|Flutter实际渲染|RepaintBoundary PNG，中文/英文、正常长屏与窄短屏160%字号|这些尺寸/字体/状态下的布局、按钮、键盘与文字|物理真机像素、全部系统字体/显示缩放、人工TalkBack|
|API28现场片段|`.local/reports/qa02-device-results.jsonl`及对应截图|明确标注RT01/QA02的已操作片段|整个同编号路径及其它API/厂商设备|
|最终QA02包|上述SHA-256、覆盖安装与API28现场截图|本包指定操作与状态|未经执行的自然跨天、完整周、真机省电条件|

**包与现场操作分开记录：** 前半段使用RT01包（e142de8）建立样本并走通知、数量、任务、手记和文件选择器。执行主机日志2026-11-10 19:28覆盖最终QA02包后，复测了数据保留、桌面操作/多实例/缩放、删除返回/关联保留、320dp英文深色160%字号、离线强停重开、真实重启与恢复后旧组件。145条映射中设备片段只证明明确执行的步骤，不表示同编号全部分支通过。

最终APK：`build/app/outputs/flutter-apk/app-debug.apk`，**174996890 bytes**；SHA-256：`1aec4ab0362a10490269e9e9f329c8059be12adfa6b1e163bd333fa1bed0d6dd`。本批无数据库升级，SQLite11/备份schema11保持。保留并审查了工作区已有配色、细边、阴影及今天圆点调整，一起纳入交付，使包与提交内容一致；不把这些审美调整冒称为已复现BUG。

最终常规整套 **404项通过**（3:47，`qa02-final-suite.log`），独立进程恢复 **6项通过**（28秒，`qa02-process-tests.log`），两批无重叠。追加E/F/G操作专项9项通过，**本轮419个不同Flutter/Dart测试全部通过**；最后加固后的锁保护5项也再次通过，不重复计数。下文123/24/14/5/4/2等专项与完整运行有重叠，不能相加。Kotlin JVM **14项通过**；API28原生 **37项通过**（43.943秒，`qa02-api28-final.log`）。

## 已复现的问题与修复证据

|问题|复现方法与实际失败|已采取的修复|已有验证及仍需补充|
|---|---|---|---|
|短暂数据库锁导致读取或写入启动失败|两个独立连接、busy_timeout=0，第一连接BEGIN IMMEDIATE持锁140ms；第二连接冷load和写事务原先返回失败。`qa02-lock-before.log`。|只在事务体尚未进入且BEGIN因BUSY失败时有界重试；事务体/提交失败不重放；等待后检查generation。启动页等待新Future时不继续展示旧错误状态。|`test/qa02_contention_test.dart`五项通过，`qa02-lock-final.log`；覆盖短锁、长锁有界失败、只写一次、等待中恢复世代变化、事务体失败回滚不重放。并不证明此前所有手机启动错误都源于同一个锁；最终包离线冷开、强停重开、重启后打开已执行；重启/解锁一度需要等待系统就绪。600ms是显式退避累计值，不是所有设备总耗时上限；没有注入COMMIT失败。|
|卡片失效说明贴屏边|恢复/缺失卡片后CardDetails直接挂EmptyState，中文/英文320×568、414×921四组合实际正文左边界为0；`qa02-content-new-first.log`及missing-card-before截图。|SafeArea内全宽ListView、20dp左右留白、可滚动和返回箭头；保留失效数据保护。|24组合中的四项失效页断言现通过，`qa02-content-new-final.log`及missing-card-fixed截图。|
|窄屏大字号Cancel断成两行|英文320dp/160%数字输入页，真实RenderParagraph行数2；`qa02-habit-ui-regression-before.log`。|共享操作按钮按内容需要响应布局，避免用固定不合理比例挤压取消文字；不得把文字整体缩到难读。|`qa02-habit-ui-fixed.log`、`qa02-visual-footer-fixed.log`，截图与行数/触达断言复核。四处底栏均在窄屏大字改为1:1；最终包外观页实际系统字体截图确认Cancel单行。|
|导航标签断词/可读性不足|同一渲染路径中英文主导航、统计导航在320dp/160%断词；`qa02-navigation-before.log`。|统计按真实字体宽度从四栏调整至两列/必要时一列；底部导航窄屏大字减少外侧留白；保留标签、选择和点击语义。|导航专项4项通过，已纳入404项最终整套；API28最终包实际320dp/160%英文深色截图确认标签完整。|

|长标题挤走记录与统计表|320dp/160%长习惯名称，记录按钮不可点击、当天表格单元首屏不可见，修复前2项失败。`qa02-long-titles-before.log`。|习惯列表标题与已选统计习惯名限两行省略，完整名称留在语义、详情和选择面板。|`qa02_long_titles_test.dart`2项通过，中英文均实际点击记录/取消与当天格；已纳入404项最终整套。|

## 内容域测试方法与截图

- 现有H/I/J/M/N专项 fresh **123项通过**63秒：`.local/reports/qa02-content-existing.log`。涵盖日志/统计/卡片/外观/备份的UI、领域和数据测试；并非123个独立人工用例。
- 新 `test/qa02_content_journeys_test.dart` **24组合通过**28秒：`.local/reports/qa02-content-new-final.log`。配置为中文/英文各414×921、100%、浅色，以及320×568、160%、深色。截图加载项目本地书页字体和MaterialIcons；它们是受支持书页主题的实际Flutter渲染，不能称为系统字体真机截图。
- 图像文件使用 `.local/reports/qa02-content-{语言}-{long-normal或short-large}-{页面}.png`。复核样例：`qa02-content-zh-short-large-missing-card-fixed.png`、`qa02-content-en-short-large-backup-invalid-visible.png`、`qa02-content-en-short-large-share-keyboard.png`。早期before截图可能含测试字体块，只作失败记录，不作最终UI通过图。
- 最后一项备份提示finder失败来自ListView错误提示未构建于可视区：改为真实滚动至提示、断言hitTestable并截图；没有改备份业务逻辑或删除断言。A/B全表对照、预览取消、确认恢复、回退和错误文件拒绝均已在四组合执行；系统文件选择仍是模拟接口。

## 逐项映射的读法

“自动化路径/子集”表示此处明确写出的步骤被执行，不默认整条人工用例完成；“部分”保留未执行的步骤；“待实测/自然观察”不得升格为通过。一个编号可能同时有Widget证据、领域证据和RT01设备片段，它们应合并理解但不能把缺少的步骤补成事实。

对K/L/P系统类，截图/工程断言必须与手机通知、桌面、安装和重启分开；对Q类，固定日期fixture只能证明规则，不能声称自然跨天/完整周/跨月已实际等待。下表收集可追溯工程证据与实际设备动作，限制一并保留。


## 准备与安装

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**A01 确认安装的是本轮版本**|RT01包 API28实际片段：隔离用户空态无演示；模板取消不创建；保存阅读到今日概览。证据：`qa02-device-results.jsonl`及其中截图名。|已核对本报告最终APK哈希并实际覆盖安装；145路径原文的a76f05d为清单历史基线。|
|**A02 首次空态**|RT01包 API28实际片段：隔离用户空态无演示；模板取消不创建；保存阅读到今日概览。证据：`qa02-device-results.jsonl`及其中截图名。|设备片段按左侧包版本与动作限定。|
|**A03 先建立三项固定样本**|RT01包 API28实际片段：三类样本已创建，观察到今日已获卡；快照核对见右侧限制说明。证据：`qa02-device-results.jsonl`及其中截图名。|设备样本覆盖完成/数量/次数；新建后今日详情与不自动记录另有自动化断言。|
|**A04 首轮先测与记录方式**|已记录API28模拟器/系统Launcher/2026-11-10及145项逐项证据。|报告未覆盖的分支保持待测；不替用户填写其真机结果。|

## 新建与模板

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**B01 打开与取消不创建**|习惯域Widget实际子路径：All16 select/cancel noDB change; custom draft cancel；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>RT01包 API28实际片段：隔离用户空态无演示；模板取消不创建；保存阅读到今日概览。证据：`qa02-device-results.jsonl`及其中截图名。|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>设备片段按左侧包版本与动作限定。|
|**B02 模板搜索与自定义承接**|习惯域Widget实际子路径：Actual search match and nonmatch custom title retained；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**B03 图标建议尊重手选**|Flutter自动化：test/habit_templates_test.dart『custom name suggests icon but manual selection survives later typing』实际自定义输入Read a page，验证建议图标2，手选18，再改名Drink water并保存后仍为18；另『existing icon changes only after applying the suggestion』验证已有习惯建议须主动应用。本轮qa02-final-suite.log整套404通过，包含该文件。|实际Flutter界面+SQLite测试；不是本轮手机手点。语言文案Read/Drink water用于图标逻辑，未逐个图标重新人工观察。|
|**B04 名称与必填校验**|习惯域Widget实际子路径：Count targets0/1.5 rejected; qty invalid strings separately；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**B05 安排需要主动选择的模板**|习惯域Widget实际子路径：Four uncertain templates cannot save before schedule chosen；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**B06 历史日期中新建不会像丢失**|test/pm04_editor_flows_test.dart『new count keeps searched title and opens visible today detail without clearing context』先选择昨天并设置morning筛选，从目录创建Practice scales，保存后HabitDetails.initialDay==today、app.selectedDay仍为昨天且记录为空。qa02-final-suite.log有该测试名，404整套通过。|自动化覆盖历史选择中新建的今日详情落点和保留原选择；未在此测试实际点返回或直接断言保存startDay字段，不能记整条设备路径通过。|
|**B07 不匹配筛选中新建**|同test/pm04_editor_flows_test.dart『new count keeps searched title and opens visible today detail without clearing context』在morning筛选下创建默认其他时段习惯，保存打开其详情且app.contextFilter仍为morning；test/pm04_root_paths_test.dart『filter empty state clears filters without adding duplicate habit』验证清除筛选不新增重复习惯。qa02-final-suite.log404通过。|自动化分别覆盖新建可见详情与筛选重置；未在一条设备路径中返回原筛选后再重置并肉眼查找。|

## 16个模板快速核对

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**T01 喝水**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T02 阅读**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T03 散步**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T04 拉伸**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T05 跑步**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T06 骑行**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T07 学外语**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T08 练习乐器**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T09 按时睡觉**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T10 写日记**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T11 吃早餐**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T12 整理房间**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T13 照顾植物**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T14 画画**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T15 力量练习**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**T16 放下手机**|习惯域Widget实际子路径：Four profile actual catalog search -> select -> draft title/kind/target/unit/choice schedule -> cancel; no data written；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|

## 完成、数量与次数

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**C01 完成与恢复待做**|test/app_widget_test.dart『first run is empty, creates a real habit, logs and reopens it』从创建进入详情，Complete后唯一记录1000，Reopen后记录为空，返回日常仍有相同习惯；test/action_first_layout_test.dart中英×正常/160%『first-screen actions remain visible』实际点日常第一习惯完成并断言1000。qa02-final-suite.log404通过。|实际Flutter操作+真实SQLite自动化；包括列表完成及详情完成/恢复，未在本条新增模拟器逐次完整来回截图。|
|**C02 处理中重复操作**|test/store_test.dart『repeated explicit habit completion remains one record』连续两次setRecord(1000)只存一行；test/home_widgets_test.dart『duplicate widget completion is explicit, earns one card, feedback once and refreshes』验证重复明确完成不会多发卡/反馈；test/pm_editor_context_test.dart『quantity save cannot be submitted twice while waiting』以未完成Future保持处理中，按钮onTap为空、busy为true、保存回调一次。均属qa02-final-suite.log404整套；qa02-full-tests.log直接记录quantity busy测试。|覆盖存储幂等及数量输入处理中防重复；尚非日常布尔完成按钮被阻塞时快速物理连点的同一测试，不把静态PendingIntent当物理点击ID。|
|**C03 按量保存与快捷草稿**|习惯域Widget实际子路径：Real quantity sheet replace draft/save；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>RT01包 API28实际片段：真实UI快捷5页保存后5/10。证据：`qa02-device-results.jsonl`及其中截图名。|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>设备片段按左侧包版本与动作限定。|
|**C04 本次量取消与确认**|习惯域Widget实际子路径：5+2 draft cancel leaves5; save7；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>RT01包 API28实际片段：本次2预览7，取消仍5；同一路径确认后7/10。证据：`qa02-device-results.jsonl`及其中截图名。|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>设备片段按左侧包版本与动作限定。|
|**C05 修改总量不会叠加**|习惯域Widget实际子路径：7 replaced3, not added；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>RT01包 API28实际片段：修改总量3后3/10非累加。证据：`qa02-device-results.jsonl`及其中截图名。|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>设备片段按左侧包版本与动作限定。|
|**C06 零值和清除记录**|习惯域Widget实际子路径：Zero saved asrecord then clear removes；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>RT01包 API28实际片段：显式0可见，清除后未记录。证据：`qa02-device-results.jsonl`及其中截图名。|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>设备片段按左侧包版本与动作限定。|
|**C07 整数次数主流程**|习惯域Widget实际子路径：Actual count1 plus2 yields3; weekly contribution one day；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>RT01包 API28实际片段：整数1加本次1后2/3。证据：`qa02-device-results.jsonl`及其中截图名。|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>设备片段按左侧包版本与动作限定。|
|**C08 次数拒绝小数**|习惯域Widget实际子路径：1.5count rejected; valid integer accepted；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>RT01包 API28实际片段：小数1.5次数拒绝且保留输入。证据：`qa02-device-results.jsonl`及其中截图名。|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>设备片段按左侧包版本与动作限定。|
|**C09 距离和时长仍支持小数**|test/store_test.dart『zero is a real quantity, thousandths exact, future/start protected』验证千分之一精度；test/count_records_test.dart『count enforces whole targets and daily values without rewriting quantity』验证count拒绝分数但quantity可存1250；test/home_widgets_ui_test.dart『quantity confirmation saves total once and returns home』实际界面输入250.001并精确存250001；test/pm04_editor_flows_test.dart『integer suggestions and editable template schedules have explicit semantics』断言km目标2500快捷值含2500。qa02-final-suite.log404通过。|自动化已覆盖数量小数与次数整数分界，但未完整实走跑步2.5km、练琴7.5分钟两个指定模板保存路径，保留为该条的部分证据。|
|**C10 非法数量与超目标**|习惯域Widget实际子路径：negative/4decimals/text rejected；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。|
|**C11 并发旧输入保护**|test/pm04_editor_flows_test.dart『ABA after opening numeric form is rejected and reload is deliberate』打开输入后外部把1000改2000再回1000，旧提交被拒且出现reload，主动重载再提交才存2000；test/count_records_test.dart『revision guarded submission cannot be replayed or overwrite ABA』『controller reloads after conflict and old generation cannot write after restore』『two independent connections cannot both commit one captured total』覆盖修订、generation及真实双连接竞争。qa02-final-suite.log404通过，ABA UI名在日志可追溯。|通过受控写入/真实SQLite独立连接模拟并发；未把Android多Activity页面能否被厂商保留的分支算通过。|

## 安排、编辑与日期

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**D01 星期安排与计划外记录**|补充工程部分步骤：实际首页无安排项经“记录其他习惯”进入对应日并保存，安排未改变；星期规则由领域测试验证。<br>证据：`test/pm04_root_paths_test.dart`：unplanned activity can reach selected date and record without changing plan；`test/domain_test.dart`：weekly schedule respects actual weekday, start and archive；`.local/reports/qa02-full-tests.log`|测试对象由fixture建立，未通过UI新建只选明天星期；未以真机确认首页分组。|
|**D02 间隔安排**|补充工程部分步骤：间隔2天锚点、跨DST/跨年、明天新计划按日期判断；未来记录拒绝。<br>证据：`test/plans_test.dart`：target/unit/schedule edit starts tomorrow, historical values and judgment stay stable；`test/plans_test.dart`：calendar intervals cross DST and year without elapsed-hour assumptions；`test/store_test.dart`：zero is a real quantity, thousandths exact, future/start protected；`.local/reports/qa02-full-tests.log`|没有实际新建隔日习惯并逐点今天/明天/后天UI；自然跨天待测。|
|**D03 周目标按天计算**|习惯域Widget实际子路径：Weeklycounttarget3 stored; dailyplanned empty；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>补充工程部分步骤：UI新建weekly3天并进入本周可记录；次数目标当日多次保存仍1达标日；每日义务不纳入weekly。<br>证据：`test/m2_widget_test.dart`：weekly habit editor persists rule and shows flexible group instead of daily obligation；`test/qa02_habit_journeys_test.dart`：QA02 C07/C08/B04/D05 integer counts and schedules cannot silently save invalid drafts；`test/plans_test.dart`：weekly count counts achieved days, stops at selected day and resets at Monday；`.local/reports/qa02-full-tests.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>布尔weekly的同一路径完成→撤销→重做未串成完整单用例；按日计数的领域证据充分但不称真机。|
|**D04 周目标搭配数量**|习惯域Widget实际子路径：Count1/3 no qualifyingday,3/3 one day (quantity-like goal)；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>补充工程部分步骤：次数1/3到3/3经真实输入，周达标数由0变1；普通数量值低于/达到目标按周达标日统计。<br>证据：`test/qa02_habit_journeys_test.dart`：QA02 C07/C08/B04/D05 integer counts and schedules cannot silently save invalid drafts；`test/plans_test.dart`：weekly count counts achieved days, stops at selected day and resets at Monday；`test/statistics_test.dart`：weekly historical values do not cross versions and range edges are not counted；`.local/reports/qa02-full-tests.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>手工指定5页→10页→20页的完整UI串未执行；没有周累计次数模型。|
|**D05 安排参数校验**|习惯域Widget实际子路径：Weekly0/8 rejected then3 accepted；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>补充工程部分步骤：实际表单周目标0/8拒绝，改3成功；interval2合法并持久化。<br>证据：`test/qa02_habit_journeys_test.dart`：QA02 C07/C08/B04/D05 integer counts and schedules cannot silently save invalid drafts；`test/qa02_habit_journeys_test.dart`：QA02 D07/D08 editing quantity plan preserves today and historical units；`.local/reports/qa02-full-tests.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>未发现间隔0/366表单逐项执行证据，不用共用validator源码当通过。|
|**D06 编辑非计划属性与取消**|补充工程部分步骤：真实新建装扮图标/色/边框保存、已有类型只读、明天提示就近；外观页预览取消有测试。<br>证据：`test/appearance_ui_test.dart`：habit style picker saves named icon color and frame without a completion；`test/pm_editor_context_test.dart`：existing type is read only and advanced settings are progressively disclosed；`.local/reports/qa02-full-tests.log`|习惯编辑中的改名/时段/图标/颜色/边框全部取消再保存未以一条完整使用路径覆盖；不能拿全局外观取消替代习惯编辑取消。|
|**D07 明天生效的计划变更**|习惯域Widget实际子路径：UI edits20minutes/interval2; today still10pages, tomorrownew (controlledclock)；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>补充工程部分步骤：实际编辑20分钟/interval2并保存；今天仍10页，明天20分钟；计划版本领域断言。<br>证据：`test/qa02_habit_journeys_test.dart`：QA02 D07/D08 editing quantity plan preserves today and historical units；`test/plans_test.dart`：same-day changes replace future plan and reverting removes redundant version；`.local/reports/qa02-full-tests.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>UI展开计划历史并核对文字未在该新聚合用例中执行；自然明天不在此结果内。|
|**D08 新建日前和未来不可写**|习惯域Widget实际子路径：Futurestore write rejects; UI picker future not executed；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>补充工程部分步骤：未来/创建前数值写入在store拒绝；统计未来格子/未来年历禁用已有UI检查。<br>证据：`test/store_test.dart`：zero is a real quantity, thousandths exact, future/start protected；`test/statistics_ui_test.dart`：table opening cancel explicit save clear and future dates preserve intended day；`test/statistics_ui_test.dart`：leap day is real and future calendar cells are disabled；`.local/reports/qa02-full-tests.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>没有通过首页新建项逐选昨天明天的完整UI链；不把controller定位等同实际日期选择。|

## 分组、筛选与排序

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**E01 分组建立和改名**|习惯域Widget实际子路径：Actual groupcreate/rename/duplicatevalidation；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>补充工程部分步骤：真实UI分组新建、改名、重复名保存拒绝。<br>证据：`test/qa02_habit_journeys_test.dart`：QA02 E01/E05 groups create rename duplicate reject and cancelled delete preserve records；`.local/reports/qa02-full-tests.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>空白名称UI保存未单独执行；真机待核。|
|**E02 情境与分组交集**|补充工程部分步骤：store建立group/context，controller过滤无匹配仍保留allDailyPlanned；新建后保存原筛选。<br>证据：`test/plans_test.dart`：deleting group clears membership, keeps habit history; ordering validates full set；`test/pm04_editor_flows_test.dart`：new count keeps searched title and opens visible today detail without clearing context；`.local/reports/qa02-full-tests.log`<br>最终追加真实Widget路径：中英文真实编辑时段/分组，打开两个筛选控件，交集仅显示目标项；重置后全部3项回来。 `test/qa02_remaining_journeys_test.dart`；`qa02-remaining-and-lock-final.log`。|上述App内路径已由真实控件+SQLite断言执行；不替代物理手机触控/系统后台，未描述的其他分支保持待验。|
|**E03 无结果可一键恢复**|补充工程核心动作：HomePage无匹配筛选→点Clear filters→原项可见，数据库数量不变。<br>证据：`test/pm04_root_paths_test.dart`：filter empty state clears filters without adding duplicate habit；`.local/reports/qa02-full-tests.log`|筛选起点通过controller设置；清除动作真实Widget点击，仍非手机结果。|
|**E04 排序保存与取消**|补充工程部分步骤：管理分组入口/实际上移下移保存排序并保留记录；领域排序完整集合校验。<br>证据：`test/m2_widget_test.dart`：group create and reorder arrows persist without deleting records；`test/plans_test.dart`：deleting group clears membership, keeps habit history; ordering validates full set；`.local/reports/qa02-full-tests.log`<br>最终追加真实Widget路径：真实排序下箭头先返回取消再保存；从第三项拖手柄到顶部并保存，重开存储顺序为Third/Second/First。 `test/qa02_remaining_journeys_test.dart`；`qa02-remaining-and-lock-final.log`。|上述App内路径已由真实控件+SQLite断言执行；不替代物理手机触控/系统后台，未描述的其他分支保持待验。|
|**E05 删分组保留事项**|习惯域Widget实际子路径：Canceldeletepreserves; confirmdeleteonlyungroupshabit；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>补充工程核心动作：UI删除分组先取消保持，确认后清除分组、习惯保留且groupId为空；既有record存续有store覆盖。<br>证据：`test/qa02_habit_journeys_test.dart`：QA02 E01/E05 groups create rename duplicate reject and cancelled delete preserve records；`test/plans_test.dart`：deleting group clears membership, keeps habit history; ordering validates full set；`.local/reports/qa02-full-tests.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>测试关联关系先由fixture设定；没有真机文件或系统行为。|

## 休息、归档与删除

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**F01 跳过与取消跳过**|习惯域Widget实际子路径：Actual skipcancel/save/unskip; no recordcreated；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>补充工程核心动作：真实详情skip取消不写→确认产生休息→取消跳过恢复，未生成完成；日/周统计休息不计完成失败。<br>证据：`test/qa02_habit_journeys_test.dart`：QA02 F01/F03 pause and skip preserve or remove only intended rest while records remain real；`test/rest_share_ui_test.dart`：skip confirmation preserves cancel and clears only selected rest；`test/rest_days_test.dart`：daily completion denominator and streak pass rest without counting success；`.local/reports/qa02-full-tests.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>冻结日期与内存库，不是自然日期真机实测。|
|**F02 不适用的跳过入口**|补充工程部分步骤：无安排日不显示skip，weekly确认说明完整周影响；归档skip只读；已有0值/未来skip领域拒绝。<br>证据：`test/pm_habit_context_test.dart`：non-scheduled day offers no meaningless skip, weekly skip explains the week；`test/pm_habit_context_test.dart`：archived skip and historical vacation expose no current rest-management action；`test/rest_days_test.dart`：skip never deletes a value, duplicates stay one row and removal is explicit；`test/rest_days_test.dart`：overlaps invalid dates archived future skips and stale finish reject without changes；`.local/reports/qa02-full-tests.log`|已有记录/未来日的每个UI入口未全部逐个点击；本文件不声称全设备。|
|**F03 暂停与恢复**|习惯域Widget实际子路径：Actual pause/resume preservescompletedvalue；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>补充工程部分步骤：真实暂停确认取消/保存/恢复；已完成记录保留，active计数恢复；旧页/旧组件跨pause写入拒绝。<br>证据：`test/qa02_habit_journeys_test.dart`：QA02 F01/F03 pause and skip preserve or remove only intended rest while records remain real；`test/rest_share_ui_test.dart`：pause confirmation cancel stays active; save pauses; explicit resume restores；`test/rest_days_test.dart`：old widget record and old rest page cannot cross pause or restored generation；`.local/reports/qa02-full-tests.log`|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>真实通知取消与Launcher刷新需要原生/设备证据，不能从Widget状态自动判定。|
|**F04 未来休假与取消**|补充工程部分步骤：数据层休假起止inclusive，到结束后次日恢复适用；未来安排可取消的部分需继续核查。<br>证据：`test/rest_days_test.dart`：vacation inclusive boundaries and tomorrow expiry restore normal eligibility；`.local/reports/qa02-full-tests.log`<br>最终追加真实Widget路径：真实日期范围输入明日起3日休假：取消不写；确认后今天不休息，明天开始；取消未来休假清除安排。 `test/qa02_remaining_journeys_test.dart`；`qa02-remaining-and-lock-final.log`。|上述App内路径已由真实控件+SQLite断言执行；不替代物理手机触控/系统后台，未描述的其他分支保持待验。|
|**F05 冲突和长休假校验**|补充工程部分步骤：数据层重叠、过去pause、未来skip、超过365天、归档及stale finish拒绝且不写。<br>证据：`test/rest_days_test.dart`：overlaps invalid dates archived future skips and stale finish reject without changes；`.local/reports/qa02-full-tests.log`<br>最终追加真实Widget路径：真实日期范围控件选择重叠及366天跨度，分别出现冲突/范围提示且已保存表不变。 `test/qa02_remaining_journeys_test.dart`；`qa02-remaining-and-lock-final.log`。|上述App内路径已由真实控件+SQLite断言执行；不替代物理手机触控/系统后台，未描述的其他分支保持待验。|
|**F06 归档与取消归档**|补充工程部分步骤：归档保留记录、阻止写入和旧编辑复活；统计归档仍可看、卡片保留；reminder设置保留。<br>证据：`test/store_test.dart`：archive preserves entries; deletion cascades without stale resurrection；`test/statistics_ui_test.dart`：archived matrix remains visible but writes are disabled；`test/reminders_test.dart`：archive preserves reminder settings, deleting habit cascades reminders；`.local/reports/qa02-full-tests.log`|HabitLibrary归档→已归档→取消归档的完整真实UI链未见fresh专门测试；实际通知停排需要设备。|
|**F07 删除习惯的关联保留**|补充工程部分步骤：真实删除取消/确认后返回正确源页面；store习惯删除级联记录、journal文本关联解除、card快照心得保持。<br>证据：`test/delete_navigation_test.dart`：deletion cancellation does not unwind the route or remove the habit；`test/delete_navigation_test.dart`：daily detail settings deletion returns to daily without an unavailable page；`test/journal_test.dart`：archive keeps editable associations; delete habit retains text and date；`test/achievements_test.dart`：undo rename archive delete and added obligation keep earned snapshot and reflection；`.local/reports/qa02-full-tests.log`<br>QA02最终包 API28实际片段：最终包从日常详情设置删除先取消再确认，回日常无变形；关联文字保留并解除Stretch；已获卡与心得仍可看。证据：`qa02-device-results.jsonl`及其中截图名。|关联同一项的日志和已获卡→完整UI删除串未由单一测试执行，分层证据不能冒充真机端到端。<br>设备片段按左侧包版本与动作限定。|

## 一次性与常驻小事

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**G01 一次性无日期**|习惯域Widget实际子路径：Actual oncecreate withoutdate；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>补充工程核心动作：两语言短屏大字：实际小事tab→新建一次性无日期→保存未自动完成，后续可操作；其它普通taskform也持久化。<br>证据：`test/qa02_habit_journeys_test.dart`：QA02 G01/G03/G05/G06 $lang short-screen long tasks keyboard and actual today；`test/app_widget_test.dart`：task and journal forms persist real content；`.local/reports/qa02-full-tests.log`<br>RT01包 API28实际片段：真实一次性无日期表单保存Return book后进入未设日期分组，未自动完成。证据：`qa02-device-results.jsonl`及其中截图名。|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>没有真机；用测试标题而非手工清单还书标题。<br>设备片段按左侧包版本与动作限定。|
|**G02 一次性日期分组**|补充工程部分步骤：TaskTile标题进入详情、编辑入口存在；store变更dueDay保持实际完成日期。<br>证据：`test/pm_secondary_context_test.dart`：one-time title opens details without entering an editor；`test/store_test.dart`：task completion uses actual date; retry/edit preserves it; reopen keeps due date；`.local/reports/qa02-full-tests.log`<br>最终追加真实Widget路径：真实一次性日期选择今天/明天/昨天及清日期，列表分别进入对应分组，未自动完成。 `test/qa02_remaining_journeys_test.dart`；`qa02-remaining-and-lock-final.log`。|上述App内路径已由真实控件+SQLite断言执行；不替代物理手机触控/系统后台，未描述的其他分支保持待验。|
|**G03 一次性完成和重开**|习惯域Widget实际子路径：Actual oncecomplete/reopen usingcurrentstoredtask；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>补充工程核心动作：真实列表一次性完成→恢复待做；详情完成记录今天；store重复完成/编辑不改已完成实际日，重开保留原dueDay。<br>证据：`test/qa02_habit_journeys_test.dart`：QA02 G01/G03/G05/G06 $lang short-screen long tasks keyboard and actual today；`test/pm_secondary_context_test.dart`：one-time title opens details without entering an editor；`test/store_test.dart`：task completion uses actual date; retry/edit preserves it; reopen keeps due date；`.local/reports/qa02-full-tests.log`<br>RT01包 API28实际片段：一次性实际完成日为今天；恢复待做保留同一项；未实际改计划日为昨天。证据：`qa02-device-results.jsonl`及其中截图名。|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>widget和数据层拆分验证，不宣称手机端同一串执行。<br>设备片段按左侧包版本与动作限定。|
|**G04 完成历史入口**|补充工程部分步骤：完成历史页面以真实fixture渲染、日期纠正有residentUI；时间线按实际完成日进入任务。<br>证据：`test/resident_task_ui_test.dart`：$language ${dark ? 'dark' : 'light'} resident and history pages fit 320dp / 160%；`test/statistics_ui_test.dart`：timeline type filtering and note edit change saved content, empty month is explicit；`test/statistics_test.dart`：timeline uses task actual dates, all record types, zero values and stable order；`.local/reports/qa02-full-tests.log`<br>最终追加真实Widget路径：真实完成历史选择日期，两类条目分别打开一次性详情/常驻所选日期详情。 `test/qa02_remaining_journeys_test.dart`；`qa02-remaining-and-lock-final.log`。|上述App内路径已由真实控件+SQLite断言执行；不替代物理手机触控/系统后台，未描述的其他分支保持待验。|
|**G05 常驻新建与当天完成**|习惯域Widget实际子路径：Actual residentcreate/complete；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>补充工程核心动作：真实新建常驻无planneddate，完成写今天1条；下天重置用受控clock；重复set1条数据层保证。<br>证据：`test/qa02_habit_journeys_test.dart`：QA02 G01/G03/G05/G06 $lang short-screen long tasks keyboard and actual today；`test/resident_task_ui_test.dart`：create resident, complete today, and next day is unlogged without erasing yesterday；`test/resident_tasks_test.dart`：resident daily completion is explicit and idempotent; gaps create no rows or debt；`.local/reports/qa02-full-tests.log`<br>RT01包 API28实际片段：常驻Clear desk无截止日；真实记为完成后今天已做，不生成新项目。证据：`qa02-device-results.jsonl`及其中截图名。|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>受控clock不等于自然跨天；phone提醒/桌面不在这里。<br>设备片段按左侧包版本与动作限定。|
|**G06 常驻撤销与重新记录**|习惯域Widget实际子路径：Actual residentcomplete/reopen sameday; no duplicate；`test/qa02_habit_journeys_test.dart`、`.local/reports/qa02-habit-ui-fixed.log`<br>补充工程核心动作：列表完成/撤销实际写入；详情以initialDay昨天纠正，今天保持独立；历史记录再次设true不会重复。<br>证据：`test/qa02_habit_journeys_test.dart`：QA02 G01/G03/G05/G06 $lang short-screen long tasks keyboard and actual today；`test/resident_task_ui_test.dart`：history correction archive and unarchive use actual stored records；`test/pm_secondary_context_test.dart`：resident opens today, history secondary; passed date remains the write target；`test/resident_tasks_test.dart`：resident daily completion is explicit and idempotent; gaps create no rows or debt；`.local/reports/qa02-full-tests.log`<br>RT01包 API28实际片段：真实常驻撤销再记录后完成历史仍为1条，当天已做。证据：`qa02-device-results.jsonl`及其中截图名。|习惯域证据使用合成日期与内存SQLite；不自动覆盖本编号所有手工分支。<br>历史日是fixture和明确initialDay，非完整手机picker手势。<br>设备片段按左侧包版本与动作限定。|
|**G07 常驻历史边界**|补充工程部分步骤：store拒绝未来、创建前、缺失对象/错误类型；给定合法历史日期详情只改该日。<br>证据：`test/resident_tasks_test.dart`：future, pre-start, wrong type and missing task reject dated writes；`test/pm_secondary_context_test.dart`：resident opens today, history secondary; passed date remains the write target；`.local/reports/qa02-full-tests.log`|日期选择器可选边界未在测试中实际点击检查。|
|**G08 常驻位置不会被未来事项压住**|补充工程核心动作：10条未来任务fixture，首屏常驻主操作可见且今天最多一次。<br>证据：`test/pm04_paths_test.dart`：resident action appears before ten future tasks and remains once per day；`test/resident_tasks_test.dart`：resident daily completion is explicit and idempotent; gaps create no rows or debt；`.local/reports/qa02-full-tests.log`|任务由fixture设置，不通过新建重复10次；未做常驻没有欠账另有store证据。|
|**G09 常驻归档恢复**|补充工程部分步骤：详情more展开→archive→unarchive实际UI动作通过，history1条保留；归档时旧编辑不能恢复。<br>证据：`test/resident_task_ui_test.dart`：history correction archive and unarchive use actual stored records；`test/resident_tasks_test.dart`：archive retains history; old editor cannot unarchive; deletion cascades；`.local/reports/qa02-full-tests.log`|没有经过TasksPage归档入口再打开同项的整个UI链。|
|**G10 任务编辑取消和删除**|补充工程部分步骤：taskkind不可改；store删除级联resident记录、禁止旧编辑复活；once编辑保留due和done。<br>证据：`test/resident_tasks_test.dart`：archive retains history; old editor cannot unarchive; deletion cascades；`test/resident_tasks_test.dart`：task kinds and start dates are immutable; ordinary completion behavior unchanged；`test/store_test.dart`：task completion uses actual date; retry/edit preserves it; reopen keeps due date；`.local/reports/qa02-full-tests.log`<br>最终追加真实Widget路径：一次性/常驻分别菜单改名取消保留、保存生效；删除取消保留，确认清除任务和对应记录。 `test/qa02_remaining_journeys_test.dart`；`qa02-remaining-and-lock-final.log`。|上述App内路径已由真实控件+SQLite断言执行；不替代物理手机触控/系统后台，未描述的其他分支保持待验。|

## 手记与关联日志

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**H01 新增与取消**|内容域部分验证：journal_ui_test: detail creates dated linked journal without completing habit and opens all logs；内容域fresh日志见上节<br>RT01包 API28实际片段：实际保存独立正文并关联Stretch；未自动打卡；关联回看与删除保留继续验证。证据：`qa02-device-results.jsonl`及其中截图名。|新增关联日志保存且不完成习惯；未走独立手记首次新增＋取消全路径<br>设备片段按左侧包版本与动作限定。|
|**H02 编辑与返回**|内容域Widget路径：qa02_content_journeys_test: H search range and editor cancel/save with keyboard (4组合)；内容域fresh日志见上节|真实编辑取消/保存及数据库正文断言；键盘下保存可点击|
|**H03 过去日期和跨月文字**|内容域部分验证：journal_ui_test: editor changes date and association; cancel and system back do not write; qa02_content H；内容域fresh日志见上节|UI选择过去一天，跨月内容由fixture建立；未通过日期选择器跨到上月|
|**H04 扩展搜索保留关键词**|内容域Widget路径：qa02_content H; pm04_paths_test: empty month search expands range without dropping text or habit；内容域fresh日志见上节|当前月无结果→全部月份，保留关键词；既有专项同时保留习惯条件|
|**H05 关联习惯与日志入口**|内容域Widget路径：journal_ui_test: detail creates dated linked journal without completing habit and opens all logs；内容域fresh日志见上节<br>RT01包 API28实际片段：实际保存独立正文并关联Stretch；未自动打卡；关联回看与删除保留继续验证。证据：`qa02-device-results.jsonl`及其中截图名。|详情设置日志创建/查看/编辑，完成记录不变<br>设备片段按左侧包版本与动作限定。|
|**H06 月/日期/类型/关键词组合**|内容域部分验证：journal_ui_test: month navigation search and habit picker combine, date cancel does not filter; journal_test query intersect；内容域fresh日志见上节|月份、全部月份、习惯和关键词及日期取消/确定已测；独立筛选/清除全部组合未逐一UI操作|
|**H07 解除关联与换关联**|内容域部分验证：journal_test: dated linked note edits and unlinking survive close reopen without completion; journal_ui_test date/association cancel；内容域fresh日志见上节|数据层解除关联持久化；UI取消关联修改保持原值；未实际确认改成另一习惯|
|**H08 归档/删除习惯后的文字**|内容域部分验证：journal_test: archive keeps editable associations; delete habit retains text and date；内容域fresh日志见上节|数据层归档/删习惯保留文本日期及解除关联，未走完整归档/删除UI|
|**H09 删除手记**|内容域部分验证：journal_ui_test: delete confirmation cancellation keeps note; confirmation removes only note；内容域fresh日志见上节|真实删除取消/确认和库结果；未再次逐一搜索/时间线确认|

## 回顾与统计

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**I01 七日回顾到当天明细**|内容域部分验证：pm04_paths_test: review day opens that day with habits tasks and notes and no writes; qa02_content I；内容域fresh日志见上节|回顾点日期到混合事实明细且完整表不变；七日计数逐项对照不是新测试重点|
|**I02 打卡表横向查看与确认**|内容域Widget路径：statistics_ui_test: table opening cancel explicit save clear and future dates preserve intended day; qa02_content I table capture；内容域fresh日志见上节|真实格子确认/取消/清除及对应日期断言；固定名称列截图检查|
|**I03 数值格子按日期输入**|内容域部分验证：statistics_ui_test: quantity correction applies to selected date and stale sheet rejects restore; qa02_content I；内容域fresh日志见上节|数量格保存/取消/旧恢复页拒绝；count同输入核心由根其他测试覆盖，本子任务未单独点count格|
|**I04 单习惯数量统计**|内容域部分验证：qa02_content I quantities capture; statistics_test: quantity grouping includes exact zero but excludes missing dates and splits units；内容域fresh日志见上节|UI7天与量图渲染、领域合计/均值/记录日数；未逐个UI点击30/365和每根柱|
|**I05 每日与周统计适用性**|内容域部分验证：statistics_test daily denominator, weekly complete periods; pm04_paths historical numeric summary；内容域fresh日志见上节|条件日/周统计领域通过，纯周相关UI既有套件通过；不是自然完整周验收|
|**I06 年度记录日历**|内容域Widget路径：statistics_ui_test: annual overview selects month and actual calendar day opens record details; qa02_content I year screenshot；内容域fresh日志见上节|真实年历月/日进入明细；显式0保留|
|**I07 跨类型时间线**|内容域部分验证：statistics_ui_test: timeline type filtering and note edit change saved content, empty month is explicit; statistics_test timeline uses task actual dates；内容域fresh日志见上节|真实按类型筛选→手记编辑保存；全部类型领域汇总，未本次逐种点击任务/卡|
|**I08 空结果与查询不改数据**|内容域Widget路径：statistics_ui_test: archived matrix remains visible but writes disabled; leap day/future disabled; pm04_paths review/day read-only；内容域fresh日志见上节|无数据/归档/未来禁写/查询不改数据已断言；新图覆盖四tab空/非空布局|

## 成就卡与完成反馈

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**J01 获得当天一张卡**|内容域部分验证：achievements_test: daily obligations require all, last completion earns once; achievements_ui_test: claim from migrated completed data；内容域fresh日志见上节<br>RT01包 API28实际片段：三类样本已创建，观察到今日已获卡；快照核对见右侧限制说明。证据：`qa02-device-results.jsonl`及其中截图名。|实际卡片在当时仅阅读样本存在时解锁，快照1项；随后新增另外两习惯不重写已获卡。全部资格分支由领域测试覆盖。|
|**J02 正反面与快照**|内容域Widget路径：achievements_ui_test: earned card flips favorites edits reflection; qa02_content J card-front capture；内容域fresh日志见上节<br>RT01包 API28实际片段：成就卡翻背面收藏，心得已保存；截图实测。证据：`qa02-device-results.jsonl`及其中截图名。|真实翻背、卡片日期/当前记录保持；无副作用<br>设备片段按左侧包版本与动作限定。|
|**J03 收藏与心得**|内容域部分验证：achievements_ui_test earned card + collection filters; achievements_test favorite reflection persistent；内容域fresh日志见上节<br>RT01包 API28实际片段：成就卡翻背面收藏，心得已保存；截图实测。证据：`qa02-device-results.jsonl`及其中截图名。|UI收藏/筛选/心得保存取消清空；取消收藏持久规则数据层覆盖<br>设备片段按左侧包版本与动作限定。|
|**J04 撤销后卡片仍在**|内容域部分验证：achievements_test: undo rename archive delete and added obligation keep earned snapshot and reflection；内容域fresh日志见上节|数据层完成撤销/编辑/删除后的卡快照保留，不是完整UI连贯测试|
|**J05 分享预览的隐私选项**|内容域Widget路径：rest_share_ui_test: share defaults hide personal details; qa02_content J share draft；内容域fresh日志见上节|默认隐藏名字/心得，开关与修改摘录不改变原文，短屏键盘保留保存和分享按钮|
|**J06 保存图片与系统分享**|内容域部分验证：rest_share_ui_test: stale share page cannot export; qa02_content share keyboard screenshots；内容域fresh日志见上节<br>RT01包 API28实际片段：SAF取消未声称保存，随后成功保存PNG；系统保存真实PNG并打开系统分享选择器后取消，未发送。证据：`qa02-device-results.jsonl`及其中截图名。<br>QA02最终包 API28实际片段：从真实系统下载目录取回50187字节PNG并打开检查；图片名称与心得保持默认隐藏，分享选择器取消未发送。证据：`qa02-device-results.jsonl`及其中截图名。|UI预览/控件与旧世代保护；没有操作SAF保存、读取PNG或真实系统分享，交root设备验收<br>设备片段按左侧包版本与动作限定。|
|**J07 完成声/触感独立开关**|内容域部分验证：achievements_ui_test: reduced motion ... switches persist; achievements_test feedback requires saved transition；内容域fresh日志见上节|真实开关UI持久+模拟反馈服务条件；没有扬声器/触感真机结论|
|**J08 不应反馈或误领卡的场景**|内容域部分验证：achievements_test empty/weeklyonly/feedback; pm04_paths card empty state distinguishes no daily goal/rest；内容域fresh日志见上节|领域反馈排除条件和空卡册适用UI通过；系统静音/桌面后台需root设备|

## 习惯提醒

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**K01 配置与取消**|RT01包 API28实际片段：编辑取消未开启；本次保存实际未来提醒；API28没有运行时通知弹窗。证据：`qa02-device-results.jsonl`及其中截图名。|设备片段按左侧包版本与动作限定。|
|**K02 拒绝通知仍保存时间**|test/reminder_ui_test.dart『permission asked only on enabled save; denial retains times and cancel does not write』实际Flutter开关/保存，保存前不请求，保存后Fake平台拒绝通知仍保留enabled和时刻，再取消不改数据。qa02-final-suite.log明确记录且404整套通过。|通知权限平台是FakeReminderPlatform，属于界面/协调规则通过；API28没有Android13+运行时通知弹窗，本轮真实系统拒绝弹窗分支仍未测，普通打卡未受限不由本测试单独证明。|
|**K03 补开系统通知与精度**|RT01包 API28实际片段：编辑取消未开启；本次保存实际未来提醒；API28没有运行时通知弹窗。证据：`qa02-device-results.jsonl`及其中截图名。|设备片段按左侧包版本与动作限定。|
|**K04 1至5个时刻**|test/reminders_test.dart『invalid or missing habit reminder cannot be saved』拒绝空列表、越界、重复、6时刻；『multiple times persist sorted and disabling preserves config with revision』保存2时刻排序、关闭保留并重开数据库核对；test/reminder_ui_test.dart中英『reminders fit small screen large text in dark mode』预存5时刻后展示提醒中心/编辑器，保存按钮可点。qa02-final-suite.log404通过。|覆盖严格1–5模型/数据库边界与5时刻大字显示；尚未把UI连续添加第1到第5、试第6、删除再取消/保存全串路径称为执行完毕。|
|**K05 实际到达**|RT01包 API28实际片段：设备设10:31，10:34实际观察到阅读通知；未测秒级延迟或厂商省电。证据：`qa02-device-results.jsonl`及其中截图名。|设备片段按左侧包版本与动作限定。|
|**K06 通知去记录**|RT01包 API28实际片段：通知去记录直接进入数量输入，显示原总量5，取消未写入。证据：`qa02-device-results.jsonl`及其中截图名。|设备片段按左侧包版本与动作限定。|
|**K07 10分钟后**|RT01包 API28实际片段：点10分钟后原通知消失，后续再次观察到阅读通知；未连续计时到秒。证据：`qa02-device-results.jsonl`及其中截图名。|设备片段按左侧包版本与动作限定。|
|**K08 达到目标取消后续**|Kotlin单测ReminderRulesTest.countGoalControlsAllReminderTimesAsOneDailyTarget验证3次目标，1次时仍取当天下一时刻，3次后当天不再合资格并排到明天；API28原生ReminderEngineTest.schemaElevenCountKeepsRemainingRemindersUntilWholeTargetIsReached验证SQLite11真实count部分/达标读取；completionCancelsNoticeAndSchedulesNextEligibleDay验证通知实际取消并重排下一日。qa02-native-test.log构建成功；qa02-api28-final.log ReminderEngineTest9项、全37项通过。|原生回归用合成测试库/受控条件触发；不代表自然等两个未来时刻、数量和次数双模式以及厂商后台延迟全通过。|
|**K09 关闭、暂停、归档取消提醒**|ReminderRulesTest.archivedDisabledAndCompletedNeverRemindToday、weeklyTargetsResetMondayAndDoNotMixPlans、pauseAndVacationSuppressUntilInclusiveEndAndSkipOnlyOneDay覆盖禁用/归档/周目标/休息资格；API28 ReminderEngineTest.pauseCancelsNoticeAndResumeReschedulesFromDatabase、disableAndGenerationChangeRejectOldNotificationActions验证通知取消/暂停恢复/旧动作；Dart reminders_test『multiple times persist sorted and disabling preserves config with revision』『archive preserves reminder settings, deleting habit cascades reminders』验证配置保留。fresh qa02-native-test.log、qa02-api28-final.log37通过、qa02-final-suite.log404通过。|自动化/原生测试已覆盖这些规则；没有自然等待每个原时刻及OEM省电条件的完整实机链，不能取代K10。|
|**K10 真实省电与重新开启**|强停后重新打开、提醒配置重新列入系统调度已有API28证据（P04/P02），原生ReminderEngineTest覆盖回落条件。|真实厂商省电、长时间Doze和关闭再开启后自然到点提醒尚未等待，保持待验。|

## 桌面组件

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**L01 App内添加取消与确认**|QA02最终包 API28实际片段：最终包App内选择Practice后系统添加确认取消，Launcher没有新增实例；之前两种实例添加已实际完成。证据：`qa02-device-results.jsonl`及其中截图名。|已操作上述系统路径；其它Launcher/机型待验。|
|**L02 从真实桌面添加与取消配置**|RT01包 API28实际片段：已存在实例配置选阅读后取消，桌面仍绑定Stretch。证据：`qa02-device-results.jsonl`及其中截图名。|设备片段按左侧包版本与动作限定。|
|**L03 完成类直接完成与撤销**|RT01包 API28实际片段：实际Launcher中布尔组件取消完成再完成，均留在桌面；显式重复投递另由原生测试验证。证据：`qa02-device-results.jsonl`及其中截图名。|设备片段按左侧包版本与动作限定。|
|**L04 数量与次数直达输入**|RT01包 API28实际片段：数量组件直接打开输入；改11但取消后桌面仍10/10。证据：`qa02-device-results.jsonl`及其中截图名。<br>QA02最终包 API28实际片段：最终包组件数量输入确认11后桌面11/10；此前输入改值取消保持10。证据：`qa02-device-results.jsonl`及其中截图名。|设备片段按左侧包版本与动作限定。|
|**L05 一次性与常驻组件**|QA02最终包 API28实际片段：最终包原小事实例重新选一次性Return book，桌面直接完成且显示实际完成状态；常驻已另测。证据：`qa02-device-results.jsonl`及其中截图名。|已操作上述系统路径；其它Launcher/机型待验。|
|**L06 独立设置与详情**|QA02最终包 API28实际片段：最终包Launcher常驻取消完成再完成；数量习惯实例一直10/10未串绑定。证据：`qa02-device-results.jsonl`及其中截图名。|设备片段按左侧包版本与动作限定。|
|**L07 多个实例不串内容**|QA02最终包 API28实际片段：最终包Launcher常驻取消完成再完成；数量习惯实例一直10/10未串绑定。证据：`qa02-device-results.jsonl`及其中截图名。|设备片段按左侧包版本与动作限定。|
|**L08 缩放与大字号**|RT01包 API28实际片段：已存在实例配置选阅读后取消，桌面仍绑定Stretch。证据：`qa02-device-results.jsonl`及其中截图名。<br>QA02最终包 API28实际片段：恢复后仅重新配置习惯实例为阅读成功，小事仍明确需要重新选择；实例独立。证据：`qa02-device-results.jsonl`及其中截图名。|设备片段按左侧包版本与动作限定。|
|**L09 App编辑和无效内容联动**|QA02最终包 API28实际片段：真实Launcher长按组件拖右侧缩放手柄，3列到2列；查看名称/日期/进度/按钮；最终包实机渲染320dp/160%英文深色；外观Cancel单行，统计四入口无断词，2列数量和常驻组件文字操作可见。证据：`qa02-device-results.jsonl`及其中截图名。|设备片段按左侧包版本与动作限定。|
|**L10 移除只删桌面实例**|QA02最终包 API28实际片段：真实Launcher拖动习惯组件到移除，只有任务组件留下；回App阅读及10/10记录仍在。证据：`qa02-device-results.jsonl`及其中截图名。|已操作上述系统路径；其它Launcher/机型待验。|
|**L11 冷启动与旧详情不拦输入**|test/home_widgets_ui_test.dart『quantity opens directly; cancelling writes nothing』『quantity confirmation saves total once and returns home』实际WidgetEntryPage打开直接输入并取消/确认；API28 WidgetDirectActionDeviceTest.backgroundCompleteUndoAndDuplicateNeverOpenAnActivity执行后台明确完成/撤销/重复并检查前台仍在Launcher。fresh qa02-final-suite.log404及qa02-api28-final.log37通过。|仅支持直接输入路由与后台写不抢前台；这些测试没有先保留旧HabitDetails Activity再从桌面开数字组件，也没有划掉App后冷进程该整条路径，不把L11整体标通过。|
|**L12 恢复后旧组件与旧输入**|test/home_widgets_ui_test.dart『old quantity page after restore rejects write』旧输入页恢复后保存不能写且不关闭；home_widgets_test『restore and rollback invalidate old widget generation, backup stays schema8』拒绝旧generation，新generation可写并验证备份不含组件绑定；widget_direct_actions_test『restore and rollback never revive old generation or revision』保护旧动作。API28 WidgetLifecycleTest.savedBindingRejectsOldGenerationConfigDayArchiveAndDeletion实际绑定同一实例，更新generation后旧绑定失效，重新save当前generation的同实例绑定后有效。fresh qa02-final-suite.log404及qa02-api28-final.log37通过。<br>QA02最终包 API28实际片段：最终包实际恢复B后两个旧桌面实例都显示内容已变请重新选择；未自动恢复虚假Launcher实例，旧输入写入由generation自动化检查覆盖。证据：`qa02-device-results.jsonl`及其中截图名。|Flutter和原生分别覆盖旧页/旧动作拒绝及同实例重绑；未把先保留真实Launcher数字草稿→SAF恢复→旧页保存→Launcher重选的完整端到端路径称为通过。测试标题中schema8是既有名称，当前库/备份版本仍11。|

## 外观与语言

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**M01 主题预览、取消和保存**|内容域Widget路径：appearance_ui_test preview reset/cancel/save; qa02_content M with actual screenshots；内容域fresh日志见上节|主题预览/取消/保存真实选择及持久化；截图覆盖多色书页字体|
|**M02 明暗与跟随系统**|内容域部分验证：appearance_ui_test dark/light narrow checks; qa02_content four-combo theme；内容域fresh日志见上节|浅深布局通过；未真实切系统模式观察桌面跟随|
|**M03 字体、默认边框与重置**|内容域Widget路径：appearance_ui_test preview choices/reset never persist + save applies all choices atomically；内容域fresh日志见上节|系统/书页/边框/默认预览取消与保存；书页实际渲染图|
|**M04 中英文与用户文字**|内容域部分验证：qa02_content all H/I/J/M/N in zh/en；内容域fresh日志见上节|分别挂载中英文，未通过语言选择器切换并重启通知/桌面|
|**M05 免费与许可说明**|内容域未执行：none；内容域fresh日志见上节<br>QA02最终包 API28实际片段：最终包实机渲染320dp/160%英文深色；外观Cancel单行，统计四入口无断词，2列数量和常驻组件文字操作可见。证据：`qa02-device-results.jsonl`及其中截图名。|实际API28英文/中文、深色/浅色、320dp/160%与桌面缩放已查看；不覆盖所有主题/字体/厂家桌面组合。|

## 备份、恢复与换机

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**N01 先留一个完整基准A**|内容域部分验证：qa02_content N exports full bytes; backup_test round trip；内容域fresh日志见上节<br>RT01包 API28实际片段：通过Android文件选择器实际导出QA02-A.json；包含三习惯、两任务、一关联手记与已获卡片。证据：`qa02-device-results.jsonl`及其中截图名。|完整封套生成；模拟DocumentFiles，不是实际手机目录文件<br>设备片段按左侧包版本与动作限定。|
|**N02 导出取消与时间事实**|内容域部分验证：pm04_backup_flow_test cancelled export ... visible after reopening; qa02_content N；内容域fresh日志见上节<br>RT01包 API28实际片段：再次导出进入系统文件页后取消；App没有报告新导出成功。证据：`qa02-device-results.jsonl`及其中截图名。|模拟AndroidDocuments频道取消不记成功、成功时间重开；SAF原生时机另验<br>设备片段按左侧包版本与动作限定。|
|**N03 准备恢复差异B**|内容域部分验证：qa02_content N creates markerB and captures complete B export；内容域fresh日志见上节<br>RT01包 API28实际片段：A后新增B标记手记并真实导出QA02-B.json，系统文件页两份同时可见。证据：`qa02-device-results.jsonl`及其中截图名。|真实SQLite差异B与完整导出字节已做；文件接口为模拟<br>设备片段按左侧包版本与动作限定。|
|**N04 恢复预览取消**|内容域Widget路径：qa02_content N A-B preview cancel；内容域fresh日志见上节<br>RT01包 API28实际片段：A文件真实预览取消后B手记仍在。证据：`qa02-device-results.jsonl`及其中截图名。|实际预览确认页取消后所有表保持B，四组合截图<br>设备片段按左侧包版本与动作限定。|
|**N05 确认恢复A**|内容域Widget路径：qa02_content N restore A; backup_test transactional faults；内容域fresh日志见上节<br>RT01包 API28实际片段：真实系统文件恢复A后B手记消失，原关联手记保留；不是合并。证据：`qa02-device-results.jsonl`及其中截图名。|真实确认→完整表回A，备份/事务正常；输入文件接口模拟<br>设备片段按左侧包版本与动作限定。|
|**N06 恢复下一步与回退**|内容域部分验证：qa02_content N rollback; pm04_backup_flow_test Today/reconnect；内容域fresh日志见上节<br>RT01包 API28实际片段：恢复后今天入口进入日常；回退预览取消保留A，确认回退后B手记回来。证据：`qa02-device-results.jsonl`及其中截图名。|实际回退→所有表B、Today返回根标签、重连帮助不新增；未本子任务运行通知权限/Launcher<br>设备片段按左侧包版本与动作限定。|
|**N07 拒绝错误文件**|内容域Widget路径：qa02_content N invalid file + backup_test strict rejection；内容域fresh日志见上节<br>RT01包 API28实际片段：系统选择卡片PNG作为备份明确拒绝，回到手记B与A正文仍在。证据：`qa02-device-results.jsonl`及其中截图名。|模拟选择无关字节→真实错误提示滚至可见可点击，完整表不变；截屏backup-invalid-visible<br>设备片段按左侧包版本与动作限定。|
|**N08 恢复后冷开一致**|内容域部分验证：backup_test: full round trip ... survives reopen；内容域fresh日志见上节<br>QA02最终包 API28实际片段：最终QA02包覆盖安装且启动后，测试用户SQLite15表每字段相同；三习惯/两任务/两手记/卡片保留，桌面阅读实例仍在。证据：`qa02-device-results.jsonl`及其中截图名。|真实文件SQLite关闭重开保持；未从系统最近任务结束App后复核<br>设备片段按左侧包版本与动作限定。|
|**N09 可选第二台手机换机**|本域无适用设备条件：none；内容域fresh日志见上节|没有第二台物理Android设备，本子任务不宣称换机通过<br>第二台物理设备不存在时记不适用；不得在主用户卸载清数据凑换机。|

## 旧Loop导入（可选）

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**O01 选择文件与取消**|补充工程部分步骤：模拟LegacyFiles选择取消/预览取消保留所有表、generation与恢复副本。<br>证据：`test/legacy_import_ui_test.dart`：preview cancellation leaves records settings generation and recovery unchanged；`test/legacy_import_ui_test.dart`：cancelled new file selection does not authorize stale preview after restore；`.local/reports/qa02-full-tests.log`|文件选择器是假接口，输入是合成解析Map；没有选择用户真实Loop.db或真实SAF。<br>仅真实兼容Loop文件可做人工流程；领域fixture通过不等于用户旧库已迁移。|
|**O02 预览选择与频率确认**|补充工程部分步骤：合成预览需要显式安排且周数8拒绝；未完成配置不允许继续；追加前无业务写。<br>证据：`test/legacy_import_ui_test.dart`：rolling frequency requires explicit schedule and valid count；`test/legacy_import_test.dart`：unknown history is not failed, interval starts on import day, weekly does not become daily；`.local/reports/qa02-full-tests.log`|未用真实.db/SAF，未逐项检查空选择和上一步选择保留；未知历史规则仅domain。<br>仅真实兼容Loop文件可做人工流程；领域fixture通过不等于用户旧库已迁移。|
|**O03 追加与重复身份**|补充工程部分步骤：合成LegacyFixture追加、旧内容保留、重复稳定identity不覆盖、不生成卡片，UI确认后提交且重复项禁选。<br>证据：`test/legacy_import_ui_test.dart`：subset explicit confirmation imports and second preview marks duplicates；`test/legacy_import_test.dart`：append preserves all existing facts, gives full rollback and never earns cards；`test/legacy_import_test.dart`：reimport skips changed existing identities and does not replace recovery or records；`.local/reports/qa02-full-tests.log`|这是合成逻辑格式fixture，不是用户真实备份文件；本轮用户没有旧数据，真实导入仍条件未测。<br>仅真实兼容Loop文件可做人工流程；领域fixture通过不等于用户旧库已迁移。|
|**O04 不支持范围与导入回退**|补充工程部分步骤：坏逻辑Map/unsupported至多在UI不可提交，领域不支持版本/非法引用/值拒绝；导入前副本restore rollback逐表一致。<br>证据：`test/legacy_import_ui_test.dart`：bad file and unsupported target are visible without writes；`test/legacy_import_test.dart`：malformed references values dates duplicates and unsupported versions reject whole input；`test/legacy_import_test.dart`：append preserves all existing facts, gives full rollback and never earns cards；`.local/reports/qa02-full-tests.log`|没有真实ZIP/CSV/损坏.db文件系统路径；没有从系统picker到回退的全UI串。<br>仅真实兼容Loop文件可做人工流程；领域fixture通过不等于用户旧库已迁移。|

## 真机系统与稳定性

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**P01 离线和重开**|补充工程部分步骤：真实磁盘DB关闭重开保留habit/task/note/preferences；新独立连接锁竞争后coldload恢复；其它widget流程在离线cached依赖执行。<br>证据：`test/store_test.dart`：real file survives close/reopen with habits tasks notes preferences；`test/qa02_contention_test.dart`：P01 cold load survives a short independent reader-writer reservation；`.local/reports/qa02-full-tests.log`<br>QA02最终包 API28实际片段：飞行模式下数量写5并强停再启动；读取保存的记录与英文深色正常；未模拟手机厂商后台策略。证据：`qa02-device-results.jsonl`及其中截图名。|没有手机打开飞行模式、真实App杀进程/恢复整串；无联网依赖不能只凭源码或测试自动证明。<br>设备片段按左侧包版本与动作限定。|
|**P02 重启手机**|补充工程低层证据（实际系统操作见本行设备补充）：当前freshDart suite无真实手机重启步骤。<br>QA02最终包 API28实际片段：设备实际重启后切测试用户解锁，2组件绑定/英文深色/5页显示保留；常驻取消完成再完成可用。提醒重排另核；重启后两个组件恢复，常驻显式完成动作可用；提醒中心10:31配置保留且系统alarm含REMINDER_FIRE和WIDGET_REFRESH；未等待重启后下一次自然提醒。证据：`qa02-device-results.jsonl`及其中截图名。|API28重启/解锁/绑定/显示/保存已实际执行；系统提醒闹钟重新存在，但没有等待重启后下一次自然到点。其它机型与厂商后台待验。|
|**P03 覆盖安装保留数据**|补充工程低层证据（实际系统操作见本行设备补充）：当前freshDart suite没有覆盖安装执行。<br>QA02最终包 API28实际片段：最终QA02包覆盖安装且启动后，测试用户SQLite15表每字段相同；三习惯/两任务/两手记/卡片保留，桌面阅读实例仍在。证据：`qa02-device-results.jsonl`及其中截图名。|最终包覆盖安装后业务15表逐字段一致、已有桌面实例保留；其它系统版本和签名升级场景未扩大验收。|
|**P04 可选强行停止后恢复**|补充工程低层证据（实际系统操作见本行设备补充）：当前freshDart suite没有真实系统强停/重新打开测试。<br>QA02最终包 API28实际片段：飞行模式下数量写5并强停再启动；读取保存的记录与英文深色正常；未模拟手机厂商后台策略。证据：`qa02-device-results.jsonl`及其中截图名。|实际执行系统强停再打开及组件操作；重开后系统调度存在。强停期间不送达是平台限制，厂商额外限制待验。|
|**P05 读屏与触控**|补充工程部分步骤：部分控件语义tap target/accessibilitylabel在widget/native工程测试中覆盖；resume有独立语义。<br>证据：`test/ui02_accessibility_test.dart`：UI02 $locale dark=$dark accessible backup and appearance actions；`test/rest_share_ui_test.dart`：resume has its own named accessible action；`.local/reports/qa02-full-tests.log`|没有开启真实TalkBack，也没有读屏完整焦点/手势流程。|
|**P06 键盘、窄屏与长内容**|补充工程部分步骤：zh/en320x568160%/414x921常规、长标题/正文/键盘的实际Flutter渲染截图与操作可达；Cancel断词先失败后修复并增加glyph行断言。<br>证据：`test/qa02_habit_journeys_test.dart`：QA02 C03-C10 $lang small=$small numeric drafts keyboard and invalid values；`test/qa02_habit_journeys_test.dart`：QA02 G01/G03/G05/G06 $lang short-screen long tasks keyboard and actual today；`test/qa02_content_journeys_test.dart`：$tag H search range and editor cancel/save with keyboard；`test/qa02_visual_journeys_test.dart`：QA02 H I J K L M N screens $lang small=$small long content；`.local/reports/qa02-full-tests.log`<br>QA02最终包 API28实际片段：最终包实机渲染320dp/160%英文深色；外观Cancel单行，统计四入口无断词，2列数量和常驻组件文字操作可见。证据：`qa02-device-results.jsonl`及其中截图名。|渲染为测试Flutter+本地字体，非手机IME/厂商显示缩放；桌面需真实RemoteViews设备证据；不能把无overflow等同所有视觉体验完美。<br>设备片段按左侧包版本与动作限定。|

## 自然跨天与周期

|编号与路径主题|本轮实际方法与证据|覆盖限度／下一步|
|---|---|---|
|**Q01 跨午夜后的各类状态**|补充工程低层证据（实测待补）：受控时钟模拟次日resident页面复位/昨天保留；一次性重复完成不改原完成日、weeklycount按周清零。<br>证据：`test/resident_task_ui_test.dart`：create resident, complete today, and next day is unlogged without erasing yesterday；`test/home_widgets_test.dart`：resident duplicate is one row; next day blank is not a new task；`test/home_widgets_test.dart`：one-time repeated completion keeps original date and preserves due date；`.local/reports/qa02-full-tests.log`|未自然等午夜，未确认真实桌面系统刷新与提醒；条件原文要求自然D1因此仍pending。<br>自然日期/完整周期尚待观察；固定时间测试不替代真实经过。|
|**Q02 补记昨天与常驻纠正**|补充工程部分步骤：用合法历史fixture执行数量/习惯/常驻纠正，所选day而非今天写；历史成就/反馈规则domain验证。<br>证据：`test/pm_habit_context_test.dart`：selected historical date reaches detail and quantity instead of today；`test/resident_task_ui_test.dart`：history correction archive and unarchive use actual stored records；`test/pm_secondary_context_test.dart`：resident opens today, history secondary; passed date remains the write target；`test/achievements_test.dart`：archive delete restore and historical completion never issue a card automatically；`.local/reports/qa02-full-tests.log`|没有自然D0创建→等D1再通过系统datepicker整链；应将自然等待标待观察。<br>自然日期/完整周期尚待观察；固定时间测试不替代真实经过。|
|**Q03 计划次日生效与单位历史**|补充工程部分步骤：真实编辑器目标/单位/interval变更及受控clock明天规则、昨天值保留；统计不同单位分开。<br>证据：`test/qa02_habit_journeys_test.dart`：QA02 D07/D08 editing quantity plan preserves today and historical units；`test/plans_test.dart`：target/unit/schedule edit starts tomorrow, historical values and judgment stay stable；`test/statistics_test.dart`：quantity grouping includes exact zero but excludes missing dates and splits units；`.local/reports/qa02-full-tests.log`|不是自然次日；UI计划历史/真实手机后台跨午夜尚待观察。<br>自然日期/完整周期尚待观察；固定时间测试不替代真实经过。|
|**Q04 间隔日和休假起止**|补充工程低层证据（实测待补）：领域按日期休假inclusive/结束后恢复、间隔跨DSTyear；过去休息首页进入当日事实有WidgetUI。<br>证据：`test/rest_days_test.dart`：vacation inclusive boundaries and tomorrow expiry restore normal eligibility；`test/plans_test.dart`：calendar intervals cross DST and year without elapsed-hour assumptions；`test/pm04_root_paths_test.dart`：past rest opens day facts instead of today management；`.local/reports/qa02-full-tests.log`|没有自然到休假开始/结束并看真实提醒/组件；未来休假日期选择/取消已由F04真实Widget路径验证；自然到期另验。<br>自然日期/完整周期尚待观察；固定时间测试不替代真实经过。|
|**Q05 完整周与连续性**|补充工程低层证据（实测待补）：合成完整/部分/进行中周、计划版本变化、休息和连续性有领域精确断言。<br>证据：`test/statistics_test.dart`：weekly complete periods exclude partial version changes and ongoing week；`test/statistics_test.dart`：weekly historical values do not cross versions and range edges are not counted；`test/rest_days_test.dart`：rest week is neutral but archived and partial weeks cannot hide failures；`.local/reports/qa02-full-tests.log`|没有自然完整周实测，不能据此宣布一周真实使用通过。<br>自然日期/完整周期尚待观察；固定时间测试不替代真实经过。|
|**Q06 跨月回看与搜索**|补充工程部分步骤：主动历史fixture的跨月关键词搜索、月导航、历史统计截止/最近入口、timeline日期/日历。<br>证据：`test/journal_ui_test.dart`：month navigation search and habit picker combine, date cancel does not filter；`test/qa02_content_journeys_test.dart`：$tag H search range and editor cancel/save with keyboard；`test/pm04_paths_test.dart`：historical numeric summary ends on selected day and latest is explicit；`test/pm04_paths_test.dart`：statistics table calendar and timeline start at historical date；`.local/reports/qa02-full-tests.log`|未自然跨月和长存储观察；这些是历史数据查询自动化，不是月底真实机时钟转换。<br>自然日期/完整周期尚待观察；固定时间测试不替代真实经过。|

## 最终工程命令与设备范围

项目根执行，路径来自ignored本地工具配置：

```powershell
./scripts/dev.ps1 pub
./scripts/dev.ps1 format
./scripts/dev.ps1 analyze
$qaTests = @('--no-pub','--concurrency=2') + @(rg --files test -g '*test.dart' | Where-Object { $_ -notlike '*process_recovery_test.dart' -and $_ -notlike '*qa02_remaining_journeys_test.dart' })
./scripts/dev.ps1 test -Extra $qaTests
./scripts/dev.ps1 test -Extra '--no-pub','--concurrency=1','test/process_recovery_test.dart'
./scripts/dev.ps1 test -Extra '--no-pub','--concurrency=1','test/qa02_remaining_journeys_test.dart','test/qa02_contention_test.dart'
./scripts/dev.ps1 assemble -Extra '--no-pub'
./scripts/dev.ps1 native-test -Extra '--offline'
git diff --check
git diff --cached --check
```

pub成功；格式检查、分析无问题（9.1秒）。常规404通过3:47，独立进程恢复6通过28秒。追加E/F/G九项与锁保护五项合跑14通过16秒（`qa02-remaining-and-lock-final.log`），九项新增与404+6无重叠，总计419。排序采用持续移动的真实拖拽手势；日期区间使用系统Widget输入字段。首次夹具误选TextFormField、单帧拖拽不足已修正，未更改产品排序/休假规则。事务体失败末次注入真正DatabaseException(BUSY)，确认不重放，未注入COMMIT失败。assemble19.6秒成功；native-test成功1:03，JUnit XML合计14项/0失败/0错误。首次analyze指出新测试未用import、单行if及弃用语义API，已修正；新测试夹具中的虚拟列表滚动、字体加载和异步等待问题经修正再通过，未因此放宽产品断言。Gradle现有Kotlin迁移提示保留。完整检查按上述步骤分别执行，没有将曾卡住的进程恢复并发运行算通过。

API28执行命令（`$adb`来自本地工具配置，`$classes`为以下九类全限定名的逗号连接）：

```powershell
& $adb -s emulator-5554 install -r -t build/app/outputs/flutter-apk/app-debug.apk
& $adb -s emulator-5554 install -r -t build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
& $adb -s emulator-5554 shell am instrument --user 10 -w -e class $classes app.daypanel.next.debug.test/androidx.test.runner.AndroidJUnitRunner
```

九类：`app.daypanel.next.reminders.ReminderEngineTest`、`app.daypanel.next.CompletionFeedbackDeviceTest`、`app.daypanel.next.widgets.WidgetSnapshotTest`、`app.daypanel.next.widgets.WidgetLifecycleTest`、`app.daypanel.next.importing.LegacyReaderTest`、`app.daypanel.next.CardImageDeviceTest`、`app.daypanel.next.widgets.WidgetDirectActionDeviceTest`、`app.daypanel.next.widgets.WidgetPinDeviceTest`、`app.daypanel.next.widgets.WidgetVisualTest`。结果 **OK (37 tests)**，43.943秒。数据夹具限定临时用户，不在主用户制造打卡。

真实系统流程包括SAF导出A/B、预览取消、替换恢复、回退、拒绝PNG错误文件；通知实到、稍后再次出现、数量去记录取消；Launcher添加/配置取消/重新配置、布尔/任务后台完成、数量输入取消/保存、多实例、3列缩至2列、英文深色大字号、覆盖安装、重启后操作及恢复后旧绑定失效。最终包安装前后测试用户15表逐字段一致（`qa02-test-user-install-retention.json`）。系统UI自动化偶尔返回空根节点，等待后重试；未将输入工具失败当作产品成功。重启后先等锁屏/用户切换就绪才检查；模拟器重启后时间/时区同步有变化，没有人为调整日期凑跨日条件，也不据此推断精确提醒延迟。

## 可复核截图

以下图片为本轮临时用户的真实API28模拟器截图，无损转为WebP；不是实体手机截图。其余原图及日志在ignored `.local/reports/`。

|场景|截图|
|---|---|
|删除后回日常，剩余习惯可操作|[查看](evidence/qa02/qa02-final-delete-daily.webp)|
|320dp/160%英文深色，取消按钮单行|[查看](evidence/qa02/qa02-final-appearance-320-160.webp)|
|320dp/160%统计导航与当天表格|[查看](evidence/qa02/qa02-final-statistics-320-160.webp)|
|Launcher两个实例、英文深色大字号|[查看](evidence/qa02/qa02-final-widgets-320-160.webp)|
|Launcher真实缩窄至两列|[查看](evidence/qa02/qa02-final-widget-narrow.webp)|

[长名称日常页](evidence/qa02/qa02-en-small-daily.webp)是加载项目书页字体的Flutter实际测试渲染，另列于此，不混称设备截图。长名称缩为两行，记录操作留在导航上方；详情和读屏保留完整名称。

## 保留范围与下一轮

145项均已建立逐项映射；不等于145项完整人工验收通过。没有连接实体手机/第二台Android，本轮未补API35/36矩阵、真实TalkBack、厂家省电/长时间Doze、大规模数据性能；旧库使用合成夹具，未拿用户真实Loop文件；完整自然跨午夜/完整周/跨月仍须持续观察。下一批继续FL19这些范围，FL20发布验收未开始，不扩大业务功能。

最终切回主用户0，停止并删除临时用户10，系统仅剩主用户。主用户打开正常无重试页，关闭进程后归档，与测试前副本逐表核对 **15表全部字段一致**（含generation/revision），SQLite11，foreign_key_check为空，见`qa02-retention-final.log`；APK、数据库、工具/本机路径、原始诊断不入库。用户要求做完关机，因此所有文件保存和提交完成后执行非强制关机，未推送远端。
