import 'package:flutter/material.dart';
import '../domain/habit_templates.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'components.dart';
import 'refined_components.dart';
import 'theme.dart';
import 'habit_icon.dart';

class HabitStarter {
  const HabitStarter([this.template]);
  final HabitTemplate? template;
}

class HabitCatalog extends StatefulWidget {
  const HabitCatalog({super.key});
  @override
  State<HabitCatalog> createState() => _HabitCatalogState();
}

class _HabitCatalogState extends State<HabitCatalog> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final items = habitTemplates
        .where(
          (t) => '${t.zh} ${t.en} ${t.keywords.join(' ')}'
              .toLowerCase()
              .contains(query.toLowerCase().trim()),
        )
        .toList();
    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(s.habitLibrary)),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Text(
                      s.habitLibraryTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.habitLibraryHint,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      key: const Key('template-search'),
                      onChanged: (v) => setState(() => query = v),
                      decoration: InputDecoration(
                        hintText: s.searchHabits,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(s.templateNoMatch),
                      ),
                    ResponsiveChoices(
                      minWidth: 145,
                      maxColumns: 2,
                      children: [
                        for (final t in items)
                          Semantics(
                            button: true,
                            child: Material(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLowest,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: .6),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                key: Key('template-${t.id}'),
                                onTap: () =>
                                    Navigator.pop(context, HabitStarter(t)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      HabitIcon(
                                        t.icon,
                                        size: 72,
                                        frame: 'plain',
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        t.title(zh),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        t.kind == HabitKind.check
                                            ? s.templateDailyCheck
                                            : s.templateDailyGoal(
                                                quantityText(t.target),
                                                t.unit(zh),
                                              ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              EditorFooter(
                children: [
                  Expanded(
                    child: AppAction(
                      key: const Key('custom-habit'),
                      label: s.customHabit,
                      icon: Icons.add_rounded,
                      primary: true,
                      onTap: () => Navigator.pop(context, const HabitStarter()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
