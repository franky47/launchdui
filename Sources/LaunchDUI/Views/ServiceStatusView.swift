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
            HStack(spacing: 6) {
                Text(service.label)
                    .font(.headline)
                    .textSelection(.enabled)

                Spacer()

                StatusIndicator(status: service.status)
                Text(service.status.displayName)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(service.status.statusColor)
            }

            Text(service.source.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Info")

            MetadataRow(label: "Plist", value: service.plistPath)

            if let program = service.program {
                MetadataRow(label: "Program", value: program)
            }

            if let args = service.programArguments, args.count > 1 {
                MetadataRow(label: "Arguments", value: args.dropFirst().joined(separator: "\n"))
            }

            if case .running(let pid) = service.status {
                MetadataRow(label: "PID", value: String(pid))
            }

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
            Label(
                ScheduleFormatter.format(service.schedule),
                systemImage: ScheduleFilter.from(service.schedule).icon
            )
            .font(.callout)
            .textSelection(.enabled)
        }
    }

    private var commandsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeader(title: "Commands")
                Spacer()
                if service.source.requiresSudo {
                    Text("Requires sudo (system daemon)")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }

            let cmds = CommandGenerator.commands(for: service.label, source: service.source, plistPath: service.plistPath)

            CommandRow(action: "Start", command: cmds.start)
            CommandRow(action: "Stop", command: cmds.stop)
            CommandRow(action: "Enable", command: cmds.enable)
            CommandRow(action: "Disable", command: cmds.disable)
            CommandRow(action: "Remove", command: cmds.remove, actionColor: .red)
        }
    }
}

// MARK: - Supporting Views

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.callout)
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
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .trailing)

            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
        }
    }
}

private struct CommandRow: View {
    let action: String
    let command: String
    var actionColor: Color = .secondary

    var body: some View {
        HStack(spacing: 8) {
            Text(action)
                .font(.subheadline)
                .foregroundStyle(actionColor)
                .frame(width: 55, alignment: .trailing)

            HStack(spacing: 0) {
                Text(command)
                    .font(.system(.subheadline, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(1)

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Copy to clipboard")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
