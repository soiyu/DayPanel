import 'package:flutter/material.dart';

ThemeData dayPanelTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF0D50D5),
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFFB5C4FF) : const Color(0xFF0D50D5),
        onPrimary: dark ? const Color(0xFF00174C) : Colors.white,
        primaryContainer: dark
            ? const Color(0xFF25396E)
            : const Color(0xFFDBE1FF),
        surface: dark ? const Color(0xFF171C2A) : const Color(0xFFF5F8FC),
        onSurface: dark ? const Color(0xFFF1F3FF) : const Color(0xFF191F33),
        secondaryContainer: dark
            ? const Color(0xFF36304C)
            : const Color(0xFFEDE9FF),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF222939) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF1D2434) : Colors.white,
      indicatorColor: scheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
];

class SoftPanel extends StatelessWidget {
  const SoftPanel({
    super.key,
    required this.child,
    this.tinted = false,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final bool tinted;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final dark = s.brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tinted
            ? s.secondaryContainer.withValues(alpha: dark ? 0.6 : 0.55)
            : (dark ? const Color(0xFF222939) : Colors.white),
        borderRadius: BorderRadius.circular(tinted ? 28 : 20),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        ),
        boxShadow: [
          if (!dark)
            BoxShadow(
              color: const Color(0xFF486895).withValues(alpha: 0.035),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: child,
    );
  }
}
