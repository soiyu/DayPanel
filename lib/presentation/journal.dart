import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/app_controller.dart';
import '../domain/journal.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'editors.dart';
import 'theme.dart';
import 'refined_components.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key, required this.app});
  final AppController app;
  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  late final TextEditingController search;
  final scroll = ScrollController();
  late JournalQuery lastQuery;
  AppController get app => widget.app;
  @override
  void initState() {
    super.initState();
    search = TextEditingController(text: app.journalQuery.text);
    lastQuery = app.journalQuery;
    app.addListener(syncSearch);
  }

  void syncSearch() {
    if (search.text != app.journalQuery.text) {
      search.text = app.journalQuery.text;
    }
    if (!identical(lastQuery, app.journalQuery)) {
      lastQuery = app.journalQuery;
      if (scroll.hasClients) scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    app.removeListener(syncSearch);
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  void month(Day? value) {
    final q = app.journalQuery;
    app.filterNotes(
      JournalQuery(
        month: value,
        habitId: q.habitId,
        independent: q.independent,
        text: q.text,
      ),
    );
  }

  Future<void> locate() async {
    FocusScope.of(context).unfocus();
    final q = app.journalQuery;
    final initial = q.day ?? q.month ?? app.today;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.date.isAfter(app.today.date)
          ? app.today.date
          : initial.date,
      firstDate: DateTime(1900),
      lastDate: app.today.date,
    );
    if (date != null && mounted) {
      final day = Day(date);
      app.filterNotes(
        JournalQuery(
          month: day,
          day: day,
          habitId: q.habitId,
          independent: q.independent,
          text: q.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      final q = app.journalQuery;
      final notes = app.visibleNotes;
      final currentMonth = q.month ?? app.today;
      final monthName = q.month == null
          ? s.allMonths
          : DateFormat.yMMMM(
              Localizations.localeOf(context).languageCode,
            ).format(currentMonth.date);
      final canExpandSearch =
          q.text.trim().isNotEmpty && (q.month != null || q.day != null);
      final searchScope = q.day == null
          ? monthName
          : MaterialLocalizations.of(context).formatMediumDate(q.day!.date);
      final hasFilter =
          q.text.trim().isNotEmpty ||
          q.habitId != null ||
          q.independent ||
          q.day != null;
      return ListView.builder(
        key: const PageStorageKey('journal'),
        controller: scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: notes.length + 1,
        itemBuilder: (context, index) {
          if (index > 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: NoteCard(app: app, note: notes[index - 1]),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const Key('note-search'),
                      controller: search,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: s.searchNotes,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: s.clearSearch,
                                onPressed: () => app.filterNotes(
                                  JournalQuery(
                                    month: q.month,
                                    day: q.day,
                                    habitId: q.habitId,
                                    independent: q.independent,
                                  ),
                                ),
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                      onChanged: (text) => app.filterNotes(
                        JournalQuery(
                          month: q.month,
                          day: q.day,
                          habitId: q.habitId,
                          independent: q.independent,
                          text: text,
                        ),
                      ),
                    ),
                    if (q.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        s.pmSearchScope(searchScope),
                        key: const Key('note-search-scope'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          key: const Key('previous-month'),
                          tooltip: s.previousMonth,
                          onPressed:
                              currentMonth.date.year == 1900 &&
                                  currentMonth.date.month == 1
                              ? null
                              : () => month(
                                  Day(
                                    DateTime(
                                      currentMonth.date.year,
                                      currentMonth.date.month - 1,
                                    ),
                                  ),
                                ),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            monthName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          key: const Key('next-month'),
                          tooltip: s.nextMonth,
                          onPressed:
                              currentMonth.date.year == app.today.date.year &&
                                  currentMonth.date.month ==
                                      app.today.date.month
                              ? null
                              : () => month(
                                  Day(
                                    DateTime(
                                      currentMonth.date.year,
                                      currentMonth.date.month + 1,
                                    ),
                                  ),
                                ),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        QuietChoice(
                          selected: q.month == null,
                          label: q.month == null ? s.thisMonth : s.allMonths,
                          icon: Icons.date_range_outlined,
                          tone: UiTone.violet,
                          onTap: () =>
                              month(q.month == null ? app.today : null),
                        ),
                        QuietChoice(
                          selected: q.day != null,
                          key: const Key('locate-note-date'),
                          label: s.locateDate,
                          icon: Icons.event_outlined,
                          tone: UiTone.peach,
                          onTap: locate,
                        ),
                        QuietChoice(
                          selected: q.habitId != null || q.independent,
                          key: const Key('note-filter'),
                          label: q.habitId != null
                              ? noteHabitLabel(context, app, q.habitId)
                              : q.independent
                              ? s.independentNote
                              : s.allNotes,
                          icon: Icons.tune_rounded,
                          tone: UiTone.violet,
                          onTap: () async {
                            FocusScope.of(context).unfocus();
                            final choice = await chooseNoteHabit(
                              context,
                              app,
                              selected: q.habitId,
                              all: q.habitId == null && !q.independent,
                              filter: true,
                            );
                            if (choice != null && mounted) {
                              app.filterNotes(
                                JournalQuery(
                                  month: q.month,
                                  day: q.day,
                                  text: q.text,
                                  independent:
                                      !choice.all && choice.habitId == null,
                                  habitId: choice.habitId,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),

                    if (q.day != null) ...[
                      const SizedBox(height: 10),
                      AppAction(
                        label: '${q.day!.key}  ·  ${s.showWholeMonth}',
                        icon: Icons.close_rounded,
                        tone: UiTone.peach,
                        onTap: () => month(q.month),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: SectionTitle(
                      s.notes,
                      count: notes.length,
                      tone: UiTone.violet,
                    ),
                  ),
                  if (hasFilter) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: TextButton(
                        onPressed: () =>
                            app.filterNotes(JournalQuery(month: q.month)),
                        child: Text(s.resetFilter),
                      ),
                    ),
                  ],
                ],
              ),
              if (notes.isEmpty)
                EmptyState(
                  icon: hasFilter
                      ? Icons.search_off_rounded
                      : Icons.edit_note_rounded,
                  title: hasFilter ? s.noNotesFound : s.emptyNoteMonth,
                  body: hasFilter ? s.noNotesFoundHint : s.emptyNoteMonthHint,
                  action: canExpandSearch
                      ? s.pmSearchAllMonths
                      : hasFilter
                      ? s.resetFilter
                      : s.newNote,
                  onAction: canExpandSearch
                      ? () => month(null)
                      : hasFilter
                      ? () => app.filterNotes(JournalQuery(month: q.month))
                      : () => openEditor(context, app, 'note'),
                  tone: UiTone.violet,
                ),
            ],
          );
        },
      );
    },
  );
}

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.app, required this.note});
  final AppController app;
  final Note note;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final epoch = app.generation;
    return SoftPanel(
      key: Key('note-card-${note.id}'),
      padding: const EdgeInsets.fromLTRB(14, 4, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).languageCode,
                  ).format(note.day.date),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: UiTone.violet.ink(context),
                  ),
                ),
              ),
              IconButton(
                tooltip: s.more,
                icon: const Icon(Icons.more_horiz_rounded),
                onPressed: app.busy
                    ? null
                    : () async {
                        final action = await showEntryActions(context, s.note);
                        if (!context.mounted) return;
                        if (action == 'edit') {
                          await openEditor(
                            context,
                            app,
                            'note',
                            note: note,
                            expectedGeneration: epoch,
                          );
                        }
                        if (action == 'delete' &&
                            context.mounted &&
                            await confirmDelete(context)) {
                          await app.run(
                            () => app.store.remove('notes', note.id),
                            expectedGeneration: epoch,
                          );
                        }
                      },
              ),
            ],
          ),
          if (note.habitId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppBadge(
                noteHabitLabel(context, app, note.habitId),
                icon: Icons.link_rounded,
                tone: UiTone.violet,
              ),
            ),
          InkWell(
            onTap: app.busy
                ? null
                : () => openEditor(context, app, 'note', note: note),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: UiTone.violet.ink(context).withValues(alpha: .25),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                note.body,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HabitJournalPage extends StatelessWidget {
  const HabitJournalPage({super.key, required this.app, required this.habitId});
  final AppController app;
  final String habitId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      final habit = app.habits.where((h) => h.id == habitId).firstOrNull;
      final notes = JournalQuery(habitId: habitId).apply(app.notes);
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(s.habitJournal),
            actions: [
              AppIconAction(
                label: s.newNote,
                icon: Icons.add_rounded,
                primary: true,
                onTap: app.busy || habit == null
                    ? null
                    : () => openEditor(
                        context,
                        app,
                        'note',
                        noteHabitId: habitId,
                      ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                habit == null
                    ? s.noteHabitMissing
                    : noteHabitLabel(context, app, habitId),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                s.noteAssociationHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (app.error != null)
                Text(
                  s.storageError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 20),
              if (notes.isEmpty)
                EmptyState(
                  icon: Icons.edit_note_rounded,
                  title: s.emptyNotes,
                  body: s.journalEmptyHint,
                  tone: UiTone.violet,
                ),
              for (final note in notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: NoteCard(app: app, note: note),
                ),
            ],
          ),
        ),
      );
    },
  );
}
