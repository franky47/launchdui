---
# launchdui-anpx
title: 'Login filter: narrow list to RunAtLoad services'
status: completed
type: feature
priority: normal
tags:
    - filter
    - ui
created_at: 2026-05-29T09:29:16Z
updated_at: 2026-05-29T09:35:07Z
---

Add a boolean **"Login only"** filter that narrows the service list to launchd
items with `RunAtLoad == true` (boot-at-login launchers, e.g. `Handy.plist`),
distinct from timer/event/resident services.

`RunAtLoad` is orthogonal to `ServiceSchedule` (which is where/when classification)
and must NOT be folded into that enum — it is a separate filter dimension.

## Acceptance criteria
- [x] `LaunchdService` gains `runAtLoad: Bool`, parsed in `PlistReader` as
      `dict["RunAtLoad"] as? Bool ?? false` (sibling to `extractSchedule`), threaded
      through `ServiceRepository`.
- [x] `AppState.showLoginOnly: Bool` (3rd filter dimension, AND-combined with the
      existing status/schedule sets) applied in `applyFilters`; affects grouped + pinned lists.
- [x] `AppState.loginCount` = unfiltered tally of `runAtLoad` services.
- [x] Dedicated row below the schedule filter bar in `ServiceListView`: label
      `power` icon + "Login only · {count}" on the left, small switch
      (`Toggle`, `.switch`, `.controlSize(.mini)`) on the right, height matching chips.
- [x] Visibility = same rule as the filter bars: hidden in inbox mode
      (`unreadCount > 0`), shown otherwise, present even at count 0. Ephemeral.
- [x] Parser/repository test for `RunAtLoad` extraction (with/without key).
- [x] `WIP.md` updated.

Design settled via /brainstorm. No plan file. Detailed handoff (transient):
`/tmp/claude-501/handoff-login-filter.md`.

## Summary of Changes
`RunAtLoad` added as an orthogonal boolean facet, deliberately kept out of
`ServiceSchedule`: new `PlistReader.extractRunAtLoad` (pure static fn), a
`runAtLoad: Bool` field on `LaunchdService`, threaded through the
`ServiceRepository` build path. `AppState` gains `showLoginOnly` (AND-combined
in `applyFilters`, so it composes with status/schedule sets across both grouped
and pinned lists) and `loginCount` (unfiltered tally driving the label). UI is a
dedicated switch row (`power` icon + "Login only · {count}") below the schedule
chips, living in the same `else` branch as the filter bars so it inherits their
inbox-mode visibility rule and is ephemeral.

Tests: `PlistReader` RunAtLoad extraction (true / absent / explicit-false) and
`AppState` login filter (unfiltered count + grouped-list narrowing). Full suite
106 tests green.

Note: visual eyeballing of the switch height vs. the chip row (`swift run`) was
not performed in this environment — verified via build + tests only.
