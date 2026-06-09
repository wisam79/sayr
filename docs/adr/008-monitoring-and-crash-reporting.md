# ADR 008: Monitoring and Crash Reporting

## Status
Accepted

## Context
Production app needs visibility into errors, crashes, and performance.

## Decision
- **Sentry** for crash reporting and performance tracing
- **Talker** for local debug logging
- **Feature flags** via `app_config` table for gradual rollouts

## Implementation
- Sentry initialized in `main.dart` with `sendDefaultPii: false`
- TalkerBlocObserver for BLoC state logging
- `app_config` table for remote feature toggles
