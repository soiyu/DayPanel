import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../domain/appearance.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'plus_page.dart';
import 'theme.dart';
import 'habit_icon.dart';
import 'refined_components.dart';

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
  s.iconHeadphones,
  s.iconLaptop,
  s.iconHike,
  s.iconInk,
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
          child: QuietChoice(
            key: Key('$prefix${entry.key}'),
            label: entry.value,
            selected: selected == entry.key,
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
    if (['apricot', 'coast'].contains(draft.palette) &&
        !await requirePlus(context, widget.app)) {
      return;
    }
    if (!mounted) return;
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
          final scheme = Theme.of(context).colorScheme;
          return PopScope(
            canPop: !saving,
            child: AppCanvas(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(s.appearance),
                  actions: [
                    IconButton(
                      key: const Key('appearance-reset'),
                      tooltip: s.appearanceReset,
                      icon: const Icon(Icons.restart_alt_rounded),
                      onPressed: saving
                          ? null
                          : () => setState(() => draft = const Appearance()),
                    ),
                  ],
                ),
                body: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          children: [
                            SoftPanel(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  HabitIcon(
                                    h?.icon ?? 2,
                                    color: h?.color ?? 'auto',
                                    frame: h?.frame ?? 'auto',
                                    size: 36,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          h?.title ?? s.uiFontSample,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                        Text(
                                          s.uiPreviewLive,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (final tone in [
                                    UiTone.blue,
                                    UiTone.violet,
                                    UiTone.peach,
                                    UiTone.teal,
                                  ])
                                    Container(
                                      width: 10,
                                      height: 18,
                                      margin: const EdgeInsets.only(left: 3),
                                      decoration: BoxDecoration(
                                        color: tone.ink(context),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (failed)
                              Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Text(
                                  epoch != widget.app.generation
                                      ? s.restoreStale
                                      : s.storageError,
                                  style: TextStyle(color: scheme.error),
                                ),
                              ),
                            const SizedBox(height: 8),
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
                            SectionHeading(s.appearancePalette),
                            ResponsiveChoices(
                              minWidth: 88,
                              children: [
                                for (final palette in Appearance.palettes)
                                  ChoiceSurface(
                                    key: Key('palette-$palette'),
                                    label: switch (palette) {
                                      'teal' => s.paletteTeal,
                                      'violet' => s.paletteViolet,
                                      'apricot' => '${s.paletteSunrise} · PLUS',
                                      'coast' => '${s.paletteOcean} · PLUS',
                                      _ => s.paletteBlue,
                                    },
                                    selected: draft.palette == palette,
                                    onTap: saving
                                        ? null
                                        : () => setState(
                                            () => draft = draft.copyWith(
                                              palette: palette,
                                            ),
                                          ),
                                    visual: _PaletteSample(
                                      palette: palette,
                                      dark: brightness == Brightness.dark,
                                    ),
                                  ),
                              ],
                            ),
                            SectionHeading(s.appearanceFont),
                            ResponsiveChoices(
                              maxColumns: 2,
                              children: [
                                for (final font in Appearance.fonts)
                                  ChoiceSurface(
                                    key: Key('font-$font'),
                                    label: font == 'serif'
                                        ? s.fontSerif
                                        : s.fontSystem,
                                    selected: draft.font == font,
                                    onTap: saving
                                        ? null
                                        : () => setState(
                                            () => draft = draft.copyWith(
                                              font: font,
                                            ),
                                          ),
                                    visual: Text(
                                      'Aa 日常',
                                      style: TextStyle(
                                        fontFamily: font == 'serif'
                                            ? 'NotoSerifSC'
                                            : null,
                                        fontSize: 25,
                                        height: 1.2,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SectionHeading(s.appearanceFrame),
                            ResponsiveChoices(
                              minWidth: 88,
                              children: [
                                for (final frame in Appearance.frames)
                                  ChoiceSurface(
                                    key: Key('frame-$frame'),
                                    label: frameLabel(s, frame),
                                    selected: draft.frame == frame,
                                    onTap: saving
                                        ? null
                                        : () => setState(
                                            () => draft = draft.copyWith(
                                              frame: frame,
                                            ),
                                          ),
                                    visual: ToneIcon(
                                      Icons.spa_outlined,
                                      frame: frame,
                                      size: 42,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DetailDisclosure(
                              title: s.uiMoreDetails,
                              child: Text(
                                s.fontHint,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      EditorFooter(
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
                            flex:
                                MediaQuery.sizeOf(context).width < 360 &&
                                    MediaQuery.textScalerOf(context).scale(1) >
                                        1.3
                                ? 1
                                : 2,
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

class _PaletteSample extends StatelessWidget {
  const _PaletteSample({required this.palette, required this.dark});
  final String palette;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    final theme = dayPanelTheme(
      dark ? Brightness.dark : Brightness.light,
      appearance: Appearance(palette: palette),
    );
    return Theme(
      data: theme,
      child: Builder(
        builder: (ctx) => Container(
          height: 76,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  for (final tone in [
                    UiTone.blue,
                    UiTone.violet,
                    UiTone.peach,
                    UiTone.teal,
                  ])
                    Expanded(
                      child: Container(
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: tone.ink(ctx),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    const HabitIcon(1, size: 32, frame: 'plain'),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 5,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: .5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          FractionallySizedBox(
                            widthFactor: .7,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 5,
                              color: theme.colorScheme.primary.withValues(
                                alpha: dark ? .35 : .22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
              HabitIcon(icon, color: color, frame: frame, size: 56),
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
        LayoutBuilder(
          builder: (context, c) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final columns = (c.maxWidth / (scale > 1.3 ? 104 : 82))
                .floor()
                .clamp(2, 5);
            final width = (c.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                for (var i = 0; i < habitIcons.length; i++)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      button: true,
                      selected: icon == i,
                      label: names[i],
                      excludeSemantics: true,
                      onTap: onIcon == null ? null : () => onIcon!(i),
                      child: Material(
                        color: icon == i
                            ? habitTone(i).wash(context)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: icon == i
                                ? habitTone(i).ink(context)
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: Key('habit-icon-$i'),
                          onTap: onIcon == null ? null : () => onIcon!(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 4,
                            ),
                            child: Column(
                              children: [
                                HabitIcon(i, size: 52, frame: 'plain'),
                                const SizedBox(height: 6),
                                Text(
                                  names[i],
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        SectionHeading(s.habitColor),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in Appearance.habitColors)
              Tooltip(
                message: colorLabel(s, c),
                child: Semantics(
                  button: true,
                  selected: color == c,
                  label: colorLabel(s, c),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: Key('habit-color-$c'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: onColor == null ? null : () => onColor!(c),
                      child: Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: color == c
                                ? habitTone(icon, c).ink(context)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: habitTone(icon, c).ink(context),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            color == c
                                ? Icons.check_rounded
                                : c == 'auto'
                                ? Icons.auto_awesome_rounded
                                : null,
                            color: Theme.of(context).colorScheme.surface,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SectionHeading(s.habitFrame),
        ResponsiveChoices(
          minWidth: 104,
          maxColumns: 4,
          children: [
            for (final f in Appearance.habitFrames)
              ChoiceSurface(
                key: Key('habit-frame-$f'),
                label: frameLabel(s, f),
                selected: frame == f,
                onTap: onFrame == null ? null : () => onFrame!(f),
                visual: HabitIcon(icon, color: color, frame: f, size: 36),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(s.decorationHint, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
