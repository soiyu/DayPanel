import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daypanel/application/app_controller.dart';
import 'package:daypanel/data/app_store.dart';
import 'package:daypanel/data/note_media_platform.dart';
import 'package:daypanel/domain/models.dart';
import 'package:daypanel/l10n/app_localizations.dart';
import 'package:daypanel/presentation/editors.dart';
import 'package:daypanel/presentation/theme.dart';
import 'package:daypanel/presentation/journal.dart';
import 'package:daypanel/presentation/note_format.dart';
import 'package:daypanel/presentation/note_images.dart';
import 'package:daypanel/presentation/plus_page.dart';

void main() {
  sqfliteFfiInit();
  late AppStore store;
  late AppController app;
  late MemoryNoteMediaPlatform media;

  setUp(() async {
    store = await AppStore.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    media = MemoryNoteMediaPlatform();
    app = AppController(
      store,
      clock: () => DateTime(2026, 11, 15),
      noteMediaPlatform: media,
    );
    await app.load();
  });

  tearDown(() async {
    app.dispose();
    await store.close();
  });

  Widget shell(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    theme: dayPanelTheme(Brightness.light),
    home: Scaffold(body: child),
  );

  testWidgets(
    'formatting toolbar wraps selection and inserts markdown prefixes',
    (tester) async {
      await tester.pumpWidget(shell(EntryEditor(app: app, type: 'note')));
      await tester.pumpAndSettle();

      // Verify format buttons exist
      expect(find.byIcon(Icons.format_bold_rounded), findsOneWidget);
      expect(find.byIcon(Icons.title_rounded), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget);
      expect(find.byIcon(Icons.format_quote_rounded), findsOneWidget);
      expect(find.byIcon(Icons.border_color_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsWidgets);

      // Enter text and test Bold
      final textField = find.byKey(const Key('entry-title'));
      await tester.enterText(textField, '今日思考');
      await tester.pump();

      // Tap bold button
      await tester.tap(find.byIcon(Icons.format_bold_rounded));
      await tester.pump();
      expect(find.textContaining('**'), findsOneWidget);

      // Tap heading button
      await tester.tap(find.byIcon(Icons.title_rounded));
      await tester.pump();
      expect(find.textContaining('## '), findsOneWidget);
    },
  );

  testWidgets('free tier allows 1 photo and gates second photo with PlusPage', (
    tester,
  ) async {
    // Force free mode
    app.plus.testing = false;
    app.plus.owned = false;

    await tester.pumpWidget(shell(EntryEditor(app: app, type: 'note')));
    await tester.pumpAndSettle();

    // Tap add photo button
    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined).first);
    await tester.pumpAndSettle();

    // First photo attaches
    expect(find.textContaining('(1/9)'), findsOneWidget);

    // Free user attempts to add 2nd photo -> triggers PlusPage
    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // PlusPage is pushed
    expect(find.byType(PlusPage), findsOneWidget);
    expect(find.text('✦ DayPanel Plus 终身会员'), findsNothing); // still free
  });

  testWidgets(
    'Plus tier allows up to 9 photos in note editor and saves cleanly',
    (tester) async {
      // Enable Plus
      app.plus.testing = true;

      await tester.pumpWidget(shell(EntryEditor(app: app, type: 'note')));
      await tester.pumpAndSettle();

      final textField = find.byKey(const Key('entry-title'));
      await tester.enterText(textField, '## 露营手记\n今天拍了很多照片');
      await tester.pump();

      // Add 3 photos
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined).first);
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('(3/9)'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Verify note is saved in store with 3 images
      final notes = await store.notes();
      expect(notes.length, 1);
      expect(notes.single.images.length, 3);
      expect(notes.single.body, '## 露营手记\n今天拍了很多照片');
    },
  );

  testWidgets('NoteCard renders NoteFormattedText and NoteImageGrid', (
    tester,
  ) async {
    final note = Note(
      id: 'card-test',
      body: '## 标题文字\n> 一句名言\n**重要事项**\n- 第一项',
      day: app.today,
      images: const ['test1.jpg', 'test2.jpg', 'test3.jpg'],
    );
    await store.saveNote(note, create: true, today: app.today);
    await app.load();

    await tester.pumpWidget(
      shell(
        SingleChildScrollView(
          child: NoteCard(app: app, note: note),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify rich text elements rendered
    expect(find.byType(NoteFormattedText), findsOneWidget);
    expect(find.text('标题文字'), findsOneWidget);
    expect(find.text('一句名言'), findsOneWidget);
    expect(find.text('重要事项'), findsOneWidget);
    expect(find.text('第一项'), findsOneWidget);

    // Verify image grid rendered with 3 items
    expect(find.byType(NoteImageGrid), findsOneWidget);
  });
}
