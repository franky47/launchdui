---
# launchdui-ystj
title: Discover newly installed launchd services
status: todo
type: epic
created_at: 2026-05-19T10:25:03Z
updated_at: 2026-05-19T10:25:03Z
---

## Problem Statement

A macOS system accumulates launchd services over time — installed by Homebrew formulae, developer tools, third-party apps, OS updates, and occasionally by malware. Users have no native way to know *what* arrived on their machine *when*. Today, LaunchdUI shows the current state of every service but treats them all as equally familiar: a daemon installed five years ago looks identical to one that landed last night. There is no mechanism to surface "this is new" or "this appeared since you last looked."

For a security-aware user — or anyone curious about what's actually running on their Mac — this is the central question the app should answer. Without it, every audit pass requires scrolling the full list from memory, hoping to spot something unfamiliar.

## Solution

LaunchdUI gains an "inbox" of newly discovered launchd services. On each refresh, the app diffs the set of `.plist` files on disk against a persisted baseline. Any service whose label is not in the baseline becomes "unread" — visually marked with a `(new)` badge in the sidebar — and contributes to a count surfaced in a conditional header above the list. The user reviews each new arrival via the existing detail panel and explicitly clears it with a "Mark as read" action, or wipes the entire inbox in one click. Once unread count drops to zero, the inbox header disappears and normal filter chrome returns. Apple-shipped services (in SIP-protected directories) are silently recorded but auto-acknowledged so OS updates never noise up the inbox.

## User Stories

1. As a Mac user, I want to see which launchd services have appeared on my machine since I last reviewed them, so that I can recognize what new software has installed background processes.
2. As a security-conscious user, I want a `(new)` badge on services I have not yet acknowledged, so that I can quickly spot unfamiliar entries while scrolling the sidebar.
3. As a power user, I want a count of unread services prominently displayed when there are any, so that I know at a glance whether there is anything to review.
4. As a power user, I want the inbox header to disappear when nothing is unread, so that the UI does not carry permanent chrome for an empty state.
5. As a user inspecting a new service, I want to click its row and review its details without that action auto-acknowledging it, so that I have time to read the plist, logs, and program arguments before deciding I have understood it.
6. As a user, I want an explicit "Mark as read" button in the detail panel that only appears when the selected service is unread, so that acknowledgment is a deliberate gesture.
7. As a user, I want a keyboard shortcut (Option+R) to mark the selected service as read, so that I can triage quickly without reaching for the mouse.
8. As a user finishing an inbox review, I want a "Mark all as read" action that clears every unread service in one click, so that I do not have to acknowledge each one individually after I have decided the batch is uninteresting.
9. As a user, I want "Mark all as read" to clear *all* unread services, not just what is filtered by the current search, so that the action is unambiguous and the inbox header disappears predictably.
10. As a user, I want services I have just marked as read to lose their `(new)` badge immediately, so that the inbox header count and the row's visual state stay in sync.
11. As a user, I want the `(new)` badge styled as a small rounded pill to the right of the service display name, so that it is visually consistent with macOS conventions and the existing app aesthetic.
12. As a first-time user of this feature, I want the app to *not* drop an avalanche of unread items on me, so that I can start from a clean slate rather than being forced to acknowledge hundreds of pre-existing services.
13. As a returning user, I want my read/unread state to persist across app launches, so that acknowledgment is durable and I am not asked to re-review the same services every session.
14. As a user, I want the app to record when each service was first observed, so that future features (e.g. "discovered in the last 30 days") have honest historical data to work with — even for services that pre-date the feature.
15. As a user, I want services in SIP-protected Apple directories to be silently auto-acknowledged, so that macOS minor updates do not flood my inbox with dozens of OS daemons I cannot meaningfully audit.
16. As a user who uninstalls a service, I want its record to be dropped from the baseline, so that a future reinstall of the same label is surfaced as a fresh discovery.
17. As a user, I want the inbox header to *replace* the status and schedule filter bars while unread > 0, so that the review pass is the foregrounded activity, and normal filtering returns once the inbox is empty.
18. As a user, I want the search field to remain available during inbox mode, so that I can still narrow the list by name while triaging.
19. As a user, I want the "Mark all as read" button to use the same chip styling as the existing filter buttons, with an eye icon and the unread count, so that it visually belongs to the surrounding UI.
20. As a developer reading the codebase, I want detection logic to piggyback on the existing refresh flow (manual refresh, window focus, app launch), so that no new background daemons or timers are introduced.
21. As a developer, I want the baseline stored as a JSON file in Application Support, so that the data is transparent, easy to back up, and easy to wipe manually for testing.
22. As a user, I want the app to self-heal if the baseline file is missing or corrupt by treating that state as a first-run, so that I am never blocked by a broken file.
23. As a maintainer, I want this feature scoped to launchd only (no cron, at, or periodic), so that the app's identity stays focused and these other mechanisms — if ever supported — get first-class treatment rather than being smuggled in.
24. As a user, I want "Mark as read" to be a one-way action, so that the unread state has a clear semantic ("I have not seen this in the inbox yet") rather than doubling as a follow-up flag.

## Implementation Decisions

**Detection model.** Snapshot diff against a persisted baseline keyed by launchd label. On each refresh, the set of `.plist` labels on disk is compared to the stored baseline; new labels become unread records, missing labels are dropped from the baseline.

**Data per record.** Each baseline entry stores: the launchd label (key), `firstSeenAt: Date`, and `readAt: Date?` (nil indicates unread). The label is the natural key — the existing app already treats label as a unique service identifier across sources.

**First-run behavior.** If the baseline file is missing or unparseable, the app treats it as a first run: for every currently-discovered service, it records `firstSeenAt` from the plist file's birthtime (fallback to mtime) and sets `readAt` to the current time (marking everything as already-read). This gives an empty inbox on first launch while preserving honest discovery timestamps for any future feature that surfaces them.

**Storage.** A new `DiscoveryStore` actor owns the baseline. The on-disk representation is a JSON file at `~/Library/Application Support/launchdui/discovery.json`. Writes are atomic. The store is intentionally separate from `PinStore` (UserDefaults) because pin state is user-chosen preference while discovery state is observational data — they have different audiences and different transparency needs.

**Apple-source policy.** Services discovered under SIP-protected directories (`/System/Library/LaunchAgents`, `/System/Library/LaunchDaemons`) are recorded with `readAt = firstSeenAt` (silently auto-acknowledged). The trust root is SIP itself: third parties cannot write to `/System/Library/*` with SIP enabled. The app assumes SIP is enabled; no `csrutil` check is performed in v1.

**Detection trigger.** Diffing runs as part of `ServiceRepository.loadAll()`. The existing refresh flow — manual `Cmd+R`, scenePhase focus, initial launch — drives detection. No timers, no FSEvents, no background daemons.

**Removed services.** When a label exists in the baseline but is no longer on disk, the baseline entry is dropped. Reinstalls of the same label are treated as fresh discoveries. Tombstoning (a symmetric "removed" inbox) is deferred to a future iteration.

**State exposure.** `AppState` gains a `discoveryStore` reference and computed properties for the unread label set, used to drive the `(new)` badge, the conditional inbox header, and the detail-panel "Mark as read" button visibility. Services themselves remain unchanged in shape; unread is a separate, label-indexed concern.

**Inbox UI.** When unread count > 0:
- The status and schedule filter bars are hidden.
- A header appears in their place containing the text `"N new services discovered"` on the left and a filter-chip-styled button (`[eye] Mark all as read [N]`) on the right. The chip reuses the existing `FilterChip` component for visual consistency.
- The search field above remains visible and continues to narrow the list.

When unread count = 0, the inbox header is removed and the filter bars return.

**Row badge.** Service rows in the unread set render a small rounded pill containing the text `(new)` to the right of the display name. Dark-mode-aware background, full-rounded corners, 1px gray border.

**Detail panel action.** `ServiceStatusView`'s Actions container gains a "Mark as read" button next to the existing pin button. The button is rendered only when the service is unread. Clicking calls the discovery store's `markRead` action; the button vanishes immediately and the row's `(new)` badge clears in the next render pass.

**Bulk action.** "Mark all as read" in the inbox header iterates the entire unread set, regardless of any active search. The inbox header disappears once the set is empty.

**Keyboard.** `Option+R` is bound app-wide to mark the currently-selected service as read. Inert when no service is selected or when the selection is already read.

**Reversibility.** Read is one-way for v1. There is no "Mark as unread" action.

**Scope.** Strictly launchd. Cron, at, and periodic are out of scope.

**Modules to build or modify.**

- `DiscoveryRecord` (new model): a small `Codable Sendable` value type holding `firstSeenAt` and `readAt`. Used as the value in the on-disk dictionary.
- `DiscoveryStore` (new actor): owns the in-memory baseline and the JSON file. Public surface: load, reconcile (drop removed labels and record sightings of new ones with per-source Apple policy and birthtime metadata), `markRead(label:)`, `markAllRead()`, `unreadLabels()`, `firstSeen(label:)`. A deep module: encapsulates persistence, first-run logic, file-corruption recovery, and Apple-source policy behind a small interface that the rest of the app does not need to understand.
- `PlistBirthtimeReader` (new helper, possibly an extension to `PlistReader`): returns the creation date of a plist file from `FileManager` resource values, falling back to modification date. Pure function over a path. Deep module: hides the `URLResourceKey` plumbing.
- `ServiceRepository`: extended so that `loadAll()` reconciles the `DiscoveryStore` after building the service list — first dropping removed labels, then recording any new ones.
- `AppState`: gains a `discoveryStore` reference; exposes `unreadCount`, `isUnread(label:) -> Bool`, and the `markRead` / `markAllRead` actions. `groupedServices` does not change shape.
- `ServiceRow`: renders a conditional `(new)` pill view to the right of the display name when the service is unread. Pinned-row layout receives the same treatment.
- `ServiceListView`: replaces the two filter bars with an `InboxHeaderView` when unread > 0; otherwise renders the filter bars as today.
- `InboxHeaderView` (new view): renders the count text and the chip-styled bulk action. Reuses the existing `FilterChip` component with `isActive: false`.
- `ServiceStatusView`: adds a "Mark as read" button to the Actions container, visible only when the displayed service is unread.
- App-level keyboard binding for `Option+R` targeting the selected service.

## Testing Decisions

A good test for this feature observes external behavior — what the user sees, what `DiscoveryStore` returns, what `ServiceRepository.loadAll()` produces — without poking at private state or asserting on internal call order. Tests should drive `DiscoveryStore` through realistic sequences (first run → second run with a new service → mark read → third run with one removed) and assert on the resulting public state, not on how the JSON was serialized.

**Modules to test.**

- `DiscoveryStore`: the load round-trip (write then re-read returns the same state), first-run backfill (missing file → all current labels recorded as already-read), corruption recovery (unparseable JSON → first-run path), new-label detection (a label not in the baseline becomes unread on next reconcile), removal (a label no longer present is dropped), Apple-source auto-acknowledgment (labels under Apple sources are recorded as already-read), `markRead` idempotency (calling twice has no extra effect), `markAllRead` clears the entire unread set. Tests use a per-test temporary directory for the JSON file, in the same shape as the existing `PlistReader` tests that use temp plist files.
- `PlistBirthtimeReader`: returns a date for an existing file, returns the appropriate fallback when birthtime is unavailable, returns nil for a missing file.
- `ServiceRepository` integration with discovery: a service whose plist appears on disk between two `loadAll()` calls is reflected in the discovery store's unread set after the second call; a service whose plist disappears is dropped from the baseline.

**Prior art.** The existing test suite (`Tests/LaunchdUITests/`) sets the pattern: parser tests use captured fixture strings; `PlistReader` tests write temp files; `PinStore` tests exercise UserDefaults round-trips. `DiscoveryStore` tests follow the `PlistReader` precedent of using temp files, scoped per test.

UI behavior (badge rendering, inbox header swap, detail-panel button visibility) is not unit-tested in this feature; the app does not currently have view-level tests and adding that infrastructure is out of scope. Manual verification through the running app is the v1 acceptance gate for UI.

## Out of Scope

- Tombstones for removed services and a symmetric "Recently Removed" inbox.
- Detecting *modified* plists (Homebrew upgrades rewriting a file, etc.) via content hashing — the v1 contract is "new label" only.
- Cron, at, and periodic task discovery.
- A "Mark as unread" or follow-up-flag mechanism.
- Background polling, FSEvents, menu-bar mode, or dock badges that update while the app is not focused.
- `codesign` verification of service binaries — trust is path-based, anchored on SIP.
- A `csrutil` check to detect disabled SIP and switch behavior accordingly.
- A settings UI to override Apple-source auto-acknowledgment or change the inbox semantics.
- Migration tooling for existing users — the feature ships as a clean first-run for everyone.
- Sound, haptic, or system notification on new discoveries.

## Further Notes

- The on-disk record stores `firstSeenAt` even for Apple sources that are auto-acknowledged. This is intentional: a future preference toggle ("Show OS services in inbox") could surface them retroactively without data loss.
- The choice to drop removed labels from the baseline (rather than tombstoning) means a malicious uninstall-then-reinstall cycle would re-surface in the inbox as a new discovery. This is the desired behavior for v1 — the reinstall *is* a new event from the user's perspective.
- Deleting the JSON file is equivalent to "reset the inbox to a clean slate." Useful escape hatch for testing and recovery.
- The Apple-source policy assumes SIP is enabled. If a user has disabled SIP, malicious daemons placed under `/System/Library/Launch*` will be auto-acknowledged — a known limit. Should be documented in code comments on `DiscoveryStore`.
- The `(new)` badge styling deliberately resembles a UI affordance rather than a system alert: it announces novelty, not danger. Color choices should match the app's overall accent treatment rather than borrow from system warning palettes.
