---
# launchdui-tm5k
title: 'Discovery foundation: data layer + (new) badge'
status: todo
type: feature
priority: normal
created_at: 2026-05-19T10:33:21Z
updated_at: 2026-05-19T10:54:16Z
parent: launchdui-ystj
---

## What to build

The end-to-end foundation that makes "this service is new" observable in the sidebar. After this slice, refreshing the app reveals a `(new)` pill badge next to the display name of any service whose label is not in the persisted baseline. First launch is silent (no avalanche of badges). Apple-source services in SIP-protected directories never get badges. The baseline persists across launches as a JSON file under Application Support. There is no clearing mechanism yet — that lands in subsequent slices.

This slice cuts vertically through every layer required to surface unread state:

- **Model**: `DiscoveryRecord` (`Codable`, `Sendable`) with `firstSeenAt: Date` and `readAt: Date?`.
- **Helper**: `PlistBirthtimeReader` (pure function from path → `Date?`), using `FileManager` resource values with `mtime` fallback. Deep module hiding `URLResourceKey` plumbing.
- **Store**: `DiscoveryStore` actor encapsulating persistence, first-run logic, corruption recovery, Apple-source policy, and the unread set. Public surface: `load()`, `reconcile(currentServices:)`, `markRead(label:)`, `markAllRead()`, `unreadLabels()`, `firstSeen(label:)`. On-disk JSON lives at `~/Library/Application Support/launchdui/discovery.json` with atomic writes.
- **Repository wiring**: `ServiceRepository.loadAll()` invokes the store's reconcile after building the service list — dropping labels no longer on disk, recording new labels with appropriate `readAt` (Apple sources → `firstSeenAt`; user-installed → `nil`).
- **State**: `AppState` holds the `DiscoveryStore` and exposes `unreadCount`, `isUnread(label:)`, `markRead(label:)`, `markAllRead()`. State updates trigger view refresh via `@Observable`.
- **View**: `ServiceRow` renders a small rounded pill containing `(new)` to the right of the display name when `state.isUnread(service.label)` is true. Both default and pinned layouts are updated. Styling: full-rounded corners, dark-mode-aware background, 1px gray border.

See parent PRD `launchdui-ystj` for the full design rationale (snapshot diff model, Apple-source policy and SIP trust root, first-run birthtime backfill, drop-on-removal, JSON storage choice).

## Acceptance criteria

- [ ] `DiscoveryRecord` model added with `firstSeenAt` and `readAt` fields, Codable and Sendable.
- [ ] `PlistBirthtimeReader` returns birthtime when available, falls back to mtime, returns `nil` for missing files.
- [ ] `DiscoveryStore` persists the baseline as JSON at `~/Library/Application Support/launchdui/discovery.json` with atomic writes.
- [ ] On first run (file missing or unparseable), every currently-discovered service is recorded with `firstSeenAt` from its plist birthtime and `readAt = .now`. Inbox is empty after first run.
- [ ] On subsequent runs, labels not in the baseline are recorded as unread (`readAt = nil`); labels no longer on disk are dropped from the baseline.
- [ ] Services discovered under `/System/Library/LaunchAgents` or `/System/Library/LaunchDaemons` are recorded with `readAt = firstSeenAt` (auto-acknowledged).
- [ ] `ServiceRepository.loadAll()` reconciles the discovery store as part of the refresh flow — no new timers, no FSEvents, no background work.
- [ ] `AppState` exposes `unreadCount`, `isUnread(label:)`, `markRead(label:)`, `markAllRead()`.
- [ ] `ServiceRow` renders a `(new)` pill to the right of the display name when the service is unread, in both default and pinned layouts.
- [ ] Pill styling: full-rounded corners, 1px gray border, background color that respects dark mode.
- [ ] Unit tests for `DiscoveryStore` cover: load round-trip, first-run backfill, corruption recovery (unparseable JSON treated as first-run), new-label detection, removal, Apple-source auto-acknowledgment, `markRead` idempotency, `markAllRead`. Tests use per-test temp directories following the `PlistReader` test precedent.
- [ ] Unit tests for `PlistBirthtimeReader` cover existing file (birthtime), missing file (nil), and fallback path.
- [ ] Test suite passes under `swift test`.
- [ ] `WIP.md` updated with a Phase 6 entry for this slice.

## User stories addressed

Reference by number from the parent PRD:

- User story 1
- User story 2
- User story 11
- User story 12
- User story 13
- User story 14
- User story 15
- User story 16
- User story 20
- User story 21
- User story 22
- User story 23
