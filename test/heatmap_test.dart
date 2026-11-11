import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/heatmap.dart';
import 'package:daypanel/presentation/theme.dart';

void main() {
  Widget buildApp(Widget child) => MaterialApp(
    theme: dayPanelTheme(Brightness.light),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  testWidgets('ActivityHeatmap renders 52 weeks grid and responds to taps', (
    tester,
  ) async {
    final today = Day(DateTime(2026, 11, 11));
    Day? tapped;

    await tester.pumpWidget(
      buildApp(
        ActivityHeatmap(
          today: today,
          title: '年度自律热力图',
          subtitle: '过去 365 天点阵',
          tone: UiTone.teal,
          levelForDay: (d) => d == today ? 3 : (d.date.day % 4),
          detailForDay: (d) => '${d.date.day} 完成',
          onDayTap: (d) => tapped = d,
        ),
      ),
    );

    expect(find.text('年度自律热力图'), findsOneWidget);
    expect(find.text('过去 365 天点阵'), findsOneWidget);
    expect(find.byType(ActivityHeatmap), findsOneWidget);

    // Initial selected day is today
    expect(find.textContaining('2026'), findsWidgets);
    expect(find.textContaining('全部完成'), findsOneWidget);

    // Tap on the heatmap custom painter
    final gesture = find.byType(GestureDetector);
    expect(gesture, findsOneWidget);
    await tester.tap(gesture);
    await tester.pumpAndSettle();

    expect(tapped, isNotNull);
  });
}
