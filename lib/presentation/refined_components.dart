import 'package:flutter/material.dart';
import 'components.dart';
import 'theme.dart';

/// Choice surfaces are visually quieter than actions that commit data.
class ChoiceSurface extends StatelessWidget {
  const ChoiceSurface({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.visual,
    this.subtitle,
    this.tone = UiTone.blue,
  });
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? visual;
  final UiTone tone;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: Material(
        color: selected ? tone.wash(context) : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? tone.ink(context)
                : scheme.outlineVariant.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? .35
                        : .65,
                  ),
            width: selected ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (visual != null) ...[visual!, const SizedBox(height: 12)],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: selected
                              ? tone.ink(context)
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 18,
                      color: selected ? tone.ink(context) : scheme.outline,
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResponsiveChoices extends StatelessWidget {
  const ResponsiveChoices({
    super.key,
    required this.children,
    this.minWidth = 130,
    this.maxColumns = 3,
  });
  final List<Widget> children;
  final double minWidth;
  final int maxColumns;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final columns =
          ((c.maxWidth + 10) / (minWidth * (scale > 1.3 ? 1.2 : 1) + 10))
              .floor()
              .clamp(1, maxColumns);
      final width = (c.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class QuietChoice extends StatelessWidget {
  const QuietChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.tone = UiTone.blue,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final UiTone tone;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: onTap != null,
    child: Material(
      color: selected ? tone.wash(context) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected
              ? tone.ink(context).withValues(alpha: .55)
              : Theme.of(context).colorScheme.outlineVariant.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? .4
                      : .8,
                ),
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null || selected) ...[
                  Icon(
                    icon ?? Icons.check_rounded,
                    size: 19,
                    color: tone.ink(context),
                  ),
                  const SizedBox(width: 7),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? tone.ink(context)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class DetailDisclosure extends StatelessWidget {
  const DetailDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon = Icons.info_outline_rounded,
    this.initiallyExpanded = false,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final IconData icon;
  final bool initiallyExpanded;
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      key: PageStorageKey('disclosure-$title'),
      initiallyExpanded: initiallyExpanded,
      tilePadding: const EdgeInsets.symmetric(horizontal: 2),
      childrenPadding: const EdgeInsets.fromLTRB(2, 0, 2, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      leading: Icon(
        icon,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
      children: [child],
    ),
  );
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.tone = UiTone.blue,
    this.emphasized = false,
    this.trailing,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final UiTone tone;
  final bool emphasized;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: Material(
      color: emphasized
          ? tone.wash(context)
          : Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: emphasized
              ? tone.ink(context).withValues(alpha: .16)
              : Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: .6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToneIcon(icon, tone: tone, size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child:
                    trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EditorFooter extends StatelessWidget {
  const EditorFooter({super.key, required this.children, this.summary});
  final List<Widget> children;
  final String? summary;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        top: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: .65),
        ),
      ),
    ),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (summary != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                summary!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(children: children),
        ],
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.title, {
    super.key,
    this.description,
    this.trailing,
  });
  final String title;
  final String? description;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ?trailing,
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 5),
          Text(description!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}
