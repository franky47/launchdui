import SwiftUI

/// A single row in the service list showing label, display name, and status.
struct ServiceRow: View {
    let service: LaunchdService
    var isPinned: Bool = false
    var isUnread: Bool = false

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
                HStack(spacing: 6) {
                    Text(service.displayName)
                        .font(.callout)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    if isUnread {
                        NewBadge()
                    }
                }

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
                HStack(spacing: 6) {
                    Text(service.displayName)
                        .font(.callout)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    if isUnread {
                        NewBadge()
                    }
                }
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

/// Small rounded pill rendered next to the display name when a service is
/// in the discovery inbox (unread). Styling is deliberately neutral —
/// novelty, not danger.
private struct NewBadge: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("new")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(
                Capsule().fill(backgroundColor)
            )
            .overlay(
                Capsule().stroke(Color.secondary.opacity(0.4), lineWidth: 1)
            )
            .accessibilityLabel("New")
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.04)
    }
}
