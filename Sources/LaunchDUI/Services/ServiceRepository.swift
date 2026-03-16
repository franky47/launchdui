import Foundation

/// Merges plist data from disk with runtime data from launchctl
/// to produce complete `LaunchdService` objects.
actor ServiceRepository {

    /// Load all services from plist directories and merge with runtime state.
    func loadAll() async throws -> [LaunchdService] {
        // Phase 1: Bulk data (fast)
        async let runtimeEntries = LaunchctlClient.listServices()
        async let disabledSet = LaunchctlClient.disabledServices()

        let entries = try await runtimeEntries
        let disabled = try await disabledSet

        // Build lookup tables
        let runtimeByLabel = Dictionary(
            entries.map { ($0.label, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // Phase 2: Read all plist files
        var services: [LaunchdService] = []
        for source in ServiceSource.allCases {
            let plists = discoverPlists(in: source.directory)
            for plistPath in plists {
                if let service = buildService(
                    plistPath: plistPath,
                    source: source,
                    runtime: runtimeByLabel,
                    disabled: disabled
                ) {
                    services.append(service)
                }
            }
        }

        return services.sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    /// Load detailed info for a single service (called when selected).
    func loadDetail(for service: LaunchdService) async -> LaunchdService {
        var updated = service
        do {
            let detail = try await LaunchctlClient.printService(
                label: service.label,
                domainTarget: service.source.domainTarget
            )
            updated.detailedInfo = detail
        } catch {
            // Non-fatal: some services may not support print
            updated.detailedInfo = ["error": error.localizedDescription]
        }
        return updated
    }

    // MARK: - Private

    private func discoverPlists(in directory: String) -> [String] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: directory) else {
            return []
        }
        return contents
            .filter { $0.hasSuffix(".plist") }
            .map { "\(directory)/\($0)" }
    }

    private func buildService(
        plistPath: String,
        source: ServiceSource,
        runtime: [String: LaunchctlListParser.Entry],
        disabled: Set<String>
    ) -> LaunchdService? {
        // Read the plist
        guard let dict = try? PlistReader.readDictionary(at: plistPath) else {
            return nil
        }

        guard let label = dict["Label"] as? String else {
            return nil
        }

        let schedule = PlistReader.extractSchedule(from: dict)
        let program = PlistReader.extractProgram(from: dict)
        let programArguments = dict["ProgramArguments"] as? [String]
        let plistContents = try? PlistReader.read(at: plistPath)

        // Determine status
        let status: ServiceStatus
        if disabled.contains(label) {
            status = .disabled
        } else if let entry = runtime[label] {
            status = deriveStatus(from: entry, schedule: schedule)
        } else {
            status = .notLoaded
        }

        return LaunchdService(
            label: label,
            source: source,
            plistPath: plistPath,
            status: status,
            program: program,
            programArguments: programArguments,
            schedule: schedule,
            plistContents: plistContents,
            detailedInfo: nil
        )
    }

    private func deriveStatus(from entry: LaunchctlListParser.Entry, schedule: ServiceSchedule) -> ServiceStatus {
        if let pid = entry.pid, pid > 0 {
            return .running(pid: pid)
        }

        let exitStatus = entry.lastExitStatus
        if exitStatus < 0 {
            // Negative exit status means killed by signal
            return .killed(signal: -exitStatus)
        }

        if exitStatus != 0 {
            return .error(exitCode: exitStatus)
        }

        // Exit status 0, not running — is it waiting or stopped?
        switch schedule {
        case .calendarInterval, .interval, .watchPaths, .keepAlive:
            return .waiting
        case .onDemand:
            return .stopped
        }
    }
}
