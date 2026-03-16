import SwiftUI

/// Color-coded status indicator for a launchd service.
struct StatusIndicator: View {
    let status: ServiceStatus

    var body: some View {
        switch status.indicatorStyle {
        case .filled:
            Image(systemName: "circle.fill")
                .foregroundStyle(status.statusColor)
                .font(.system(size: 8))
        case .slashed:
            Image(systemName: "circle.slash")
                .foregroundStyle(status.statusColor)
                .font(.system(size: 10))
        case .outline:
            Image(systemName: "circle")
                .foregroundStyle(status.statusColor.opacity(0.5))
                .font(.system(size: 8))
        }
    }
}
