import 'dart:ui';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

class ToneIcon extends StatelessWidget {
  const ToneIcon(
    this.icon, {
    super.key,
    this.tone = UiTone.blue,
    this.size = 46,
    this.frame = 'soft',
  });
  final IconData icon;
  final UiTone tone;
  final double size;
  final String frame;
  @override
  Widget build(BuildContext context) {
    final style = frame == 'auto'
        ? (Theme.of(context).extension<DayPanelStyle>()?.appearance.frame ??
              'soft')
        : frame;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style == 'soft' ? tone.wash(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(
          style == 'ring' ? size : size * .32,
        ),
        border: style == 'plain'
            ? null
            : Border.all(
                color: tone
                    .ink(context)
                    .withValues(alpha: style == 'ring' ? .7 : .12),
                width: style == 'ring' ? 1.6 : 1,
              ),
      ),
      child: Icon(icon, size: size * .48, color: tone.ink(context)),
    );
  }
}

class AppAction extends StatelessWidget {
  const AppAction({
    super.key,
    required this.label,
    this.icon,
    this.maxLines,
    required this.onTap,
    this.primary = false,
    this.danger = false,
    this.busy = false,
    this.tone = UiTone.blue,
  });
  final String label;
  final IconData? icon;
  final int? maxLines;
  final VoidCallback? onTap;
  final bool primary, danger, busy;
  final UiTone tone;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = primary
        ? Colors.white
        : danger
        ? s.error
        : tone.ink(context);
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      child: Opacity(
        opacity: onTap == null && !busy ? .45 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (primary)
                BoxShadow(
                  color: DayPanelStyle.of(
                    context,
                  ).actionEnd.withValues(alpha: dark ? .32 : .22),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: primary
                    ? LinearGradient(
                        colors: [
                          DayPanelStyle.of(context).actionStart,
                          DayPanelStyle.of(context).actionEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: primary
                    ? null
                    : danger
                    ? s.errorContainer.withValues(alpha: .5)
                    : tone.wash(context),
                border: primary
                    ? null
                    : Border.all(
                        color: danger
                            ? s.error.withValues(alpha: .25)
                            : tone
                                  .ink(context)
                                  .withValues(alpha: dark ? .22 : .12),
                      ),
              ),
              child: InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    minWidth: 48,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (busy)
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ink,
                            ),
                          )
                        else if (icon != null)
                          Icon(icon, size: 18, color: ink),
                        if (busy || icon != null) const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: maxLines,
                            overflow: maxLines == null
                                ? null
                                : TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppIconAction extends StatelessWidget {
  const AppIconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.tone = UiTone.blue,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final UiTone tone;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (primary)
            BoxShadow(
              color: DayPanelStyle.of(
                context,
              ).actionEnd.withValues(alpha: dark ? .30 : .20),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: IconButton(
        tooltip: label,
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        style: IconButton.styleFrom(
          backgroundColor: primary
              ? DayPanelStyle.of(context).actionEnd
              : tone.wash(context),
          foregroundColor: primary ? Colors.white : tone.ink(context),
          side: primary
              ? null
              : BorderSide(
                  color: tone.ink(context).withValues(alpha: dark ? .20 : .12),
                ),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class AppBadge extends StatelessWidget {
  const AppBadge(this.text, {super.key, this.tone = UiTone.blue, this.icon});
  final String text;
  final UiTone tone;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: tone.wash(context),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: tone.ink(context)),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tone.ink(context),
            ),
          ),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.count,
    this.tone = UiTone.blue,
  });
  final String title;
  final int? count;
  final UiTone tone;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 8),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: tone.ink(context).withValues(alpha: .6),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (count != null) AppBadge('$count', tone: tone),
      ],
    ),
  );
}

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.tone = UiTone.blue,
    this.trailing,
    this.leading,
  });
  final Widget? leading;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final UiTone tone;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            leading ?? ToneIcon(icon, tone: tone, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: .6),
                ),
          ],
        ),
      ),
    ),
  );
}

class GlassNavigation extends StatelessWidget {
  const GlassNavigation({
    super.key,
    required this.index,
    required this.onSelected,
  });
  final int index;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final narrowWithLargeText =
        MediaQuery.sizeOf(context).width < 360 &&
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final labels = [s.today, s.tasks, s.notes, s.mine];
    final shadowColor = dark
        ? Colors.black.withValues(alpha: .30)
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: .06),
            const Color(0xFF0F172A),
          ).withValues(alpha: .06);
    const icons = [
      Icons.wb_sunny_outlined,
      Icons.checklist_rounded,
      Icons.auto_stories_outlined,
      Icons.person_outline_rounded,
    ];
    return RepaintBoundary(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            narrowWithLargeText ? 8 : 16,
            4,
            narrowWithLargeText ? 8 : 16,
            6,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 24,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest.withValues(
                      alpha: dark ? .88 : .92,
                    ),
                    border: Border.all(
                      color: dark
                          ? scheme.outlineVariant.withValues(alpha: .25)
                          : Colors.white.withValues(alpha: .85),
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        for (var i = 0; i < 4; i++)
                          Expanded(
                            child: Semantics(
                              selected: index == i,
                              button: true,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: Key('tab-$i'),
                                  borderRadius: BorderRadius.circular(19),
                                  onTap: () => onSelected(i),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: index == i
                                          ? [
                                              UiTone.blue,
                                              UiTone.peach,
                                              UiTone.violet,
                                              UiTone.teal,
                                            ][i].wash(context)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(19),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          icons[i],
                                          size: 20,
                                          color: index == i
                                              ? [
                                                  UiTone.blue,
                                                  UiTone.peach,
                                                  UiTone.violet,
                                                  UiTone.teal,
                                                ][i].ink(context)
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          labels[i],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: index == i
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: index == i
                                                ? [
                                                    UiTone.blue,
                                                    UiTone.peach,
                                                    UiTone.violet,
                                                    UiTone.teal,
                                                  ][i].ink(context)
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SheetFrame extends StatefulWidget {
  const SheetFrame({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.icon,
    required this.body,
    required this.footer,
    this.tone = UiTone.blue,
    this.busy = false,
  });
  final String title;
  final String? subtitle;
  final Widget? leading;
  final IconData icon;
  final Widget body, footer;
  final UiTone tone;
  final bool busy;

  @override
  State<SheetFrame> createState() => _SheetFrameState();
}

class _SheetFrameState extends State<SheetFrame> {
  double _lastBottomInset = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final route = ModalRoute.of(context);
    final isClosing = route?.animation?.status == AnimationStatus.reverse;
    final currentInset = MediaQuery.viewInsetsOf(context).bottom;
    if (!isClosing) {
      _lastBottomInset = currentInset;
    }
    final bottomInset = isClosing ? _lastBottomInset : currentInset;
    return RepaintBoundary(
      child: PopScope(
        canPop: !widget.busy,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .9 - bottomInset,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
                            child: Row(
                              children: [
                                widget.leading ??
                                    ToneIcon(widget.icon, tone: widget.tone),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      if (widget.subtitle != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.subtitle!,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: s.cancel,
                                  onPressed: widget.busy
                                      ? null
                                      : () {
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                          Navigator.pop(context);
                                        },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: widget.body,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: .6),
                        ),
                      ),
                    ),
                    child: SafeArea(top: false, child: widget.footer),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
    this.actionIcon = Icons.add,
    this.tone = UiTone.blue,
  });
  final IconData icon, actionIcon;
  final String title, body;
  final String? action;
  final VoidCallback? onAction;
  final UiTone tone;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 26),
    child: Column(
      children: [
        SizedBox(
          width: 150,
          height: 116,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -.12,
                child: Container(
                  width: 83,
                  height: 94,
                  decoration: BoxDecoration(
                    color: tone.wash(context),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              Transform.rotate(
                angle: .08,
                child: SoftPanel(
                  padding: const EdgeInsets.all(23),
                  radius: 22,
                  child: Icon(icon, size: 36, color: tone.ink(context)),
                ),
              ),
              Positioned(
                top: 6,
                right: 9,
                child: ToneIcon(
                  Icons.wb_sunny_outlined,
                  tone: UiTone.peach,
                  size: 28,
                ),
              ),
              Positioned(
                bottom: 9,
                left: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: UiTone.violet.ink(context).withValues(alpha: .35),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 20),
          AppAction(
            label: action!,
            icon: actionIcon,
            onTap: onAction,
            tone: tone,
          ),
        ],
      ],
    ),
  );
}

Future<String?> showEntryActions(BuildContext context, String title) {
  final s = AppLocalizations.of(context);
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (ctx) => SheetFrame(
      title: title,
      icon: Icons.tune_rounded,
      body: Column(
        children: [
          SettingRow(
            icon: Icons.edit_outlined,
            title: s.edit,
            onTap: () => Navigator.pop(ctx, 'edit'),
          ),
          SettingRow(
            icon: Icons.delete_outline_rounded,
            title: s.delete,
            tone: UiTone.peach,
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
        ],
      ),
      footer: AppAction(label: s.cancel, onTap: () => Navigator.pop(ctx)),
    ),
  );
}
