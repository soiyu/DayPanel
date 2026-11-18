import 'package:flutter/material.dart';

/// Text editing helpers for formatting toolbar.
class NoteFormatHelper {
  /// Wraps current selection in [prefix] and [suffix], or inserts template.
  static void wrapSelection(
    TextEditingController controller,
    String prefix,
    String suffix, {
    String placeholder = '',
  }) {
    final text = controller.text;
    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) {
      final insertPos = selection.isValid ? selection.start : text.length;
      final newText = text.replaceRange(
        insertPos,
        insertPos,
        '$prefix$placeholder$suffix',
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: insertPos + prefix.length,
          extentOffset: insertPos + prefix.length + placeholder.length,
        ),
      );
    } else {
      final selected = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selected$suffix',
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start + prefix.length,
          extentOffset: selection.start + prefix.length + selected.length,
        ),
      );
    }
  }

  /// Toggles line prefix (like '## ', '- ', '> ') on the current line.
  static void toggleLinePrefix(
    TextEditingController controller,
    String prefix,
  ) {
    final text = controller.text;
    final selection = controller.selection;
    final cursor = selection.isValid ? selection.start : text.length;

    // Find current line start
    final lineStart = text.lastIndexOf('\n', cursor > 0 ? cursor - 1 : 0);
    final actualStart = lineStart == -1 ? 0 : lineStart + 1;

    // Check if the line already starts with prefix
    if (text.substring(actualStart).startsWith(prefix)) {
      // Remove prefix
      final newText = text.replaceRange(
        actualStart,
        actualStart + prefix.length,
        '',
      );
      final newCursor = (cursor - prefix.length).clamp(
        actualStart,
        newText.length,
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
    } else {
      // Add prefix
      final newText = text.replaceRange(actualStart, actualStart, prefix);
      final newCursor = cursor + prefix.length;
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
    }
  }
}

/// Parses inline text into TextSpans supporting **bold**, ==highlight==, and ~~strikethrough~~.
List<InlineSpan> parseInlineSpans({
  required String text,
  required TextStyle baseStyle,
  required Color highlightColor,
  required Color highlightTextColor,
}) {
  final spans = <InlineSpan>[];
  final regex = RegExp(r'(\*\*(.+?)\*\*)|(==(.+?)==)|(~~(.+?)~~)|(\*(.+?)\*)');

  int lastIndex = 0;
  for (final match in regex.allMatches(text)) {
    if (match.start > lastIndex) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ),
      );
    }

    final boldMatch = match.group(2);
    final highlightMatch = match.group(4);
    final strikeMatch = match.group(6);
    final italicMatch = match.group(8);

    if (boldMatch != null) {
      spans.add(
        TextSpan(
          text: boldMatch,
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ),
      );
    } else if (highlightMatch != null) {
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: highlightColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              highlightMatch,
              style: baseStyle.copyWith(
                color: highlightTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    } else if (strikeMatch != null) {
      spans.add(
        TextSpan(
          text: strikeMatch,
          style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
        ),
      );
    } else if (italicMatch != null) {
      spans.add(
        TextSpan(
          text: italicMatch,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }

    lastIndex = match.end;
  }

  if (lastIndex < text.length) {
    spans.add(TextSpan(text: text.substring(lastIndex), style: baseStyle));
  }

  return spans;
}

/// Formatted view for a note body, supporting headings, quotes, bullets, and inline formatting.
class NoteFormattedText extends StatelessWidget {
  const NoteFormattedText({
    super.key,
    required this.text,
    this.maxLines,
    this.style,
  });

  final String text;
  final int? maxLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseStyle = style ?? theme.textTheme.bodyMedium ?? const TextStyle();

    final highlightBg = isDark
        ? const Color(0xFF713F12).withValues(alpha: 0.8)
        : const Color(0xFFFEF08A);
    final highlightText = isDark
        ? const Color(0xFFFEF08A)
        : const Color(0xFF713F12);

    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        if (i < lines.length - 1) {
          widgets.add(const SizedBox(height: 6));
        }
        continue;
      }

      if (line.startsWith('## ') || line.startsWith('### ')) {
        final headingText = line.replaceFirst(RegExp(r'^#{2,3}\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text.rich(
              TextSpan(
                children: parseInlineSpans(
                  text: headingText,
                  baseStyle: theme.textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  highlightColor: highlightBg,
                  highlightTextColor: highlightText,
                ),
              ),
            ),
          ),
        );
      } else if (line.startsWith('> ')) {
        final quoteText = line.substring(2);
        widgets.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  width: 3,
                ),
              ),
            ),
            child: Text.rich(
              TextSpan(
                children: parseInlineSpans(
                  text: quoteText,
                  baseStyle: baseStyle.copyWith(
                    fontStyle: FontStyle.italic,
                    color: baseStyle.color?.withValues(alpha: 0.85),
                  ),
                  highlightColor: highlightBg,
                  highlightTextColor: highlightText,
                ),
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        final bulletText = line.substring(2);
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: baseStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: parseInlineSpans(
                        text: bulletText,
                        baseStyle: baseStyle,
                        highlightColor: highlightBg,
                        highlightTextColor: highlightText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text.rich(
              TextSpan(
                children: parseInlineSpans(
                  text: line,
                  baseStyle: baseStyle,
                  highlightColor: highlightBg,
                  highlightTextColor: highlightText,
                ),
              ),
            ),
          ),
        );
      }
    }

    if (widgets.isEmpty) {
      return Text(text, style: baseStyle);
    }

    if (maxLines != null) {
      // In constrained preview mode (like NoteCard), wrap in limited height or Column
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: widgets.take(maxLines!).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}
