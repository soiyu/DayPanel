import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../application/app_controller.dart';
import '../data/card_image.dart';
import '../domain/achievement.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'card_art.dart';
import 'components.dart';
import 'refined_components.dart';
import 'theme.dart';

class CardSharePage extends StatefulWidget {
  const CardSharePage({
    super.key,
    required this.app,
    required this.day,
    required this.title,
    this.files,
  });
  final AppController app;
  final Day day;
  final String title;
  final CardImageFiles? files;
  @override
  State<CardSharePage> createState() => _CardSharePageState();
}

class _CardSharePageState extends State<CardSharePage> {
  final boundary = GlobalKey();
  late final int epoch;
  late final AchievementCard? card;
  late final TextEditingController excerpt;
  bool names = false, reflection = false, working = false;
  String? message;
  @override
  void initState() {
    super.initState();
    epoch = widget.app.generation;
    card = widget.app.cardFor(widget.day);
    excerpt = TextEditingController(
      text: card?.reflection.characters.take(280).toString() ?? '',
    );
  }

  @override
  void dispose() {
    excerpt.dispose();
    super.dispose();
  }

  Future<void> output(bool share) async {
    if (working || card == null) return;
    final s = AppLocalizations.of(context);
    setState(() {
      working = true;
      message = null;
    });
    try {
      if (epoch != widget.app.generation ||
          await widget.app.store.generation() != epoch ||
          widget.app.cardFor(widget.day) == null) {
        if (mounted) setState(() => message = s.cardShareStale);
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      if (boundary.currentContext != null) {
        await Scrollable.ensureVisible(
          boundary.currentContext!,
          alignment: 0,
          duration: Duration.zero,
        );
      }
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final render =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // Keep long, enlarged-text posters within Android's image bounds.
      final ratio = math.min(
        3.0,
        math.min(4096 / render.size.width, 16000 / render.size.height),
      );
      final image = await render.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('Image unavailable');
      if (await widget.app.store.generation() != epoch) {
        throw StateError('Stale image');
      }
      final files = widget.files ?? AndroidCardImageFiles();
      final bytes = data.buffer.asUint8List();
      final name = 'DayPanel-${widget.day.key}.png';
      if (share) {
        await files.share(bytes, name);
      } else {
        final saved = await files.save(bytes, name);
        if (saved && mounted) setState(() => message = s.cardImageSaved);
      }
    } catch (_) {
      if (mounted) setState(() => message = s.cardImageFailed);
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return PopScope(
      canPop: !working,
      child: AppCanvas(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(s.cardShare)),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          key: const Key('share-names'),
                          title: Text(s.cardShareNames),
                          value: names,
                          onChanged: working
                              ? null
                              : (v) => setState(() => names = v),
                        ),
                        SwitchListTile(
                          key: const Key('share-reflection'),
                          title: Text(s.cardShareReflection),
                          value: reflection,
                          onChanged: working
                              ? null
                              : (v) => setState(() => reflection = v),
                        ),
                        if (reflection)
                          TextField(
                            key: const Key('share-excerpt'),
                            controller: excerpt,
                            maxLength: 280,
                            minLines: 2,
                            maxLines: 6,
                            decoration: InputDecoration(
                              labelText: s.cardShareExcerpt,
                            ),
                            enabled: !working,
                            onChanged: (_) => setState(() {}),
                          ),
                        const SizedBox(height: 12),
                        if (card != null)
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 380),
                              child: RepaintBoundary(
                                key: boundary,
                                child: ShareCardPoster(
                                  card: card!,
                                  title: widget.title,
                                  names: names,
                                  excerpt: reflection ? excerpt.text : null,
                                ),
                              ),
                            ),
                          )
                        else
                          EmptyState(
                            icon: Icons.image_not_supported_outlined,
                            title: s.cardShareStale,
                            body: s.cardShareHint,
                          ),
                        const SizedBox(height: 18),
                        if (message != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(message!),
                          ),
                      ],
                    ),
                  ),
                ),
                EditorFooter(
                  children: [
                    Expanded(
                      child: AppAction(
                        key: const Key('save-card-image'),
                        label: s.cardSaveImage,
                        onTap: working || card == null
                            ? null
                            : () => output(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppAction(
                        key: const Key('share-card-image'),
                        label: s.cardShareAction,
                        icon: Icons.ios_share_rounded,
                        primary: true,
                        busy: working,
                        onTap: working || card == null
                            ? null
                            : () => output(true),
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
  }
}

class ShareCardPoster extends StatelessWidget {
  const ShareCardPoster({
    super.key,
    required this.card,
    required this.title,
    required this.names,
    this.excerpt,
  });
  final AchievementCard card;
  final String title;
  final bool names;
  final String? excerpt;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF202A40) : const Color(0xFFFBFCFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 6,
              children: [
                Text('DayPanel', style: Theme.of(context).textTheme.titleSmall),
                Text(
                  card.day.key,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 18),
            CardArt(artwork: card.artwork, height: 210),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              s.cardShareCount(card.evidence.length),
              style: TextStyle(color: UiTone.violet.ink(context)),
            ),
            if (names) ...[
              const SizedBox(height: 14),
              for (final h in card.evidence.take(6))
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text('✓  ${h.title}'),
                ),
              if (card.evidence.length > 6)
                Text(
                  s.cardShareMore(card.evidence.length - 6),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
            if (excerpt != null && excerpt!.trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              Divider(color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Text(excerpt!),
            ],
          ],
        ),
      ),
    );
  }
}
