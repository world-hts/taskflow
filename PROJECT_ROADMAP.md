# TaskFlow Roadmap

## V4.0 — Portfolio foundation (current)

- [x] Flutter app source and responsive dashboard.
- [x] Create, edit, complete and delete tasks.
- [x] Due dates, categories and priority levels.
- [x] Search and view/category/priority filters.
- [x] Device-local persistence adapter.
- [x] Unit/controller/widget test sources.
- [ ] Run `flutter pub get`, `dart format`, `flutter analyze` and `flutter test` on the target Mac.
- [ ] Verify macOS/mobile/web UI manually.
- [ ] Generate native platform folders from the installed Flutter SDK.
- [ ] Publish to its own GitHub repository.

## V4.1 — Polish after verification

- Accessibility pass and keyboard navigation.
- More extensive date-boundary tests.
- Optional recurring tasks only if the core version remains simple and stable.

## Scope guardrails

- No login or cloud sync in V4.0.
- No external APIs, trackers or analytics.
- Keep the task model and persistence adapter isolated so a future storage migration can be assessed independently.
