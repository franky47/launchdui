# LaunchDUI - macOS LaunchD Service Viewer

## Context

macOS `launchd` manages hundreds of background services but provides no GUI for inspecting them. Users must use `launchctl` CLI commands and manually read `.plist` files. This app provides a **read-only** native SwiftUI viewer to browse and inspect launchd services with human-friendly schedule display and formatted plist viewing. Instead of executing actions directly, the app displays copyable `launchctl` commands the user can paste into a terminal with appropriate privileges.

## Data Access Findings

**Plist locations** (service definitions):
- `~/Library/LaunchAgents/` - User agents
- `/Library/LaunchAgents/` - System-wide agents
- `/Library/LaunchDaemons/` - System daemons
- `/System/Library/LaunchAgents/` - Apple agents (SIP-protected)
- `/System/Library/LaunchDaemons/` - Apple daemons (SIP-protected)

**Runtime data via `launchctl` (read-only):**
- `launchctl list` → TSV: PID, exit status, label (bulk, fast)
- `launchctl print gui/<uid>/<label>` → detailed runtime info (per-service, slower)
- `launchctl print-disabled gui/<uid>` → enabled/disabled map (bulk, fast)

**Key insight: two-phase loading.** Bulk load on startup (plists + `launchctl list` + `print-disabled`), then fetch detailed `launchctl print` data only when a service is selected. This avoids running 500+ subprocess calls on launch.

**Plist reading:** Use `PropertyListSerialization` directly (handles binary, XML, OpenStep formats natively) rather than shelling out to `plutil`.

## Architecture

Native SwiftUI app, built as a Swift Package (no Xcode project needed). Swift 6 strict concurrency throughout. **Strictly read-only** — the app never executes `launchctl` mutating commands, only reads state and generates copyable command strings.

### File Structure

```
LaunchDUI/
├── Package.swift
├── Sources/LaunchDUI/
│   ├── App/
│   │   ├── LaunchDUIApp.swift          # @main SwiftUI app entry
│   │   └── AppState.swift              # @Observable state container
│   ├── Models/
│   │   ├── LaunchdService.swift        # Core domain model
│   │   ├── ServiceSource.swift         # Enum: userAgent/systemAgent/systemDaemon/appleAgent/appleDaemon
│   │   ├── ServiceStatus.swift         # Enum: running/waiting/stopped/error/killed/disabled/notLoaded
│   │   └── ServiceSchedule.swift       # Schedule representation
│   ├── Services/
│   │   ├── ShellExecutor.swift         # Async Process wrapper (read-only commands only)
│   │   ├── LaunchctlClient.swift       # launchctl read-only queries
│   │   ├── PlistReader.swift           # PropertyListSerialization-based reader
│   │   ├── ServiceRepository.swift     # Merges plist + runtime data
│   │   └── CommandGenerator.swift      # Generates copyable launchctl command strings (never executes them)
│   ├── Parsing/
│   │   ├── LaunchctlListParser.swift   # TSV parser for `launchctl list`
│   │   ├── LaunchctlPrintParser.swift  # Key-value block parser for `launchctl print`
│   │   ├── LaunchctlDisabledParser.swift
│   │   └── ScheduleFormatter.swift     # "Every hour", "Daily at 12:00", etc.
│   └── Views/
│       ├── ContentView.swift           # Two-column HSplitView layout
│       ├── ServiceListView.swift       # Left column: filterable service list
│       ├── ServiceRow.swift            # Row: Name, label, status indicator, ACTIVE/DISABLED
│       ├── StatusIndicator.swift       # Green circle (active) / gray X circle (disabled)
│       ├── DetailPanelView.swift       # Right column: top/bottom vertical split
│       ├── ServiceStatusView.swift     # Top-right: info, metadata, schedule, status, commands
│       ├── PlistInspectorView.swift    # Bottom-right: tabbed plist viewer (Tree | Source)
│       ├── PlistTreeView.swift        # Tree tab: hierarchical OutlineGroup/DisclosureGroup view
│       └── PlistSourceView.swift      # Source tab: raw XML in monospaced selectable text
```

### Data Flow

```
PlistReader (disk) ──┐
                     ├──▶ ServiceRepository (actor) ──▶ AppState (@Observable, @MainActor) ──▶ Views
LaunchctlClient ─────┘        merges data                 holds services, selection, filters
  (read-only queries)

CommandGenerator (pure string builder, never executes) ──▶ ServiceStatusView (copy-to-clipboard)
```

### Key Design Decisions

1. **Read-only safety** — the app only runs `launchctl list`, `launchctl print`, and `launchctl print-disabled`. It never runs `kickstart`, `bootout`, `bootstrap`, `enable`, `disable`, or any mutating command. Actions are shown as copyable command strings.
2. **`CommandGenerator`** — pure function that takes a service label + domain and returns command strings like `launchctl kickstart gui/501/com.example.service`. Each command has a copy button. Never executed by the app.
3. **`AppState`** is `@MainActor @Observable` — single source of truth for all UI state
4. **`ServiceRepository`** is an `actor` — protects concurrent refresh operations
5. **Parsers** are pure static functions — unit-testable with captured output fixtures
6. **`[String: Any]` plist data** — convert to a recursive `Sendable` enum (`PlistValue`) to cross isolation boundaries safely under Swift 6
7. **Refresh strategy** — manual (Cmd+R) + auto on window focus

### UI Layout

Two-column layout matching the mockup:

```
┌─────────────────────────────┬────────────────────────────────────────┐
│  [Search field           ]  │                                        │
│                             │   Service status                       │
│  ▼ User Agents (12)        │                                        │
│  ┌────────────────────────┐ │   Info, metadata, schedule, status     │
│  │ Name  com.unique.id    │ │   Copyable launchctl commands          │
│  │       ● ACTIVE         │ │                                        │
│  ├────────────────────────┤ │                                        │
│  │ Name  com.inactive.task│ ├────────────────────────────────────────┤
│  │       ⊘ DISABLED       │ │                                        │
│  └────────────────────────┘ │   Plist inspector                      │
│  ▶ System Agents (3)       │   Plist inspector  [Tree] [Source]      │
│  ▶ System Daemons (6)      │                                        │
│  ▶ Apple Agents (180)      │   ▼ ProgramArguments   Array(3)        │
│  ▶ Apple Daemons (300)     │     0: "/usr/bin/keybase"               │
│                             │     1: "-d"                             │
│                             │   ▶ EnvironmentVariables  Dict(3)      │
│                             │   KeepAlive: true                       │
│                             │                                        │
└─────────────────────────────┴────────────────────────────────────────┘
```

- **Left column**: Scrollable service list grouped by source (User Agents, System Agents, System Daemons, Apple Agents, Apple Daemons) as **collapsible `DisclosureGroup` sections**. Each row shows the service label, a status indicator (green circle = ACTIVE, gray circle-X = DISABLED), and the status text. Includes a search/filter field at the top.
- **Right column, top half**: Service status panel — info, metadata (program, PID, source), schedule in human-readable form, copyable `launchctl` commands.
- **Right column, bottom half**: Plist inspector — tabbed view with two tabs:
  - **Tree** (default): Hierarchical view using recursive `DisclosureGroup`. Dictionary keys are expandable nodes, scalar values (strings, numbers, booleans, dates) are leaves shown inline. Arrays show index-based children. Uses the `PlistValue` enum (already needed for `Sendable` crossing) to model the tree. Each node shows the key name, value type badge, and value preview.
  - **Source**: Raw plist XML in a monospaced, selectable `Text` view. Generated via `PropertyListSerialization.data(fromPropertyList:format:.xml)`.

Uses `HSplitView` for the left/right split and `VSplitView` for the top/bottom split on the right side, giving the user resizable panes.

Status indicators:
- `●` green = **Running** — PID present, actively executing
- `●` blue = **Waiting** — loaded, idle, will fire on schedule/trigger (calendar interval, watch path, etc.)
- `●` gray = **Stopped** — loaded, exited cleanly (exit 0), no pending trigger
- `●` red = **Error** — loaded, exited with non-zero code (e.g. 78: EX_CONFIG). Show code + reason
- `●` orange = **Killed** — loaded, terminated by signal (e.g. -9: SIGKILL, -15: SIGTERM). Show signal name
- `⊘` gray slash = **Disabled** — explicitly disabled via `launchctl disable` (from `print-disabled` output)
- `○` dim outline = **Not Loaded** — plist exists on disk but service not bootstrapped into launchd

### Copyable Commands in Service Status Panel

The service status view includes copyable `launchctl` commands:

```
Commands
  Start    launchctl kickstart gui/501/keybase.service  [copy]
  Stop     launchctl bootout gui/501/keybase.service    [copy]
  Enable   launchctl enable gui/501/keybase.service     [copy]
  Disable  launchctl disable gui/501/keybase.service    [copy]

  System daemons: prefix with sudo
```

## Implementation Phases

### Phase 1: Data Layer
1. `Package.swift` (swift-tools-version: 6.0, macOS 15, executable target)
2. Models: `LaunchdService`, `ServiceSource`, `ServiceStatus`, `ServiceSchedule`
3. `ShellExecutor` — async `Process` wrapper (read-only)
4. Parsers: `LaunchctlListParser`, `LaunchctlDisabledParser`, `LaunchctlPrintParser`, `ScheduleFormatter`
5. `PlistReader` — read plists via `PropertyListSerialization`
6. `LaunchctlClient` — wire parsers to read-only shell commands
7. `ServiceRepository` — merge all data sources

### Phase 2: UI
8. `LaunchDUIApp.swift` + `ContentView.swift` — app entry + HSplitView/VSplitView layout
9. `AppState.swift` — observable state
10. `ServiceListView` + `ServiceRow` + `StatusIndicator` — left column
11. `DetailPanelView` + `ServiceStatusView` — right top
12. `PlistInspectorView` — right bottom
13. `CommandGenerator` — copyable command strings in the status view

### Phase 3: Polish
14. Auto-refresh on window focus
15. Keyboard shortcut (Cmd+R for refresh)
16. Search/filter in the service list
17. Error handling (non-modal banners for read failures)

## Verification

1. `swift build` — must compile without errors
2. `swift run LaunchDUI` — launches the app window
3. Service list shows real services with correct status indicators (green/gray)
4. Selecting a service populates the right panels
5. Service status panel shows info, metadata, schedule, and copyable commands
6. Plist inspector shows formatted plist content
7. Search filters the list correctly
8. **Verify no mutating commands are ever executed** — grep codebase for kickstart/bootout/bootstrap/enable/disable and confirm they only appear in `CommandGenerator` string literals
