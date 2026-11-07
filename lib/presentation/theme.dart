import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/appearance.dart';

enum UiTone { blue, violet, peach, teal, rose, sky }

class DayPanelStyle extends ThemeExtension<DayPanelStyle> {
  const DayPanelStyle({
    required this.appearance,
    required this.actionStart,
    required this.actionEnd,
  });
  final Appearance appearance;
  final Color actionStart, actionEnd;
  static DayPanelStyle of(BuildContext context) =>
      Theme.of(context).extension<DayPanelStyle>()!;
  @override
  DayPanelStyle copyWith({
    Appearance? appearance,
    Color? actionStart,
    Color? actionEnd,
  }) => DayPanelStyle(
    appearance: appearance ?? this.appearance,
    actionStart: actionStart ?? this.actionStart,
    actionEnd: actionEnd ?? this.actionEnd,
  );
  @override
  DayPanelStyle lerp(covariant DayPanelStyle? other, double t) => other == null
      ? this
      : DayPanelStyle(
          appearance: t < .5 ? appearance : other.appearance,
          actionStart: Color.lerp(actionStart, other.actionStart, t)!,
          actionEnd: Color.lerp(actionEnd, other.actionEnd, t)!,
        );
}

/// Each theme is a balanced set of role colors, not a single tinted seed.
const harmonyInks = <String, List<int>>{
  'blue': [
    0xFF2459CC,
    0xFF7956B4,
    0xFFA65B2B,
    0xFF247365,
    0xFFA04E69,
    0xFF316CB0,
  ],
  'teal': [
    0xFF226B62,
    0xFF75629B,
    0xFFA15C37,
    0xFF35755A,
    0xFF9A5463,
    0xFF366BA3,
  ],
  'violet': [
    0xFF6650A2,
    0xFF80619F,
    0xFF946128,
    0xFF347568,
    0xFF99566D,
    0xFF4267A8,
  ],
};
const harmonyWashes = <String, List<int>>{
  'blue': [
    0xFFEAF0FD,
    0xFFF0EBF8,
    0xFFFBF0E4,
    0xFFE7F3EE,
    0xFFF9EBF0,
    0xFFE9F1F8,
  ],
  'teal': [
    0xFFE5F0EB,
    0xFFEEEBF4,
    0xFFF6ECE2,
    0xFFEAF1E6,
    0xFFF5EAEC,
    0xFFE7EEF6,
  ],
  'violet': [
    0xFFEDEAF7,
    0xFFF1ECF7,
    0xFFF6F0DE,
    0xFFE9F2ED,
    0xFFF7EAEF,
    0xFFEAF0F8,
  ],
};
const harmonyNights = <String, List<int>>{
  'blue': [
    0xFFADC4FF,
    0xFFD1BEF2,
    0xFFF3C99B,
    0xFFA5DACE,
    0xFFF0BCD0,
    0xFFA9C9EF,
  ],
  'teal': [
    0xFFA2D7CB,
    0xFFC7BBDD,
    0xFFF2C29D,
    0xFFBAD7B4,
    0xFFE2B9C4,
    0xFFAACBEF,
  ],
  'violet': [
    0xFFC9BCED,
    0xFFD7BCE9,
    0xFFE4CA91,
    0xFFADD6C6,
    0xFFE6B9CD,
    0xFFBCCCF0,
  ],
};

extension ToneColors on UiTone {
  Color ink(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return Color(
        harmonyNights[DayPanelStyle.of(context).appearance.palette]![index],
      );
    }
    return Color(
      harmonyInks[DayPanelStyle.of(context).appearance.palette]![index],
    );
  }

  Color wash(BuildContext context) {
    final palette = DayPanelStyle.of(context).appearance.palette;
    if (Theme.of(context).brightness == Brightness.dark) {
      return Color.alphaBlend(
        ink(context).withValues(alpha: .12),
        Theme.of(context).colorScheme.surfaceContainerLowest,
      );
    }
    return Color(harmonyWashes[palette]![index]);
  }
}

ThemeData dayPanelTheme(
  Brightness brightness, {
  Appearance appearance = const Appearance(),
}) {
  final palette = appearance.palette;
  final accent = Color(harmonyInks[palette]![0]);
  final pale = Color(harmonyWashes[palette]![0]);
  final family = appearance.font == 'serif' ? 'NotoSerifSC' : null;
  final dark = brightness == Brightness.dark;
  final base = Color(
    dark
        ? switch (palette) {
            'teal' => 0xFF172320,
            'violet' => 0xFF211E2B,
            _ => 0xFF192231,
          }
        : switch (palette) {
            'teal' => 0xFFF4F7F5,
            'violet' => 0xFFF8F6FA,
            _ => 0xFFF7F8FC,
          },
  );
  final paper = Color(
    dark
        ? switch (palette) {
            'teal' => 0xFF24322D,
            'violet' => 0xFF302A3B,
            _ => 0xFF273244,
          }
        : 0xFFFFFFFF,
  );
  final actionStart = accent;
  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
      .copyWith(
        surface: base,
        surfaceContainerLowest: paper,
        surfaceContainerLow: Color.lerp(base, paper, .45),
        surfaceContainer: Color.lerp(base, paper, .65),
        surfaceContainerHigh: dark
            ? const Color(0xFF384251)
            : const Color(0xFFEDF0F5),
        onSurface: dark ? const Color(0xFFEDF1F7) : const Color(0xFF26324A),
        onSurfaceVariant: dark
            ? const Color(0xFFB8C4D4)
            : const Color(0xFF647188),
        primary: dark ? Color(harmonyNights[palette]![0]) : accent,
        onPrimary: dark ? const Color(0xFF162542) : Colors.white,
        primaryContainer: dark
            ? Color.alphaBlend(
                Color(harmonyNights[palette]![0]).withValues(alpha: .12),
                paper,
              )
            : pale,
        secondary: dark
            ? Color(harmonyNights[palette]![1])
            : Color(harmonyInks[palette]![1]),
        secondaryContainer: dark
            ? const Color(0xFF383247)
            : Color(harmonyWashes[palette]![1]),
        tertiary: dark
            ? Color(harmonyNights[palette]![2])
            : Color(harmonyInks[palette]![2]),
        tertiaryContainer: dark
            ? const Color(0xFF443B30)
            : Color(harmonyWashes[palette]![2]),
        outlineVariant: dark
            ? const Color(0xFF424B59)
            : const Color(0xFFE1E6ED),
      );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));
  return ThemeData(
    useMaterial3: true,
    fontFamily: family,
    extensions: [
      DayPanelStyle(
        appearance: appearance,
        actionStart: actionStart,
        actionEnd: accent,
      ),
    ],
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      systemOverlayStyle:
          (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: family,
        color: scheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        letterSpacing: -0.7,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        letterSpacing: -0.4,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: scheme.onSurface),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: scheme.onSurface),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.45,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ).apply(fontFamily: family),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
        fontWeight: FontWeight.w400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      elevation: 4,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      headerBackgroundColor: scheme.primaryContainer,
      headerForegroundColor: scheme.onSurface,
      headerHeadlineStyle: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      dayStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      weekdayStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
      dayShape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: scheme.outlineVariant,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      shape: shape,
      hourMinuteShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      hourMinuteColor: scheme.primaryContainer,
      hourMinuteTextColor: scheme.primary,
      dialBackgroundColor: scheme.primaryContainer,
      dialHandColor: scheme.primary,
      dayPeriodShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      helpTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.7),
      thickness: 1,
      space: 1,
    ),
  );
}

const habitIcons = [
  Icons.wb_sunny_outlined,
  Icons.water_drop_outlined,
  Icons.menu_book_rounded,
  Icons.directions_walk_rounded,
  Icons.favorite_border_rounded,
  Icons.nights_stay_outlined,
  Icons.fitness_center_rounded,
  Icons.self_improvement_rounded,
  Icons.directions_run_rounded,
  Icons.pedal_bike_rounded,
  Icons.restaurant_outlined,
  Icons.local_florist_outlined,
  Icons.music_note_outlined,
  Icons.brush_outlined,
  Icons.edit_outlined,
  Icons.language_rounded,
  Icons.savings_outlined,
  Icons.cleaning_services_outlined,
  Icons.pets_outlined,
  Icons.coffee_outlined,
  Icons.medication_outlined,
  Icons.bedtime_outlined,
  Icons.phone_disabled_outlined,
  Icons.volunteer_activism_outlined,
];
UiTone habitTone(int icon, [String color = 'auto']) => switch (color) {
  'blue' => UiTone.sky,
  'violet' => UiTone.violet,
  'peach' => UiTone.peach,
  'teal' => UiTone.teal,
  'rose' => UiTone.rose,
  _ => switch (icon) {
    0 || 10 || 16 || 18 => UiTone.peach,
    2 || 4 || 13 || 19 || 23 => UiTone.rose,
    5 || 7 || 12 || 21 => UiTone.violet,
    3 || 9 || 11 || 17 || 20 => UiTone.teal,
    _ => UiTone.sky,
  },
};

class AppCanvas extends StatelessWidget {
  const AppCanvas({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.surface,
          Color.lerp(
            Theme.of(context).colorScheme.surface,
            UiTone.violet.wash(context),
            .14,
          )!,
          Theme.of(context).colorScheme.surface,
        ],
      ),
    ),
    child: child,
  );
}

class SoftPanel extends StatelessWidget {
  const SoftPanel({
    super.key,
    required this.child,
    this.tinted = false,
    this.tone = UiTone.blue,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
  });
  final Widget child;
  final bool tinted;
  final UiTone tone;
  final EdgeInsets padding;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surface.withValues(alpha: dark ? 0.95 : 0.98),
            tinted ? Color.lerp(surface, tone.wash(context), .65)! : surface,
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: .55),
        ),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : const Color(0xFF425E9A)).withValues(
              alpha: dark ? 0.12 : 0.045,
            ),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
