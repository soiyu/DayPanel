import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/app_controller.dart';
import '../data/app_store.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'card_art.dart';
import 'components.dart';
import 'theme.dart';
import 'card_share.dart';
import 'refined_components.dart';

String cardTitle(AppLocalizations s, int art) => [
  s.cardDawn,
  s.cardRoots,
  s.cardRiver,
  s.cardSteps,
  s.cardWindow,
  s.cardStars,
][art];
String cardDate(BuildContext context, Day day) => DateFormat.yMMMd(
  Localizations.localeOf(context).languageCode,
).format(day.date);
void openCard(BuildContext context, AppController app, Day day) =>
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CardDetails(app: app, day: day),
      ),
    );

class DailyCardPanel extends StatelessWidget {
  const DailyCardPanel({super.key, required this.app, required this.day});
  final AppController app;
  final Day day;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final card = app.cardFor(day);
    if (day != app.today && card == null) return const SizedBox.shrink();
    final hasDailyObligation = app.habits.any(
      (h) =>
          app.scheduled(h, day) &&
          app.planAt(h, day).schedule.isWeekly == false,
    );
    if (card == null && !hasDailyObligation) return const SizedBox.shrink();
    final epoch = app.generation;
    final canClaim = day == app.today && app.canClaimCard;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: SoftPanel(
        tinted: true,
        tone: UiTone.violet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ToneIcon(
                  card == null
                      ? Icons.auto_awesome_outlined
                      : Icons.style_outlined,
                  tone: UiTone.violet,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    card == null ? s.todayCard : cardTitle(s, card.artwork),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              card != null ? s.cardKeptHint : s.cardUnlockHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (card != null)
                  AppAction(
                    label: s.viewCard,
                    icon: Icons.auto_stories_outlined,
                    tone: UiTone.violet,
                    onTap: () => openCard(context, app, day),
                  ),
                if (card == null && canClaim)
                  AppAction(
                    key: const Key('claim-card'),
                    label: s.claimCard,
                    icon: Icons.auto_awesome_rounded,
                    primary: true,
                    onTap: app.busy
                        ? null
                        : () async {
                            final ok = await app.run(
                              () => app.store.claimCard(day, today: app.today),
                              expectedGeneration: epoch,
                            );
                            if (ok && context.mounted) {
                              openCard(context, app, day);
                            }
                          },
                  ),
                AppAction(
                  label: s.cardCollection,
                  icon: Icons.collections_bookmark_outlined,
                  tone: UiTone.violet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CardCollection(app: app),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CardCollection extends StatefulWidget {
  const CardCollection({super.key, required this.app});
  final AppController app;
  @override
  State<CardCollection> createState() => _CardCollectionState();
}

class _CardCollectionState extends State<CardCollection> {
  bool favorites = false;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      final hasDailyObligation = widget.app.habits.any(
        (h) =>
            widget.app.scheduled(h, widget.app.today) &&
            widget.app.planAt(h, widget.app.today).schedule.isWeekly == false,
      );
      final cards = widget.app.cards
          .where((c) => !favorites || c.favorite)
          .toList();
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(s.cardCollection),
            actions: [
              IconButton(
                key: const Key('card-guide'),
                tooltip: s.cardGuide,
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CardGuidePage(),
                  ),
                ),
              ),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: cards.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppAction(
                          label: '${s.allCards} ${widget.app.cards.length}',
                          icon: favorites
                              ? Icons.style_outlined
                              : Icons.check_circle_rounded,
                          tone: UiTone.violet,
                          onTap: () => setState(() => favorites = false),
                        ),
                        AppAction(
                          key: const Key('favorite-filter'),
                          label:
                              '${s.favoriteCards} ${widget.app.cards.where((c) => c.favorite).length}',
                          icon: favorites
                              ? Icons.check_circle_rounded
                              : Icons.favorite_outline,
                          tone: UiTone.peach,
                          onTap: () => setState(() => favorites = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!favorites && widget.app.cards.isNotEmpty) ...[
                      Builder(
                        builder: (ctx) {
                          final count = widget.app.cards.length;
                          final milestones = [
                            (
                              7,
                              s.cardMilestone7,
                              s.cardMilestone7Desc,
                              Icons.bolt_rounded,
                            ),
                            (
                              21,
                              s.cardMilestone21,
                              s.cardMilestone21Desc,
                              Icons.all_inclusive_rounded,
                            ),
                            (
                              30,
                              s.cardMilestone30,
                              s.cardMilestone30Desc,
                              Icons.nightlight_round,
                            ),
                            (
                              100,
                              s.cardMilestone100,
                              s.cardMilestone100Desc,
                              Icons.park_rounded,
                            ),
                            (
                              365,
                              s.cardMilestone365,
                              s.cardMilestone365Desc,
                              Icons.wb_sunny_rounded,
                            ),
                          ];
                          final next = milestones
                              .where((m) => m.$1 > count)
                              .firstOrNull;
                          if (next == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SoftPanel(
                              tone: UiTone.violet,
                              tinted: true,
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        next.$4,
                                        size: 18,
                                        color: UiTone.violet.ink(ctx),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${s.cardNextMilestone}: ${next.$2}',
                                          style: Theme.of(
                                            ctx,
                                          ).textTheme.titleSmall,
                                        ),
                                      ),
                                      Text(
                                        '$count / ${next.$1}',
                                        style: Theme.of(ctx).textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: (count / next.$1).clamp(0.0, 1.0),
                                    minHeight: 3,
                                    borderRadius: BorderRadius.circular(2),
                                    color: UiTone.violet.ink(ctx),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    next.$3,
                                    style: Theme.of(ctx).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (cards.isEmpty)
                      EmptyState(
                        icon: Icons.collections_bookmark_outlined,
                        title: favorites
                            ? s.noFavoriteCards
                            : hasDailyObligation
                            ? s.noCards
                            : s.cardCollection,
                        body: favorites
                            ? s.favoriteHint
                            : hasDailyObligation
                            ? s.cardUnlockHint
                            : s.pmCardsNoDaily,
                        tone: UiTone.violet,
                      ),
                  ],
                );
              }
              final card = cards[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SoftPanel(
                  padding: const EdgeInsets.all(14),
                  child: InkWell(
                    onTap: () => openCard(context, widget.app, card.day),
                    borderRadius: BorderRadius.circular(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CardArt(artwork: card.artwork, height: 160),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cardTitle(s, card.artwork),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (card.favorite)
                              Icon(
                                Icons.favorite_rounded,
                                color: UiTone.peach.ink(context),
                                semanticLabel: s.favoriteCards,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${cardDate(context, card.day)} · ${card.evidence.length} ${s.habitCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (card.reflection.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            card.reflection,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

/// Artwork previews explain the feature; they are not earned card records.
class CardGuidePage extends StatelessWidget {
  const CardGuidePage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(s.cardGuide)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(s.cardPurpose, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              Text(s.cardUnlockHint),
              const SizedBox(height: 8),
              Text(
                s.cardGuideEligibility,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                s.cardArtPreviewTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                s.cardArtPreviewHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ResponsiveChoices(
                minWidth: 155,
                maxColumns: 2,
                children: [
                  for (var art = 0; art < 6; art++)
                    SoftPanel(
                      key: Key('card-art-preview-$art'),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CardArt(artwork: art, height: 105),
                          const SizedBox(height: 8),
                          Text(
                            cardTitle(s, art),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                s.cardMilestonesTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                s.cardMilestonesHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              for (final (_, title, desc, icon) in [
                (7, s.cardMilestone7, s.cardMilestone7Desc, Icons.bolt_rounded),
                (
                  21,
                  s.cardMilestone21,
                  s.cardMilestone21Desc,
                  Icons.all_inclusive_rounded,
                ),
                (
                  30,
                  s.cardMilestone30,
                  s.cardMilestone30Desc,
                  Icons.nightlight_round,
                ),
                (
                  100,
                  s.cardMilestone100,
                  s.cardMilestone100Desc,
                  Icons.park_rounded,
                ),
                (
                  365,
                  s.cardMilestone365,
                  s.cardMilestone365Desc,
                  Icons.wb_sunny_rounded,
                ),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SoftPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 22, color: UiTone.violet.ink(context)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                desc,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(s.cardShare, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(s.cardGuideShare),
            ],
          ),
        ),
      ),
    );
  }
}

class CardDetails extends StatefulWidget {
  const CardDetails({super.key, required this.app, required this.day});
  final AppController app;
  final Day day;
  @override
  State<CardDetails> createState() => _CardDetailsState();
}

class _CardDetailsState extends State<CardDetails> {
  bool back = false;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, _) {
      final app = widget.app;
      final s = AppLocalizations.of(context);
      final card = app.cardFor(widget.day);
      final epoch = app.generation;
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.dailyCard)),
          body: card == null
              ? SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    children: [
                      EmptyState(
                        key: const Key('card-unavailable'),
                        icon: Icons.style_outlined,
                        title: s.cardUnavailable,
                        body: s.cardRestoreHint,
                        action: s.back,
                        actionIcon: Icons.arrow_back_rounded,
                        onAction: () => Navigator.maybePop(context),
                        tone: UiTone.violet,
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      cardDate(context, card.day),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SoftPanel(
                      tone: UiTone.violet,
                      tinted: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 260),
                            transitionBuilder: cardFlipTransition,
                            child: back
                                ? Container(
                                    key: const ValueKey('card-back'),
                                    width: double.infinity,
                                    constraints: const BoxConstraints(
                                      minHeight: 190,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.cardReflection,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          card.reflection.isEmpty
                                              ? s.emptyReflection
                                              : card.reflection,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    key: const ValueKey('card-front'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      CardArt(
                                        artwork: card.artwork,
                                        height: 180,
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        cardTitle(s, card.artwork),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        s.cardMoment,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AppAction(
                                key: const Key('flip-card'),
                                label: back ? s.cardFront : s.cardBack,
                                icon: Icons.flip_rounded,
                                tone: UiTone.violet,
                                onTap: () => setState(() => back = !back),
                              ),
                              AppAction(
                                key: const Key('favorite-card'),
                                label: card.favorite
                                    ? s.unfavoriteCard
                                    : s.favoriteCard,
                                icon: card.favorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_outline,
                                tone: UiTone.peach,
                                onTap: app.busy
                                    ? null
                                    : () => app.run(
                                        () => app.store.favoriteCard(
                                          card.day,
                                          !card.favorite,
                                        ),
                                        expectedGeneration: epoch,
                                      ),
                              ),
                              AppAction(
                                key: const Key('open-card-share'),
                                label: s.cardShare,
                                icon: Icons.ios_share_rounded,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => CardSharePage(
                                      app: app,
                                      day: card.day,
                                      title: cardTitle(s, card.artwork),
                                    ),
                                  ),
                                ),
                              ),
                              AppAction(
                                key: const Key('edit-reflection'),
                                label: s.editReflection,
                                icon: Icons.edit_note_rounded,
                                primary: true,
                                onTap: app.busy
                                    ? null
                                    : () => showModalBottomSheet<void>(
                                        context: context,
                                        isScrollControlled: true,
                                        useSafeArea: true,
                                        builder: (_) => _ReflectionEditor(
                                          app: app,
                                          day: card.day,
                                          text: card.reflection,
                                          epoch: epoch,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (app.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          s.storageError,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      s.cardKeptHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    SectionTitle(
                      s.cardEvidence,
                      count: card.evidence.length,
                      tone: UiTone.violet,
                    ),
                    for (final h in card.evidence)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SoftPanel(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                h.kind == HabitKind.check
                                    ? s.finished
                                    : '${quantityText(h.value)} / ${quantityText(h.target)} ${h.unit}',
                              ),
                              Text(
                                '${s.effectiveFrom} ${h.planDay.key}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      );
    },
  );
}

class _ReflectionEditor extends StatefulWidget {
  const _ReflectionEditor({
    required this.app,
    required this.day,
    required this.text,
    required this.epoch,
  });
  final AppController app;
  final Day day;
  final String text;
  final int epoch;
  @override
  State<_ReflectionEditor> createState() => _ReflectionEditorState();
}

class _ReflectionEditorState extends State<_ReflectionEditor> {
  late final text = TextEditingController(text: widget.text);
  bool saving = false, failed = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SheetFrame(
      title: s.cardReflection,
      subtitle: '${cardDate(context, widget.day)}\n${s.reflectionHint}',
      icon: Icons.edit_note_rounded,
      tone: UiTone.violet,
      busy: saving,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('reflection-text'),
            controller: text,
            enabled: !saving,
            minLines: 4,
            maxLines: 12,
            maxLength: 10000,
            decoration: InputDecoration(hintText: s.emptyReflection),
          ),
          if (failed)
            Text(
              s.storageError,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: AppAction(
              label: s.cancel,
              onTap: saving ? null : () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppAction(
              key: const Key('save-reflection'),
              label: s.save,
              primary: true,
              busy: saving,
              onTap: saving
                  ? null
                  : () async {
                      setState(() {
                        saving = true;
                        failed = false;
                      });
                      final ok = await widget.app.run(
                        () => widget.app.store.reflectOnCard(
                          widget.day,
                          text.text.trim(),
                        ),
                        expectedGeneration: widget.epoch,
                      );
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.pop(context);
                      } else {
                        setState(() {
                          saving = false;
                          failed = true;
                        });
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key, required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      final epoch = app.generation;
      return AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.completionFeedback)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                s.feedbackHint,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              for (final entry in {
                'completion_sound': s.completionSound,
                'completion_haptics': s.completionHaptics,
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SoftPanel(
                    padding: const EdgeInsets.all(4),
                    tinted: true,
                    tone: entry.key == 'completion_sound'
                        ? UiTone.violet
                        : UiTone.peach,
                    child: SettingRow(
                      onTap: null,
                      icon: entry.key == 'completion_sound'
                          ? Icons.volume_up_outlined
                          : Icons.vibration_rounded,
                      title: entry.value,
                      subtitle: app.preferences[entry.key] == 'on'
                          ? s.feedbackOn
                          : s.feedbackOff,
                      trailing: Switch(
                        key: Key(entry.key),
                        value: app.preferences[entry.key] == 'on',
                        onChanged: app.busy
                            ? null
                            : (on) => app.run(
                                () => app.store.preference(
                                  entry.key,
                                  on ? 'on' : 'off',
                                ),
                                expectedGeneration: epoch,
                              ),
                      ),
                    ),
                  ),
                ),
              Text(
                s.feedbackSystemHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (app.feedbackFailed)
                Text(
                  s.feedbackFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (app.error != null)
                Text(
                  s.storageError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      );
    },
  );
}
