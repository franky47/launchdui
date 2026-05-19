---
# launchdui-ikgz
title: Detail-panel "Mark as read" button
status: in-progress
type: feature
priority: normal
created_at: 2026-05-19T10:33:54Z
updated_at: 2026-05-19T11:05:15Z
parent: launchdui-ystj
blocked_by:
    - launchdui-tm5k
---

## What to build

Adds the per-service acknowledgment affordance: a "Mark as read" button in the detail panel's Actions container that appears only when the selected service is unread. Clicking it invokes `AppState.markRead(label:)`, the button disappears, and the row's `(new)` badge clears on the next render pass.

Selecting a row does **not** auto-mark it read — the user explicitly clicks the button after reviewing the plist, logs, and program arguments. Read is one-way for v1: no "Mark as unread" inverse exists.

Touches:

- **View**: `ServiceStatusView` Actions container gains a "Mark as read" button next to the existing `pinButton`. Rendered conditionally on `state.isUnread(service.label)`. Once read, the button vanishes — the Actions container resizes naturally, no replacement slot.
- **Styling**: button shape matches the existing `pinButton` (borderless, SF Symbol + label or tooltip). Suggested icon: `eye` or `envelope.open`. Keep tooltip for discoverability.

See parent PRD `launchdui-ystj` for rationale on explicit acknowledgment, one-way semantics, and button visibility behavior.

## Acceptance criteria

- [x] "Mark as read" button appears in `ServiceStatusView` Actions container only when the selected service is unread.
- [x] Button is positioned adjacent to the existing pin button, matching its borderless styling.
- [x] Clicking the button calls `state.markRead(label:)` and persists the change via `DiscoveryStore`.
- [x] After click, the button disappears from the panel (service is no longer unread).
- [x] The row's `(new)` badge in the sidebar clears in the same render pass.
- [x] Selecting a row does NOT mark it read — only the button does.
- [x] No "Mark as unread" inverse is added; read is one-way.
- [ ] Manual verification: launch app, install a test daemon, refresh, select the new row, confirm badge present and button visible. Click button. Confirm badge and button both gone. Re-launch app and confirm the service remains read.

## User stories addressed

Reference by number from the parent PRD:

- User story 5
- User story 6
- User story 10
- User story 24

## Summary of Changes

- `ServiceStatusView` gains two required parameters, `isUnread: Bool` and `markRead: () -> Void`, and renders a borderless `envelope.open` button (tooltip: "Mark as read") to the left of the existing pin button when `isUnread` is true. The Actions row resizes naturally — no replacement slot.
- `DetailPanelView` threads `isUnread` and `markRead` through to `ServiceStatusView`.
- `ContentView` reads `state.selectedService` once, computes `isUnread` from it, and constructs a closure that captures the selected label and dispatches `state.markRead(label:)` on a `Task` (synchronous SwiftUI button action → `@MainActor` AppState → `DiscoveryStore` actor). The capture-at-render-time pattern (rather than re-reading `selectedService` at click time) avoids the theoretical case where a selection change between render and click marks the wrong service.
- Defaults dropped from the new view parameters per code-review feedback — every call site must supply both.
- Existing 101-test suite remains green; no new tests added (bean explicitly gates on manual verification only).

Manual verification is left to the user (see acceptance criterion above) — I cannot exercise the running app.
