// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get statisticsTitle => 'Statistics & history';

  @override
  String get checkinTable => 'Check-in table';

  @override
  String get habitStatistics => 'Habit statistics';

  @override
  String get yearCalendar => 'Year calendar';

  @override
  String get timelineTitle => 'Timeline';

  @override
  String get historyUnknown => 'History not known';

  @override
  String get notScheduled => 'Not scheduled';

  @override
  String get correctionHint =>
      'Only an explicit save changes this date. Opening or cancelling does not write a record.';

  @override
  String get restoreToCorrect =>
      'Unarchive this habit before correcting records.';

  @override
  String get previousPeriod => 'Previous period';

  @override
  String get nextPeriod => 'Next period';

  @override
  String get tableHint =>
      'Swipe across the week. ✓ achieved · • recorded below target · ○ unlogged · ~ flexible weekly · ? unknown history · — not scheduled. Tap a date to view or correct it.';

  @override
  String get statisticsKnownHint =>
      'Archive history is tracked from this upgrade onward. Earlier unknown days are excluded from rates and streaks. Older plan changes cannot be reconstructed.';

  @override
  String get chooseStatisticsHabit => 'Choose one habit';

  @override
  String get singleHabitStatistics =>
      'Use the habit filter above to inspect its plans, completion and quantities without mixing units.';

  @override
  String get daysLabel => 'days';

  @override
  String get dailyCompletionRate => 'Daily plan completion';

  @override
  String get noDenominator => 'No completed planned days';

  @override
  String get dailyRateHint =>
      'Achieved / planned days through yesterday. Today, flexible weekly goals, archived and unknown dates are excluded.';

  @override
  String get currentRun => 'Current planned-day run';

  @override
  String get bestRun => 'Best planned-day run';

  @override
  String get streakRangeHint =>
      'Within this date range only. Rest days are skipped; today\'s unfinished plan does not break a run.';

  @override
  String get weeklyStatistics => 'Weekly goals';

  @override
  String get noFullWeeks => 'No complete weeks to evaluate';

  @override
  String get completedWeeks => 'weeks achieved';

  @override
  String get weeklyStatsHint =>
      'Only full Monday–Sunday weeks with one plan and known active history count. Partial weeks are excluded; this week is still in progress.';

  @override
  String get currentWeeks => 'Current week run';

  @override
  String get bestWeeks => 'Best week run';

  @override
  String get inProgress => 'In progress';

  @override
  String get partialPeriod => 'Partial / unknown';

  @override
  String get quantityStatistics => 'Recorded quantities';

  @override
  String get quantityStatsHint =>
      'Each historical unit has its own totals and daily bars. Zero is a record; missing days are excluded from the average.';

  @override
  String get noRecordedValues => 'No quantities recorded in this range';

  @override
  String get noUnit => 'No unit';

  @override
  String get quantitySum => 'Total';

  @override
  String get recordedAverage => 'Average per recorded day';

  @override
  String get recordedDays => 'Recorded days';

  @override
  String get trendScrollHint =>
      'Swipe through recorded dates; tap a bar to correct that day.';

  @override
  String get yearCalendarHint =>
      'Color shows the number of actual habit records, including zero values, not a completion rate. Tap a day for details; swipe within a month if needed.';

  @override
  String get allEvents => 'All types';

  @override
  String get timelineHint =>
      'Current saved facts by calendar day. Habit logs, task completion dates, notes and earned cards; no invented times or deleted events.';

  @override
  String get noTimeline => 'No records for this selection';

  @override
  String get noTimelineHint => 'Choose another month, date or type.';

  @override
  String get noRecordHabits => 'Habits without a record';

  @override
  String get cardDawn => 'A little dawn';

  @override
  String get cardRoots => 'Putting down roots';

  @override
  String get cardRiver => 'Finding a way';

  @override
  String get cardSteps => 'One small step';

  @override
  String get cardWindow => 'A window of light';

  @override
  String get cardStars => 'Small constellations';

  @override
  String get todayCard => 'Today\'s card';

  @override
  String get dailyCard => 'Daily card';

  @override
  String get cardKeptHint =>
      'A keepsake of the moment you finished. Later changes or undone logs do not remove this card or your words.';

  @override
  String get cardUnlockHint =>
      'Finish every habit planned for today to earn one card. Flexible weekly goals are excluded; backdated logs do not earn cards.';

  @override
  String get viewCard => 'View card';

  @override
  String get claimCard => 'Collect today\'s card';

  @override
  String get cardCollection => 'Card collection';

  @override
  String get cardCollectionHint =>
      'One day, one keepsake. Open a card to turn it over and keep a few words.';

  @override
  String get allCards => 'All';

  @override
  String get favoriteCards => 'Favorites';

  @override
  String get noFavoriteCards => 'No favorites yet';

  @override
  String get favoriteHint =>
      'Open an earned card and tap Favorite to keep it here.';

  @override
  String get noCards => 'A little collection starts today';

  @override
  String get cardReflection => 'Words on the back';

  @override
  String get emptyReflection =>
      'What would you like to remember about this day?';

  @override
  String get cardMoment => 'A moment of effort, kept for you.';

  @override
  String get cardFront => 'Show artwork';

  @override
  String get cardBack => 'Turn over';

  @override
  String get unfavoriteCard => 'Remove favorite';

  @override
  String get favoriteCard => 'Favorite';

  @override
  String get editReflection => 'Edit reflection';

  @override
  String get cardEvidence => 'Completed when earned';

  @override
  String get cardUnavailable => 'This card is no longer in your data';

  @override
  String get cardRestoreHint =>
      'Return to the collection to see the cards in your current data.';

  @override
  String get reflectionHint =>
      'Save keeps your words. Empty text clears the reflection; Cancel keeps the previous version.';

  @override
  String get completionFeedback => 'Completion feedback';

  @override
  String get completionSound => 'Completion sound';

  @override
  String get completionHaptics => 'Completion haptics';

  @override
  String get feedbackOn => 'On';

  @override
  String get feedbackOff => 'Off';

  @override
  String get feedbackHint =>
      'An optional soft sound or tap after a habit first reaches its target today. Both start off.';

  @override
  String get feedbackSystemHint =>
      'Saved changes, not opening a card, trigger feedback. Silent mode, Do Not Disturb, system volume and haptic settings still apply. Backdated logs, cancellations and repeated values stay quiet.';

  @override
  String get feedbackFailed =>
      'Your record was saved. Feedback was unavailable this time.';

  @override
  String get cardsCount => 'cards';

  @override
  String get noteDate => 'Record date';

  @override
  String get noteHabit => 'Linked habit';

  @override
  String get independentNote => 'Independent notes';

  @override
  String get noteHabitMissing => 'This habit is no longer available';

  @override
  String get noteEditorHint =>
      'Choose a date and an optional habit. Save keeps your words; Cancel discards this edit.';

  @override
  String get noteAssociationHint =>
      'Notes do not mark a habit complete. Archived habits keep their notes.';

  @override
  String get habitJournal => 'Habit journal';

  @override
  String get writeHabitNote => 'Write a log';

  @override
  String get viewHabitNotes => 'All related notes';

  @override
  String get allNotes => 'All notes';

  @override
  String get filterNotes => 'Filter notes';

  @override
  String get searchNotes => 'Search note text';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get allMonths => 'All months';

  @override
  String get thisMonth => 'This month';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get locateDate => 'Find a date';

  @override
  String get showWholeMonth => 'Show whole month';

  @override
  String get journalFilterHint =>
      'Filters combine. Search matches note text only.';

  @override
  String get noNotesFound => 'No matching notes';

  @override
  String get noNotesFoundHint =>
      'Try another word, month or habit. Clear filters to browse this date range.';

  @override
  String get emptyNoteMonth => 'No notes in this date range';

  @override
  String get emptyNoteMonthHint =>
      'Choose another month, view all months, or write a note. New notes start with today\'s date.';

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
      'Replace current content with the copy from before the last restore or legacy import. Later additions and changes will also be replaced.';

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
  String get deleteHabitConfirm =>
      'Delete this habit and its completion records? Linked notes will become independent notes. Earned cards, their original snapshots and reflections will be kept.';

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

  @override
  String get widgetsTitle => 'Home widgets';

  @override
  String get widgetChoose => 'Choose an item to display';

  @override
  String get widgetConfigHint =>
      'Each widget keeps its own choice. Save to return to your home screen.';

  @override
  String get widgetEmpty =>
      'No items yet. Create a habit or task in the app first.';

  @override
  String get widgetExpired =>
      'The content or date changed. Return to your home screen and open again. After restoring data, choose the widget item again.';

  @override
  String get widgetOpenApp => 'Open DayPanel';

  @override
  String get widgetClose => 'Return to home screen';

  @override
  String get widgetSaving => 'Saving your record';

  @override
  String get widgetHelp =>
      'Touch and hold your home screen, choose Widgets, then add a DayPanel habit or task. Resize it or use its settings to choose another item. Battery saving may delay updates; reopen the app after a force stop. Widget choices stay on this device.';

  @override
  String get widgetOpening => 'Opening your record';

  @override
  String get appearancePreview => 'Appearance preview';

  @override
  String get appearanceHint =>
      'Try it here. Only Save applies your choices. All styles are free.';

  @override
  String get appearanceSample => 'Typography sample';

  @override
  String get appearanceSampleText =>
      'Make room for the little things you enjoy.';

  @override
  String get appearanceMode => 'Display mode';

  @override
  String get appearancePalette => 'Color theme';

  @override
  String get paletteBlue => 'Daylight desk';

  @override
  String get paletteTeal => 'Morning grove';

  @override
  String get paletteViolet => 'Twilight garden';

  @override
  String get appearanceFont => 'Font';

  @override
  String get fontSystem => 'System font';

  @override
  String get fontSerif => 'Book serif';

  @override
  String get fontHint =>
      'Book serif uses bundled Noto Serif SC, with no download. Home widgets use the Android system font.';

  @override
  String get appearanceFrame => 'Default icon frame';

  @override
  String get frameSoft => 'Soft tile';

  @override
  String get frameRing => 'Ring';

  @override
  String get framePlain => 'Plain';

  @override
  String get followDefault => 'Use default';

  @override
  String get automaticColor => 'Original colors';

  @override
  String get appearanceReset => 'Preview defaults';

  @override
  String get habitDecoration => 'Icon and style';

  @override
  String get habitColor => 'Frame accent';

  @override
  String get habitFrame => 'Icon frame';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorViolet => 'Violet';

  @override
  String get colorPeach => 'Orange';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorRose => 'Rose';

  @override
  String get decorationHint =>
      'Illustrations keep their original colors. The accent changes the frame and item details; your plan stays the same.';

  @override
  String get iconSun => 'Sun';

  @override
  String get iconWater => 'Water';

  @override
  String get iconBook => 'Reading';

  @override
  String get iconWalk => 'Walking';

  @override
  String get iconHeart => 'Heart';

  @override
  String get iconMoon => 'Moon';

  @override
  String get iconStrength => 'Strength';

  @override
  String get iconMeditate => 'Stretching';

  @override
  String get iconRun => 'Running';

  @override
  String get iconBike => 'Cycling';

  @override
  String get iconMeal => 'Meals';

  @override
  String get iconFlower => 'Flower';

  @override
  String get iconMusic => 'Music';

  @override
  String get iconArt => 'Art';

  @override
  String get iconWrite => 'Writing';

  @override
  String get iconLanguage => 'Language';

  @override
  String get iconSavings => 'Savings';

  @override
  String get iconClean => 'Tidying';

  @override
  String get iconPet => 'Pet';

  @override
  String get iconCoffee => 'Coffee';

  @override
  String get iconMedicine => 'Medicine';

  @override
  String get iconSleep => 'Sleep';

  @override
  String get iconUnplug => 'Unplug';

  @override
  String get iconCare => 'Care';

  @override
  String get legacyTitle => 'Import old habits';

  @override
  String get legacyIntro =>
      'Append habits and actual records from a Loop database backup. Keep existing content. Review before importing.';

  @override
  String get legacyPick => 'Choose Loop backup .db';

  @override
  String get legacySupported =>
      'Supports Loop database versions 21–25, up to 8 MiB. ZIP, CSV and other app backups are not supported. Export a complete database from the old app.';

  @override
  String get legacyDifference =>
      'Only actual records transfer. Automatic coverage is not completion. Skips and notes become journal entries. Past schedules, target changes and archive history cannot be reconstructed; earlier days are not counted as failures. Reminders, scores, colors and old tasks/scenes are not imported. Quantities use the unit saved in the file. The start date is the earliest record, or the import day when empty; it is not the original creation date. In files without UUIDs, renaming may create a new identity, so avoid repeated imports.';

  @override
  String get legacyReview => 'Review import';

  @override
  String get legacyExisting => 'Already here; keep current content';

  @override
  String get legacyUnsupported => 'This item cannot be imported';

  @override
  String get legacyAtMost =>
      'At-most targets are not supported; their meaning will not be reversed.';

  @override
  String get legacyTarget =>
      'Targets must be positive with at most three decimal places.';

  @override
  String get legacyLength =>
      'The name or unit is too long. Adjust it in the old app first.';

  @override
  String get legacySourceFrequency => 'Source frequency (times/days)';

  @override
  String get legacyRecords => 'Actual records';

  @override
  String get legacyIgnored => 'Automatic/unknown (not completion)';

  @override
  String get legacySkips => 'Skips (saved as journal)';

  @override
  String get legacyNotes => 'Journal entries (including source note)';

  @override
  String get legacyChooseSchedule => 'Choose the schedule after import';

  @override
  String get legacyScheduleHint =>
      'Rolling frequency differs from fixed intervals and calendar weeks. Choose your future schedule. Unknown earlier days will not be counted as failures. Intervals start on the import day.';

  @override
  String get legacyDaily => 'Every day';

  @override
  String get legacyWeekly => 'Days per calendar week';

  @override
  String get legacyInterval => 'Every N days';

  @override
  String get legacyCount => 'Number of days';

  @override
  String get legacyAcknowledge =>
      'I understand the differences and confirm the selected schedules';

  @override
  String get legacyConfirm => 'Append selected habits';

  @override
  String get legacyDone =>
      'Import complete. Existing content is preserved. Data & backup can restore the copy from before import.';

  @override
  String get legacyInvalid =>
      'The file is damaged, unsupported or contains invalid records. Your data is unchanged.';

  @override
  String get legacyFailed =>
      'Import could not finish. The content or date may have changed. Select the file again.';

  @override
  String get legacyEmpty =>
      'No habits to append. Existing habits are never overwritten or merged.';

  @override
  String get legacyRecovery =>
      'The latest full copy from before import is kept. Rollback also replaces later changes. Export a file first if you need a lasting copy.';

  @override
  String get offlineTransferTitle => 'Move devices offline';

  @override
  String get offlineTransferBody =>
      '1. Export a full DayPanel JSON backup on the old device.\n2. Transfer the file yourself using USB or file transfer.\n3. Choose Restore from file on the new device and review before confirming.\n4. Set notification permissions and widgets again.\n\nThere is no cloud sync or automatic backup. Files are not encrypted; keep them private. Uninstalling deletes app data and the rollback copy. Keep exported files outside the app.';

  @override
  String get uiAppearanceHint =>
      'Choose the colors and type that feel like you.';

  @override
  String get uiPreviewLive => 'Live preview';

  @override
  String get uiPreviewHint => 'Applies to every page when saved';

  @override
  String get uiFontSample => 'A little progress, every day';

  @override
  String get uiMoreDetails => 'Details';

  @override
  String get uiBackupHint => 'Keep your days in your own hands.';

  @override
  String get uiExportHint =>
      'Save a complete copy for safekeeping or a new device.';

  @override
  String get uiRestoreHint => 'Review a backup before replacing current data.';

  @override
  String get uiLegacyHint =>
      'Bring habits from Loop while keeping current content.';

  @override
  String get uiRecoveryHint =>
      'A complete copy from before your last import or restore';

  @override
  String get uiFileScope => 'Supported files';

  @override
  String get uiChooseFile => 'Choose a backup file';

  @override
  String get uiChooseItems => 'Choose items';

  @override
  String get uiReviewImport => 'Review import';

  @override
  String get uiContinue => 'Continue';

  @override
  String get uiBack => 'Back';

  @override
  String get uiChangeFile => 'Choose another file';

  @override
  String get uiImportSelectHint =>
      'Choose the habits to bring over and their future schedules.';

  @override
  String get uiImportReviewHint =>
      'Your current content stays. Only selected items are added.';

  @override
  String get uiImportRules => 'What changes after import';

  @override
  String get uiImportNoSelection => 'Choose at least one supported habit';

  @override
  String get uiImportNeedsSchedule =>
      'Choose a schedule for each selected habit';

  @override
  String uiSelectedCount(int count) {
    return '$count habits selected';
  }

  @override
  String uiRecordCount(int count) {
    return '$count records';
  }

  @override
  String get uiNeedsSchedule => 'Schedule needed';

  @override
  String get uiSchedule => 'New schedule';

  @override
  String get uiImportedDone => 'Your habits are here';

  @override
  String get uiReturnData => 'Back to data & backup';

  @override
  String get uiWidgetChooseHint =>
      'Keep a habit or task within reach on your home screen.';

  @override
  String get uiNoWidgetChoice => 'Choose an item to show';

  @override
  String get uiReminderIntro => 'A gentle reminder at the right time.';

  @override
  String get uiReminderRules => 'How reminders work';

  @override
  String get uiStatisticsHelp => 'How these numbers are calculated';

  @override
  String get uiShowDetails => 'Record details';

  @override
  String get uiTabTable => 'Table';

  @override
  String get uiTabHabits => 'Habits';

  @override
  String get uiTabYear => 'Year';

  @override
  String get uiTabTimeline => 'Timeline';

  @override
  String get restTitle => 'Rest days';

  @override
  String get restPaused => 'Paused';

  @override
  String get restVacation => 'On a break';

  @override
  String get restSkipped => 'Skipped this day';

  @override
  String get restPause => 'Pause from today';

  @override
  String get restPlanVacation => 'Plan a break';

  @override
  String get restSkip => 'Skip this day';

  @override
  String get restUnskip => 'Remove skip';

  @override
  String get restResume => 'Resume today';

  @override
  String get restCancelFuture => 'Cancel this break';

  @override
  String get restHint =>
      'Rest days count as neither failure nor completion. History stays and reminders pause.';

  @override
  String get restRules =>
      'Daily streaks pass over rest days. Weeks containing rest days are excluded from full-week assessments. No card is earned when all habits rest. Resuming keeps the original plan.';

  @override
  String get restConflict =>
      'These dates overlap a break, or this day already has a record. Check and retry.';

  @override
  String get restEnded => 'Ended';

  @override
  String get restUntilResume => 'Until you resume';

  @override
  String get restRange => 'Choose start and end dates';

  @override
  String get restConfirmSkip =>
      'Skipping affects only this day and keeps all other records.';

  @override
  String get restRecordBlocked =>
      'This is a rest day. End or cancel the break before logging.';

  @override
  String get cardShare => 'Share card';

  @override
  String get cardSaveImage => 'Save image';

  @override
  String get cardShareAction => 'Share';

  @override
  String get cardShareNames => 'Include habit names';

  @override
  String get cardShareReflection => 'Include a reflection';

  @override
  String get cardShareExcerpt =>
      'Share excerpt (keeps the original reflection)';

  @override
  String get cardShareHint =>
      'This preview is the image you will save or share. Names and reflections are hidden by default.';

  @override
  String get cardImageSaved => 'Image saved';

  @override
  String get cardImageFailed =>
      'Could not create or save the image. Try again.';

  @override
  String get cardShareStale => 'Card data changed. Reopen the share page.';

  @override
  String cardShareMore(int count) {
    return 'And $count more';
  }

  @override
  String cardShareCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count habits completed',
      one: '1 habit completed',
    );
    return '$_temp0';
  }

  @override
  String get restRangeLimit => 'Choose up to 365 days';

  @override
  String get restSchedule => 'Breaks and history';

  @override
  String get restStale =>
      'This habit changed. Reopen its rest days to continue.';

  @override
  String get restConfirmUnskip =>
      'This day will follow its original plan again. No completion record will be added.';

  @override
  String get habitLibrary => 'Habit library';

  @override
  String get habitLibraryTitle => 'Make room for a little good';

  @override
  String get habitLibraryHint =>
      'Start with a familiar habit. Adjust its goal before adding it.';

  @override
  String get searchHabits => 'Search everyday habits';

  @override
  String get templateNoMatch => 'No matching template. Create your own below.';

  @override
  String get customHabit => 'Create your own';

  @override
  String get templateDailyCheck => 'Every day · check off';

  @override
  String templateDailyGoal(String amount, String unit) {
    return '$amount $unit / day';
  }

  @override
  String get templateEditable =>
      'A starting goal, ready to adjust to your day.';

  @override
  String suggestedIcon(String name) {
    return 'Suggested icon: $name';
  }

  @override
  String get iconSuggestionHint =>
      'Apply the icon only; keep your goal and schedule.';

  @override
  String get paletteCompositionHint =>
      'A coordinated palette for actions, notes and everyday details. Habit illustrations keep their own colors.';
}
