# TaskFlow — V4.0.0

A polished, local-first task manager built with Flutter. TaskFlow is designed to work across Android, iOS, macOS, Windows, Linux and web, with a responsive desktop dashboard and a mobile-first navigation layout.

## Current status

- App source, persistence adapter, example tasks, tests and documentation are included in this archive.
- The full native platform folders are generated on the target machine using `flutter create` (instructions below).
- Flutter analysis, tests and builds have **not** been run in the packaging environment. Run the checks locally before marking this release as verified.

## Features

- Create, edit, complete and delete tasks.
- Categories, optional notes, four priority levels and due dates.
- Search task titles, notes and categories.
- Filter by All, Today, Upcoming and Completed views, category and priority.
- Overview cards for open, completed and overdue tasks.
- Local persistence using `shared_preferences`; no account, API key, database server or remote AI service is required.
- First-launch sample data, task completion progress, and clear-completed action.
- Widget and controller/model tests.

## Requirements

- Flutter 3.35 or newer (Dart 3.9+).
- `shared_preferences` supports Android, iOS, Linux, macOS, web and Windows. This app uses its asynchronous API for local key-value storage.

## Setup on macOS

From the extracted project directory:

```bash
flutter --version
flutter create --platforms=android,ios,macos,windows,linux,web --org com.worldhts .
flutter pub get
dart format lib test
flutter analyze
flutter test
```

`flutter create` generates the native and web runner files for the Flutter SDK installed on your Mac. It should not be run from the parent folder.

Run on macOS:

```bash
flutter run -d macos
```

Run in Chrome:

```bash
flutter run -d chrome
```

Run on an Android device (USB debugging enabled):

```bash
flutter devices
flutter run -d <device-id>
```

Build release targets when local platform tooling is installed:

```bash
flutter build macos
flutter build web
flutter build apk --release
```

## Data and privacy

Tasks are saved on the current device using shared preferences. They are not synced between devices, and clearing the app's local storage removes the saved list. `shared_preferences` is intended for lightweight, non-critical data, not secrets or financial records. TaskFlow does not collect or transmit task data.

The starter list contains fictional sample tasks. Delete them or replace them with your own after launch.

## Quality checks

```bash
dart format lib test
flutter analyze
flutter test
```

The checked-in GitHub Actions workflow runs Flutter formatting, analysis and tests on pushes and pull requests once the Flutter toolchain is available in CI.
