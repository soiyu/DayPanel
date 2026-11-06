// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get taskKind => 'Task type';

  @override
  String get oneTimeTask => 'One-time';

  @override
  String get residentTask => 'Keep around';

  @override
  String get residentTasks => 'Keep-around tasks';

  @override
  String get residentHelp =>
      'Keep it for whenever you need it. Log once per day, with no due date or overdue backlog.';

  @override
  String get oneTimeHelp =>
      'Complete once, then move to history. A planned date is optional.';

  @override
  String get residentToday => 'Done today';

  @override
  String get residentUnrecorded => 'Not logged today';

  @override
  String get recordThisDay => 'Mark completed';

  @override
  String get clearThisDay => 'Clear this day';

  @override
  String get residentRecords => 'Keep-around logs';

  @override
  String get taskHistory => 'Completion history';

  @override
  String get taskArchive => 'Archived keep-around tasks';

  @override
  String get taskArchiveHint =>
      'Archive to hide it from Tasks. Completion history stays available.';

  @override
  String get residentDeleteWarning =>
      'Delete this keep-around task and all its completion records? This cannot be undone.';

  @override
  String get residentDetailHint =>
      'Log the days you did it. Days without a log are not failures.';

  @override
  String get taskTypeFixed =>
      'The type stays fixed after creation so existing records keep their meaning.';

  @override
  String get noTaskHistory => 'No completions for this day';

  @override
  String get noArchivedTasks => 'No archived keep-around tasks';

  @override
  String get residentStart => 'Started';

  @override
  String get editTaskHistory => 'View & correct records';

  @override
  String get residentHistoryHint =>
      'Choose a date to log or correct. Only that day changes.';

  @override
  String get historyShowsBoth =>
      'One-time tasks use their actual completion date. Keep-around tasks use each logged date.';

  @override
  String get residentTypeChoice => 'Choose a task type';

  @override
  String get taskHistoryCount => 'Completions';

  @override
  String get taskSummaryPending => 'Open one-time tasks';

  @override
  String get taskSummaryToday => 'Completed today';

  @override
  String get taskHistoryEditHint =>
      'Open an item to edit or correct it. Archived items remain here.';

  @override
  String get habitReminder => 'Habit reminder';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get remindersIntro =>
      'Make a little time for your habits, at the right moments.';

  @override
  String get reminderOff => 'Off';

  @override
  String get reminderOn => 'Enable reminder';

  @override
  String get reminderTimes => 'Reminder times';

  @override
  String get addReminderTime => 'Add a time';

  @override
  String get reminderLimit => 'Choose up to 5 different times.';

  @override
  String get reminderScheduleHint =>
      'Remind only on planned days while unfinished. Weekly reminders stop once the weekly goal is reached.';

  @override
  String get reminderLocalTime =>
      'Times follow your current time zone. Turning reminders off keeps your chosen times.';

  @override
  String get notificationAllowed => 'Notifications are allowed';

  @override
  String get notificationBlocked => 'Notifications are blocked';

  @override
  String get enableNotifications => 'Allow notifications';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get exactReminder => 'Reminder timing';

  @override
  String get exactAvailable => 'Precise timing allowed';

  @override
  String get exactUnavailable =>
      'Standard timing; power saving may delay delivery';

  @override
  String get requestExact => 'Set precise timing';

  @override
  String get reminderSavedBlocked =>
      'Reminder saved, but notifications are blocked. You can enable them later in Reminders.';

  @override
  String get reminderSaveFailed => 'Could not save the reminder. Please retry.';

  @override
  String get reminderSyncFailed =>
      'Settings are saved, but system scheduling did not update. Retry or reopen the app.';

  @override
  String get reminderSystemHint =>
      'Manage sound and vibration in system notification settings. After force-stopping the app, reopen it to resume reminders.';

  @override
  String get reminderPermissionHint =>
      'Only for habit reminders you choose. Turn them off at any time.';

  @override
  String get removeTime => 'Remove time';

  @override
  String get noReminders => 'Start with a habit';

  @override
  String get noRemindersBody => 'Create a habit to choose its reminder times.';

  @override
  String get reminderArchived => 'Archived; reminders paused';

  @override
  String get reminderSettingsFailed =>
      'Could not open system settings. Please try again.';

  @override
  String get remindersCount => 'Enabled reminders';

  @override
  String get snoozeHint =>
      'From a notification, log your habit or snooze for 10 minutes. Opening it never logs automatically.';

  @override
  String get reminderBackups =>
      'Reminder settings are backed up. System permission must be enabled on each device.';

  @override
  String get reminderChannelHint =>
      'Your times are kept if notification permission is denied.';

  @override
  String get restoreRefreshFailed =>
      'Data was restored, but the screen could not refresh. Go back and reload before making more changes.';

  @override
  String get dataBackup => 'Data & backup';

  @override
  String get backupBody =>
      'Keep your habits, plans, logs, tasks, journal and preferences in one file.';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get importBackup => 'Restore from file';

  @override
  String get exportHint =>
      'Choose a location. Backup files are not encrypted; keep them private.';

  @override
  String get restoreHint =>
      'Review the file first. Your data changes only after confirmation.';

  @override
  String get backupSaved => 'Backup saved';

  @override
  String get backupError =>
      'Could not read or save the file. Try another location.';

  @override
  String get backupInvalid =>
      'This is not a valid supported DayPanel backup, or it is damaged. Your data is unchanged.';

  @override
  String get restorePreview => 'Review this backup';

  @override
  String get restoreConfirm => 'Restore & replace';

  @override
  String get replaceWarning =>
      'Restore replaces all current data; it does not merge. A copy of your previous data will be kept here for rollback.';

  @override
  String get restoreDone => 'Backup restored';

  @override
  String get rollbackTitle => 'Return to previous data';

  @override
  String get rollbackBody =>
      'Replace current content with the copy from before the last restore. Newer additions and changes will also be replaced.';

  @override
  String get rollbackDone => 'Previous data restored';

  @override
  String get noRecovery => 'No previous restore copy';

  @override
  String get backupDate => 'Backup date';

  @override
  String get backupItems => 'File contents';

  @override
  String get recordsLabel => 'Logs';

  @override
  String get plansLabel => 'Plan versions';

  @override
  String get groupsLabel => 'Habit groups';

  @override
  String get backupLocal => 'Full file backups, free and without an account.';

  @override
  String get restoreFailed =>
      'Restore failed. Your current data is unchanged. Please retry.';

  @override
  String get contextLabel => 'Time of day';

  @override
  String get anytime => 'Anytime';

  @override
  String get morning => 'Morning';

  @override
  String get daytime => 'Daytime';

  @override
  String get evening => 'Evening';

  @override
  String get allHabits => 'All habits';

  @override
  String get allGroups => 'All groups';

  @override
  String get ungrouped => 'Ungrouped';

  @override
  String get groupLabel => 'Group';

  @override
  String get manageGroups => 'Manage groups';

  @override
  String get newGroup => 'New group';

  @override
  String get groupName => 'Group name';

  @override
  String get groupDeleteHint =>
      'Deleting a group removes membership only. Habits and records are kept.';

  @override
  String get groupNameError =>
      'Use 1–40 characters and a name that is not already in use.';

  @override
  String get noGroups => 'Bring related habits together';

  @override
  String get noGroupsBody =>
      'Try Health, Reading or Learning. Grouping is optional.';

  @override
  String get filterHabits => 'Filter habits';

  @override
  String get applyFilter => 'Apply filters';

  @override
  String get resetFilter => 'Clear filters';

  @override
  String get noFilterMatches => 'No habits match these filters';

  @override
  String get sortHabits => 'Arrange habits';

  @override
  String get sortHint =>
      'Drag the handle or use the arrows. Daily follows this order after saving.';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get frequency => 'Schedule';

  @override
  String get byWeekday => 'Weekdays';

  @override
  String get everyNDays => 'Every few days';

  @override
  String get weeklyTarget => 'Weekly target';

  @override
  String get intervalLabel => 'Days between';

  @override
  String get weeklyGoalLabel => 'Days per week';

  @override
  String get scheduleNumberError =>
      'Use 1–365 days for intervals, or 1–7 days per week.';

  @override
  String get planTomorrow =>
      'Target, unit and schedule changes start tomorrow. Past plans and logs stay intact.';

  @override
  String get planPending => 'An updated plan starts tomorrow';

  @override
  String get planHistory => 'Plan history';

  @override
  String get effectiveFrom => 'Effective from';

  @override
  String get weeklyAvailable => 'Flexible this week';

  @override
  String get weeklyHint =>
      'Count achieved days Monday–Sunday. Choose your days; these are not daily obligations.';

  @override
  String get weekProgress => 'Achieved this week';

  @override
  String get partialWeek => 'This plan counts from its start date this week';

  @override
  String get scheduleStarts => 'Intervals start on the plan’s effective date';

  @override
  String get organization => 'Schedule & organize';

  @override
  String get planVersionNote =>
      'Changes made before this upgrade cannot be reconstructed. Saved versions track changes from this upgrade onward.';

  @override
  String get restoreStale =>
      'Data has changed. Select the backup again before continuing.';

  @override
  String get dailyCardTitle => 'Little steps, real progress';

  @override
  String get journalHeading => 'A page for your everyday';

  @override
  String get journalEmptyHint => 'A sentence is a lovely place to start.';

  @override
  String get yourSpace => 'Your everyday';

  @override
  String get preferencesTitle => 'Make yourself at home';

  @override
  String get habitEditorHint => 'Make a little space for something good.';

  @override
  String get taskEditorHint => 'Capture it now. Make time for it later.';

  @override
  String get notePlaceholder => 'What would you like to remember today?';

  @override
  String get habitPlaceholder => 'For example: read a few pages';

  @override
  String get taskPlaceholder => 'For example: return a friend\'s book';

  @override
  String get unitPlaceholder => 'For example: pages, cups, ml';

  @override
  String get currentRecord => 'Already logged';

  @override
  String get prefillTotal => 'Quick totals';

  @override
  String get confirmBeforeWrite =>
      'Choosing a total fills the field. Only Save updates your record.';

  @override
  String get appName => 'DayPanel';

  @override
  String get extraRecords => 'Other logs for this day';

  @override
  String get notCompleted => 'Not completed';

  @override
  String get today => 'Daily';

  @override
  String get tasks => 'Tasks';

  @override
  String get notes => 'Journal';

  @override
  String get mine => 'You';

  @override
  String get add => 'Add';

  @override
  String get newHabit => 'New habit';

  @override
  String get newTask => 'New task';

  @override
  String get newNote => 'Write a note';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Complete';

  @override
  String get reopen => 'Reopen';

  @override
  String get record => 'Log';

  @override
  String get clearRecord => 'Clear record';

  @override
  String get settings => 'Settings';

  @override
  String get review => 'Seven-day review';

  @override
  String get manageHabits => 'Manage habits';

  @override
  String get title => 'Name';

  @override
  String get noteBody => 'What\'s on your mind?';

  @override
  String get type => 'Tracking';

  @override
  String get checkHabit => 'Check off';

  @override
  String get quantityHabit => 'Quantity';

  @override
  String get target => 'Daily target';

  @override
  String get unit => 'Unit';

  @override
  String get schedule => 'Repeat on';

  @override
  String get everyDay => 'Every day';

  @override
  String get icon => 'Icon';

  @override
  String get dueDate => 'Planned date';

  @override
  String get noDate => 'No date yet';

  @override
  String get chooseDate => 'Choose date';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get english => 'English';

  @override
  String get chinese => '简体中文';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get archived => 'Archived';

  @override
  String get active => 'Active';

  @override
  String get emptyHabits => 'Make room for a small habit';

  @override
  String get emptyHabitsBody =>
      'Start with something you\'d like to keep doing.';

  @override
  String get emptyDay => 'No habits planned for this day';

  @override
  String get emptyDayBody => 'Choose another day, or add a new habit.';

  @override
  String get emptyTasks => 'One little thing at a time';

  @override
  String get emptyTasksBody => 'Write it down. Take it at your own pace.';

  @override
  String get emptyNotes => 'A little room for your thoughts';

  @override
  String get emptyNotesBody => 'An idea, a feeling, or a moment worth keeping.';

  @override
  String get dailyHeading => 'A little good, every day';

  @override
  String get dailySubtitle => 'Small habits. Your own rhythm.';

  @override
  String get todayLabel => 'Today';

  @override
  String get inbox => 'Inbox';

  @override
  String get overdue => 'Overdue';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get completedToday => 'Completed today';

  @override
  String get completedEarlier => 'Completed earlier';

  @override
  String get planned => 'Planned habits';

  @override
  String get allDone => 'Everything planned is done';

  @override
  String get progressHint => 'Take it one small step at a time.';

  @override
  String get date => 'Date';

  @override
  String get total => 'Total for this day';

  @override
  String get quantityHelp =>
      'Enter the daily total, up to 3 decimals, without grouping separators.';

  @override
  String get invalidTitle => 'Please enter a name';

  @override
  String get invalidQuantity => 'Enter a valid number (up to 3 decimals)';

  @override
  String get invalidTarget => 'Target must be greater than zero';

  @override
  String get selectWeekday => 'Select at least one day';

  @override
  String get noteRequired => 'Write something before saving';

  @override
  String get deleteConfirm => 'This cannot be undone. Continue?';

  @override
  String get deleteHabitConfirm => 'Delete this habit and all its records?';

  @override
  String get storageError => 'Couldn\'t read or save your data. Please retry.';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get freeTitle => 'Your everyday, always free';

  @override
  String get freeBody => 'No ads, subscriptions or paid feature gates.';

  @override
  String get localData => 'Stored on this device';

  @override
  String get localDataBody =>
      'Full backup is not available yet. Uninstalling deletes local data.';

  @override
  String get licenses => 'Open-source licenses';

  @override
  String get reviewBody =>
      'Actual log counts. Quantities with different units are never added together.';

  @override
  String get habitLogs => 'Habit logs';

  @override
  String get taskCompletions => 'Tasks completed';

  @override
  String get noReview => 'Your story starts with your first entry.';

  @override
  String get history => 'History';

  @override
  String get notRecorded => 'Not logged';

  @override
  String get futureDate => 'Future days can be planned, but not logged';

  @override
  String get notStarted => 'This habit hadn\'t started yet';

  @override
  String get saved => 'Saved';

  @override
  String get archivedHint =>
      'Archive keeps the history and removes the habit from Daily.';

  @override
  String get weekMon => 'M';

  @override
  String get weekTue => 'T';

  @override
  String get weekWed => 'W';

  @override
  String get weekThu => 'T';

  @override
  String get weekFri => 'F';

  @override
  String get weekSat => 'S';

  @override
  String get weekSun => 'S';

  @override
  String get weekMonFull => 'Monday';

  @override
  String get weekTueFull => 'Tuesday';

  @override
  String get weekWedFull => 'Wednesday';

  @override
  String get weekThuFull => 'Thursday';

  @override
  String get weekFriFull => 'Friday';

  @override
  String get weekSatFull => 'Saturday';

  @override
  String get weekSunFull => 'Sunday';

  @override
  String get more => 'More actions';

  @override
  String get goToday => 'Back to today';

  @override
  String get editHabit => 'Edit habit';

  @override
  String get editTask => 'Edit task';

  @override
  String get editNote => 'Edit note';

  @override
  String get noArchived => 'No archived habits';

  @override
  String get finished => 'Completed';

  @override
  String get habitCount => 'habits';

  @override
  String get habit => 'Habit';

  @override
  String get note => 'Note';

  @override
  String get task => 'Task';
}
