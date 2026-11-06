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

extension ToneColors on UiTone {
  Color ink(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (this) {
      UiTone.blue => Theme.of(context).colorScheme.primary,
      UiTone.sky => dark ? const Color(0xFFAFC5FF) : const Color(0xFF1656DF),
      UiTone.teal => dark ? const Color(0xFF9DDACD) : const Color(0xFF146A5B),
      UiTone.rose => dark ? const Color(0xFFF5B8CF) : const Color(0xFF9D365D),
      UiTone.violet => dark ? const Color(0xFFD1BEFF) : const Color(0xFF7252BE),
      UiTone.peach => dark ? const Color(0xFFFFC395) : const Color(0xFFA95824),
    };
  }

  Color wash(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (this) {
      UiTone.blue => Theme.of(context).colorScheme.primaryContainer,
      UiTone.sky => dark ? const Color(0xFF263957) : const Color(0xFFEAF0FF),
      UiTone.teal => dark ? const Color(0xFF203D38) : const Color(0xFFE5F4F0),
      UiTone.rose => dark ? const Color(0xFF452A38) : const Color(0xFFFFEAF1),
      UiTone.violet => dark ? const Color(0xFF36304C) : const Color(0xFFF0EBFF),
      UiTone.peach => dark ? const Color(0xFF48352D) : const Color(0xFFFFEEE1),
    };
  }
}

ThemeData dayPanelTheme(
  Brightness brightness, {
  Appearance appearance = const Appearance(),
}) {
  final palette = appearance.palette;
  final accent = Color(switch (palette) {
    'teal' => 0xFF146A5B,
    'violet' => 0xFF6843AB,
    _ => 0xFF1656DF,
  });
  final pale = Color(switch (palette) {
    'teal' => 0xFFE5F4F0,
    'violet' => 0xFFF0EBFF,
    _ => 0xFFEAF0FF,
  });
  final night = Color(switch (palette) {
    'teal' => 0xFF203D38,
    'violet' => 0xFF36304C,
    _ => 0xFF263957,
  });
  final lightInk = Color(switch (palette) {
    'teal' => 0xFF9DDACD,
    'violet' => 0xFFD1BEFF,
    _ => 0xFFAFC5FF,
  });
  final family = appearance.font == 'serif' ? 'NotoSerifSC' : null;
  final actionStart = Color(switch (palette) {
    'teal' => 0xFF167564,
    'violet' => 0xFF7953B7,
    _ => 0xFF2864D4,
  });
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
      .copyWith(
        surface: dark ? const Color(0xFF151C2B) : const Color(0xFFF6F8FE),
        onSurface: dark ? const Color(0xFFEEF2FF) : const Color(0xFF18223B),
        onSurfaceVariant: dark
            ? const Color(0xFFB3BFD6)
            : const Color(0xFF637089),
        primary: dark ? lightInk : accent,
        onPrimary: dark ? const Color(0xFF10234A) : Colors.white,
        primaryContainer: dark ? night : pale,
        secondaryContainer: dark
            ? const Color(0xFF36304C)
            : const Color(0xFFF0EBFF),
        outlineVariant: dark
            ? const Color(0xFF354157)
            : const Color(0xFFE1E7F2),
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
      fillColor: dark ? const Color(0xFF171F30) : const Color(0xFFF3F6FC),
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
      backgroundColor: dark ? const Color(0xFF222B3D) : const Color(0xFFFBFCFF),
      surfaceTintColor: Colors.transparent,
      shape: shape,
      elevation: 4,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: dark ? const Color(0xFF222B3D) : const Color(0xFFFBFCFF),
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
      backgroundColor: dark ? const Color(0xFF222B3D) : const Color(0xFFFBFCFF),
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
  _ => switch (icon % 6) {
    0 || 3 => UiTone.peach,
    2 || 5 => UiTone.violet,
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
            Theme.of(context).colorScheme.primaryContainer,
            .34,
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
    final surface = dark ? const Color(0xFF232C3F) : Colors.white;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surface.withValues(alpha: dark ? 0.95 : 0.98),
            tinted ? tone.wash(context) : surface.withValues(alpha: 0.83),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.95),
        ),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : const Color(0xFF425E9A)).withValues(
              alpha: dark ? 0.12 : 0.045,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
