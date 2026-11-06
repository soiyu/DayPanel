# Sources and distribution

DayPanel Flutter is a new implementation authored in this repository. No Loop Habit Tracker application source or bundled assets are copied into the initial implementation. Prior DayPanel/Loop development informs requirements and planned file-format migration only.

Product and design references: the owner's approved Stitch Luminous Focus direction and the prior competitive research snapshot (2026-11-04). Referenced product names belong to their owners; this project has no affiliation with them.

Flutter and third-party packages retain their own licenses. The app exposes Flutter's package license page. Pin resolved versions in pubspec.lock and audit their notices before release. No root distribution license has been chosen; absence of a LICENSE is not a grant to redistribute this project.

FL14 artwork: the six scenes in `lib/presentation/card_art.dart` are original code-drawn compositions authored for this project. Completion audio `android/app/src/main/res/raw/daypanel_complete.wav` is an original 0.22-second synthesized two-note PCM sound, reproducible with `scripts/generate-feedback.ps1`. Neither uses third-party illustrations, recordings or melodies.


FL17 font asset: `assets/fonts/NotoSerifSC.ttf` is Noto Serif SC from google/fonts, distributed under SIL Open Font License 1.1. See `assets/fonts/OFL-NotoSerifSC.txt` and `SOURCE.md`.

Habit icons use the Material Icons font already distributed with Flutter (Apache 2.0). Android widgets render the same 24 referenced glyphs from the bundled Flutter font; no Loop or competitor icon assets are used.

FL18 Loop file compatibility: the SQLite field/version declarations and numeric encodings of Loop v2.3.2 were inspected only to document an interoperable file format. The parser, conversion rules, transaction integration and synthetic tests are independently authored here; no Loop import, scoring, frequency, or migration implementation is copied or translated. See docs/development/LEGACY-FORMAT.md. Final distribution licensing remains a separate review.
