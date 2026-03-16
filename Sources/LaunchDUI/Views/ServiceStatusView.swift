import SwiftUI

/// Top-right panel: service info, metadata, schedule, and copyable commands.
struct ServiceStatusView: View {
    let service: LaunchdService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                metadataSection
                scheduleSection
                commandsSection
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                StatusIndicator(status: service.status)
                Text(service.status.displayName)
                    .font(.headline)
                    .foregroundStyle(service.status.statusColor)
            }

            Text(service.label)
                .font(.title3)
                .fontWeight(.semibold)
                .textSelection(.enabled)

            Text(service.source.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Info")

            if let program = service.program {
                MetadataRow(label: "Program", value: program)
            }

            if let args = service.programArguments, !args.isEmpty {
                MetadataRow(label: "Arguments", value: args.joined(separator: " "))
            }

            if case .running(let pid) = service.status {
                MetadataRow(label: "PID", value: String(pid))
            }

            MetadataRow(label: "Plist", value: service.plistPath)

            if let detail = service.detailedInfo {
                ForEach(Array(detail.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                    MetadataRow(label: key, value: value)
                }
            }
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Schedule")
            Text(ScheduleFormatter.format(service.schedule))
                .font(.body)
        }
    }

    private var commandsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Commands")

            let cmds = CommandGenerator.commands(for: service.label, source: service.source)

            CommandRow(action: "Start", command: cmds.start)
            CommandRow(action: "Stop", command: cmds.stop)
            CommandRow(action: "Enable", command: cmds.enable)
            CommandRow(action: "Disable", command: cmds.disable)

            if service.source.requiresSudo {
                Text("Requires sudo (system daemon)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}

// MARK: - Supporting Views

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }
}

private struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)

            Text(value)
                .font(.caption)
                .textSelection(.enabled)
                .lineLimit(3)
        }
    }
}

private struct CommandRow: View {
    let action: String
    let command: String

    var body: some View {
        HStack(spacing: 8) {
            Text(action)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)

            Text(command)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(1)

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(command, forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Copy to clipboard")
        }
    }
}
