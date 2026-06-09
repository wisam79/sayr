# ADR 006: Offline-First Data Strategy

## Status
Accepted

## Context
Sayr operates in Iraqi university environments where network connectivity is unreliable. Students need to browse routes, view subscriptions, and track trips even when offline.

## Decision
Implement **cache-then-network** pattern using Drift (SQLite):

1. **Read**: Always serve from local DB first, then refresh from network
2. **Write**: Queue mutations in local DB, sync when online via `retry` package
3. **Conflict**: Server wins on timestamp conflict; user is notified

## Consequences
- (+) App works fully offline
- (+) Faster perceived performance
- (-) Increased app size (~5MB SQLite)
- (-) Complex sync logic
