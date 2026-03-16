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

### 1.5 Tests (63 tests, all passing)
- [x] Parser tests with fixture data (LaunchctlListParser, DisabledParser, PrintParser)
- [x] ScheduleFormatter tests
- [x] PlistValue tests
- [x] CommandGenerator tests
- [x] PlistReader tests (with temp plist files)

---

## Phase 2: UI

### 2.1 App Shell
- [ ] `LaunchDUIApp.swift` — @main SwiftUI app entry (placeholder exists)
- [ ] `ContentView.swift` — HSplitView/VSplitView layout
- [ ] `AppState.swift` — @Observable state container

### 2.2 Left Column
- [ ] `ServiceListView.swift` — Filterable service list grouped by source
- [ ] `ServiceRow.swift` — Row: name, label, status indicator
- [ ] `StatusIndicator.swift` — Color-coded status circles

### 2.3 Right Column
- [ ] `DetailPanelView.swift` — Top/bottom vertical split
- [ ] `ServiceStatusView.swift` — Info, metadata, schedule, status, commands
- [ ] `PlistInspectorView.swift` — Tabbed plist viewer container
- [ ] `PlistTreeView.swift` — Tree tab: hierarchical DisclosureGroup
- [ ] `PlistSourceView.swift` — Source tab: raw XML monospaced text

---

## Phase 3: Polish

- [ ] Auto-refresh on window focus
- [ ] Keyboard shortcut (Cmd+R for refresh)
- [ ] Search/filter in the service list
- [ ] Error handling (non-modal banners for read failures)

---

## Current Focus
**Phase 1: COMPLETE.** Ready for review before starting Phase 2 (UI).
