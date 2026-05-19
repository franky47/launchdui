---
# launchdui-ia0n
title: Option+R keyboard shortcut for Mark as read
status: todo
type: feature
created_at: 2026-05-19T10:34:36Z
updated_at: 2026-05-19T10:34:36Z
parent: launchdui-ystj
blocked_by:
    - launchdui-ikgz
---

## What to build

Adds an app-level keyboard shortcut — `Option+R` — that marks the currently-selected service as read. Mirrors the existing `P`-for-pin keyboard pattern but uses a modifier to avoid conflict with `Cmd+R` (refresh).

The binding triggers the same `state.markRead(label:)` action as the detail-panel button introduced in `launchdui-ikgz`. It is inert when no service is selected or when the selected service is already read.

Suggested wiring: `.keyboardShortcut("r", modifiers: .option)` attached to a hidden or invisible button at the app/scene level, or as a `.keyboardShortcut` modifier on the existing detail-panel "Mark as read" button so it only triggers when that button is present.

See parent PRD `launchdui-ystj` for rationale on keyboard surface and shortcut choice.

## Acceptance criteria

- [ ] `Option+R` invokes `state.markRead(label:)` on the currently-selected service.
- [ ] Shortcut is inert (no-op) when no service is selected.
- [ ] Shortcut is inert when the selected service is already read.
- [ ] Shortcut does not conflict with `Cmd+R` (refresh) or any other existing binding.
- [ ] Pressing the shortcut clears the row's `(new)` badge and removes the detail-panel button in the same render pass.
- [ ] Manual verification: select an unread service, press `Option+R`, confirm badge and button both clear. Select a read service and press the shortcut — nothing changes.

## User stories addressed

Reference by number from the parent PRD:

- User story 7
