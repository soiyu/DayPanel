# DayPanel Flutter development

- Read README.md, docs/product/FEATURES.md, docs/development/BACKLOG.md and STATUS.md first.
- This is the new Flutter / Android-first product authorized on 2026-11-05. Do not generate iOS, web or desktop targets yet. Older native DayPanel is a separate project, not this project's execution backlog.
- Latest direction: match Xiaorichang non-focus capabilities. Existing core features remain free. ADR0016 authorizes a Google Play one-time Plus purchase for new advanced features; backups, export and access to user data remain free. No focus timers/music, ads, analytics, account or cloud sync. Use docs/product/XIAORICHANG-PARITY.md for sourced capabilities and unknown details.
- User explicitly waived external five-person walkthroughs as an implementation gate. Proceed with design and implementation; retain automated correctness, accessibility and device verification.
- Build real vertical slices. No fake persistence, placeholder navigation, fake purchases, fake notifications or demo data in production.
- Pure rules live in lib/domain; SQLite adapters in lib/data; application coordination in lib/application; Flutter UI in lib/presentation. Android widgets/notification adapters belong in android, behind explicit interfaces.
- Habit records, tasks, journals and achievement cards are distinct concepts. Date-only values are local calendar days; never infer historical schedules from today's editable schedule. Resident tasks are not automatically repeating tasks.
- Persist explicit completion values. Quantity uses integer thousandths; reject invalid input. Preserve creation dates, task completion dates and actual vs planned dates.
- Do not copy/translate Loop GPL implementation into this codebase without a provenance/license decision. The new code is authored here; independently supporting file formats does not grant rights to copy implementations. Final distribution license remains a separate decision.
- Use scripts/dev.ps1 and ignored .local/toolchain.json for machine paths. Never change global JDK/Android/Flutter settings or commit tools, credentials, APKs, private paths or databases.
- A successful build is not device verification. Record exact checks and remaining gaps. Run formatter, analyzer, relevant tests, Android debug build and git diff --check for code changes.
