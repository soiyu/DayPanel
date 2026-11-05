import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @dailyCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Little steps, real progress'**
  String get dailyCardTitle;

  /// No description provided for @journalHeading.
  ///
  /// In en, this message translates to:
  /// **'A page for your everyday'**
  String get journalHeading;

  /// No description provided for @journalEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'A sentence is a lovely place to start.'**
  String get journalEmptyHint;

  /// No description provided for @yourSpace.
  ///
  /// In en, this message translates to:
  /// **'Your everyday'**
  String get yourSpace;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Make yourself at home'**
  String get preferencesTitle;

  /// No description provided for @habitEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Make a little space for something good.'**
  String get habitEditorHint;

  /// No description provided for @taskEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Capture it now. Make time for it later.'**
  String get taskEditorHint;

  /// No description provided for @notePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'What would you like to remember today?'**
  String get notePlaceholder;

  /// No description provided for @habitPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example: read a few pages'**
  String get habitPlaceholder;

  /// No description provided for @taskPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example: return a friend\'s book'**
  String get taskPlaceholder;

  /// No description provided for @unitPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'For example: pages, cups, ml'**
  String get unitPlaceholder;

  /// No description provided for @currentRecord.
  ///
  /// In en, this message translates to:
  /// **'Already logged'**
  String get currentRecord;

  /// No description provided for @prefillTotal.
  ///
  /// In en, this message translates to:
  /// **'Quick totals'**
  String get prefillTotal;

  /// No description provided for @confirmBeforeWrite.
  ///
  /// In en, this message translates to:
  /// **'Choosing a total fills the field. Only Save updates your record.'**
  String get confirmBeforeWrite;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'DayPanel'**
  String get appName;

  /// No description provided for @extraRecords.
  ///
  /// In en, this message translates to:
  /// **'Other logs for this day'**
  String get extraRecords;

  /// No description provided for @notCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get notCompleted;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get today;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get notes;

  /// No description provided for @mine.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get mine;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @newHabit.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get newHabit;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'Write a note'**
  String get newNote;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get done;

  /// No description provided for @reopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopen;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get record;

  /// No description provided for @clearRecord.
  ///
  /// In en, this message translates to:
  /// **'Clear record'**
  String get clearRecord;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Seven-day review'**
  String get review;

  /// No description provided for @manageHabits.
  ///
  /// In en, this message translates to:
  /// **'Manage habits'**
  String get manageHabits;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get title;

  /// No description provided for @noteBody.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get noteBody;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get type;

  /// No description provided for @checkHabit.
  ///
  /// In en, this message translates to:
  /// **'Check off'**
  String get checkHabit;

  /// No description provided for @quantityHabit.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityHabit;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Daily target'**
  String get target;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Repeat on'**
  String get schedule;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Planned date'**
  String get dueDate;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No date yet'**
  String get noDate;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get chooseDate;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get chinese;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @emptyHabits.
  ///
  /// In en, this message translates to:
  /// **'Make room for a small habit'**
  String get emptyHabits;

  /// No description provided for @emptyHabitsBody.
  ///
  /// In en, this message translates to:
  /// **'Start with something you\'d like to keep doing.'**
  String get emptyHabitsBody;

  /// No description provided for @emptyDay.
  ///
  /// In en, this message translates to:
  /// **'No habits planned for this day'**
  String get emptyDay;

  /// No description provided for @emptyDayBody.
  ///
  /// In en, this message translates to:
  /// **'Choose another day, or add a new habit.'**
  String get emptyDayBody;

  /// No description provided for @emptyTasks.
  ///
  /// In en, this message translates to:
  /// **'One little thing at a time'**
  String get emptyTasks;

  /// No description provided for @emptyTasksBody.
  ///
  /// In en, this message translates to:
  /// **'Write it down. Take it at your own pace.'**
  String get emptyTasksBody;

  /// No description provided for @emptyNotes.
  ///
  /// In en, this message translates to:
  /// **'A little room for your thoughts'**
  String get emptyNotes;

  /// No description provided for @emptyNotesBody.
  ///
  /// In en, this message translates to:
  /// **'An idea, a feeling, or a moment worth keeping.'**
  String get emptyNotesBody;

  /// No description provided for @dailyHeading.
  ///
  /// In en, this message translates to:
  /// **'A little good, every day'**
  String get dailyHeading;

  /// No description provided for @dailySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Small habits. Your own rhythm.'**
  String get dailySubtitle;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @completedToday.
  ///
  /// In en, this message translates to:
  /// **'Completed today'**
  String get completedToday;

  /// No description provided for @completedEarlier.
  ///
  /// In en, this message translates to:
  /// **'Completed earlier'**
  String get completedEarlier;

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'Planned habits'**
  String get planned;

  /// No description provided for @allDone.
  ///
  /// In en, this message translates to:
  /// **'Everything planned is done'**
  String get allDone;

  /// No description provided for @progressHint.
  ///
  /// In en, this message translates to:
  /// **'Take it one small step at a time.'**
  String get progressHint;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total for this day'**
  String get total;

  /// No description provided for @quantityHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter the daily total, up to 3 decimals, without grouping separators.'**
  String get quantityHelp;

  /// No description provided for @invalidTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get invalidTitle;

  /// No description provided for @invalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number (up to 3 decimals)'**
  String get invalidQuantity;

  /// No description provided for @invalidTarget.
  ///
  /// In en, this message translates to:
  /// **'Target must be greater than zero'**
  String get invalidTarget;

  /// No description provided for @selectWeekday.
  ///
  /// In en, this message translates to:
  /// **'Select at least one day'**
  String get selectWeekday;

  /// No description provided for @noteRequired.
  ///
  /// In en, this message translates to:
  /// **'Write something before saving'**
  String get noteRequired;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Continue?'**
  String get deleteConfirm;

  /// No description provided for @deleteHabitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this habit and all its records?'**
  String get deleteHabitConfirm;

  /// No description provided for @storageError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read or save your data. Please retry.'**
  String get storageError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @freeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your everyday, always free'**
  String get freeTitle;

  /// No description provided for @freeBody.
  ///
  /// In en, this message translates to:
  /// **'No ads, subscriptions or paid feature gates.'**
  String get freeBody;

  /// No description provided for @localData.
  ///
  /// In en, this message translates to:
  /// **'Stored on this device'**
  String get localData;

  /// No description provided for @localDataBody.
  ///
  /// In en, this message translates to:
  /// **'Full backup is not available yet. Uninstalling deletes local data.'**
  String get localDataBody;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get licenses;

  /// No description provided for @reviewBody.
  ///
  /// In en, this message translates to:
  /// **'Actual log counts. Quantities with different units are never added together.'**
  String get reviewBody;

  /// No description provided for @habitLogs.
  ///
  /// In en, this message translates to:
  /// **'Habit logs'**
  String get habitLogs;

  /// No description provided for @taskCompletions.
  ///
  /// In en, this message translates to:
  /// **'Tasks completed'**
  String get taskCompletions;

  /// No description provided for @noReview.
  ///
  /// In en, this message translates to:
  /// **'Your story starts with your first entry.'**
  String get noReview;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @notRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not logged'**
  String get notRecorded;

  /// No description provided for @futureDate.
  ///
  /// In en, this message translates to:
  /// **'Future days can be planned, but not logged'**
  String get futureDate;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'This habit hadn\'t started yet'**
  String get notStarted;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @archivedHint.
  ///
  /// In en, this message translates to:
  /// **'Archive keeps the history and removes the habit from Daily.'**
  String get archivedHint;

  /// No description provided for @weekMon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get weekMon;

  /// No description provided for @weekTue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get weekTue;

  /// No description provided for @weekWed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get weekWed;

  /// No description provided for @weekThu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get weekThu;

  /// No description provided for @weekFri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get weekFri;

  /// No description provided for @weekSat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get weekSat;

  /// No description provided for @weekSun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get weekSun;

  /// No description provided for @weekMonFull.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekMonFull;

  /// No description provided for @weekTueFull.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekTueFull;

  /// No description provided for @weekWedFull.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekWedFull;

  /// No description provided for @weekThuFull.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekThuFull;

  /// No description provided for @weekFriFull.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekFriFull;

  /// No description provided for @weekSatFull.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekSatFull;

  /// No description provided for @weekSunFull.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekSunFull;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get more;

  /// No description provided for @goToday.
  ///
  /// In en, this message translates to:
  /// **'Back to today'**
  String get goToday;

  /// No description provided for @editHabit.
  ///
  /// In en, this message translates to:
  /// **'Edit habit'**
  String get editHabit;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @noArchived.
  ///
  /// In en, this message translates to:
  /// **'No archived habits'**
  String get noArchived;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get finished;

  /// No description provided for @habitCount.
  ///
  /// In en, this message translates to:
  /// **'habits'**
  String get habitCount;

  /// No description provided for @habit.
  ///
  /// In en, this message translates to:
  /// **'Habit'**
  String get habit;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
