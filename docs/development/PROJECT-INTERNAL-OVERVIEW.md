# DayPanel Flutter — Internal Development Record

> This file archives the internal development timeline, feature logs, and historical milestone tracking from the original development phase.

## Original Overview

新的 Flutter / Android 工程。功能以小日常为主对标，排除整个专注模块，基础功能免费，无广告或订阅；新增高级能力通过 Google Play 一次性购买解锁。备份、恢复、导出和用户自己的数据访问始终保留。现有原生 DayPanel/Loop 工程独立保留。

2026-11-11 Plus：组合桌面面板、逐次记录与单条纠正、自然周累计目标、周/月复盘卡、原创装扮、提醒加入日历和免费CSV已实现。SQLite12/schema12兼容旧schema2–11；新增Google Play买断/恢复与发布AAB准备。debug开放测试权益，不发生真实购买；release需要真实Play商品/公钥与签名资料。设计见[PLUS-FLOWS](../design/PLUS-FLOWS.md)，测试和限制见[PLUS-VALIDATION](PLUS-VALIDATION.md)，上架准备见[GOOGLE-PLAY](../release/GOOGLE-PLAY.md)。

2026-11-10 QA02 已按145条使用路径梳理工程与实际模拟器证据，修复启动短锁、卡片失效页、窄屏按钮/导航断字和长名称挤走主操作。419项Flutter/Dart、14项JVM、37项API28原生回归通过；最终包覆盖安装保留数据。逐项覆盖、真实截图、APK哈希和待验范围见[本轮自测报告](QA02-SELF-TEST.md)。真机/TalkBack/厂商省电和自然跨日等继续待验。

这是可构建运行的 Android 开发版，已交付「日常、小事、手记、我的」与 [UI 精修](../design/UI-POLISH.md)。M2 第一批新增完整文件备份/恢复/回退、情境与分组筛选、排序、间隔/周目标和计划版本历史，延续同一视觉体系。验证命令和实际设备证据见 [STATUS](STATUS.md)。完整对标进度见任务表，不能把旧原生版本的能力算进此安装包。

FL11 已接入习惯提醒：详情设置 1–5 个本地时刻，提醒中心显示系统通知和准时权限，通知可去记录/稍后10分钟。达标、归档、删除或关闭后同步取消；重启/时间或时区变化重排。API28 与 API35 已完成限定范围验证。标准模式可能被系统节电延迟；强停后需重新打开。全部免费。

FL12 已接入常驻小事：新建时选择一次性/常驻；常驻项按需每天记录一次，没做不产生逾期，历史独立保留。支持按日期纠正、归档/恢复、完成历史与七日回顾，完整备份包含常驻记录。规则见 [ADR0004](../adr/0004-resident-tasks.md)。

FL13 已接入习惯关联日志、明确记录日期、月份/单日浏览与正文搜索。月份、习惯与关键词同时筛选，也可搜索全部月份；归档保留日志，删除习惯后日志解除关联并保留文字。规则见 [ADR0005](../adr/0005-associated-journal.md)，交互见 [JOURNAL](../design/JOURNAL.md)。

FL14 已接入每日成就卡、六款原创卡面、收藏与卡背心得。达成当天全部按日计划后自动解锁，也可主动领取；已获得卡片在撤销打卡或以后改计划后保留。声音/触感分别可关，默认关闭。规则见 [ADR0006](../adr/0006-achievement-cards.md)，交互见 [ACHIEVEMENTS](../design/ACHIEVEMENTS.md)。

FL15 已接入打卡表、单习惯完成率/连续性与数量趋势、年度记录日历、跨类型时间线。指标使用历史计划，数量分单位；归档履历从升级当天起保存，之前未知日期不算失败。规则见 [ADR0007](../adr/0007-history-statistics.md)，界面见 [STATISTICS](../design/STATISTICS.md)。

FL16 已接入真实 Android 习惯/小事桌面组件：长按桌面添加，选择内容后保存；每个实例独立绑定，可缩放、重新配置和移除。布尔/小事设置明确完成值，数量直接打开总量输入，取消不写入。冷进程、跨日/时区、重启和覆盖安装会刷新；系统节电可能延迟，强停后重新打开。中英明暗跟随 App 设置；组件不需要通知权限、不承诺锁屏能力。规则见 [ADR0008](../adr/0008-home-widgets.md)，流程见 [WIDGETS](../design/WIDGETS.md)。

FL17 已接入免费外观预览：三种主题、系统/浅/深模式、系统字体与离线书页体、默认图标边框。习惯支持24个有文字名称的图标、独立配色与边框，保存前可预览，取消不写入。SQLite8/备份schema8包含装扮，兼容schema2–7；装扮不改变计划、记录或成就卡。桌面主题和大尺寸习惯图标同步更新，组件文字仍采用Android系统字体。见 [ADR0009](../adr/0009-personalization.md) 和 [PERSONALIZATION](../design/PERSONALIZATION.md)。

FL18 已接入 Loop 21–25版习惯数据库备份导入：只读检查、逐项预览、选择后追加，已有内容保留；原滚动频率需要明确选择新安排。真实日期/数量/备注保留，自动覆盖不算完成，历史计划未知不计失败；已有身份跳过，导入前保留完整回退副本。Android换机采用用户主动导出/传输/恢复完整JSON文件，无云同步。范围与流程见 [ADR0010](../adr/0010-legacy-import.md)、[LEGACY-IMPORT](../design/LEGACY-IMPORT.md)。

UI02 按新的视觉反馈重构外观、备份、旧习惯导入、统计导航、提醒介绍、手记筛选和组件配置。主题/字体/边框采用可视化选项，导入分为选文件、选内容、确认三步；说明按需展开，核心数据和操作优先。设计与系统验证见 [UI02](../design/UI02-REFINEMENT.md) 和 [FL19矩阵](SYSTEM-REGRESSION.md)。

UX01 已加入习惯暂停、按日期休假与单日跳过：休息不算失败或完成，提醒暂停，已有记录与卡片保留。成就卡可预览、保存PNG或调用系统分享，名称/心得默认隐藏；分享摘录不改原文。SQLite9/schema9兼容旧schema2–8，详见 [ADR0011](../adr/0011-rest-and-card-sharing.md) 与 [休息和分享设计](../design/REST-AND-SHARE.md)。

FL19 持续补做系统回归：休息组件的状态和说明保持一致，提醒开关整行可点。API28/35/36的实际通过范围、失败重试和待验收项以 [系统矩阵](SYSTEM-REGRESSION.md) 与 [STATUS](STATUS.md) 为准，模拟器通过不代表真机全部通过。

UI03 重新组织事项与外观：新建时提供喝水、阅读、散步等16个常用模板，带可编辑的目标/单位和对应插画；自定义名称支持图标建议。24个原创多色生活图在App与桌面共用，三套主题采用协调的多色组合。保存才创建事项，原数据不批量修改；见 [UI03](../design/UI03-LIVING-PALETTE.md)。

桌面快捷操作现支持布尔习惯/小事直接完成或取消，保持桌面可见；数量一步进入总量输入，确认后写入。详情与配置各自独立，旧详情页不会拦住数量入口。SQLite10增加本机并发版本保护，备份schema10兼容2–9。规则见 [ADR0013](../adr/0013-direct-widget-actions.md)。

UI04 以首屏操作重排页面：日常紧凑日期/进度后直接显示习惯，小事待办优先，手记正文优先，我的常用管理入口前置；模板/外观/备份/提醒等页面压缩重复展示。保持48dp点击区、字号缩放和原数据规则，见 [页面重心设计](../design/UI04-ACTION-FIRST.md)。

PM01 完成按用户任务的功能审查：数量累计记录、历史查看与整项设置分层，保留进入时日期；常驻今天操作与历史纠正分开，日/周统计按历史计划适用性展示，无日义务时不再承诺解锁卡。完整功能保留/移动/条件展示清单见 [产品审查](../product/PM01-FUNCTION-REVIEW.md)，规则见 [ADR0014](../adr/0014-contextual-product-flows.md)。

PM02 从首次建立、日常记录、回顾、中断后继续和数据保留审查用户路径，已复现新建结果不可见与筛选空态等问题；修复建议尚未实施，见 [用户路径与运营体验审查](../product/PM02-USER-JOURNEYS.md)。

PM04 按使用方式修复产品路径：完成、数量、整数次数三类记录；数量/次数可明确选择记入本次或修改日总量，预览合计后确认并检测并发。新建后直接展示新项，补计划外记录、历史日期承接、跨月搜索、常驻前置、导出事实与恢复下一步、系统确认的桌面添加。SQLite11/schema11，规则见 [ADR0015](../adr/0015-recording-modes-and-product-paths.md) 与 [流程设计](../design/PM04-PRODUCT-PATHS.md)，实际验收范围见STATUS。

UI05 重排Android桌面组件：默认建议3×2，名称/实际值前置，数量进度条与完成状态色，设置/详情改轻量图形，窄尺寸和大字号切换紧凑布局；直接完成和数量确认规则保持，见 [桌面视觉设计](../design/UI05-HOME-WIDGETS.md)。

RT01 修复真机反馈的习惯删除返回与失效页偏移：从日常详情删除回日常，管理列表删除仍回列表，缺失/恢复旧页全宽留白且可滚动；卡片册新增六款预览与用途/分享说明。详见 [删除流程修复](../design/RT01-DELETE-FLOW.md)，应用/备份仍为SQLite11/schema11。
