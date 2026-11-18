import 'dart:io';
import 'package:flutter/material.dart';
import '../application/app_controller.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

class NoteImageViewerPage extends StatefulWidget {
  const NoteImageViewerPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.app,
  });

  final List<String> images;
  final int initialIndex;
  final AppController app;

  @override
  State<NoteImageViewerPage> createState() => _NoteImageViewerPageState();
}

class _NoteImageViewerPageState extends State<NoteImageViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final fileName = widget.images[index];
          return FutureBuilder<String?>(
            future: widget.app.noteMediaPlatform?.getImagePath(fileName),
            builder: (context, snapshot) {
              final path = snapshot.data;
              if (path == null) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                );
              }
              final file = File(path);
              if (!file.existsSync()) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                );
              }
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(child: Image.file(file, fit: BoxFit.contain)),
              );
            },
          );
        },
      ),
    );
  }
}

class NoteImageGrid extends StatelessWidget {
  const NoteImageGrid({super.key, required this.images, required this.app});

  final List<String> images;
  final AppController app;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _NoteImageItem(
              fileName: images[0],
              app: app,
              onTap: () => _openViewer(context, 0),
            ),
          ),
        ),
      );
    }

    final count = images.length;
    final crossAxisCount = (count == 2 || count == 4) ? 2 : 3;
    final spacing = (count == 2 || count == 4) ? 6.0 : 4.0;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _NoteImageItem(
              fileName: images[index],
              app: app,
              onTap: () => _openViewer(context, index),
            ),
          );
        },
      ),
    );
  }

  void _openViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => NoteImageViewerPage(
          images: images,
          initialIndex: initialIndex,
          app: app,
        ),
      ),
    );
  }
}

class _NoteImageItem extends StatelessWidget {
  const _NoteImageItem({
    required this.fileName,
    required this.app,
    required this.onTap,
  });

  final String fileName;
  final AppController app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: app.noteMediaPlatform?.getImagePath(fileName),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) {
          return Container(
            color: Colors.black12,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final file = File(path);
        if (!file.existsSync()) {
          return Container(
            color: Colors.black12,
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 28,
                color: Colors.grey,
              ),
            ),
          );
        }
        return InkWell(
          onTap: onTap,
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        );
      },
    );
  }
}

class NoteImagePickerSection extends StatelessWidget {
  const NoteImagePickerSection({
    super.key,
    required this.images,
    required this.app,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> images;
  final AppController app;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isZh
                    ? '手记配图 (${images.length}/9)'
                    : '${s.noteImages} (${images.length}/9)',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (!app.plus.enabled && images.isNotEmpty)
              Text(
                isZh ? '✦ Plus 可选 9 张' : '✦ Plus: 9 photos',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: UiTone.violet.ink(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < images.length; i++)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: _NoteImageItem(
                        fileName: images[i],
                        app: app,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => NoteImageViewerPage(
                                images: images,
                                initialIndex: i,
                                app: app,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (images.length < 9)
              InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: UiTone.violet.ink(context),
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isZh ? '添加' : 'Add',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: UiTone.violet.ink(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
