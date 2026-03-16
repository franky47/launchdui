import SwiftUI

/// A single row in the service list showing label, display name, and status.
struct ServiceRow: View {
    let service: LaunchdService

    var body: some View {
        HStack(spacing: 8) {
            StatusIndicator(status: service.status)

            VStack(alignment: .leading, spacing: 2) {
                Text(service.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(service.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(service.status.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(service.status.statusColor)
        }
        .padding(.vertical, 2)
    }
}
