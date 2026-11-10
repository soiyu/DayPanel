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
    0xFF1D4ED8,
    0xFF6D28D9,
    0xFFC2410C,
    0xFF047857,
    0xFFBE123C,
    0xFF0369A1,
  ],
  'teal': [
    0xFF0F766E,
    0xFF6D28D9,
    0xFFB45309,
    0xFF047857,
    0xFFBE185D,
    0xFF0369A1,
  ],
  'violet': [
    0xFF6D28D9,
    0xFF7E22CE,
    0xFFB45309,
    0xFF047857,
    0xFFBE123C,
    0xFF1D4ED8,
  ],
};
const harmonyWashes = <String, List<int>>{
  'blue': [
    0xFFEFF6FF,
    0xFFF5F3FF,
    0xFFFFF7ED,
    0xFFECFDF5,
    0xFFFFF1F2,
    0xFFF0F9FF,
  ],
  'teal': [
    0xFFF0FDFA,
    0xFFF5F3FF,
    0xFFFEF3C7,
    0xFFECFDF5,
    0xFFFCE7F3,
    0xFFE0F2FE,
  ],
  'violet': [
    0xFFF5F3FF,
    0xFFFAF5FF,
    0xFFFEF3C7,
    0xFFECFDF5,
    0xFFFFE4E6,
    0xFFEFF6FF,
  ],
};
const harmonyNights = <String, List<int>>{
  'blue': [
    0xFF93C5FD,
    0xFFC4B5FD,
    0xFFFDBA74,
    0xFF6EE7B7,
    0xFFFDA4AF,
    0xFF7DD3FC,
  ],
  'teal': [
    0xFF5EEAD4,
    0xFFC4B5FD,
    0xFFFCD34D,
    0xFF6EE7B7,
    0xFFF472B6,
    0xFF38BDF8,
  ],
  'violet': [
    0xFFC4B5FD,
    0xFFE9D5FF,
    0xFFFBBF24,
    0xFF6EE7B7,
    0xFFFB7185,
    0xFF60A5FA,
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
            'teal' => 0xFF081512,
            'violet' => 0xFF0F0B18,
            _ => 0xFF0A0F1D,
          }
        : switch (palette) {
            'teal' => 0xFFF2F9F6,
            'violet' => 0xFFFAF8FD,
            _ => 0xFFF8FAFC,
          },
  );
  final paper = Color(
    dark
        ? switch (palette) {
            'teal' => 0xFF122620,
            'violet' => 0xFF1D162C,
            _ => 0xFF161F30,
          }
        : 0xFFFFFFFF,
  );
  final actionStart = Color(switch (palette) {
    'teal' => 0xFF0D7E73,
    'violet' => 0xFF7C3AED,
    _ => 0xFF2563EB,
  });
  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
      .copyWith(
        surface: base,
        surfaceContainerLowest: paper,
        surfaceContainerLow: Color.lerp(base, paper, .45),
        surfaceContainer: Color.lerp(base, paper, .65),
        surfaceContainerHigh: dark
            ? Color.lerp(paper, Colors.white, .08)
            : const Color(0xFFF1F5F9),
        onSurface: dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
        onSurfaceVariant: dark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF64748B),
        primary: dark ? Color(harmonyNights[palette]![0]) : accent,
        onPrimary: dark
            ? switch (palette) {
                'teal' => const Color(0xFF042F2C),
                'violet' => const Color(0xFF240E47),
                _ => const Color(0xFF08224E),
              }
            : Colors.white,
        primaryContainer: dark
            ? Color.alphaBlend(
                Color(harmonyNights[palette]![0]).withValues(alpha: .14),
                paper,
              )
            : pale,
        secondary: dark
            ? Color(harmonyNights[palette]![1])
            : Color(harmonyInks[palette]![1]),
        secondaryContainer: dark
            ? Color.alphaBlend(
                Color(harmonyNights[palette]![1]).withValues(alpha: .14),
                paper,
              )
            : Color(harmonyWashes[palette]![1]),
        tertiary: dark
            ? Color(harmonyNights[palette]![2])
            : Color(harmonyInks[palette]![2]),
        tertiaryContainer: dark
            ? Color.alphaBlend(
                Color(harmonyNights[palette]![2]).withValues(alpha: .14),
                paper,
              )
            : Color(harmonyWashes[palette]![2]),
        outlineVariant: dark
            ? const Color(0xFF2A3649)
            : const Color(0xFFE2E8F0),
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
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final wash = Theme.of(context).colorScheme.primaryContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surface,
            dark
                ? Color.lerp(surface, wash, .10)!
                : Color.lerp(surface, wash, .28)!,
            surface,
          ],
        ),
      ),
      child: child,
    );
  }
}

class SoftPanel extends StatelessWidget {
  const SoftPanel({
    super.key,
    required this.child,
    this.tinted = false,
    this.tone = UiTone.blue,
    this.padding = const EdgeInsets.all(20),
    this.radius = 22,
  });
  final Widget child;
  final bool tinted;
  final UiTone tone;
  final EdgeInsets padding;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final surface = scheme.surfaceContainerLowest;
    final shadowColor = dark
        ? Colors.black.withValues(alpha: .28)
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: .04),
            const Color(0xFF1E293B),
          ).withValues(alpha: .045);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surface.withValues(alpha: dark ? 0.96 : 0.98),
            tinted ? Color.lerp(surface, tone.wash(context), .45)! : surface,
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? .35 : .6),
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
