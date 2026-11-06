// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get statisticsTitle => '统计与历史';

  @override
  String get checkinTable => '打卡表';

  @override
  String get habitStatistics => '习惯统计';

  @override
  String get yearCalendar => '年度日历';

  @override
  String get timelineTitle => '时间线';

  @override
  String get historyUnknown => '履历未知';

  @override
  String get notScheduled => '未安排';

  @override
  String get correctionHint => '确认保存后才修改这一天，打开或取消不会写入记录。';

  @override
  String get restoreToCorrect => '当前习惯已归档，取消归档后可纠正记录。';

  @override
  String get previousPeriod => '上一时段';

  @override
  String get nextPeriod => '下一时段';

  @override
  String get tableHint =>
      '横向查看整周。✓ 达标 · • 已记录未达标 · ○ 未记录 · ~ 弹性周目标 · ? 履历未知 · — 未安排。点开日期查看或纠正。';

  @override
  String get statisticsKnownHint =>
      '归档履历从本次升级开始保存。更早的未知日期不计完成率或连续性；未保存的旧计划改动无法还原。';

  @override
  String get chooseStatisticsHabit => '选择一个习惯';

  @override
  String get singleHabitStatistics => '通过上方筛选查看单个习惯的计划、完成情况与数量，不混合不同单位。';

  @override
  String get daysLabel => '天';

  @override
  String get dailyCompletionRate => '按日计划完成率';

  @override
  String get noDenominator => '没有可统计的已结束计划日';

  @override
  String get dailyRateHint => '达标日 / 应做日，统计至昨天。今天、弹性周目标、归档期与未知履历不计入。';

  @override
  String get currentRun => '当前连续计划日';

  @override
  String get bestRun => '最长连续计划日';

  @override
  String get streakRangeHint => '仅在所选范围内计算。未安排日跳过，今天未完成暂不打断连续性。';

  @override
  String get weeklyStatistics => '周目标统计';

  @override
  String get noFullWeeks => '暂无可统计的完整周';

  @override
  String get completedWeeks => '周达标';

  @override
  String get weeklyStatsHint => '仅计算周一至周日完整、同一计划且履历已知活跃的周。部分周不进分母，本周仍在进行。';

  @override
  String get currentWeeks => '当前连续周';

  @override
  String get bestWeeks => '最长连续周';

  @override
  String get inProgress => '进行中';

  @override
  String get partialPeriod => '部分周 / 履历未知';

  @override
  String get quantityStatistics => '实际记录数量';

  @override
  String get quantityStatsHint => '按历史单位分开汇总和绘制逐日趋势。零值算记录，未记录日期不填零，也不计入均值。';

  @override
  String get noRecordedValues => '此范围没有数量记录';

  @override
  String get noUnit => '未设单位';

  @override
  String get quantitySum => '合计';

  @override
  String get recordedAverage => '每个记录日均值';

  @override
  String get recordedDays => '记录日数';

  @override
  String get trendScrollHint => '横向查看记录日期，点柱形可纠正当天数值。';

  @override
  String get yearCalendarHint => '颜色表示实际习惯记录数，含零值，不代表完成率。点日期查看明细；窄屏可在月份内横向滑动。';

  @override
  String get allEvents => '全部类型';

  @override
  String get timelineHint => '按当地日期展示当前保存的事实，包括习惯、小事完成、手记和已获卡片；不虚构具体时间或已删除事件。';

  @override
  String get noTimeline => '当前筛选没有记录';

  @override
  String get noTimelineHint => '可以切换月份、日期或记录类型。';

  @override
  String get noRecordHabits => '未记录的习惯';

  @override
  String get cardDawn => '一点晨光';

  @override
  String get cardRoots => '慢慢生根';

  @override
  String get cardRiver => '自有去处';

  @override
  String get cardSteps => '向前一步';

  @override
  String get cardWindow => '窗边有光';

  @override
  String get cardStars => '点点成星';

  @override
  String get todayCard => '今日成就卡';

  @override
  String get dailyCard => '日常卡片';

  @override
  String get cardKeptHint => '留住当时全部完成的这一刻。以后改计划或撤销记录，卡片与心得仍会保留。';

  @override
  String get cardUnlockHint => '完成今天全部按日安排的习惯，每天可获得一张。周目标不计入，历史补记不发卡。';

  @override
  String get viewCard => '查看卡片';

  @override
  String get claimCard => '领取今日卡片';

  @override
  String get cardCollection => '卡片册';

  @override
  String get cardCollectionHint => '一天一张，收好生活里的小小进步。打开卡片，翻到背面写下心得。';

  @override
  String get allCards => '全部';

  @override
  String get favoriteCards => '收藏';

  @override
  String get noFavoriteCards => '还没有收藏卡片';

  @override
  String get favoriteHint => '打开已获得的卡片，点收藏，就能在这里找到。';

  @override
  String get noCards => '从今天的一张卡开始';

  @override
  String get cardReflection => '卡背心得';

  @override
  String get emptyReflection => '这一天，有什么想留给自己？';

  @override
  String get cardMoment => '认真生活的这一刻，值得留下。';

  @override
  String get cardFront => '查看正面';

  @override
  String get cardBack => '翻到背面';

  @override
  String get unfavoriteCard => '取消收藏';

  @override
  String get favoriteCard => '收藏卡片';

  @override
  String get editReflection => '编辑心得';

  @override
  String get cardEvidence => '解锁时的完成记录';

  @override
  String get cardUnavailable => '当前数据里已没有这张卡片';

  @override
  String get cardRestoreHint => '请返回卡片册，查看当前数据里的卡片。';

  @override
  String get reflectionHint => '保存后留下文字；清空再保存可删除心得，取消保留原文。';

  @override
  String get completionFeedback => '完成反馈';

  @override
  String get completionSound => '完成声音';

  @override
  String get completionHaptics => '完成触感';

  @override
  String get feedbackOn => '已开启';

  @override
  String get feedbackOff => '已关闭';

  @override
  String get feedbackHint => '当天从未达标变为达标后，可以播放轻提示音或触感。两项默认关闭。';

  @override
  String get feedbackSystemHint =>
      '保存达标记录后才反馈，打开卡片不会播放。遵循系统静音、勿扰、音量与触感设置；补记、取消和重复保存相同值不反馈。';

  @override
  String get feedbackFailed => '记录已保存，本次声音或触感暂不可用。';

  @override
  String get cardsCount => '张卡片';

  @override
  String get noteDate => '记录日期';

  @override
  String get noteHabit => '关联习惯';

  @override
  String get independentNote => '独立手记';

  @override
  String get noteHabitMissing => '这个习惯已不存在';

  @override
  String get noteEditorHint => '选好日期和关联习惯再保存。取消或返回不会保存本次修改。';

  @override
  String get noteAssociationHint => '日志不等于打卡。归档习惯后，关联日志仍会保留。';

  @override
  String get habitJournal => '习惯日志';

  @override
  String get writeHabitNote => '写日志';

  @override
  String get viewHabitNotes => '查看全部日志';

  @override
  String get allNotes => '全部手记';

  @override
  String get filterNotes => '筛选手记';

  @override
  String get searchNotes => '搜索手记正文';

  @override
  String get clearSearch => '清除搜索';

  @override
  String get allMonths => '全部月份';

  @override
  String get thisMonth => '本月';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String get locateDate => '定位日期';

  @override
  String get showWholeMonth => '查看整月';

  @override
  String get journalFilterHint => '月份、习惯与正文关键词同时筛选。';

  @override
  String get noNotesFound => '没有符合条件的手记';

  @override
  String get noNotesFoundHint => '换个关键词、月份或习惯试试，也可以清除筛选后浏览当前日期范围。';

  @override
  String get emptyNoteMonth => '这个日期范围还没有手记';

  @override
  String get emptyNoteMonthHint => '可以换个月、查看全部月份，或写下新的手记。新增默认今天，可修改日期。';

  @override
  String get taskKind => '小事类型';

  @override
  String get oneTimeTask => '一次性';

  @override
  String get residentTask => '常驻';

  @override
  String get residentTasks => '常驻小事';

  @override
  String get residentHelp => '一直保留，按需记录；每天最多完成一次，不设截止日，也不累积逾期。';

  @override
  String get oneTimeHelp => '完成后进入已完成列表，可以安排日期。';

  @override
  String get residentToday => '今天已做';

  @override
  String get residentUnrecorded => '今天未记录';

  @override
  String get recordThisDay => '记为完成';

  @override
  String get clearThisDay => '撤销这天的记录';

  @override
  String get residentRecords => '常驻完成记录';

  @override
  String get taskHistory => '完成历史';

  @override
  String get taskArchive => '已归档常驻小事';

  @override
  String get taskArchiveHint => '归档后不再显示在小事页，完成历史仍保留。';

  @override
  String get residentDeleteWarning => '将删除这项常驻小事及其全部完成记录，无法恢复。';

  @override
  String get residentDetailHint => '只记录实际做过的日子，没做的日子不算失败。';

  @override
  String get taskTypeFixed => '创建后类型固定，避免改变已有完成记录的含义。';

  @override
  String get noTaskHistory => '这一天还没有完成记录';

  @override
  String get noArchivedTasks => '没有已归档的常驻小事';

  @override
  String get residentStart => '开始于';

  @override
  String get editTaskHistory => '查看与纠正记录';

  @override
  String get residentHistoryHint => '选择日期补记或纠正，只影响这一天。';

  @override
  String get historyShowsBoth => '一次性小事按实际完成日归档，常驻小事按记录日期显示。';

  @override
  String get residentTypeChoice => '选一次性或常驻';

  @override
  String get taskHistoryCount => '完成记录';

  @override
  String get taskSummaryPending => '待处理的一次性小事';

  @override
  String get taskSummaryToday => '今天完成';

  @override
  String get taskHistoryEditHint => '点开条目可编辑或纠正，归档内容也能在这里找到。';

  @override
  String get habitReminder => '习惯提醒';

  @override
  String get remindersTitle => '提醒中心';

  @override
  String get remindersIntro => '在合适的时刻，给自己的小习惯留一点时间。';

  @override
  String get reminderOff => '未开启';

  @override
  String get reminderOn => '开启提醒';

  @override
  String get reminderTimes => '提醒时刻';

  @override
  String get addReminderTime => '添加时刻';

  @override
  String get reminderLimit => '最多 5 个时刻，不能重复。';

  @override
  String get reminderScheduleHint => '只在计划日且尚未达标时提醒；周目标达标后，本周不再提醒。';

  @override
  String get reminderLocalTime => '时间跟随当前时区；关闭提醒会保留所选时刻。';

  @override
  String get notificationAllowed => '系统通知已开启';

  @override
  String get notificationBlocked => '系统通知未开启';

  @override
  String get enableNotifications => '允许通知';

  @override
  String get notificationSettings => '系统通知设置';

  @override
  String get exactReminder => '提醒精度';

  @override
  String get exactAvailable => '已允许准时提醒';

  @override
  String get exactUnavailable => '标准提醒，可能受节电策略延迟';

  @override
  String get requestExact => '设置准时提醒';

  @override
  String get reminderSavedBlocked => '提醒已保存，但系统通知未开启。可以稍后在提醒中心设置。';

  @override
  String get reminderSaveFailed => '提醒未保存，请重试。';

  @override
  String get reminderSyncFailed => '设置已保存，系统调度暂未更新。请重试或重新打开 App。';

  @override
  String get reminderSystemHint => '声音和震动由系统通知设置管理。强行停止 App 后，请重新打开以恢复提醒。';

  @override
  String get reminderPermissionHint => '仅用于你设置的习惯提醒，可以随时关闭。';

  @override
  String get removeTime => '移除此时刻';

  @override
  String get noReminders => '从一个习惯开始';

  @override
  String get noRemindersBody => '创建习惯后，即可为它设置提醒。';

  @override
  String get reminderArchived => '已归档，提醒暂停';

  @override
  String get reminderSettingsFailed => '无法打开系统设置，请稍后重试。';

  @override
  String get remindersCount => '已开启提醒';

  @override
  String get snoozeHint => '通知中可去记录，或选择 10 分钟后再提醒。打开通知不会自动打卡。';

  @override
  String get reminderBackups => '提醒配置随备份保存；系统权限需要在设备上单独开启。';

  @override
  String get reminderChannelHint => '通知权限被拒绝时，已选时刻仍然保留。';

  @override
  String get restoreRefreshFailed => '数据已恢复，但页面刷新失败。请返回并重试加载，勿重复恢复。';

  @override
  String get dataBackup => '数据与备份';

  @override
  String get backupBody => '习惯、计划、记录、小事、手记和外观设置，完整保存在一份文件中。';

  @override
  String get exportBackup => '导出完整备份';

  @override
  String get importBackup => '从文件恢复';

  @override
  String get exportHint => '选择保存位置，备份文件不加密，请妥善保管。';

  @override
  String get restoreHint => '先检查文件并预览内容，确认后才替换当前数据。';

  @override
  String get backupSaved => '备份已保存';

  @override
  String get backupError => '文件无法读取或保存，请换一个位置重试。';

  @override
  String get backupInvalid => '这不是有效的当前版本 DayPanel 备份，或文件已损坏。当前数据未改变。';

  @override
  String get restorePreview => '检查这份备份';

  @override
  String get restoreConfirm => '恢复并替换';

  @override
  String get replaceWarning => '恢复会替换当前所有数据，不会合并。恢复前的数据会保留一份，可在本页回退。';

  @override
  String get restoreDone => '已恢复备份';

  @override
  String get rollbackTitle => '回到恢复前';

  @override
  String get rollbackBody => '用最近一次恢复或旧习惯导入前的副本替换当前内容；之后的新增和改动也会被替换。';

  @override
  String get rollbackDone => '已回到恢复前的数据';

  @override
  String get noRecovery => '还没有恢复前副本';

  @override
  String get backupDate => '备份时间';

  @override
  String get backupItems => '文件内容';

  @override
  String get recordsLabel => '记录';

  @override
  String get plansLabel => '计划版本';

  @override
  String get groupsLabel => '习惯分组';

  @override
  String get backupLocal => '完整文件备份，免费且无需账号。';

  @override
  String get restoreFailed => '恢复未完成，当前数据保持不变，请重试。';

  @override
  String get contextLabel => '情境';

  @override
  String get anytime => '不限时段';

  @override
  String get morning => '早晨';

  @override
  String get daytime => '白天';

  @override
  String get evening => '夜晚';

  @override
  String get allHabits => '全部习惯';

  @override
  String get allGroups => '全部分组';

  @override
  String get ungrouped => '未分组';

  @override
  String get groupLabel => '所属分组';

  @override
  String get manageGroups => '管理分组';

  @override
  String get newGroup => '新建分组';

  @override
  String get groupName => '分组名称';

  @override
  String get groupDeleteHint => '删除分组只会解除习惯的归属，习惯与记录都会保留。';

  @override
  String get groupNameError => '请输入 1–40 个字符，名称不能与已有分组重复。';

  @override
  String get noGroups => '把相关习惯放在一起';

  @override
  String get noGroupsBody => '例如健康、阅读或学习，也可以先不分组。';

  @override
  String get filterHabits => '筛选习惯';

  @override
  String get applyFilter => '应用筛选';

  @override
  String get resetFilter => '清除筛选';

  @override
  String get noFilterMatches => '这个筛选下没有习惯';

  @override
  String get sortHabits => '调整顺序';

  @override
  String get sortHint => '拖动右侧手柄，或用上下按钮调整。保存后日常页按此顺序显示。';

  @override
  String get moveUp => '上移';

  @override
  String get moveDown => '下移';

  @override
  String get frequency => '安排方式';

  @override
  String get byWeekday => '指定星期';

  @override
  String get everyNDays => '每隔几天';

  @override
  String get weeklyTarget => '每周目标';

  @override
  String get intervalLabel => '间隔天数';

  @override
  String get weeklyGoalLabel => '每周达标天数';

  @override
  String get scheduleNumberError => '间隔为 1–365 天；每周目标为 1–7 天。';

  @override
  String get planTomorrow => '目标、单位和安排改动从明天生效。过去的计划和记录保持原样。';

  @override
  String get planPending => '有计划从明天生效';

  @override
  String get planHistory => '计划历史';

  @override
  String get effectiveFrom => '生效日期';

  @override
  String get weeklyAvailable => '本周可记录';

  @override
  String get weeklyHint => '按周一至周日统计达标日，自行选择哪天做；不计入每日必做。';

  @override
  String get weekProgress => '本周达标';

  @override
  String get partialWeek => '新计划从生效日起计本周';

  @override
  String get scheduleStarts => '从计划生效日计算间隔';

  @override
  String get organization => '安排与整理';

  @override
  String get planVersionNote => '迁移前的计划改动无法还原；当前保存的版本从本次升级起准确追踪。';

  @override
  String get restoreStale => '数据已发生变化，请重新选择备份后再操作。';

  @override
  String get dailyCardTitle => '一点一滴，都是进步';

  @override
  String get journalHeading => '给回忆，留一页空白';

  @override
  String get journalEmptyHint => '不用写得完整，从一句话开始。';

  @override
  String get yourSpace => '我的日常';

  @override
  String get preferencesTitle => '用自己喜欢的方式';

  @override
  String get habitEditorHint => '从一个小习惯开始，慢慢坚持。';

  @override
  String get taskEditorHint => '记下要做的事，再安排时间。';

  @override
  String get notePlaceholder => '今天，有什么想记住的？';

  @override
  String get habitPlaceholder => '例如：读几页书';

  @override
  String get taskPlaceholder => '例如：把书还给朋友';

  @override
  String get unitPlaceholder => '例如：页、杯、ml';

  @override
  String get currentRecord => '已记录';

  @override
  String get prefillTotal => '快速填写总量';

  @override
  String get confirmBeforeWrite => '选择只会填写输入框，保存后才更新记录。';

  @override
  String get appName => 'DayPanel';

  @override
  String get extraRecords => '计划外记录';

  @override
  String get notCompleted => '未完成';

  @override
  String get today => '日常';

  @override
  String get tasks => '小事';

  @override
  String get notes => '手记';

  @override
  String get mine => '我的';

  @override
  String get add => '添加';

  @override
  String get newHabit => '添加习惯';

  @override
  String get newTask => '添加小事';

  @override
  String get newNote => '写下此刻';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get done => '完成';

  @override
  String get reopen => '恢复待做';

  @override
  String get record => '记录';

  @override
  String get clearRecord => '清除记录';

  @override
  String get settings => '设置';

  @override
  String get review => '七日回顾';

  @override
  String get manageHabits => '管理习惯';

  @override
  String get title => '名称';

  @override
  String get noteBody => '手记正文';

  @override
  String get type => '记录方式';

  @override
  String get checkHabit => '完成打卡';

  @override
  String get quantityHabit => '数量目标';

  @override
  String get target => '每日目标';

  @override
  String get unit => '单位';

  @override
  String get schedule => '重复星期';

  @override
  String get everyDay => '每天';

  @override
  String get icon => '图标';

  @override
  String get dueDate => '安排日期';

  @override
  String get noDate => '暂不安排日期';

  @override
  String get chooseDate => '选择日期';

  @override
  String get language => '语言';

  @override
  String get appearance => '外观';

  @override
  String get system => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get english => 'English';

  @override
  String get chinese => '简体中文';

  @override
  String get archive => '归档';

  @override
  String get unarchive => '取消归档';

  @override
  String get archived => '已归档';

  @override
  String get active => '进行中';

  @override
  String get emptyHabits => '给日常一点期待';

  @override
  String get emptyHabitsBody => '从一件你想坚持的小事开始。';

  @override
  String get emptyDay => '这天没有安排习惯';

  @override
  String get emptyDayBody => '可以换一天看看，或添加一个新习惯。';

  @override
  String get emptyTasks => '小事，慢慢来';

  @override
  String get emptyTasksBody => '先记下来，再按自己的节奏完成。';

  @override
  String get emptyNotes => '留下生活里的小片段';

  @override
  String get emptyNotesBody => '想法、心情或一件值得记住的事。';

  @override
  String get dailyHeading => '把日子过成喜欢的样子';

  @override
  String get dailySubtitle => '每一件小事，都有自己的节奏。';

  @override
  String get todayLabel => '今天';

  @override
  String get inbox => '未设日期';

  @override
  String get overdue => '已逾期';

  @override
  String get upcoming => '接下来';

  @override
  String get completedToday => '今天已完成';

  @override
  String get completedEarlier => '以前已完成';

  @override
  String get planned => '当日习惯';

  @override
  String get allDone => '今天的安排都完成了';

  @override
  String get progressHint => '按自己的节奏，一点点来。';

  @override
  String get date => '日期';

  @override
  String get total => '当日总量';

  @override
  String get quantityHelp => '输入总量，最多三位小数，不使用千位分隔符。';

  @override
  String get invalidTitle => '请填写名称';

  @override
  String get invalidQuantity => '请输入有效数量（最多三位小数）';

  @override
  String get invalidTarget => '目标需要大于零';

  @override
  String get selectWeekday => '至少选择一天';

  @override
  String get noteRequired => '写点内容再保存';

  @override
  String get deleteConfirm => '删除后无法恢复。要继续吗？';

  @override
  String get deleteHabitConfirm =>
      '将删除这个习惯及其打卡记录。关联手记解除关联并保留；已获得的卡片、解锁快照和心得也会保留。要继续吗？';

  @override
  String get storageError => '暂时无法读取或保存数据，请重试。';

  @override
  String get retry => '重试';

  @override
  String get back => '返回';

  @override
  String get freeTitle => '你的日常，始终免费';

  @override
  String get freeBody => '没有广告、订阅和功能付费墙。';

  @override
  String get localData => '数据保存在这台设备';

  @override
  String get localDataBody => '当前版本尚无完整备份，卸载会删除本地数据。';

  @override
  String get licenses => '开源许可';

  @override
  String get reviewBody => '展示实际记录次数，不把不同单位的数量相加。';

  @override
  String get habitLogs => '习惯记录';

  @override
  String get taskCompletions => '小事完成';

  @override
  String get noReview => '还没有记录，从今天开始吧。';

  @override
  String get history => '历史记录';

  @override
  String get notRecorded => '未记录';

  @override
  String get futureDate => '未来日期可以安排，暂不能打卡';

  @override
  String get notStarted => '这个习惯还未开始';

  @override
  String get saved => '已保存';

  @override
  String get archivedHint => '归档后保留记录，不再出现在日常中。';

  @override
  String get weekMon => '一';

  @override
  String get weekTue => '二';

  @override
  String get weekWed => '三';

  @override
  String get weekThu => '四';

  @override
  String get weekFri => '五';

  @override
  String get weekSat => '六';

  @override
  String get weekSun => '日';

  @override
  String get weekMonFull => '星期一';

  @override
  String get weekTueFull => '星期二';

  @override
  String get weekWedFull => '星期三';

  @override
  String get weekThuFull => '星期四';

  @override
  String get weekFriFull => '星期五';

  @override
  String get weekSatFull => '星期六';

  @override
  String get weekSunFull => '星期日';

  @override
  String get more => '更多操作';

  @override
  String get goToday => '回到今天';

  @override
  String get editHabit => '编辑习惯';

  @override
  String get editTask => '编辑小事';

  @override
  String get editNote => '编辑手记';

  @override
  String get noArchived => '没有已归档习惯';

  @override
  String get finished => '已完成';

  @override
  String get habitCount => '个习惯';

  @override
  String get habit => '习惯';

  @override
  String get note => '手记';

  @override
  String get task => '小事';

  @override
  String get widgetsTitle => '桌面组件';

  @override
  String get widgetChoose => '选择显示的内容';

  @override
  String get widgetConfigHint => '每个组件独立保存选择。保存后返回桌面。';

  @override
  String get widgetEmpty => '还没有可用内容，请先在 App 创建习惯或小事。';

  @override
  String get widgetExpired => '内容或日期已改变，请返回桌面后重新打开。恢复数据后需要重新选择组件内容。';

  @override
  String get widgetOpenApp => '打开 DayPanel';

  @override
  String get widgetClose => '返回桌面';

  @override
  String get widgetSaving => '正在保存记录';

  @override
  String get widgetHelp =>
      '长按桌面，选择组件，再添加 DayPanel 习惯或小事。组件可缩放，可通过设置重新选择内容。后台刷新可能受系统节电影响；强行停止后请重新打开 App。组件选择仅保存在这台设备。';

  @override
  String get widgetOpening => '正在打开记录';

  @override
  String get appearancePreview => '外观预览';

  @override
  String get appearanceHint => '先看看效果，保存后才应用。所有选择免费。';

  @override
  String get appearanceSample => '排版样张';

  @override
  String get appearanceSampleText => '把喜欢的小事，放进每一天。';

  @override
  String get appearanceMode => '明暗模式';

  @override
  String get appearancePalette => '主题配色';

  @override
  String get paletteBlue => '晴空蓝';

  @override
  String get paletteTeal => '林间青';

  @override
  String get paletteViolet => '暮色紫';

  @override
  String get appearanceFont => '字体';

  @override
  String get fontSystem => '系统字体';

  @override
  String get fontSerif => '书页体';

  @override
  String get fontHint => '书页体采用本地 Noto Serif SC，无需下载。桌面组件使用 Android 系统字体。';

  @override
  String get appearanceFrame => '默认图标边框';

  @override
  String get frameSoft => '柔和底';

  @override
  String get frameRing => '圆环';

  @override
  String get framePlain => '无边框';

  @override
  String get followDefault => '跟随默认';

  @override
  String get automaticColor => '自动配色';

  @override
  String get appearanceReset => '恢复默认预览';

  @override
  String get habitDecoration => '图标与装扮';

  @override
  String get habitColor => '图标配色';

  @override
  String get habitFrame => '图标边框';

  @override
  String get colorBlue => '蓝色';

  @override
  String get colorViolet => '紫色';

  @override
  String get colorPeach => '暖橙';

  @override
  String get colorTeal => '青色';

  @override
  String get colorRose => '玫瑰';

  @override
  String get decorationHint => '装扮不改变安排、目标或完成记录。';

  @override
  String get iconSun => '阳光';

  @override
  String get iconWater => '水滴';

  @override
  String get iconBook => '阅读';

  @override
  String get iconWalk => '散步';

  @override
  String get iconHeart => '爱心';

  @override
  String get iconMoon => '月亮';

  @override
  String get iconStrength => '力量';

  @override
  String get iconMeditate => '舒展';

  @override
  String get iconRun => '跑步';

  @override
  String get iconBike => '骑行';

  @override
  String get iconMeal => '餐食';

  @override
  String get iconFlower => '花朵';

  @override
  String get iconMusic => '音乐';

  @override
  String get iconArt => '绘画';

  @override
  String get iconWrite => '书写';

  @override
  String get iconLanguage => '语言';

  @override
  String get iconSavings => '储蓄';

  @override
  String get iconClean => '整理';

  @override
  String get iconPet => '宠物';

  @override
  String get iconCoffee => '咖啡';

  @override
  String get iconMedicine => '用药';

  @override
  String get iconSleep => '睡眠';

  @override
  String get iconUnplug => '少看手机';

  @override
  String get iconCare => '关怀';

  @override
  String get legacyTitle => '导入旧习惯';

  @override
  String get legacyIntro => '从 Loop 数据库备份追加习惯和真实记录，现有内容保留。先检查和预览，确认后才写入。';

  @override
  String get legacyPick => '选择 Loop 备份 .db';

  @override
  String get legacySupported =>
      '支持 Loop 21–25 版数据库，最大8 MiB。不支持旧双库ZIP、CSV或其他应用备份。请从旧App导出完整数据库文件。';

  @override
  String get legacyDifference =>
      '只迁移原始记录，自动覆盖不算完成。跳过和备注保留为手记；历史安排、目标变动和归档履历无法还原，导入前日期不计失败。旧提醒、得分、配色及旧版小事/场景不导入。数量按文件中的单位解释。 起始日取最早记录，无记录时取导入日，不代表原创建日。没有UUID的旧文件在改名后可能被识别为新习惯，请勿反复导入。';

  @override
  String get legacyReview => '检查导入内容';

  @override
  String get legacyExisting => '本机已有，保留现有内容';

  @override
  String get legacyUnsupported => '此项不支持导入';

  @override
  String get legacyAtMost => '暂不支持“至多”目标，不会反向解释。';

  @override
  String get legacyTarget => '目标必须是正数，且最多三位小数。';

  @override
  String get legacyLength => '名称或单位超出当前长度限制，请先在旧App调整。';

  @override
  String get legacySourceFrequency => '原频率（次数/天数）';

  @override
  String get legacyRecords => '真实记录';

  @override
  String get legacyIgnored => '自动覆盖/未知（不计完成）';

  @override
  String get legacySkips => '跳过（保存为手记）';

  @override
  String get legacyNotes => '手记（含来源说明）';

  @override
  String get legacyChooseSchedule => '选择导入后的安排';

  @override
  String get legacyScheduleHint =>
      '原滚动频率不等同严格间隔或自然周。请选择今后的安排，过去未知日期不会按新安排算失败。间隔从导入当天起计。';

  @override
  String get legacyDaily => '每天';

  @override
  String get legacyWeekly => '每自然周达标日';

  @override
  String get legacyInterval => '每隔几天';

  @override
  String get legacyCount => '天数';

  @override
  String get legacyAcknowledge => '我已了解差异，并确认所选安排';

  @override
  String get legacyConfirm => '追加所选习惯';

  @override
  String get legacyDone => '导入完成，已有内容保留。可在数据与备份回到导入前副本。';

  @override
  String get legacyInvalid => '文件损坏、格式不支持或含无法解释的记录。没有修改数据。';

  @override
  String get legacyFailed => '未能导入。内容或日期可能已改变，请重新选择文件。';

  @override
  String get legacyEmpty => '没有可追加的习惯。已存在的习惯不会覆盖或合并。';

  @override
  String get legacyRecovery => '导入前保留最近一次完整副本。回退会替换导入后的新改动；需要长期保留时请先导出文件。';

  @override
  String get offlineTransferTitle => '离线换机与数据保留';

  @override
  String get offlineTransferBody =>
      '1. 在旧设备导出完整 DayPanel JSON 文件。\n2. 自行通过USB或文件传输保存到新设备。\n3. 在新设备选择“从文件恢复”，核对预览后确认。\n4. 重新设置通知权限和桌面组件。\n\n不提供云同步或自动备份。备份未加密，请保存在安全位置；卸载会删除App内数据和恢复副本，务必保留App之外的导出文件。';

  @override
  String get uiAppearanceHint => '按你的喜好，安排页面的颜色与字形。';

  @override
  String get uiPreviewLive => '实时预览';

  @override
  String get uiPreviewHint => '保存后应用到所有页面';

  @override
  String get uiFontSample => '日常的小小进步';

  @override
  String get uiMoreDetails => '查看说明';

  @override
  String get uiBackupHint => '把日常留在自己手里。';

  @override
  String get uiExportHint => '保存一份完整文件，方便备份与换机。';

  @override
  String get uiRestoreHint => '先预览文件，再确认替换当前数据。';

  @override
  String get uiLegacyHint => '从 Loop 带回习惯，已有内容保留。';

  @override
  String get uiRecoveryHint => '最近一次操作前的完整副本';

  @override
  String get uiFileScope => '文件支持范围';

  @override
  String get uiChooseFile => '选择备份文件';

  @override
  String get uiChooseItems => '选择内容';

  @override
  String get uiReviewImport => '确认导入';

  @override
  String get uiContinue => '继续';

  @override
  String get uiBack => '上一步';

  @override
  String get uiChangeFile => '重新选择文件';

  @override
  String get uiImportSelectHint => '选择要带回的习惯，并确认今后的安排。';

  @override
  String get uiImportReviewHint => '已有内容保留，只追加本次选择。';

  @override
  String get uiImportRules => '导入后的变化';

  @override
  String get uiImportNoSelection => '请至少选择一个可导入习惯';

  @override
  String get uiImportNeedsSchedule => '请为选中习惯选择新的安排';

  @override
  String uiSelectedCount(int count) {
    return '已选 $count 个习惯';
  }

  @override
  String uiRecordCount(int count) {
    return '$count 条记录';
  }

  @override
  String get uiNeedsSchedule => '待选择安排';

  @override
  String get uiSchedule => '今后安排';

  @override
  String get uiImportedDone => '你的习惯已安放好';

  @override
  String get uiReturnData => '返回数据与备份';

  @override
  String get uiWidgetChooseHint => '选一个习惯或小事，放到桌面随时查看。';

  @override
  String get uiNoWidgetChoice => '先选择显示的内容';

  @override
  String get uiReminderIntro => '在合适的时候，轻轻提醒你。';

  @override
  String get uiReminderRules => '提醒如何工作';

  @override
  String get uiStatisticsHelp => '统计口径与说明';

  @override
  String get uiShowDetails => '记录详情';

  @override
  String get uiTabTable => '打卡表';

  @override
  String get uiTabHabits => '习惯';

  @override
  String get uiTabYear => '年历';

  @override
  String get uiTabTimeline => '时间线';

  @override
  String get restTitle => '休息安排';

  @override
  String get restPaused => '已暂停';

  @override
  String get restVacation => '休假中';

  @override
  String get restSkipped => '这天已跳过';

  @override
  String get restPause => '从今天暂停';

  @override
  String get restPlanVacation => '安排一段休假';

  @override
  String get restSkip => '跳过这天';

  @override
  String get restUnskip => '取消跳过';

  @override
  String get restResume => '从今天恢复';

  @override
  String get restCancelFuture => '取消这次安排';

  @override
  String get restHint => '休息不算失败，也不算完成。历史记录保留，期间不提醒。';

  @override
  String get restRules =>
      '每日连续性跨过休息日；包含休息日的周不参与完整周考核。全部习惯都休息的日子不发成就卡。恢复后继续原计划。';

  @override
  String get restConflict => '这段日期已有休息安排，或这天已有记录。请检查后再试。';

  @override
  String get restEnded => '已结束';

  @override
  String get restUntilResume => '直到手动恢复';

  @override
  String get restRange => '选择开始与结束日期';

  @override
  String get restConfirmSkip => '跳过只影响这一天，不删除其他记录。';

  @override
  String get restRecordBlocked => '这天正在休息。先结束或取消休息，再记录。';

  @override
  String get cardShare => '分享卡片';

  @override
  String get cardSaveImage => '保存图片';

  @override
  String get cardShareAction => '分享';

  @override
  String get cardShareNames => '包含习惯名称';

  @override
  String get cardShareReflection => '包含心得摘录';

  @override
  String get cardShareExcerpt => '分享摘录（不修改原心得）';

  @override
  String get cardShareHint => '预览就是将保存或分享的图片。名称和心得默认隐藏。';

  @override
  String get cardImageSaved => '图片已保存';

  @override
  String get cardImageFailed => '图片生成或保存失败，请重试。';

  @override
  String get cardShareStale => '卡片数据已改变，请重新打开分享页。';

  @override
  String cardShareMore(int count) {
    return '另有 $count 项';
  }

  @override
  String cardShareCount(int count) {
    return '完成了 $count 个习惯';
  }

  @override
  String get restRangeLimit => '选择休假日期，最多 365 天';

  @override
  String get restSchedule => '休息安排与记录';

  @override
  String get restStale => '习惯内容已变化，请重新打开休息安排。';

  @override
  String get restConfirmUnskip => '这天将重新按原计划统计，不会添加完成记录。';
}
