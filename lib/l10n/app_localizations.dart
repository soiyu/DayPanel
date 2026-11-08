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

  /// No description provided for @statisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics & history'**
  String get statisticsTitle;

  /// No description provided for @checkinTable.
  ///
  /// In en, this message translates to:
  /// **'Check-in table'**
  String get checkinTable;

  /// No description provided for @habitStatistics.
  ///
  /// In en, this message translates to:
  /// **'Habit statistics'**
  String get habitStatistics;

  /// No description provided for @yearCalendar.
  ///
  /// In en, this message translates to:
  /// **'Year calendar'**
  String get yearCalendar;

  /// No description provided for @timelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineTitle;

  /// No description provided for @historyUnknown.
  ///
  /// In en, this message translates to:
  /// **'History not known'**
  String get historyUnknown;

  /// No description provided for @notScheduled.
  ///
  /// In en, this message translates to:
  /// **'Not scheduled'**
  String get notScheduled;

  /// No description provided for @correctionHint.
  ///
  /// In en, this message translates to:
  /// **'Only an explicit save changes this date. Opening or cancelling does not write a record.'**
  String get correctionHint;

  /// No description provided for @restoreToCorrect.
  ///
  /// In en, this message translates to:
  /// **'Unarchive this habit before correcting records.'**
  String get restoreToCorrect;

  /// No description provided for @previousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get previousPeriod;

  /// No description provided for @nextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get nextPeriod;

  /// No description provided for @tableHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe across the week. ✓ achieved · • recorded below target · ○ unlogged · ~ flexible weekly · ? unknown history · — not scheduled. Tap a date to view or correct it.'**
  String get tableHint;

  /// No description provided for @statisticsKnownHint.
  ///
  /// In en, this message translates to:
  /// **'Archive history is tracked from this upgrade onward. Earlier unknown days are excluded from rates and streaks. Older plan changes cannot be reconstructed.'**
  String get statisticsKnownHint;

  /// No description provided for @chooseStatisticsHabit.
  ///
  /// In en, this message translates to:
  /// **'Choose one habit'**
  String get chooseStatisticsHabit;

  /// No description provided for @singleHabitStatistics.
  ///
  /// In en, this message translates to:
  /// **'Use the habit filter above to inspect its plans, completion and quantities without mixing units.'**
  String get singleHabitStatistics;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysLabel;

  /// No description provided for @dailyCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Daily plan completion'**
  String get dailyCompletionRate;

  /// No description provided for @noDenominator.
  ///
  /// In en, this message translates to:
  /// **'No completed planned days'**
  String get noDenominator;

  /// No description provided for @dailyRateHint.
  ///
  /// In en, this message translates to:
  /// **'Achieved / planned days through yesterday. Today, flexible weekly goals, archived and unknown dates are excluded.'**
  String get dailyRateHint;

  /// No description provided for @currentRun.
  ///
  /// In en, this message translates to:
  /// **'Current planned-day run'**
  String get currentRun;

  /// No description provided for @bestRun.
  ///
  /// In en, this message translates to:
  /// **'Best planned-day run'**
  String get bestRun;

  /// No description provided for @streakRangeHint.
  ///
  /// In en, this message translates to:
  /// **'Within this date range only. Rest days are skipped; today\'s unfinished plan does not break a run.'**
  String get streakRangeHint;

  /// No description provided for @weeklyStatistics.
  ///
  /// In en, this message translates to:
  /// **'Weekly goals'**
  String get weeklyStatistics;

  /// No description provided for @noFullWeeks.
  ///
  /// In en, this message translates to:
  /// **'No complete weeks to evaluate'**
  String get noFullWeeks;

  /// No description provided for @completedWeeks.
  ///
  /// In en, this message translates to:
  /// **'weeks achieved'**
  String get completedWeeks;

  /// No description provided for @weeklyStatsHint.
  ///
  /// In en, this message translates to:
  /// **'Only full Monday–Sunday weeks with one plan and known active history count. Partial weeks are excluded; this week is still in progress.'**
  String get weeklyStatsHint;

  /// No description provided for @currentWeeks.
  ///
  /// In en, this message translates to:
  /// **'Current week run'**
  String get currentWeeks;

  /// No description provided for @bestWeeks.
  ///
  /// In en, this message translates to:
  /// **'Best week run'**
  String get bestWeeks;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @partialPeriod.
  ///
  /// In en, this message translates to:
  /// **'Partial / unknown'**
  String get partialPeriod;

  /// No description provided for @quantityStatistics.
  ///
  /// In en, this message translates to:
  /// **'Recorded quantities'**
  String get quantityStatistics;

  /// No description provided for @quantityStatsHint.
  ///
  /// In en, this message translates to:
  /// **'Each historical unit has its own totals and daily bars. Zero is a record; missing days are excluded from the average.'**
  String get quantityStatsHint;

  /// No description provided for @noRecordedValues.
  ///
  /// In en, this message translates to:
  /// **'No quantities recorded in this range'**
  String get noRecordedValues;

  /// No description provided for @noUnit.
  ///
  /// In en, this message translates to:
  /// **'No unit'**
  String get noUnit;

  /// No description provided for @quantitySum.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get quantitySum;

  /// No description provided for @recordedAverage.
  ///
  /// In en, this message translates to:
  /// **'Average per recorded day'**
  String get recordedAverage;

  /// No description provided for @recordedDays.
  ///
  /// In en, this message translates to:
  /// **'Recorded days'**
  String get recordedDays;

  /// No description provided for @trendScrollHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe through recorded dates; tap a bar to correct that day.'**
  String get trendScrollHint;

  /// No description provided for @yearCalendarHint.
  ///
  /// In en, this message translates to:
  /// **'Color shows the number of actual habit records, including zero values, not a completion rate. Tap a day for details; swipe within a month if needed.'**
  String get yearCalendarHint;

  /// No description provided for @allEvents.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get allEvents;

  /// No description provided for @timelineHint.
  ///
  /// In en, this message translates to:
  /// **'Current saved facts by calendar day. Habit logs, task completion dates, notes and earned cards; no invented times or deleted events.'**
  String get timelineHint;

  /// No description provided for @noTimeline.
  ///
  /// In en, this message translates to:
  /// **'No records for this selection'**
  String get noTimeline;

  /// No description provided for @noTimelineHint.
  ///
  /// In en, this message translates to:
  /// **'Choose another month, date or type.'**
  String get noTimelineHint;

  /// No description provided for @noRecordHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits without a record'**
  String get noRecordHabits;

  /// No description provided for @cardDawn.
  ///
  /// In en, this message translates to:
  /// **'A little dawn'**
  String get cardDawn;

  /// No description provided for @cardRoots.
  ///
  /// In en, this message translates to:
  /// **'Putting down roots'**
  String get cardRoots;

  /// No description provided for @cardRiver.
  ///
  /// In en, this message translates to:
  /// **'Finding a way'**
  String get cardRiver;

  /// No description provided for @cardSteps.
  ///
  /// In en, this message translates to:
  /// **'One small step'**
  String get cardSteps;

  /// No description provided for @cardWindow.
  ///
  /// In en, this message translates to:
  /// **'A window of light'**
  String get cardWindow;

  /// No description provided for @cardStars.
  ///
  /// In en, this message translates to:
  /// **'Small constellations'**
  String get cardStars;

  /// No description provided for @todayCard.
  ///
  /// In en, this message translates to:
  /// **'Today\'s card'**
  String get todayCard;

  /// No description provided for @dailyCard.
  ///
  /// In en, this message translates to:
  /// **'Daily card'**
  String get dailyCard;

  /// No description provided for @cardKeptHint.
  ///
  /// In en, this message translates to:
  /// **'A keepsake of the moment you finished. Later changes or undone logs do not remove this card or your words.'**
  String get cardKeptHint;

  /// No description provided for @cardUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'Finish every habit planned for today to earn one card. Flexible weekly goals are excluded; backdated logs do not earn cards.'**
  String get cardUnlockHint;

  /// No description provided for @viewCard.
  ///
  /// In en, this message translates to:
  /// **'View card'**
  String get viewCard;

  /// No description provided for @claimCard.
  ///
  /// In en, this message translates to:
  /// **'Collect today\'s card'**
  String get claimCard;

  /// No description provided for @cardCollection.
  ///
  /// In en, this message translates to:
  /// **'Card collection'**
  String get cardCollection;

  /// No description provided for @cardCollectionHint.
  ///
  /// In en, this message translates to:
  /// **'One day, one keepsake. Open a card to turn it over and keep a few words.'**
  String get cardCollectionHint;

  /// No description provided for @allCards.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCards;

  /// No description provided for @favoriteCards.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoriteCards;

  /// No description provided for @noFavoriteCards.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoriteCards;

  /// No description provided for @favoriteHint.
  ///
  /// In en, this message translates to:
  /// **'Open an earned card and tap Favorite to keep it here.'**
  String get favoriteHint;

  /// No description provided for @noCards.
  ///
  /// In en, this message translates to:
  /// **'A little collection starts today'**
  String get noCards;

  /// No description provided for @cardReflection.
  ///
  /// In en, this message translates to:
  /// **'Words on the back'**
  String get cardReflection;

  /// No description provided for @emptyReflection.
  ///
  /// In en, this message translates to:
  /// **'What would you like to remember about this day?'**
  String get emptyReflection;

  /// No description provided for @cardMoment.
  ///
  /// In en, this message translates to:
  /// **'A moment of effort, kept for you.'**
  String get cardMoment;

  /// No description provided for @cardFront.
  ///
  /// In en, this message translates to:
  /// **'Show artwork'**
  String get cardFront;

  /// No description provided for @cardBack.
  ///
  /// In en, this message translates to:
  /// **'Turn over'**
  String get cardBack;

  /// No description provided for @unfavoriteCard.
  ///
  /// In en, this message translates to:
  /// **'Remove favorite'**
  String get unfavoriteCard;

  /// No description provided for @favoriteCard.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favoriteCard;

  /// No description provided for @editReflection.
  ///
  /// In en, this message translates to:
  /// **'Edit reflection'**
  String get editReflection;

  /// No description provided for @cardEvidence.
  ///
  /// In en, this message translates to:
  /// **'Completed when earned'**
  String get cardEvidence;

  /// No description provided for @cardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This card is no longer in your data'**
  String get cardUnavailable;

  /// No description provided for @cardRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Return to the collection to see the cards in your current data.'**
  String get cardRestoreHint;

  /// No description provided for @reflectionHint.
  ///
  /// In en, this message translates to:
  /// **'Save keeps your words. Empty text clears the reflection; Cancel keeps the previous version.'**
  String get reflectionHint;

  /// No description provided for @completionFeedback.
  ///
  /// In en, this message translates to:
  /// **'Completion feedback'**
  String get completionFeedback;

  /// No description provided for @completionSound.
  ///
  /// In en, this message translates to:
  /// **'Completion sound'**
  String get completionSound;

  /// No description provided for @completionHaptics.
  ///
  /// In en, this message translates to:
  /// **'Completion haptics'**
  String get completionHaptics;

  /// No description provided for @feedbackOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get feedbackOn;

  /// No description provided for @feedbackOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get feedbackOff;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'An optional soft sound or tap after a habit first reaches its target today. Both start off.'**
  String get feedbackHint;

  /// No description provided for @feedbackSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Saved changes, not opening a card, trigger feedback. Silent mode, Do Not Disturb, system volume and haptic settings still apply. Backdated logs, cancellations and repeated values stay quiet.'**
  String get feedbackSystemHint;

  /// No description provided for @feedbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Your record was saved. Feedback was unavailable this time.'**
  String get feedbackFailed;

  /// No description provided for @cardsCount.
  ///
  /// In en, this message translates to:
  /// **'cards'**
  String get cardsCount;

  /// No description provided for @noteDate.
  ///
  /// In en, this message translates to:
  /// **'Record date'**
  String get noteDate;

  /// No description provided for @noteHabit.
  ///
  /// In en, this message translates to:
  /// **'Linked habit'**
  String get noteHabit;

  /// No description provided for @independentNote.
  ///
  /// In en, this message translates to:
  /// **'Independent notes'**
  String get independentNote;

  /// No description provided for @noteHabitMissing.
  ///
  /// In en, this message translates to:
  /// **'This habit is no longer available'**
  String get noteHabitMissing;

  /// No description provided for @noteEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a date and an optional habit. Save keeps your words; Cancel discards this edit.'**
  String get noteEditorHint;

  /// No description provided for @noteAssociationHint.
  ///
  /// In en, this message translates to:
  /// **'Notes do not mark a habit complete. Archived habits keep their notes.'**
  String get noteAssociationHint;

  /// No description provided for @habitJournal.
  ///
  /// In en, this message translates to:
  /// **'Habit journal'**
  String get habitJournal;

  /// No description provided for @writeHabitNote.
  ///
  /// In en, this message translates to:
  /// **'Write a log'**
  String get writeHabitNote;

  /// No description provided for @viewHabitNotes.
  ///
  /// In en, this message translates to:
  /// **'All related notes'**
  String get viewHabitNotes;

  /// No description provided for @allNotes.
  ///
  /// In en, this message translates to:
  /// **'All notes'**
  String get allNotes;

  /// No description provided for @filterNotes.
  ///
  /// In en, this message translates to:
  /// **'Filter notes'**
  String get filterNotes;

  /// No description provided for @searchNotes.
  ///
  /// In en, this message translates to:
  /// **'Search note text'**
  String get searchNotes;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @allMonths.
  ///
  /// In en, this message translates to:
  /// **'All months'**
  String get allMonths;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @locateDate.
  ///
  /// In en, this message translates to:
  /// **'Find a date'**
  String get locateDate;

  /// No description provided for @showWholeMonth.
  ///
  /// In en, this message translates to:
  /// **'Show whole month'**
  String get showWholeMonth;

  /// No description provided for @journalFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filters combine. Search matches note text only.'**
  String get journalFilterHint;

  /// No description provided for @noNotesFound.
  ///
  /// In en, this message translates to:
  /// **'No matching notes'**
  String get noNotesFound;

  /// No description provided for @noNotesFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try another word, month or habit. Clear filters to browse this date range.'**
  String get noNotesFoundHint;

  /// No description provided for @emptyNoteMonth.
  ///
  /// In en, this message translates to:
  /// **'No notes in this date range'**
  String get emptyNoteMonth;

  /// No description provided for @emptyNoteMonthHint.
  ///
  /// In en, this message translates to:
  /// **'Choose another month, view all months, or write a note. New notes start with today\'s date.'**
  String get emptyNoteMonthHint;

  /// No description provided for @taskKind.
  ///
  /// In en, this message translates to:
  /// **'Task type'**
  String get taskKind;

  /// No description provided for @oneTimeTask.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get oneTimeTask;

  /// No description provided for @residentTask.
  ///
  /// In en, this message translates to:
  /// **'Keep around'**
  String get residentTask;

  /// No description provided for @residentTasks.
  ///
  /// In en, this message translates to:
  /// **'Keep-around tasks'**
  String get residentTasks;

  /// No description provided for @residentHelp.
  ///
  /// In en, this message translates to:
  /// **'Keep it for whenever you need it. Log once per day, with no due date or overdue backlog.'**
  String get residentHelp;

  /// No description provided for @oneTimeHelp.
  ///
  /// In en, this message translates to:
  /// **'Complete once, then move to history. A planned date is optional.'**
  String get oneTimeHelp;

  /// No description provided for @residentToday.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get residentToday;

  /// No description provided for @residentUnrecorded.
  ///
  /// In en, this message translates to:
  /// **'Not logged today'**
  String get residentUnrecorded;

  /// No description provided for @recordThisDay.
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get recordThisDay;

  /// No description provided for @clearThisDay.
  ///
  /// In en, this message translates to:
  /// **'Clear this day'**
  String get clearThisDay;

  /// No description provided for @residentRecords.
  ///
  /// In en, this message translates to:
  /// **'Keep-around logs'**
  String get residentRecords;

  /// No description provided for @taskHistory.
  ///
  /// In en, this message translates to:
  /// **'Completion history'**
  String get taskHistory;

  /// No description provided for @taskArchive.
  ///
  /// In en, this message translates to:
  /// **'Archived keep-around tasks'**
  String get taskArchive;

  /// No description provided for @taskArchiveHint.
  ///
  /// In en, this message translates to:
  /// **'Archive to hide it from Tasks. Completion history stays available.'**
  String get taskArchiveHint;

  /// No description provided for @residentDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Delete this keep-around task and all its completion records? This cannot be undone.'**
  String get residentDeleteWarning;

  /// No description provided for @residentDetailHint.
  ///
  /// In en, this message translates to:
  /// **'Log the days you did it. Days without a log are not failures.'**
  String get residentDetailHint;

  /// No description provided for @taskTypeFixed.
  ///
  /// In en, this message translates to:
  /// **'The type stays fixed after creation so existing records keep their meaning.'**
  String get taskTypeFixed;

  /// No description provided for @noTaskHistory.
  ///
  /// In en, this message translates to:
  /// **'No completions for this day'**
  String get noTaskHistory;

  /// No description provided for @noArchivedTasks.
  ///
  /// In en, this message translates to:
  /// **'No archived keep-around tasks'**
  String get noArchivedTasks;

  /// No description provided for @residentStart.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get residentStart;

  /// No description provided for @editTaskHistory.
  ///
  /// In en, this message translates to:
  /// **'View & correct records'**
  String get editTaskHistory;

  /// No description provided for @residentHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a date to log or correct. Only that day changes.'**
  String get residentHistoryHint;

  /// No description provided for @historyShowsBoth.
  ///
  /// In en, this message translates to:
  /// **'One-time tasks use their actual completion date. Keep-around tasks use each logged date.'**
  String get historyShowsBoth;

  /// No description provided for @residentTypeChoice.
  ///
  /// In en, this message translates to:
  /// **'Choose a task type'**
  String get residentTypeChoice;

  /// No description provided for @taskHistoryCount.
  ///
  /// In en, this message translates to:
  /// **'Completions'**
  String get taskHistoryCount;

  /// No description provided for @taskSummaryPending.
  ///
  /// In en, this message translates to:
  /// **'Open one-time tasks'**
  String get taskSummaryPending;

  /// No description provided for @taskSummaryToday.
  ///
  /// In en, this message translates to:
  /// **'Completed today'**
  String get taskSummaryToday;

  /// No description provided for @taskHistoryEditHint.
  ///
  /// In en, this message translates to:
  /// **'Open an item to edit or correct it. Archived items remain here.'**
  String get taskHistoryEditHint;

  /// No description provided for @habitReminder.
  ///
  /// In en, this message translates to:
  /// **'Habit reminder'**
  String get habitReminder;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @remindersIntro.
  ///
  /// In en, this message translates to:
  /// **'Make a little time for your habits, at the right moments.'**
  String get remindersIntro;

  /// No description provided for @reminderOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get reminderOff;

  /// No description provided for @reminderOn.
  ///
  /// In en, this message translates to:
  /// **'Enable reminder'**
  String get reminderOn;

  /// No description provided for @reminderTimes.
  ///
  /// In en, this message translates to:
  /// **'Reminder times'**
  String get reminderTimes;

  /// No description provided for @addReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Add a time'**
  String get addReminderTime;

  /// No description provided for @reminderLimit.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 5 different times.'**
  String get reminderLimit;

  /// No description provided for @reminderScheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Remind only on planned days while unfinished. Weekly reminders stop once the weekly goal is reached.'**
  String get reminderScheduleHint;

  /// No description provided for @reminderLocalTime.
  ///
  /// In en, this message translates to:
  /// **'Times follow your current time zone. Turning reminders off keeps your chosen times.'**
  String get reminderLocalTime;

  /// No description provided for @notificationAllowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications are allowed'**
  String get notificationAllowed;

  /// No description provided for @notificationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked'**
  String get notificationBlocked;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get enableNotifications;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @exactReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder timing'**
  String get exactReminder;

  /// No description provided for @exactAvailable.
  ///
  /// In en, this message translates to:
  /// **'Precise timing allowed'**
  String get exactAvailable;

  /// No description provided for @exactUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Standard timing; power saving may delay delivery'**
  String get exactUnavailable;

  /// No description provided for @requestExact.
  ///
  /// In en, this message translates to:
  /// **'Set precise timing'**
  String get requestExact;

  /// No description provided for @reminderSavedBlocked.
  ///
  /// In en, this message translates to:
  /// **'Reminder saved, but notifications are blocked. You can enable them later in Reminders.'**
  String get reminderSavedBlocked;

  /// No description provided for @reminderSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the reminder. Please retry.'**
  String get reminderSaveFailed;

  /// No description provided for @reminderSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Settings are saved, but system scheduling did not update. Retry or reopen the app.'**
  String get reminderSyncFailed;

  /// No description provided for @reminderSystemHint.
  ///
  /// In en, this message translates to:
  /// **'Manage sound and vibration in system notification settings. After force-stopping the app, reopen it to resume reminders.'**
  String get reminderSystemHint;

  /// No description provided for @reminderPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Only for habit reminders you choose. Turn them off at any time.'**
  String get reminderPermissionHint;

  /// No description provided for @removeTime.
  ///
  /// In en, this message translates to:
  /// **'Remove time'**
  String get removeTime;

  /// No description provided for @noReminders.
  ///
  /// In en, this message translates to:
  /// **'Start with a habit'**
  String get noReminders;

  /// No description provided for @noRemindersBody.
  ///
  /// In en, this message translates to:
  /// **'Create a habit to choose its reminder times.'**
  String get noRemindersBody;

  /// No description provided for @reminderArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived; reminders paused'**
  String get reminderArchived;

  /// No description provided for @reminderSettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open system settings. Please try again.'**
  String get reminderSettingsFailed;

  /// No description provided for @remindersCount.
  ///
  /// In en, this message translates to:
  /// **'Enabled reminders'**
  String get remindersCount;

  /// No description provided for @snoozeHint.
  ///
  /// In en, this message translates to:
  /// **'From a notification, log your habit or snooze for 10 minutes. Opening it never logs automatically.'**
  String get snoozeHint;

  /// No description provided for @reminderBackups.
  ///
  /// In en, this message translates to:
  /// **'Reminder settings are backed up. System permission must be enabled on each device.'**
  String get reminderBackups;

  /// No description provided for @reminderChannelHint.
  ///
  /// In en, this message translates to:
  /// **'Your times are kept if notification permission is denied.'**
  String get reminderChannelHint;

  /// No description provided for @restoreRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Data was restored, but the screen could not refresh. Go back and reload before making more changes.'**
  String get restoreRefreshFailed;

  /// No description provided for @dataBackup.
  ///
  /// In en, this message translates to:
  /// **'Data & backup'**
  String get dataBackup;

  /// No description provided for @backupBody.
  ///
  /// In en, this message translates to:
  /// **'Keep your habits, plans, logs, tasks, journal and preferences in one file.'**
  String get backupBody;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from file'**
  String get importBackup;

  /// No description provided for @exportHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a location. Backup files are not encrypted; keep them private.'**
  String get exportHint;

  /// No description provided for @restoreHint.
  ///
  /// In en, this message translates to:
  /// **'Review the file first. Your data changes only after confirmation.'**
  String get restoreHint;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupSaved;

  /// No description provided for @backupError.
  ///
  /// In en, this message translates to:
  /// **'Could not read or save the file. Try another location.'**
  String get backupError;

  /// No description provided for @backupInvalid.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid supported DayPanel backup, or it is damaged. Your data is unchanged.'**
  String get backupInvalid;

  /// No description provided for @restorePreview.
  ///
  /// In en, this message translates to:
  /// **'Review this backup'**
  String get restorePreview;

  /// No description provided for @restoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore & replace'**
  String get restoreConfirm;

  /// No description provided for @replaceWarning.
  ///
  /// In en, this message translates to:
  /// **'Restore replaces all current data; it does not merge. A copy of your previous data will be kept here for rollback.'**
  String get replaceWarning;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Backup restored'**
  String get restoreDone;

  /// No description provided for @rollbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Return to previous data'**
  String get rollbackTitle;

  /// No description provided for @rollbackBody.
  ///
  /// In en, this message translates to:
  /// **'Replace current content with the copy from before the last restore or legacy import. Later additions and changes will also be replaced.'**
  String get rollbackBody;

  /// No description provided for @rollbackDone.
  ///
  /// In en, this message translates to:
  /// **'Previous data restored'**
  String get rollbackDone;

  /// No description provided for @noRecovery.
  ///
  /// In en, this message translates to:
  /// **'No previous restore copy'**
  String get noRecovery;

  /// No description provided for @backupDate.
  ///
  /// In en, this message translates to:
  /// **'Backup date'**
  String get backupDate;

  /// No description provided for @backupItems.
  ///
  /// In en, this message translates to:
  /// **'File contents'**
  String get backupItems;

  /// No description provided for @recordsLabel.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get recordsLabel;

  /// No description provided for @plansLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan versions'**
  String get plansLabel;

  /// No description provided for @groupsLabel.
  ///
  /// In en, this message translates to:
  /// **'Habit groups'**
  String get groupsLabel;

  /// No description provided for @backupLocal.
  ///
  /// In en, this message translates to:
  /// **'Full file backups, free and without an account.'**
  String get backupLocal;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed. Your current data is unchanged. Please retry.'**
  String get restoreFailed;

  /// No description provided for @contextLabel.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get contextLabel;

  /// No description provided for @anytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get anytime;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @daytime.
  ///
  /// In en, this message translates to:
  /// **'Daytime'**
  String get daytime;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @allHabits.
  ///
  /// In en, this message translates to:
  /// **'All habits'**
  String get allHabits;

  /// No description provided for @allGroups.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get allGroups;

  /// No description provided for @ungrouped.
  ///
  /// In en, this message translates to:
  /// **'Ungrouped'**
  String get ungrouped;

  /// No description provided for @groupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupLabel;

  /// No description provided for @manageGroups.
  ///
  /// In en, this message translates to:
  /// **'Manage groups'**
  String get manageGroups;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @groupDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Deleting a group removes membership only. Habits and records are kept.'**
  String get groupDeleteHint;

  /// No description provided for @groupNameError.
  ///
  /// In en, this message translates to:
  /// **'Use 1–40 characters and a name that is not already in use.'**
  String get groupNameError;

  /// No description provided for @noGroups.
  ///
  /// In en, this message translates to:
  /// **'Bring related habits together'**
  String get noGroups;

  /// No description provided for @noGroupsBody.
  ///
  /// In en, this message translates to:
  /// **'Try Health, Reading or Learning. Grouping is optional.'**
  String get noGroupsBody;

  /// No description provided for @filterHabits.
  ///
  /// In en, this message translates to:
  /// **'Filter habits'**
  String get filterHabits;

  /// No description provided for @applyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilter;

  /// No description provided for @resetFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get resetFilter;

  /// No description provided for @noFilterMatches.
  ///
  /// In en, this message translates to:
  /// **'No habits match these filters'**
  String get noFilterMatches;

  /// No description provided for @sortHabits.
  ///
  /// In en, this message translates to:
  /// **'Arrange habits'**
  String get sortHabits;

  /// No description provided for @sortHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the handle or use the arrows. Daily follows this order after saving.'**
  String get sortHint;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get frequency;

  /// No description provided for @byWeekday.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get byWeekday;

  /// No description provided for @everyNDays.
  ///
  /// In en, this message translates to:
  /// **'Every few days'**
  String get everyNDays;

  /// No description provided for @weeklyTarget.
  ///
  /// In en, this message translates to:
  /// **'Weekly target'**
  String get weeklyTarget;

  /// No description provided for @intervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Days between'**
  String get intervalLabel;

  /// No description provided for @weeklyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Days per week'**
  String get weeklyGoalLabel;

  /// No description provided for @scheduleNumberError.
  ///
  /// In en, this message translates to:
  /// **'Use 1–365 days for intervals, or 1–7 days per week.'**
  String get scheduleNumberError;

  /// No description provided for @planTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Target, unit and schedule changes start tomorrow. Past plans and logs stay intact.'**
  String get planTomorrow;

  /// No description provided for @planPending.
  ///
  /// In en, this message translates to:
  /// **'An updated plan starts tomorrow'**
  String get planPending;

  /// No description provided for @planHistory.
  ///
  /// In en, this message translates to:
  /// **'Plan history'**
  String get planHistory;

  /// No description provided for @effectiveFrom.
  ///
  /// In en, this message translates to:
  /// **'Effective from'**
  String get effectiveFrom;

  /// No description provided for @weeklyAvailable.
  ///
  /// In en, this message translates to:
  /// **'Flexible this week'**
  String get weeklyAvailable;

  /// No description provided for @weeklyHint.
  ///
  /// In en, this message translates to:
  /// **'Count achieved days Monday–Sunday. Choose your days; these are not daily obligations.'**
  String get weeklyHint;

  /// No description provided for @weekProgress.
  ///
  /// In en, this message translates to:
  /// **'Achieved this week'**
  String get weekProgress;

  /// No description provided for @partialWeek.
  ///
  /// In en, this message translates to:
  /// **'This plan counts from its start date this week'**
  String get partialWeek;

  /// No description provided for @scheduleStarts.
  ///
  /// In en, this message translates to:
  /// **'Intervals start on the plan’s effective date'**
  String get scheduleStarts;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Schedule & organize'**
  String get organization;

  /// No description provided for @planVersionNote.
  ///
  /// In en, this message translates to:
  /// **'Changes made before this upgrade cannot be reconstructed. Saved versions track changes from this upgrade onward.'**
  String get planVersionNote;

  /// No description provided for @restoreStale.
  ///
  /// In en, this message translates to:
  /// **'Data has changed. Select the backup again before continuing.'**
  String get restoreStale;

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
  /// **'Delete this habit and its completion records? Linked notes will become independent notes. Earned cards, their original snapshots and reflections will be kept.'**
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

  /// No description provided for @widgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Home widgets'**
  String get widgetsTitle;

  /// No description provided for @widgetChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose an item to display'**
  String get widgetChoose;

  /// No description provided for @widgetConfigHint.
  ///
  /// In en, this message translates to:
  /// **'Each widget keeps its own choice. Save to return to your home screen.'**
  String get widgetConfigHint;

  /// No description provided for @widgetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items yet. Create a habit or task in the app first.'**
  String get widgetEmpty;

  /// No description provided for @widgetExpired.
  ///
  /// In en, this message translates to:
  /// **'The content or date changed. Return to your home screen and open again. After restoring data, choose the widget item again.'**
  String get widgetExpired;

  /// No description provided for @widgetOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open DayPanel'**
  String get widgetOpenApp;

  /// No description provided for @widgetClose.
  ///
  /// In en, this message translates to:
  /// **'Return to home screen'**
  String get widgetClose;

  /// No description provided for @widgetSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving your record'**
  String get widgetSaving;

  /// No description provided for @widgetHelp.
  ///
  /// In en, this message translates to:
  /// **'Touch and hold your home screen, choose Widgets, then add a DayPanel habit or task. Resize it or use its settings to choose another item. Battery saving may delay updates; reopen the app after a force stop. Widget choices stay on this device.'**
  String get widgetHelp;

  /// No description provided for @widgetOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening your record'**
  String get widgetOpening;

  /// No description provided for @appearancePreview.
  ///
  /// In en, this message translates to:
  /// **'Appearance preview'**
  String get appearancePreview;

  /// No description provided for @appearanceHint.
  ///
  /// In en, this message translates to:
  /// **'Try it here. Only Save applies your choices. All styles are free.'**
  String get appearanceHint;

  /// No description provided for @appearanceSample.
  ///
  /// In en, this message translates to:
  /// **'Typography sample'**
  String get appearanceSample;

  /// No description provided for @appearanceSampleText.
  ///
  /// In en, this message translates to:
  /// **'Make room for the little things you enjoy.'**
  String get appearanceSampleText;

  /// No description provided for @appearanceMode.
  ///
  /// In en, this message translates to:
  /// **'Display mode'**
  String get appearanceMode;

  /// No description provided for @appearancePalette.
  ///
  /// In en, this message translates to:
  /// **'Color theme'**
  String get appearancePalette;

  /// No description provided for @paletteBlue.
  ///
  /// In en, this message translates to:
  /// **'Daylight desk'**
  String get paletteBlue;

  /// No description provided for @paletteTeal.
  ///
  /// In en, this message translates to:
  /// **'Morning grove'**
  String get paletteTeal;

  /// No description provided for @paletteViolet.
  ///
  /// In en, this message translates to:
  /// **'Twilight garden'**
  String get paletteViolet;

  /// No description provided for @appearanceFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get appearanceFont;

  /// No description provided for @fontSystem.
  ///
  /// In en, this message translates to:
  /// **'System font'**
  String get fontSystem;

  /// No description provided for @fontSerif.
  ///
  /// In en, this message translates to:
  /// **'Book serif'**
  String get fontSerif;

  /// No description provided for @fontHint.
  ///
  /// In en, this message translates to:
  /// **'Book serif uses bundled Noto Serif SC, with no download. Home widgets use the Android system font.'**
  String get fontHint;

  /// No description provided for @appearanceFrame.
  ///
  /// In en, this message translates to:
  /// **'Default icon frame'**
  String get appearanceFrame;

  /// No description provided for @frameSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft tile'**
  String get frameSoft;

  /// No description provided for @frameRing.
  ///
  /// In en, this message translates to:
  /// **'Ring'**
  String get frameRing;

  /// No description provided for @framePlain.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get framePlain;

  /// No description provided for @followDefault.
  ///
  /// In en, this message translates to:
  /// **'Use default'**
  String get followDefault;

  /// No description provided for @automaticColor.
  ///
  /// In en, this message translates to:
  /// **'Original colors'**
  String get automaticColor;

  /// No description provided for @appearanceReset.
  ///
  /// In en, this message translates to:
  /// **'Preview defaults'**
  String get appearanceReset;

  /// No description provided for @habitDecoration.
  ///
  /// In en, this message translates to:
  /// **'Icon and style'**
  String get habitDecoration;

  /// No description provided for @habitColor.
  ///
  /// In en, this message translates to:
  /// **'Frame accent'**
  String get habitColor;

  /// No description provided for @habitFrame.
  ///
  /// In en, this message translates to:
  /// **'Icon frame'**
  String get habitFrame;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get colorViolet;

  /// No description provided for @colorPeach.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorPeach;

  /// No description provided for @colorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// No description provided for @colorRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get colorRose;

  /// No description provided for @decorationHint.
  ///
  /// In en, this message translates to:
  /// **'Illustrations keep their original colors. The accent changes the frame and item details; your plan stays the same.'**
  String get decorationHint;

  /// No description provided for @iconSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get iconSun;

  /// No description provided for @iconWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get iconWater;

  /// No description provided for @iconBook.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get iconBook;

  /// No description provided for @iconWalk.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get iconWalk;

  /// No description provided for @iconHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get iconHeart;

  /// No description provided for @iconMoon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get iconMoon;

  /// No description provided for @iconStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get iconStrength;

  /// No description provided for @iconMeditate.
  ///
  /// In en, this message translates to:
  /// **'Stretching'**
  String get iconMeditate;

  /// No description provided for @iconRun.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get iconRun;

  /// No description provided for @iconBike.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get iconBike;

  /// No description provided for @iconMeal.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get iconMeal;

  /// No description provided for @iconFlower.
  ///
  /// In en, this message translates to:
  /// **'Flower'**
  String get iconFlower;

  /// No description provided for @iconMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get iconMusic;

  /// No description provided for @iconArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get iconArt;

  /// No description provided for @iconWrite.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get iconWrite;

  /// No description provided for @iconLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get iconLanguage;

  /// No description provided for @iconSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get iconSavings;

  /// No description provided for @iconClean.
  ///
  /// In en, this message translates to:
  /// **'Tidying'**
  String get iconClean;

  /// No description provided for @iconPet.
  ///
  /// In en, this message translates to:
  /// **'Pet'**
  String get iconPet;

  /// No description provided for @iconCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get iconCoffee;

  /// No description provided for @iconMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get iconMedicine;

  /// No description provided for @iconSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get iconSleep;

  /// No description provided for @iconUnplug.
  ///
  /// In en, this message translates to:
  /// **'Unplug'**
  String get iconUnplug;

  /// No description provided for @iconCare.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get iconCare;

  /// No description provided for @legacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Import old habits'**
  String get legacyTitle;

  /// No description provided for @legacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Append habits and actual records from a Loop database backup. Keep existing content. Review before importing.'**
  String get legacyIntro;

  /// No description provided for @legacyPick.
  ///
  /// In en, this message translates to:
  /// **'Choose Loop backup .db'**
  String get legacyPick;

  /// No description provided for @legacySupported.
  ///
  /// In en, this message translates to:
  /// **'Supports Loop database versions 21–25, up to 8 MiB. ZIP, CSV and other app backups are not supported. Export a complete database from the old app.'**
  String get legacySupported;

  /// No description provided for @legacyDifference.
  ///
  /// In en, this message translates to:
  /// **'Only actual records transfer. Automatic coverage is not completion. Skips and notes become journal entries. Past schedules, target changes and archive history cannot be reconstructed; earlier days are not counted as failures. Reminders, scores, colors and old tasks/scenes are not imported. Quantities use the unit saved in the file. The start date is the earliest record, or the import day when empty; it is not the original creation date. In files without UUIDs, renaming may create a new identity, so avoid repeated imports.'**
  String get legacyDifference;

  /// No description provided for @legacyReview.
  ///
  /// In en, this message translates to:
  /// **'Review import'**
  String get legacyReview;

  /// No description provided for @legacyExisting.
  ///
  /// In en, this message translates to:
  /// **'Already here; keep current content'**
  String get legacyExisting;

  /// No description provided for @legacyUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This item cannot be imported'**
  String get legacyUnsupported;

  /// No description provided for @legacyAtMost.
  ///
  /// In en, this message translates to:
  /// **'At-most targets are not supported; their meaning will not be reversed.'**
  String get legacyAtMost;

  /// No description provided for @legacyTarget.
  ///
  /// In en, this message translates to:
  /// **'Targets must be positive with at most three decimal places.'**
  String get legacyTarget;

  /// No description provided for @legacyLength.
  ///
  /// In en, this message translates to:
  /// **'The name or unit is too long. Adjust it in the old app first.'**
  String get legacyLength;

  /// No description provided for @legacySourceFrequency.
  ///
  /// In en, this message translates to:
  /// **'Source frequency (times/days)'**
  String get legacySourceFrequency;

  /// No description provided for @legacyRecords.
  ///
  /// In en, this message translates to:
  /// **'Actual records'**
  String get legacyRecords;

  /// No description provided for @legacyIgnored.
  ///
  /// In en, this message translates to:
  /// **'Automatic/unknown (not completion)'**
  String get legacyIgnored;

  /// No description provided for @legacySkips.
  ///
  /// In en, this message translates to:
  /// **'Skips (saved as journal)'**
  String get legacySkips;

  /// No description provided for @legacyNotes.
  ///
  /// In en, this message translates to:
  /// **'Journal entries (including source note)'**
  String get legacyNotes;

  /// No description provided for @legacyChooseSchedule.
  ///
  /// In en, this message translates to:
  /// **'Choose the schedule after import'**
  String get legacyChooseSchedule;

  /// No description provided for @legacyScheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Rolling frequency differs from fixed intervals and calendar weeks. Choose your future schedule. Unknown earlier days will not be counted as failures. Intervals start on the import day.'**
  String get legacyScheduleHint;

  /// No description provided for @legacyDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get legacyDaily;

  /// No description provided for @legacyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Days per calendar week'**
  String get legacyWeekly;

  /// No description provided for @legacyInterval.
  ///
  /// In en, this message translates to:
  /// **'Every N days'**
  String get legacyInterval;

  /// No description provided for @legacyCount.
  ///
  /// In en, this message translates to:
  /// **'Number of days'**
  String get legacyCount;

  /// No description provided for @legacyAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand the differences and confirm the selected schedules'**
  String get legacyAcknowledge;

  /// No description provided for @legacyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Append selected habits'**
  String get legacyConfirm;

  /// No description provided for @legacyDone.
  ///
  /// In en, this message translates to:
  /// **'Import complete. Existing content is preserved. Data & backup can restore the copy from before import.'**
  String get legacyDone;

  /// No description provided for @legacyInvalid.
  ///
  /// In en, this message translates to:
  /// **'The file is damaged, unsupported or contains invalid records. Your data is unchanged.'**
  String get legacyInvalid;

  /// No description provided for @legacyFailed.
  ///
  /// In en, this message translates to:
  /// **'Import could not finish. The content or date may have changed. Select the file again.'**
  String get legacyFailed;

  /// No description provided for @legacyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No habits to append. Existing habits are never overwritten or merged.'**
  String get legacyEmpty;

  /// No description provided for @legacyRecovery.
  ///
  /// In en, this message translates to:
  /// **'The latest full copy from before import is kept. Rollback also replaces later changes. Export a file first if you need a lasting copy.'**
  String get legacyRecovery;

  /// No description provided for @offlineTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Move devices offline'**
  String get offlineTransferTitle;

  /// No description provided for @offlineTransferBody.
  ///
  /// In en, this message translates to:
  /// **'1. Export a full DayPanel JSON backup on the old device.\n2. Transfer the file yourself using USB or file transfer.\n3. Choose Restore from file on the new device and review before confirming.\n4. Set notification permissions and widgets again.\n\nThere is no cloud sync or automatic backup. Files are not encrypted; keep them private. Uninstalling deletes app data and the rollback copy. Keep exported files outside the app.'**
  String get offlineTransferBody;

  /// No description provided for @uiAppearanceHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the colors and type that feel like you.'**
  String get uiAppearanceHint;

  /// No description provided for @uiPreviewLive.
  ///
  /// In en, this message translates to:
  /// **'Live preview'**
  String get uiPreviewLive;

  /// No description provided for @uiPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Applies to every page when saved'**
  String get uiPreviewHint;

  /// No description provided for @uiFontSample.
  ///
  /// In en, this message translates to:
  /// **'A little progress, every day'**
  String get uiFontSample;

  /// No description provided for @uiMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get uiMoreDetails;

  /// No description provided for @uiBackupHint.
  ///
  /// In en, this message translates to:
  /// **'Keep your days in your own hands.'**
  String get uiBackupHint;

  /// No description provided for @uiExportHint.
  ///
  /// In en, this message translates to:
  /// **'Save a complete copy for safekeeping or a new device.'**
  String get uiExportHint;

  /// No description provided for @uiRestoreHint.
  ///
  /// In en, this message translates to:
  /// **'Review a backup before replacing current data.'**
  String get uiRestoreHint;

  /// No description provided for @uiLegacyHint.
  ///
  /// In en, this message translates to:
  /// **'Bring habits from Loop while keeping current content.'**
  String get uiLegacyHint;

  /// No description provided for @uiRecoveryHint.
  ///
  /// In en, this message translates to:
  /// **'A complete copy from before your last import or restore'**
  String get uiRecoveryHint;

  /// No description provided for @uiFileScope.
  ///
  /// In en, this message translates to:
  /// **'Supported files'**
  String get uiFileScope;

  /// No description provided for @uiChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a backup file'**
  String get uiChooseFile;

  /// No description provided for @uiChooseItems.
  ///
  /// In en, this message translates to:
  /// **'Choose items'**
  String get uiChooseItems;

  /// No description provided for @uiReviewImport.
  ///
  /// In en, this message translates to:
  /// **'Review import'**
  String get uiReviewImport;

  /// No description provided for @uiContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get uiContinue;

  /// No description provided for @uiBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get uiBack;

  /// No description provided for @uiChangeFile.
  ///
  /// In en, this message translates to:
  /// **'Choose another file'**
  String get uiChangeFile;

  /// No description provided for @uiImportSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the habits to bring over and their future schedules.'**
  String get uiImportSelectHint;

  /// No description provided for @uiImportReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Your current content stays. Only selected items are added.'**
  String get uiImportReviewHint;

  /// No description provided for @uiImportRules.
  ///
  /// In en, this message translates to:
  /// **'What changes after import'**
  String get uiImportRules;

  /// No description provided for @uiImportNoSelection.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one supported habit'**
  String get uiImportNoSelection;

  /// No description provided for @uiImportNeedsSchedule.
  ///
  /// In en, this message translates to:
  /// **'Choose a schedule for each selected habit'**
  String get uiImportNeedsSchedule;

  /// No description provided for @uiSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} habits selected'**
  String uiSelectedCount(int count);

  /// No description provided for @uiRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String uiRecordCount(int count);

  /// No description provided for @uiNeedsSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule needed'**
  String get uiNeedsSchedule;

  /// No description provided for @uiSchedule.
  ///
  /// In en, this message translates to:
  /// **'New schedule'**
  String get uiSchedule;

  /// No description provided for @uiImportedDone.
  ///
  /// In en, this message translates to:
  /// **'Your habits are here'**
  String get uiImportedDone;

  /// No description provided for @uiReturnData.
  ///
  /// In en, this message translates to:
  /// **'Back to data & backup'**
  String get uiReturnData;

  /// No description provided for @uiWidgetChooseHint.
  ///
  /// In en, this message translates to:
  /// **'Keep a habit or task within reach on your home screen.'**
  String get uiWidgetChooseHint;

  /// No description provided for @uiNoWidgetChoice.
  ///
  /// In en, this message translates to:
  /// **'Choose an item to show'**
  String get uiNoWidgetChoice;

  /// No description provided for @uiReminderIntro.
  ///
  /// In en, this message translates to:
  /// **'A gentle reminder at the right time.'**
  String get uiReminderIntro;

  /// No description provided for @uiReminderRules.
  ///
  /// In en, this message translates to:
  /// **'How reminders work'**
  String get uiReminderRules;

  /// No description provided for @uiStatisticsHelp.
  ///
  /// In en, this message translates to:
  /// **'How these numbers are calculated'**
  String get uiStatisticsHelp;

  /// No description provided for @uiShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Record details'**
  String get uiShowDetails;

  /// No description provided for @uiTabTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get uiTabTable;

  /// No description provided for @uiTabHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get uiTabHabits;

  /// No description provided for @uiTabYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get uiTabYear;

  /// No description provided for @uiTabTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get uiTabTimeline;

  /// No description provided for @restTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest days'**
  String get restTitle;

  /// No description provided for @restPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get restPaused;

  /// No description provided for @restVacation.
  ///
  /// In en, this message translates to:
  /// **'On a break'**
  String get restVacation;

  /// No description provided for @restSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped this day'**
  String get restSkipped;

  /// No description provided for @restPause.
  ///
  /// In en, this message translates to:
  /// **'Pause from today'**
  String get restPause;

  /// No description provided for @restPlanVacation.
  ///
  /// In en, this message translates to:
  /// **'Plan a break'**
  String get restPlanVacation;

  /// No description provided for @restSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip this day'**
  String get restSkip;

  /// No description provided for @restUnskip.
  ///
  /// In en, this message translates to:
  /// **'Remove skip'**
  String get restUnskip;

  /// No description provided for @restResume.
  ///
  /// In en, this message translates to:
  /// **'Resume today'**
  String get restResume;

  /// No description provided for @restCancelFuture.
  ///
  /// In en, this message translates to:
  /// **'Cancel this break'**
  String get restCancelFuture;

  /// No description provided for @restHint.
  ///
  /// In en, this message translates to:
  /// **'Rest days count as neither failure nor completion. History stays and reminders pause.'**
  String get restHint;

  /// No description provided for @restRules.
  ///
  /// In en, this message translates to:
  /// **'Daily streaks pass over rest days. Weeks containing rest days are excluded from full-week assessments. No card is earned when all habits rest. Resuming keeps the original plan.'**
  String get restRules;

  /// No description provided for @restConflict.
  ///
  /// In en, this message translates to:
  /// **'These dates overlap a break, or this day already has a record. Check and retry.'**
  String get restConflict;

  /// No description provided for @restEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get restEnded;

  /// No description provided for @restUntilResume.
  ///
  /// In en, this message translates to:
  /// **'Until you resume'**
  String get restUntilResume;

  /// No description provided for @restRange.
  ///
  /// In en, this message translates to:
  /// **'Choose start and end dates'**
  String get restRange;

  /// No description provided for @restConfirmSkip.
  ///
  /// In en, this message translates to:
  /// **'Skipping affects only this day and keeps all other records.'**
  String get restConfirmSkip;

  /// No description provided for @restRecordBlocked.
  ///
  /// In en, this message translates to:
  /// **'This is a rest day. End or cancel the break before logging.'**
  String get restRecordBlocked;

  /// No description provided for @cardShare.
  ///
  /// In en, this message translates to:
  /// **'Share card'**
  String get cardShare;

  /// No description provided for @cardSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get cardSaveImage;

  /// No description provided for @cardShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get cardShareAction;

  /// No description provided for @cardShareNames.
  ///
  /// In en, this message translates to:
  /// **'Include habit names'**
  String get cardShareNames;

  /// No description provided for @cardShareReflection.
  ///
  /// In en, this message translates to:
  /// **'Include a reflection'**
  String get cardShareReflection;

  /// No description provided for @cardShareExcerpt.
  ///
  /// In en, this message translates to:
  /// **'Share excerpt (keeps the original reflection)'**
  String get cardShareExcerpt;

  /// No description provided for @cardShareHint.
  ///
  /// In en, this message translates to:
  /// **'This preview is the image you will save or share. Names and reflections are hidden by default.'**
  String get cardShareHint;

  /// No description provided for @cardImageSaved.
  ///
  /// In en, this message translates to:
  /// **'Image saved'**
  String get cardImageSaved;

  /// No description provided for @cardImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create or save the image. Try again.'**
  String get cardImageFailed;

  /// No description provided for @cardShareStale.
  ///
  /// In en, this message translates to:
  /// **'Card data changed. Reopen the share page.'**
  String get cardShareStale;

  /// No description provided for @cardShareMore.
  ///
  /// In en, this message translates to:
  /// **'And {count} more'**
  String cardShareMore(int count);

  /// No description provided for @cardShareCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 habit completed} other{{count} habits completed}}'**
  String cardShareCount(int count);

  /// No description provided for @restRangeLimit.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 365 days'**
  String get restRangeLimit;

  /// No description provided for @restSchedule.
  ///
  /// In en, this message translates to:
  /// **'Breaks and history'**
  String get restSchedule;

  /// No description provided for @restStale.
  ///
  /// In en, this message translates to:
  /// **'This habit changed. Reopen its rest days to continue.'**
  String get restStale;

  /// No description provided for @restConfirmUnskip.
  ///
  /// In en, this message translates to:
  /// **'This day will follow its original plan again. No completion record will be added.'**
  String get restConfirmUnskip;

  /// No description provided for @habitLibrary.
  ///
  /// In en, this message translates to:
  /// **'Habit library'**
  String get habitLibrary;

  /// No description provided for @habitLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Make room for a little good'**
  String get habitLibraryTitle;

  /// No description provided for @habitLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'Start with a familiar habit. Adjust its goal before adding it.'**
  String get habitLibraryHint;

  /// No description provided for @searchHabits.
  ///
  /// In en, this message translates to:
  /// **'Search everyday habits'**
  String get searchHabits;

  /// No description provided for @templateNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching template. Create your own below.'**
  String get templateNoMatch;

  /// No description provided for @customHabit.
  ///
  /// In en, this message translates to:
  /// **'Create your own'**
  String get customHabit;

  /// No description provided for @templateDailyCheck.
  ///
  /// In en, this message translates to:
  /// **'Every day · check off'**
  String get templateDailyCheck;

  /// No description provided for @templateDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit} / day'**
  String templateDailyGoal(String amount, String unit);

  /// No description provided for @templateEditable.
  ///
  /// In en, this message translates to:
  /// **'A starting goal, ready to adjust to your day.'**
  String get templateEditable;

  /// No description provided for @suggestedIcon.
  ///
  /// In en, this message translates to:
  /// **'Suggested icon: {name}'**
  String suggestedIcon(String name);

  /// No description provided for @iconSuggestionHint.
  ///
  /// In en, this message translates to:
  /// **'Apply the icon only; keep your goal and schedule.'**
  String get iconSuggestionHint;

  /// No description provided for @paletteCompositionHint.
  ///
  /// In en, this message translates to:
  /// **'A coordinated palette for actions, notes and everyday details. Habit illustrations keep their own colors.'**
  String get paletteCompositionHint;

  /// No description provided for @habitSettings.
  ///
  /// In en, this message translates to:
  /// **'Habit settings'**
  String get habitSettings;

  /// No description provided for @recordHistory.
  ///
  /// In en, this message translates to:
  /// **'History & statistics'**
  String get recordHistory;

  /// No description provided for @recordSelectedDay.
  ///
  /// In en, this message translates to:
  /// **'Back to selected day'**
  String get recordSelectedDay;

  /// No description provided for @contextChanged.
  ///
  /// In en, this message translates to:
  /// **'Data has changed'**
  String get contextChanged;

  /// No description provided for @habitUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This habit is no longer available'**
  String get habitUnavailable;

  /// No description provided for @reopenContext.
  ///
  /// In en, this message translates to:
  /// **'Return to the list and reopen the item you need.'**
  String get reopenContext;

  /// No description provided for @backToList.
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get backToList;

  /// No description provided for @optionalHabitNotes.
  ///
  /// In en, this message translates to:
  /// **'Optional notes; separate from completion'**
  String get optionalHabitNotes;

  /// No description provided for @restManagementHint.
  ///
  /// In en, this message translates to:
  /// **'Pause from today or plan a future break'**
  String get restManagementHint;

  /// No description provided for @restWeeklySkipHint.
  ///
  /// In en, this message translates to:
  /// **'This day will be a rest day, not a completion. Its week is excluded from full-week goal assessment. Existing records and goals stay.'**
  String get restWeeklySkipHint;

  /// No description provided for @quantityReplaceTotal.
  ///
  /// In en, this message translates to:
  /// **'Total for this day'**
  String get quantityReplaceTotal;

  /// No description provided for @quantitySavedTotal.
  ///
  /// In en, this message translates to:
  /// **'Recorded: {amount} {unit}'**
  String quantitySavedTotal(String amount, String unit);

  /// No description provided for @quantityReplacePreview.
  ///
  /// In en, this message translates to:
  /// **'Saving sets this day\'s total to {amount} {unit}; it does not add to it.'**
  String quantityReplacePreview(String amount, String unit);

  /// No description provided for @quantityTotalHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the total for this day. Saving replaces the previous value.'**
  String get quantityTotalHint;

  /// No description provided for @habitTypeFixed.
  ///
  /// In en, this message translates to:
  /// **'Tracking type cannot be changed after creation'**
  String get habitTypeFixed;

  /// No description provided for @habitAdvancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Timing, group & appearance'**
  String get habitAdvancedSettings;

  /// No description provided for @pmTaskUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This task is no longer available'**
  String get pmTaskUnavailable;

  /// No description provided for @widgetsHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'How to add widgets'**
  String get widgetsHelpTitle;
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
