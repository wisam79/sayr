# Changelog

## 3.0.1 (2026-06-09)

### Infrastructure
- ✅ CI/CD pipelines updated to Flutter 3.44.1 / Dart 3.12.1
- ✅ Pre-commit hooks via lefthook (`format:check`, `analyze:strict`, `test:all`)
- ✅ All 448+ tests passing across all packages

### Testing
- ✅ 180 mobile app tests (bloc + widget)
- ✅ 101 core package tests
- ✅ 144 data package tests
- ✅ 21 ui_kit tests
- ✅ Integration test structure added for E2E flows

### Edge Functions
- 🆕 Added Deno unit test template for edge functions (`supabase/functions/_test/`)

### Offline-First
- 🆕 `OfflineTripDao` for route caching and location sync queue
- ✅ Drift local database with `CachedRoute`, `CachedTrip`, `PendingLocationUpdate` tables

### Documentation
- 🆕 ADR 006: Offline-First Strategy
- 🆕 ADR 007: Accessibility Strategy
- 🆕 ADR 008: Monitoring and Crash Reporting
- 🆕 `CONTRIBUTING.md` with setup and PR guidelines
- 🆕 `a11y-audit.md` with action items

## 3.0.0 (2026-06-03)

### Initial Release
- Clean Architecture monorepo
- 10 feature modules with complete BLoC structure
- Supabase backend with 33 migrations
- Material 3 design system
- RTL Arabic support
