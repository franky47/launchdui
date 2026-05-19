import SwiftUI

/// `markAllRead` ignores any active search — clearing the inbox is unambiguous
/// and always returns the header to zero.
struct InboxHeaderView: View {
    let unreadCount: Int
    let markAllRead: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(countText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            FilterChip(
                label: "Mark all as read",
                count: unreadCount,
                color: .secondary,
                icon: "eye",
                isActive: false,
                action: markAllRead
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }

    private var countText: String {
        unreadCount == 1
            ? "1 new service discovered"
            : "\(unreadCount) new services discovered"
    }
}
