import 'tasks.dart';
import 'home_widgets.dart';
import 'appearance.dart';
import 'journal.dart';
import 'achievements.dart';
import 'statistics.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'editors.dart';
import 'habits.dart';
import 'review.dart';
import 'theme.dart';
import 'refined_components.dart';
import 'organization.dart';
import 'backup_page.dart';
import 'reminders.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.app});
  final AppController app;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int tab = 0;
  Timer? timer;
  late Day lastToday;
  AppController get app => widget.app;
  @override
  void initState() {
    super.initState();
    lastToday = app.today;
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 30), (_) => refreshDate());
  }

  void refreshDate() {
    final now = app.today;
    if (now != lastToday) {
      if (app.selectedDay == lastToday) app.select(now);
      lastToday = now;
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshDate();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      final titles = [s.today, s.tasks, s.notes, s.mine];
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            toolbarHeight: 56,
            titleSpacing: 20,
            title: Text(
              titles[tab],
              style: Theme.of(context).textTheme.titleLarge,
            ),
            actions: [
              if (tab == 0)
                AppIconAction(
                  icon: Icons.bar_chart_rounded,
                  label: s.review,
                  tone: UiTone.violet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ReviewPage(app: app),
                    ),
                  ),
                ),
              if (tab == 0) const SizedBox(width: 8),
              if (tab < 3)
                AppIconAction(
                  key: const Key('add-entry'),
                  icon: Icons.add,
                  label: [s.newHabit, s.newTask, s.newNote][tab],
                  primary: true,
                  onTap: app.busy
                      ? null
                      : () => openEditor(
                          context,
                          app,
                          ['habit', 'task', 'note'][tab],
                        ),
                ),
              const SizedBox(width: 20),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (app.busy) const LinearProgressIndicator(minHeight: 2),
                if (app.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SoftPanel(
                      tone: UiTone.peach,
                      tinted: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.storageError),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: app.busy
                                    ? null
                                    : () => app.run(() async {}),
                                child: Text(s.retry),
                              ),
                              TextButton(
                                onPressed: app.acknowledgeError,
                                child: Text(s.cancel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: switch (tab) {
                    0 => daily(context),
                    1 => TasksPage(app: app),
                    2 => JournalPage(app: app),
                    _ => preferences(context),
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: GlassNavigation(
            index: tab,
            onSelected: (i) => setState(() => tab = i),
          ),
        ),
      );
    },
  );

  Widget daily(BuildContext context) {
    final s = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final day = app.selectedDay;
    final planned = app.planned;
    final weekly = app.weeklyPlanned;
    final summaryCount = app.allDailyPlanned.length;
    final summaryDone = app.allDailyCompleted;
    final anyActive = app.habits.any((h) => !h.archived);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return ListView(
      key: const PageStorageKey('daily'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                key: const Key('daily-date'),
                icon: Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: UiTone.peach.ink(context),
                ),
                label: Text(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).languageCode,
                  ).format(day.date),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: day.date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) app.select(Day(d));
                },
              ),
            ),
            if (day != app.today)
              TextButton(
                onPressed: () => app.select(app.today),
                child: Text(s.todayLabel),
              ),
            IconButton(
              key: const Key('daily-filter'),
              tooltip: s.filterHabits,
              onPressed: () => showHabitFilter(context, app),
              icon: Icon(Icons.tune_rounded, color: UiTone.violet.ink(context)),
            ),
          ],
        ),
        if (scale <= 1.3)
          LayoutBuilder(
            builder: (context, c) {
              final cell =
                  ((c.maxWidth - 6 * 4) / 7).clamp(48.0, 64.0) *
                  scale.clamp(1.0, 1.35);
              return SizedBox(
                height: 54 * scale.clamp(1.0, 1.8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  separatorBuilder: (_, _) => const SizedBox(width: 4),
                  itemBuilder: (context, i) {
                    final d = day.plus(i - (day.date.weekday - 1));
                    final selected = d == day;
                    return SizedBox(
                      width: cell,
                      child: Semantics(
                        label: MaterialLocalizations.of(
                          context,
                        ).formatFullDate(d.date),
                        selected: selected,
                        button: true,
                        child: Material(
                          color: selected ? scheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => app.select(d),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat.E(
                                    Localizations.localeOf(
                                      context,
                                    ).languageCode,
                                  ).format(d.date),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: selected
                                        ? scheme.onPrimary
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '${d.date.day}',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? scheme.onPrimary
                                        : scheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        if (app.contextFilter != null || app.groupFilter != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              [
                if (app.contextFilter != null)
                  contextName(s, app.contextFilter!),
                if (app.groupFilter != null)
                  app.groups.firstWhere((g) => g.id == app.groupFilter).name,
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (summaryCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    s.planned,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: summaryDone / summaryCount,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(3),
                    semanticsLabel: '${s.planned} $summaryDone/$summaryCount',
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$summaryDone / $summaryCount',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        if (planned.isEmpty &&
            weekly.isEmpty &&
            !app.habits.any(
              (h) =>
                  !h.archived &&
                  app.restOn(h, day) != null &&
                  app.matchesFilter(h),
            ))
          EmptyState(
            icon: Icons.spa_outlined,
            title: app.contextFilter != null || app.groupFilter != null
                ? s.noFilterMatches
                : anyActive
                ? s.emptyDay
                : s.emptyHabits,
            body: anyActive ? s.emptyDayBody : s.emptyHabitsBody,
            action: s.newHabit,
            onAction: () => openEditor(context, app, 'habit'),
          ),
        for (final h in planned)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HabitTile(app: app, habit: h, day: day),
          ),
        if (weekly.isNotEmpty) ...[
          SectionTitle(
            s.weeklyAvailable,
            count: weekly.length,
            tone: UiTone.violet,
          ),
          for (final h in weekly)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HabitTile(app: app, habit: h, day: day),
            ),
        ],
        if (app.habits.any(
          (h) =>
              !h.archived && app.restOn(h, day) != null && app.matchesFilter(h),
        )) ...[
          SectionTitle(s.restTitle, tone: UiTone.violet),
          for (final h in app.habits.where(
            (h) =>
                !h.archived &&
                app.restOn(h, day) != null &&
                app.matchesFilter(h),
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HabitTile(app: app, habit: h, day: day),
            ),
        ],
        if (app.habits.any(
          (h) =>
              !h.archived &&
              !app.scheduled(h, day) &&
              app.restOn(h, day) == null &&
              app.matchesFilter(h) &&
              app.value(h, day) != null,
        )) ...[
          SectionTitle(s.extraRecords, tone: UiTone.violet),
          for (final h in app.habits.where(
            (h) =>
                !h.archived &&
                !app.scheduled(h, day) &&
                app.restOn(h, day) == null &&
                app.matchesFilter(h) &&
                app.value(h, day) != null,
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HabitTile(app: app, habit: h, day: day),
            ),
        ],
        DailyCardPanel(app: app, day: day),
      ],
    );
  }

  Widget preferences(BuildContext context) {
    final s = AppLocalizations.of(context);
    void open(Widget page) =>
        Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
    return ListView(
      key: const PageStorageKey('preferences'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        SoftPanel(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              SettingRow(
                key: const Key('settings-habits'),
                icon: Icons.grid_view_rounded,
                title: s.manageHabits,
                onTap: () => open(HabitLibrary(app: app)),
              ),
              SettingRow(
                key: const Key('settings-appearance'),
                icon: Icons.palette_outlined,
                title: s.appearance,
                tone: UiTone.peach,
                onTap: () => open(AppearancePage(app: app)),
              ),
              SettingRow(
                key: const Key('settings-reminders'),
                icon: Icons.notifications_none_rounded,
                title: s.remindersTitle,
                tone: UiTone.peach,
                onTap: () => open(RemindersPage(app: app)),
              ),
              SettingRow(
                key: const Key('settings-backup'),
                icon: Icons.shield_outlined,
                title: s.dataBackup,
                tone: UiTone.teal,
                onTap: () => open(BackupPage(app: app)),
              ),
              SettingRow(
                icon: Icons.widgets_outlined,
                title: s.widgetsHelpTitle,
                tone: UiTone.violet,
                onTap: () => open(const WidgetsHelpPage()),
              ),
            ],
          ),
        ),
        SectionTitle(s.yourSpace, tone: UiTone.violet),
        SoftPanel(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              SettingRow(
                icon: Icons.collections_bookmark_outlined,
                title: s.cardCollection,
                tone: UiTone.violet,
                onTap: () => open(CardCollection(app: app)),
              ),
              SettingRow(
                icon: Icons.insights_outlined,
                title: s.statisticsTitle,
                tone: UiTone.violet,
                onTap: () => open(StatisticsPage(app: app)),
              ),
              SettingRow(
                icon: Icons.bar_chart_rounded,
                title: s.review,
                tone: UiTone.violet,
                onTap: () => open(ReviewPage(app: app)),
              ),
            ],
          ),
        ),
        SectionTitle(s.preferencesTitle, tone: UiTone.peach),
        SoftPanel(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              SettingRow(
                icon: Icons.touch_app_outlined,
                title: s.completionFeedback,
                tone: UiTone.violet,
                onTap: () => open(FeedbackPage(app: app)),
              ),
              SettingRow(
                icon: Icons.translate_rounded,
                title: s.language,
                subtitle: switch (app.preferences['locale']) {
                  'zh' => s.chinese,
                  'en' => s.english,
                  _ => s.system,
                },
                onTap: () => preferencePicker(context, 'locale', {
                  'system': s.system,
                  'zh': s.chinese,
                  'en': s.english,
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DetailDisclosure(title: s.freeTitle, child: Text(s.freeBody)),
        SettingRow(
          icon: Icons.code_rounded,
          title: s.licenses,
          tone: UiTone.violet,
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'DayPanel',
            applicationVersion: '0.1.0-dev',
          ),
        ),
      ],
    );
  }

  Future<void> preferencePicker(
    BuildContext context,
    String key,
    Map<String, String> choices,
  ) async {
    final s = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => SheetFrame(
        title: key == 'theme' ? s.appearance : s.language,
        icon: key == 'theme' ? Icons.palette_outlined : Icons.translate_rounded,
        tone: UiTone.violet,
        body: Column(
          children: choices.entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SoftPanel(
                    tinted: (app.preferences[key] ?? 'system') == e.key,
                    tone: UiTone.violet,
                    padding: EdgeInsets.zero,
                    child: SettingRow(
                      icon: key == 'theme'
                          ? switch (e.key) {
                              'light' => Icons.light_mode_outlined,
                              'dark' => Icons.nights_stay_outlined,
                              _ => Icons.brightness_auto_outlined,
                            }
                          : Icons.translate_rounded,
                      title: e.value,
                      tone: UiTone.violet,
                      onTap: () => Navigator.pop(ctx, e.key),
                      trailing: Icon(
                        (app.preferences[key] ?? 'system') == e.key
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: UiTone.violet.ink(ctx),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        footer: AppAction(
          label: s.cancel,
          onTap: () => Navigator.pop(ctx),
          tone: UiTone.violet,
        ),
      ),
    );
    if (selected != null) {
      await app.run(() => app.store.preference(key, selected));
    }
  }
}
