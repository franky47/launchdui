# LaunchdUI - Work In Progress

## Phase 1: Data Layer

### 1.1 Package.swift
- [x] Create `Package.swift` (swift-tools-version: 6.0, macOS 15, executable target + test target)

### 1.2 Models
- [x] `LaunchdService.swift` — Core domain model
- [x] `ServiceSource.swift` — Enum: userAgent/systemAgent/systemDaemon/appleAgent/appleDaemon
- [x] `ServiceStatus.swift` — Enum: running/waiting/stopped/error/killed/disabled/notLoaded
- [x] `ServiceSchedule.swift` — Schedule representation
- [x] `PlistValue.swift` — Recursive Sendable enum for plist data crossing isolation boundaries

### 1.3 Shell & Parsing
- [x] `ShellExecutor.swift` — Async Process wrapper (read-only)
- [x] `LaunchctlListParser.swift` — TSV parser for `launchctl list`
- [x] `LaunchctlDisabledParser.swift` — Parser for `launchctl print-disabled`
- [x] `LaunchctlPrintParser.swift` — Key-value block parser for `launchctl print`
- [x] `ScheduleFormatter.swift` — Human-readable schedule strings

### 1.4 Data Access
- [x] `PlistReader.swift` — Read plists via PropertyListSerialization
- [x] `LaunchctlClient.swift` — Wire parsers to read-only shell commands
- [x] `ServiceRepository.swift` — Merge plist + runtime data
- [x] `CommandGenerator.swift` — Generate copyable launchctl command strings

### 1.5 Tests (68 tests, all passing)
- [x] Parser tests with fixture data (LaunchctlListParser, DisabledParser, PrintParser)
- [x] ScheduleFormatter tests
- [x] PlistValue tests
- [x] CommandGenerator tests
- [x] PlistReader tests (with temp plist files)

---

## Phase 2: UI

### 2.1 App Shell
- [x] `LaunchdUIApp.swift` — @main SwiftUI app entry
- [x] `ContentView.swift` — HSplitView/VSplitView layout
- [x] `AppState.swift` — @Observable state container

### 2.2 Left Column
- [x] `ServiceListView.swift` — Filterable service list grouped by source
- [x] `ServiceRow.swift` — Row: name, label, status indicator
- [x] `StatusIndicator.swift` — Color-coded status circles

### 2.3 Right Column
- [x] `DetailPanelView.swift` — Top/bottom vertical split
- [x] `ServiceStatusView.swift` — Info, metadata, schedule, status, commands
- [x] `PlistInspectorView.swift` — Tabbed plist viewer container
- [x] `PlistTreeView.swift` — Tree tab: hierarchical DisclosureGroup
- [x] `PlistSourceView.swift` — Source tab: raw XML monospaced text

---

## Phase 3: Polish

- [x] Auto-refresh on window focus (scenePhase onChange)
- [x] Keyboard shortcut (Cmd+R toolbar button)
- [x] Search/filter in the service list (wired in Phase 2)
- [x] Error handling (non-modal dismiss banner)

---

## Phase 4: Runtime Log Viewer

- [x] Extract `StandardOutPath`/`StandardErrorPath` from plist to `LaunchdService` model
- [x] `PlistReader` extraction methods with readability checks in `ServiceRepository`
- [x] `LogTailer` — efficient backward file reading (last 500 lines) + live streaming via DispatchSource
- [x] `LogTabView` — monospaced log display with auto-scroll (pauses on scroll-up)
- [x] Conditional Logs/Errors tabs in `PlistInspectorView`
- [x] Inline search with match highlighting
- [x] Per-service tab memory via `DetailPanelView` binding
- [x] LogTailer tests (initial read, streaming, cancellation)
- [x] PlistReader extraction tests

---

## Phase 5: Pinnable Services

### 5.1 Core Pinning
- [x] `PinStore.swift` — UserDefaults-backed pin persistence with ordered labels
- [x] PinStore unit tests (9 tests)
- [x] `AppState` integration — `pinnedServices` computed property, filters exclude pinned from groups
- [x] `ServiceRow` pinned layout variant (badge + name, pin icon + bundle ID)
- [x] `ServiceListView` — pinned rows above groups, context menus (Pin to Top / Unpin)
- [x] Bundle ID change to `com.47ng.launchdui`

### 5.2 Additional Interactions (pending)
- [ ] Detail panel pin button (Actions container)
- [ ] `P` keyboard shortcut
- [ ] Drag reorder within pinned rows

---

## Current Focus
**Phase 5.1 COMPLETE.** Core pinning with context menu, persistence, and list rendering.
