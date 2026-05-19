---
# launchdui-xn3s
title: Inbox header + Mark all as read bulk action
status: todo
type: feature
created_at: 2026-05-19T10:34:15Z
updated_at: 2026-05-19T10:34:15Z
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

- [ ] `InboxHeaderView` exists as a new view rendering count text + chip-styled bulk button.
- [ ] Bulk button uses the existing `FilterChip` component (icon: `eye`, label: `Mark all as read`, count, `isActive: false`) so it matches the surrounding filter chrome.
- [ ] When `state.unreadCount > 0`, `ServiceListView` renders the inbox header in place of the status and schedule filter bars.
- [ ] When `state.unreadCount == 0`, the inbox header is gone and both filter bars are visible as today.
- [ ] The search field above remains visible and functional in both modes.
- [ ] Clicking the bulk button invokes `state.markAllRead()`, clearing every unread label (ignoring any active search).
- [ ] After bulk clear, the inbox header disappears and filter bars return without requiring a manual refresh.
- [ ] The count in the header text and in the chip stays in sync as individual services are marked read.
- [ ] Manual verification: with multiple unread services present, confirm filter bars are hidden and header shows correct count. Type in search to narrow the list — header count remains the global total. Click bulk button — all badges clear, header gone, filter bars back.

## User stories addressed

Reference by number from the parent PRD:

- User story 3
- User story 4
- User story 8
- User story 9
- User story 17
- User story 18
- User story 19
