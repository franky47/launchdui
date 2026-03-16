# LaunchDUI - Work In Progress

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
- [x] `LaunchDUIApp.swift` — @main SwiftUI app entry
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

- [ ] Auto-refresh on window focus
- [ ] Keyboard shortcut (Cmd+R for refresh)
- [ ] Search/filter in the service list
- [ ] Error handling (non-modal banners for read failures)

---

## Current Focus
**Phase 2: COMPLETE.** Ready for review before starting Phase 3 (Polish).
