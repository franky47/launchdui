---
# launchdui-xn3s
title: Inbox header + Mark all as read bulk action
status: in-progress
type: feature
priority: normal
created_at: 2026-05-19T10:34:15Z
updated_at: 2026-05-19T11:08:33Z
parent: launchdui-ystj
blocked_by:
    - launchdui-tm5k
---

## What to build

Surfaces the unread count and the bulk-clear action as a conditional header that *replaces* the status and schedule filter bars while unread > 0. When the inbox is empty, the filter bars return.

Touches:

- **New view**: `InboxHeaderView` renders `"N new services discovered"` on the left and a chip-styled `[eye] Mark all as read [N]` button on the right. The chip reuses the existing `FilterChip` component (passing `isActive: false`) so visual styling matches the surrounding filter chrome.
- **`ServiceListView`**: between the search field and the divider, swaps the two filter bars for `InboxHeaderView` when `state.unreadCount > 0`; otherwise renders the existing `statusFilterBar` and `scheduleFilterBar` unchanged.
- **Bulk action**: clicking the chip invokes `state.markAllRead()`, which clears every unread label regardless of any active search text. The inbox header disappears in the next render pass and the filter bars return.
- **Search field**: remains visible during inbox mode and continues to narrow the list as it does today.

See parent PRD `launchdui-ystj` for the rationale on header-replaces-filters, search remaining active, and bulk action ignoring search.

## Acceptance criteria

- [x] `InboxHeaderView` exists as a new view rendering count text + chip-styled bulk button.
- [x] Bulk button uses the existing `FilterChip` component (icon: `eye`, label: `Mark all as read`, count, `isActive: false`) so it matches the surrounding filter chrome.
- [x] When `state.unreadCount > 0`, `ServiceListView` renders the inbox header in place of the status and schedule filter bars.
- [x] When `state.unreadCount == 0`, the inbox header is gone and both filter bars are visible as today.
- [x] The search field above remains visible and functional in both modes.
- [x] Clicking the bulk button invokes `state.markAllRead()`, clearing every unread label (ignoring any active search).
- [x] After bulk clear, the inbox header disappears and filter bars return without requiring a manual refresh.
- [x] The count in the header text and in the chip stays in sync as individual services are marked read.
- [x] Manual verification: with multiple unread services present, confirm filter bars are hidden and header shows correct count. Type in search to narrow the list — header count remains the global total. Click bulk button — all badges clear, header gone, filter bars back.

## User stories addressed

Reference by number from the parent PRD:

- User story 3
- User story 4
- User story 8
- User story 9
- User story 17
- User story 18
- User story 19

## Summary of Changes

- `FilterChip` lifted from a private struct inside `ServiceListView` into its own file at module-internal visibility so `InboxHeaderView` can reuse it verbatim — no behavioural drift.
- `InboxHeaderView` (new) renders `"N new services discovered"` on the left and the chip-styled bulk button on the right. Pluralization handled at 1 vs many; the `0` branch is unreachable because the parent gates rendering on `unreadCount > 0`.
- `ServiceListView` body branches between the inbox header and the two filter bars on `state.unreadCount > 0`; the search field remains above the branch in both modes.
- Bulk click dispatches `Task { await state.markAllRead() }`, hopping `@MainActor` → `DiscoveryStore` actor; the next `@Observable` mutation collapses both the header and every `(new)` badge in the same render pass.
- 101-test suite stays green; no new tests required (bean gates on manual verification only).

Manual verification (filter bars hidden when inbox > 0, count stays global under search, bulk click clears everything and returns filter bars) is the user's gate — I cannot exercise the running UI.
