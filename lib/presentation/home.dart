import 'tasks.dart';
import 'home_widgets.dart';
import 'appearance.dart';
import 'journal.dart';
import 'achievements.dart';
import 'statistics.dart';
import 'insights.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/app_controller.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'plus_page.dart';
import 'review_card.dart';
import 'privacy_page.dart';
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
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titles[tab],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (app.plus.enabled) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 11,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'PLUS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (tab == 0)
                AppIconAction(
                  key: const Key('home-insights-action'),
                  icon: app.plus.enabled
                      ? Icons.auto_graph_rounded
                      : Icons.bar_chart_rounded,
                  label: app.plus.enabled ? s.insightsTitle : s.review,
                  tone: UiTone.violet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => app.plus.enabled
                          ? InsightsPage(app: app)
                          : ReviewPage(app: app),
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
    final filtered = app.contextFilter != null || app.groupFilter != null;
    final extras = app.habits
        .where(
          (h) =>
              !h.archived &&
              day.compareTo(h.startDay) >= 0 &&
              day.compareTo(app.today) <= 0 &&
              app.restOn(h, day) == null &&
              !app.scheduled(h, day),
        )
        .toList();
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
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
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
                                if (d == app.today)
                                  Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.only(top: 2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: selected
                                          ? scheme.onPrimary
                                          : scheme.primary,
                                    ),
                                  )
                                else
                                  const SizedBox(height: 6),
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
                    filtered ? s.allHabitsProgress : s.planned,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: summaryDone / summaryCount,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(3),
                    semanticsLabel:
                        '${filtered ? s.allHabitsProgress : s.planned} $summaryDone/$summaryCount',
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
            body: filtered
                ? s.filterEmptyHelp
                : anyActive
                ? s.emptyDayHelp
                : s.emptyHabitsBody,
            action: filtered
                ? s.resetFilter
                : !anyActive
                ? s.newHabit
                : day != app.today
                ? s.todayLabel
                : s.manageHabits,
            onAction: filtered
                ? () => app.filter()
                : !anyActive
                ? () => openEditor(context, app, 'habit')
                : day != app.today
                ? () => app.select(app.today)
                : () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => HabitLibrary(app: app),
                    ),
                  ),
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
        if (extras.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AppAction(
              key: const Key('record-other-habit'),
              label: s.recordOtherHabit,
              icon: Icons.playlist_add_check_rounded,
              tone: UiTone.violet,
              onTap: app.busy
                  ? null
                  : () => chooseExtraRecord(context, day, extras),
            ),
          ),
        DailyCardPanel(app: app, day: day),
        const SizedBox(height: 12),
        _DailyInsightsStrip(app: app),
      ],
    );
  }

  Future<void> chooseExtraRecord(
    BuildContext context,
    Day day,
    List<Habit> choices,
  ) async {
    final epoch = app.generation;
    final s = AppLocalizations.of(context);
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SheetFrame(
        title: s.recordOtherHabit,
        subtitle: s.extraRecordHelp,
        icon: Icons.playlist_add_check_rounded,
        tone: UiTone.violet,
        body: Column(
          children: [
            for (final h in choices)
              SettingRow(
                key: Key('extra-habit-${h.id}'),
                icon: Icons.edit_outlined,
                title: h.title,
                subtitle: s.extraRecords,
                onTap: () => Navigator.pop(ctx, h.id),
              ),
          ],
        ),
        footer: AppAction(label: s.cancel, onTap: () => Navigator.pop(ctx)),
      ),
    );
    if (id == null || !context.mounted || epoch != app.generation) return;
    final h = app.habits.where((h) => h.id == id && !h.archived).firstOrNull;
    if (h == null || app.restOn(h, day) != null) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HabitDetails(
          app: app,
          id: id,
          initialDay: day,
          logOnOpen: h.kind.isNumeric,
        ),
      ),
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
                onTap: () => open(
                  BackupPage(
                    app: app,
                    onReturnToday: () => setState(() => tab = 0),
                  ),
                ),
              ),
              SettingRow(
                icon: Icons.widgets_outlined,
                title: s.widgetsHelpTitle,
                tone: UiTone.violet,
                onTap: () => open(WidgetsHelpPage(app: app)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PlusMemberCard(app: app),
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
                key: const Key('home-insights'),
                icon: Icons.auto_graph_rounded,
                title: s.insightsTitle,
                subtitle: s.insightsRowSubtitle,
                tone: UiTone.violet,
                onTap: () => open(InsightsPage(app: app)),
              ),
              SettingRow(
                icon: Icons.auto_graph_outlined,
                title: s.reviewBuilder,
                tone: UiTone.violet,
                onTap: () => open(ReviewCardPage(app: app)),
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
        SettingRow(
          icon: Icons.auto_awesome_outlined,
          title: s.plusTitle,
          subtitle: app.plus.enabled
              ? (Localizations.localeOf(context).languageCode == 'zh'
                    ? '✦ 终身会员已生效 · 查看全部 6 项特权'
                    : '✦ Lifetime Active · View all 6 privileges')
              : s.plusBase,
          tone: UiTone.violet,
          onTap: () => open(PlusPage(app: app)),
        ),
        DetailDisclosure(title: s.freeTitle, child: Text(s.freeBody)),
        SettingRow(
          icon: Icons.privacy_tip_outlined,
          title: Localizations.localeOf(context).languageCode == 'zh'
              ? '隐私与支持'
              : 'Privacy & support',
          onTap: () => open(const PrivacyPage()),
        ),
        SettingRow(
          icon: Icons.code_rounded,
          title: s.licenses,
          tone: UiTone.violet,
          onTap: () =>
              showLicensePage(context: context, applicationName: 'DayPanel'),
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

class _PlusMemberCard extends StatelessWidget {
  const _PlusMemberCard({required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) {
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final theme = Theme.of(context);
    final isPlus = app.plus.enabled;

    if (isPlus) {
      return SoftPanel(
        key: const Key('plus-vip-card'),
        tone: UiTone.violet,
        tinted: true,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => PlusPage(app: app)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFFDE047),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              isZh
                                  ? '✦ DayPanel Plus 终身会员'
                                  : '✦ DayPanel Plus Lifetime',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isZh ? '已激活' : 'ACTIVE',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isZh
                              ? '尊享 6 大高级特权 · 纯本地私密无订阅'
                              : 'All 6 premium privileges active · 100% Private',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: UiTone.violet.ink(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeatureChip(
                  icon: Icons.auto_graph_rounded,
                  label: isZh ? '深度洞察' : 'Insights',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => InsightsPage(app: app),
                    ),
                  ),
                ),
                _FeatureChip(
                  icon: Icons.dashboard_customize_outlined,
                  label: isZh ? '组合组件' : 'Widgets',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => WidgetsHelpPage(app: app),
                    ),
                  ),
                ),
                _FeatureChip(
                  icon: Icons.palette_outlined,
                  label: isZh ? '专属装扮' : 'Themes',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AppearancePage(app: app),
                    ),
                  ),
                ),
                _FeatureChip(
                  icon: Icons.insights_outlined,
                  label: isZh ? '复盘长图' : 'Cards',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ReviewCardPage(app: app),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return InkWell(
      key: const Key('plus-upgrade-card'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => PlusPage(app: app)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: SoftPanel(
        tone: UiTone.violet,
        tinted: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: UiTone.violet.ink(context).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 20,
                color: UiTone.violet.ink(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isZh ? '升级到 DayPanel Plus' : 'Upgrade to DayPanel Plus',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isZh
                        ? '解锁深度洞察、周累计目标、组合桌面与原创主题'
                        : 'Unlock Insights, weekly goals, combo widgets & palettes',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: UiTone.violet.ink(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: UiTone.violet.ink(context)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyInsightsStrip extends StatelessWidget {
  const _DailyInsightsStrip({required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: InkWell(
        key: const Key('daily-insights-strip'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => InsightsPage(app: app)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: SoftPanel(
          tone: UiTone.violet,
          tinted: true,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: UiTone.violet.ink(context).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  app.plus.enabled
                      ? Icons.auto_graph_rounded
                      : Icons.auto_awesome_rounded,
                  size: 16,
                  color: UiTone.violet.ink(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: app.plus.enabled
                                ? (Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'zh'
                                      ? '✦ Plus 深度洞察'
                                      : '✦ Plus Deep Insights')
                                : (Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'zh'
                                      ? '✦ 深度洞察效果预览'
                                      : '✦ Insights Demo Preview'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: UiTone.violet.ink(context),
                            ),
                          ),
                          TextSpan(
                            text:
                                Localizations.localeOf(context).languageCode ==
                                    'zh'
                                ? (app.plus.enabled
                                      ? ' · 周期节律分析'
                                      : ' · 查看周期节律报表')
                                : (app.plus.enabled
                                      ? ' · Rhythm & Trends'
                                      : ' · See Sample Report'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      app.plus.enabled
                          ? (Localizations.localeOf(context).languageCode ==
                                    'zh'
                                ? '查看 30/90/365 天完成率趋势、星期强弱与共现规律 >'
                                : 'View 30/90/365d trends, weekdays & co-occurrence >')
                          : (Localizations.localeOf(context).languageCode ==
                                    'zh'
                                ? '点击预览 30/90 天完成率趋势、星期强弱与习惯共现样例 >'
                                : 'Tap to preview 30/90d trends, weekdays & habit pairs >'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: UiTone.violet.ink(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
