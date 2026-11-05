// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

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
  String get rollbackBody => '用最近一次恢复前的数据替换当前内容。恢复后新增或修改的内容也会被替换。';

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
  String get noteBody => '写下今天的想法';

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
  String get deleteHabitConfirm => '将删除这个习惯及其全部记录。要继续吗？';

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
}
