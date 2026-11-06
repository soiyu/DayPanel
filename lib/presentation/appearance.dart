import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../domain/appearance.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'theme.dart';

String frameLabel(AppLocalizations s, String frame) => switch (frame) {
  'ring' => s.frameRing,
  'plain' => s.framePlain,
  'soft' => s.frameSoft,
  _ => s.followDefault,
};
String colorLabel(AppLocalizations s, String color) => switch (color) {
  'blue' => s.colorBlue,
  'violet' => s.colorViolet,
  'peach' => s.colorPeach,
  'teal' => s.colorTeal,
  'rose' => s.colorRose,
  _ => s.automaticColor,
};
List<String> iconLabels(AppLocalizations s) => [
  s.iconSun,
  s.iconWater,
  s.iconBook,
  s.iconWalk,
  s.iconHeart,
  s.iconMoon,
  s.iconStrength,
  s.iconMeditate,
  s.iconRun,
  s.iconBike,
  s.iconMeal,
  s.iconFlower,
  s.iconMusic,
  s.iconArt,
  s.iconWrite,
  s.iconLanguage,
  s.iconSavings,
  s.iconClean,
  s.iconPet,
  s.iconCoffee,
  s.iconMedicine,
  s.iconSleep,
  s.iconUnplug,
  s.iconCare,
];

class StyleChoices extends StatelessWidget {
  const StyleChoices({
    super.key,
    required this.choices,
    required this.selected,
    required this.onChanged,
    this.prefix = '',
  });
  final Map<String, String> choices;
  final String selected, prefix;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final entry in choices.entries)
        Semantics(
          selected: selected == entry.key,
          child: AppAction(
            key: Key('$prefix${entry.key}'),
            label: entry.value,
            icon: selected == entry.key ? Icons.check_circle_outline : null,
            primary: selected == entry.key,
            onTap: onChanged == null ? null : () => onChanged!(entry.key),
          ),
        ),
    ],
  );
}

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key, required this.app});
  final AppController app;
  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  late Appearance draft;
  late int epoch;
  bool saving = false, failed = false;
  @override
  void initState() {
    super.initState();
    draft = Appearance.fromSettings(widget.app.preferences);
    epoch = widget.app.generation;
  }

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    final ok = await widget.app.run(
      () => widget.app.store.saveAppearance(draft),
      expectedGeneration: epoch,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        saving = false;
        failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = switch (draft.mode) {
      'light' => Brightness.light,
      'dark' => Brightness.dark,
      _ => MediaQuery.platformBrightnessOf(context),
    };
    return Theme(
      data: dayPanelTheme(brightness, appearance: draft),
      child: Builder(
        builder: (context) {
          final s = AppLocalizations.of(context);
          final h = widget.app.habits.where((h) => !h.archived).firstOrNull;
          Widget section(String title, Widget child) => Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [SectionTitle(title), child],
            ),
          );
          return PopScope(
            canPop: !saving,
            child: AppCanvas(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(title: Text(s.appearance)),
                body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            SoftPanel(
                              tinted: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.appearancePreview,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(s.appearanceHint),
                                  const SizedBox(height: 22),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ToneIcon(
                                        habitIcons[h?.icon ?? 2],
                                        tone: habitTone(
                                          h?.icon ?? 2,
                                          h?.color ?? 'auto',
                                        ),
                                        frame: h?.frame ?? 'auto',
                                        size: 52,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              h?.title ?? s.appearanceSample,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              h == null
                                                  ? s.appearanceSampleText
                                                  : MaterialLocalizations.of(
                                                      context,
                                                    ).formatFullDate(
                                                      widget.app.today.date,
                                                    ),
                                            ),
                                            if (h != null) ...[
                                              const SizedBox(height: 8),
                                              AppBadge(
                                                widget.app.achieved(
                                                      h,
                                                      widget.app.today,
                                                    )
                                                    ? s.finished
                                                    : widget.app.value(
                                                            h,
                                                            widget.app.today,
                                                          ) ==
                                                          null
                                                    ? s.notRecorded
                                                    : s.notCompleted,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (failed)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  epoch != widget.app.generation
                                      ? s.restoreStale
                                      : s.storageError,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            section(
                              s.appearanceMode,
                              StyleChoices(
                                prefix: 'mode-',
                                choices: {
                                  'system': s.system,
                                  'light': s.light,
                                  'dark': s.dark,
                                },
                                selected: draft.mode,
                                onChanged: saving
                                    ? null
                                    : (v) => setState(
                                        () => draft = draft.copyWith(mode: v),
                                      ),
                              ),
                            ),
                            section(
                              s.appearancePalette,
                              StyleChoices(
                                prefix: 'palette-',
                                choices: {
                                  'blue': s.paletteBlue,
                                  'teal': s.paletteTeal,
                                  'violet': s.paletteViolet,
                                },
                                selected: draft.palette,
                                onChanged: saving
                                    ? null
                                    : (v) => setState(
                                        () =>
                                            draft = draft.copyWith(palette: v),
                                      ),
                              ),
                            ),
                            section(
                              s.appearanceFont,
                              StyleChoices(
                                prefix: 'font-',
                                choices: {
                                  'system': s.fontSystem,
                                  'serif': s.fontSerif,
                                },
                                selected: draft.font,
                                onChanged: saving
                                    ? null
                                    : (v) => setState(
                                        () => draft = draft.copyWith(font: v),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              s.fontHint,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            section(
                              s.appearanceFrame,
                              StyleChoices(
                                prefix: 'frame-',
                                choices: {
                                  for (final f in Appearance.frames)
                                    f: frameLabel(s, f),
                                },
                                selected: draft.frame,
                                onChanged: saving
                                    ? null
                                    : (v) => setState(
                                        () => draft = draft.copyWith(frame: v),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 20,
                              children: [
                                for (final f in Appearance.frames)
                                  Column(
                                    children: [
                                      ToneIcon(
                                        Icons.spa_outlined,
                                        frame: f,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(frameLabel(s, f)),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            AppAction(
                              key: const Key('appearance-reset'),
                              label: s.appearanceReset,
                              onTap: saving
                                  ? null
                                  : () => setState(
                                      () => draft = const Appearance(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppAction(
                                label: s.cancel,
                                onTap: saving
                                    ? null
                                    : () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppAction(
                                key: const Key('appearance-save'),
                                label: s.save,
                                primary: true,
                                busy: saving,
                                onTap: saving ? null : save,
                              ),
                            ),
                          ],
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
  }
}

class HabitStylePicker extends StatelessWidget {
  const HabitStylePicker({
    super.key,
    required this.icon,
    required this.color,
    required this.frame,
    required this.onIcon,
    required this.onColor,
    required this.onFrame,
    required this.title,
  });
  final int icon;
  final String color, frame, title;
  final ValueChanged<int>? onIcon;
  final ValueChanged<String>? onColor, onFrame;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final names = iconLabels(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(s.habitDecoration),
        SoftPanel(
          tinted: true,
          tone: habitTone(icon, color),
          child: Row(
            children: [
              ToneIcon(
                habitIcons[icon],
                tone: habitTone(icon, color),
                frame: frame,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title.isEmpty ? s.habitDecoration : title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < habitIcons.length; i++)
              Semantics(
                selected: icon == i,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: icon == i
                          ? habitTone(i, color).ink(context)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: AppIconAction(
                    key: Key('habit-icon-$i'),
                    icon: habitIcons[i],
                    label: names[i],
                    tone: habitTone(i, color),
                    onTap: onIcon == null ? null : () => onIcon!(i),
                  ),
                ),
              ),
          ],
        ),
        SectionTitle(s.habitColor),
        StyleChoices(
          prefix: 'habit-color-',
          choices: {
            for (final c in Appearance.habitColors) c: colorLabel(s, c),
          },
          selected: color,
          onChanged: onColor,
        ),
        SectionTitle(s.habitFrame),
        StyleChoices(
          prefix: 'habit-frame-',
          choices: {
            for (final f in Appearance.habitFrames) f: frameLabel(s, f),
          },
          selected: frame,
          onChanged: onFrame,
        ),
        const SizedBox(height: 12),
        Text(s.decorationHint, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
