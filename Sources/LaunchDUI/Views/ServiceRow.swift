import SwiftUI

/// A single row in the service list showing label, display name, and status.
struct ServiceRow: View {
    let service: LaunchdService
    var isPinned: Bool = false

    var body: some View {
        if isPinned {
            pinnedLayout
        } else {
            defaultLayout
        }
    }

    private var defaultLayout: some View {
        HStack(spacing: 8) {
            StatusIndicator(status: service.status)

            VStack(alignment: .leading, spacing: 2) {
                Text(service.displayName)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(service.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(service.status.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(service.status.statusColor)
        }
        .padding(.vertical, 2)
    }

    private var pinnedLayout: some View {
        HStack(spacing: 8) {
            VStack(alignment: .center, spacing: 0) {
                StatusIndicator(status: service.status)
                    .frame(height: pinnedLineHeight)
                Image(systemName: "pin.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .frame(height: pinnedLineHeight)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(service.displayName)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .frame(height: pinnedLineHeight)

                Text(service.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(height: pinnedLineHeight)
            }

            Spacer()

            Text(service.status.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(service.status.statusColor)
        }
        .padding(.vertical, 2)
    }

    private var pinnedLineHeight: CGFloat { 20 }
}
