import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../application/app_controller.dart';
import '../data/card_image.dart';
import '../domain/models.dart';
import '../domain/statistics.dart';
import '../l10n/app_localizations.dart';
import 'card_art.dart';
import 'components.dart';
import 'theme.dart';
import 'plus_page.dart';

class ReviewCardPage extends StatefulWidget {
  const ReviewCardPage({super.key, required this.app, this.files});
  final AppController app;
  final CardImageFiles? files;
  @override
  State<ReviewCardPage> createState() => _ReviewCardPageState();
}

class _ReviewCardPageState extends State<ReviewCardPage> {
  AppController get app => widget.app;
  late final int epoch = app.generation;
  late Day anchor = app.today;
  late final selected = app.habits.take(4).map((h) => h.id).toSet();
  bool month = false,
      names = false,
      reflection = false,
      amounts = true,
      recordDays = true,
      working = false,
      preview = false;
  int artwork = 6;
  final words = TextEditingController();
  final boundary = GlobalKey();
  final scroll = ScrollController();
  String? error;
  Day get start => month
      ? Day(DateTime(anchor.date.year, anchor.date.month))
      : anchor.monday;
  Day get end {
    final last = month
        ? Day(DateTime(anchor.date.year, anchor.date.month + 1, 0))
        : anchor.monday.plus(6);
    return last.compareTo(app.today) > 0 ? app.today : last;
  }

  @override
  void dispose() {
    words.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> output(bool share) async {
    if (working || epoch != app.generation) return;
    final s = AppLocalizations.of(context);
    if (!await requirePlus(context, app) || !mounted) return;
    setState(() {
      working = true;
      error = null;
    });
    try {
      if (await app.store.generation() != epoch) throw StateError('Changed');
      await Scrollable.ensureVisible(boundary.currentContext!, alignment: 0);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final render =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ratio = math.min(
        2.5,
        math.min(4096 / render.size.width, 16000 / render.size.height),
      );
      final image = await render.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null || await app.store.generation() != epoch) {
        throw StateError('Changed');
      }
      final files = widget.files ?? AndroidCardImageFiles();
      final name = 'DayPanel-review-${start.key}-${end.key}.png';
      if (share) {
        await files.share(data.buffer.asUint8List(), name);
      } else {
        final saved = await files.save(data.buffer.asUint8List(), name);
        if (saved && mounted) setState(() => error = s.cardImageSaved);
      }
    } catch (_) {
      if (mounted) setState(() => error = s.cardShareStale);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Widget poster(BuildContext context) {
    final s = AppLocalizations.of(context);
    final chosen = app.habits.where((h) => selected.contains(h.id)).toList();
    return RepaintBoundary(
      key: boundary,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'DayPanel',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                const Icon(Icons.auto_awesome_outlined),
              ],
            ),
            const SizedBox(height: 16),
            CardArt(artwork: artwork, height: 150),
            const SizedBox(height: 18),
            Text(
              month ? s.reviewMonth : s.reviewWeek,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${start.key} — ${end.key}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < chosen.length; i++) ...[
              Text(
                names ? chosen[i].title : '${s.privateHabit} ${i + 1}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (recordDays)
                Text(
                  '${s.recordedDays}: ${app.entries.where((e) => e.habitId == chosen[i].id && e.day.compareTo(start) >= 0 && e.day.compareTo(end) <= 0).length}',
                ),
              if (amounts && chosen[i].kind.isNumeric)
                for (final group in HabitStatistics(
                  chosen[i],
                  app.plans,
                  app.activity,
                  app.entries,
                  app.today,
                  breaks: app.rests,
                ).quantities(start, end).entries)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${quantityText(group.value.fold<int>(0, (v, e) => v + e.value))} ${group.key}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          label: '${start.key} — ${end.key}',
                          child: SizedBox(
                            height: 40,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (
                                  var offset = 0;
                                  offset < end.daysSince(start) + 1;
                                  offset++
                                )
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          width: 12,
                                          height: math.max(
                                            2,
                                            40 *
                                                (group.value
                                                        .where(
                                                          (p) =>
                                                              p.day ==
                                                              start.plus(
                                                                offset,
                                                              ),
                                                        )
                                                        .firstOrNull
                                                        ?.value ??
                                                    0) /
                                                math.max(
                                                  1,
                                                  group.value
                                                      .map((p) => p.value)
                                                      .reduce(math.max),
                                                ),
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                group.value.any(
                                                  (p) =>
                                                      p.day ==
                                                      start.plus(offset),
                                                )
                                                ? UiTone.violet.ink(context)
                                                : UiTone.violet.wash(context),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${start.date.month}/${start.date.day}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${end.date.month}/${end.date.day}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 18),
            ],
            if (reflection && words.text.trim().isNotEmpty) ...[
              const Divider(),
              Text(words.text.trim()),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.reviewBuilder)),
          body: SafeArea(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(20),
              children: [
                if (epoch != app.generation)
                  Text(s.recordChanged)
                else ...[
                  if (!preview) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppAction(
                          label: s.reviewWeek,
                          primary: !month,
                          onTap: () => setState(() => month = false),
                        ),
                        AppAction(
                          label: s.reviewMonth,
                          primary: month,
                          onTap: () => setState(() => month = true),
                        ),
                      ],
                    ),
                    SettingRow(
                      icon: Icons.calendar_today_outlined,
                      title: '${start.key} — ${end.key}',
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: anchor.date,
                          firstDate: DateTime(1900),
                          lastDate: app.today.date,
                        );
                        if (picked != null && mounted) {
                          setState(() => anchor = Day(picked));
                        }
                      },
                    ),
                    Text(
                      s.reviewChoose,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (app.habits.isEmpty) Text(s.emptyHabits),
                    for (final h in app.habits)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          h.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: selected.contains(h.id),
                        onChanged:
                            selected.length >= 6 && !selected.contains(h.id)
                            ? null
                            : (v) => setState(() {
                                if (v == true) {
                                  if (selected.length < 6) selected.add(h.id);
                                } else {
                                  selected.remove(h.id);
                                }
                              }),
                      ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.recordedDays),
                      value: recordDays,
                      onChanged: (v) => setState(() => recordDays = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.quantityHabit),
                      value: amounts,
                      onChanged: (v) => setState(() => amounts = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.cardShareNames),
                      value: names,
                      onChanged: (v) => setState(() => names = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.cardShareReflection),
                      value: reflection,
                      onChanged: (v) => setState(() => reflection = v),
                    ),
                    if (reflection)
                      TextField(
                        controller: words,
                        maxLines: 3,
                        maxLength: 280,
                        decoration: InputDecoration(
                          labelText: s.editReflection,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final i in [6, 7])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Semantics(
                                button: true,
                                selected: artwork == i,
                                label: '${s.styleExtra} ${i - 5}',
                                child: InkWell(
                                  onTap: () => setState(() => artwork = i),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: artwork == i
                                            ? UiTone.blue.ink(context)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: CardArt(artwork: i, height: 90),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppAction(
                      key: const Key('review-preview'),
                      label: s.reviewPreview,
                      primary: true,
                      onTap: selected.isEmpty
                          ? null
                          : () async {
                              if (await requirePlus(context, app) && mounted) {
                                setState(() => preview = true);
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted && scroll.hasClients) {
                                    scroll.jumpTo(0);
                                  }
                                });
                              }
                            },
                    ),
                  ] else ...[
                    Text(
                      s.cardShareHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    poster(context),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppAction(
                          label: s.cardSaveImage,
                          icon: Icons.save_alt,
                          onTap: working ? null : () => output(false),
                        ),
                        AppAction(
                          label: s.cardShareAction,
                          icon: Icons.ios_share,
                          primary: true,
                          onTap: working ? null : () => output(true),
                        ),
                        AppAction(
                          label: s.edit,
                          onTap: working
                              ? null
                              : () => setState(() => preview = false),
                        ),
                      ],
                    ),
                  ],
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error!),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
