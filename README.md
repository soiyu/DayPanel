# DayPanel

<p align="center">
  <strong>Mindful Habits, Daily Tasks & Reflective Journal</strong>
  <br>
  <em>A craftsman-built, privacy-first, offline-first personal tracker for Android.</em>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README_zh.md">简体中文</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47.9-blue.svg" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.13.7-blue.svg" alt="Dart">
  <img src="https://img.shields.io/badge/Android-API%2028--36-green.svg" alt="Android">
  <img src="https://img.shields.io/badge/Privacy-100%25%20Offline-emerald.svg" alt="Offline-First">
  <img src="https://img.shields.io/badge/Ads-Zero-brightgreen.svg" alt="Zero Ads">
  <img src="https://img.shields.io/badge/License-GPL%20v3-orange.svg" alt="License">
</p>

---

## ✨ Overview

**DayPanel** is an Android habit tracker, task organizer, and daily journal designed for clarity, mindfulness, and complete user privacy.

Most habit apps push intrusive subscriptions, require cloud accounts, display ads, or harvest user telemetry. DayPanel is built on opposite principles:
- **100% Offline-First**: All data stays on your device in a local SQLite database. No developer servers, no cloud sync lock-in.
- **Zero Ads & Zero Trackers**: No analytics SDKs, no behavioral tracking frameworks.
- **Craftsmanship & Aesthetics**: Modern, fresh UI palette, fluid tactile interactions, and original hand-drawn artwork.
- **True Data Freedom**: Full JSON backup/restore with transactional rollback, readable CSV export, and legacy Loop Habit Tracker database import — permanently free.

---

## 🚀 Key Features

### 1. Multi-Mode Habit Tracking
* **Boolean Habits**: Simple one-tap daily completion.
* **Numeric Quantity Habits**: Log daily totals (water intake in `ml`, reading in `pages`, running in `km`) with **smart, unit-aware quick increment buttons** (e.g., `+250 ml`, `+10 pages`).
* **Frequency Count Habits**: Track daily repetition counts and sets.
* **Flexible Schedules**: Daily, specific weekdays, or custom interval cadences (e.g., every 3 days).
* **Rest & Vacations**: Take planned days off or pause habits without breaking historical streaks.

### 2. Resident Everyday Tasks & One-Time To-Dos
* Separate one-time errands from reusable daily routines.
* **Resident Tasks** are logged on-demand each day; missing a day never triggers overdue penalties or artificial anxiety.

### 3. Associated Mindful Journal
* Capture quick notes and reflections alongside habit completions or as standalone daily entries.
* Calendar browsing and fast full-text keyword search across months.

### 4. Dual 365-Day Activity Heatmaps
* **Global Activity Heatmap**: View your entire year's consistency at a glance in the Statistics center, modeled after code contribution matrices.
* **Single-Habit Intensity Heatmaps**: Dive into individual habit consistency and daily volume ratios across 365 days.
* Completion trends, strength ratings, and plan revision history.

### 5. Collectible Original Achievement Cards
* Complete your daily commitments to unlock **6 hand-crafted original illustrated cards**.
* Flip cards over to record reflective thoughts; export high-resolution shareable cards with **default privacy masking** for sensitive habit names.

### 6. Native Android Home-Screen Widgets
* Add lightweight, high-performance widgets to your launcher.
* Mark boolean habits and tasks done directly from the home screen, or open quick quantity popups in one tap.

### 7. Optional DayPanel Plus (One-Time Lifetime Unlock)
An optional, one-time lifetime purchase on Google Play (no subscriptions) for power users:
* **Multi-Item Combined Widget**: Pin multiple habits and tasks together into a unified home-screen panel.
* **Itemized Sub-Event Logs**: Save individual timestamps, amounts, and notes for numeric habits (e.g., `+250ml at 10:15 AM`) with single-record editing and correction.
* **Weekly Total Targets**: Set cumulative goals (e.g., 100 km per week) independent of completed days.
* **Panoramic Review Cards**: Generate beautiful weekly and monthly long-image summary infographics.
* **Extended Color Palettes**: Unlock bespoke theme accents and custom icon borders.

---

## 🏛️ Architecture & Clean Code

The codebase strictly adheres to clean layered architecture:

```text
lib/
├── domain/          # Pure business models, dates, schedules, and calculations (Zero Flutter dependencies)
├── data/            # Local SQLite schema, transactional migrations, and Android method bridges
├── application/     # Application state management, error handling, and orchestration
├── presentation/    # Flutter UI widgets, screens, custom painters (Heatmap), and themes
└── l10n/            # Localization ARB files (English & Simplified Chinese)
android/             # Android host, native widgets, alarm receivers, and Plus Google Play Billing
test/                # Exhaustive unit, SQLite migration, and UI widget test suites
release_materials/   # Google Play listing materials, legal templates, and keystore scripts
```

---

## 🛠️ Building from Source

### Prerequisites
* **Flutter SDK**: 3.47.x (Dart 3.13+)
* **JDK**: 17
* **Android SDK**: API 28 through 36

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/soiyu/DayPanel.git
   cd DayPanel
   ```
2. Configure machine toolchain paths in `.local/toolchain.json`:
   ```json
   {
     "flutterSdk": "path/to/flutter",
     "javaHome": "path/to/jdk-17",
     "androidSdk": "path/to/android-sdk"
   }
   ```
3. Run verification and build using the included PowerShell tool:
   ```powershell
   # Install dependencies & generate localizations
   powershell -ExecutionPolicy Bypass -File ./scripts/dev.ps1 pub

   # Run code analyzer and test suite
   powershell -ExecutionPolicy Bypass -File ./scripts/dev.ps1 verify

   # Build debug APK (Testing Plus entitlement enabled automatically)
   powershell -ExecutionPolicy Bypass -File ./scripts/dev.ps1 assemble
   ```

*In Debug builds, Plus features are automatically unlocked in testing mode for evaluation and community development.*

---

## 📦 Google Play Publishing Materials

All assets and guides required for building a release AAB and listing on Google Play are organized under [`release_materials/`](release_materials/README.md):
- [Account Setup & 14-Day Testing Guide](release_materials/01_ACCOUNT_AND_STORE_GUIDE.md)
- [Keystore Generation Script](release_materials/02_KEYSTORE_SETUP/KEYSTORE_GUIDE.md)
- [Store Listing Metadata (EN & ZH)](release_materials/03_STORE_METADATA/)
- [Deployable Privacy Policy HTML & Data Safety Form](release_materials/04_LEGAL_AND_PRIVACY/)
- [Open Source Strategy & Licensing](release_materials/05_OPEN_SOURCE_STRATEGY.md)

---

## 📄 License & Attribution

* **Source Code**: Distributed under the [GNU General Public License v3 (GPLv3)](LICENSE).
* **Trademarks & Artwork**: The name **DayPanel**, logo, and hand-drawn card illustrations are proprietary assets owned by the project author and may not be used in commercial derivatives or unauthorized store redistributions without permission.
* **Font Asset**: Noto Serif SC is distributed under the [SIL Open Font License 1.1](assets/fonts/OFL-NotoSerifSC.txt).
