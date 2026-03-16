import SwiftUI

/// Hierarchical tree view of plist contents using recursive DisclosureGroup.
struct PlistTreeView: View {
    let value: PlistValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                switch value {
                case .dictionary(let entries):
                    ForEach(entries, id: \.key) { entry in
                        PlistNodeView(key: entry.key, value: entry.value)
                    }
                case .array(let items):
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        PlistNodeView(key: String(index), value: item)
                    }
                default:
                    PlistLeafView(key: nil, value: value)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// A single node in the plist tree — either expandable (dict/array) or a leaf.
private struct PlistNodeView: View {
    let key: String
    let value: PlistValue

    var body: some View {
        switch value {
        case .dictionary(let entries):
            DisclosureGroup {
                ForEach(entries, id: \.key) { entry in
                    PlistNodeView(key: entry.key, value: entry.value)
                }
            } label: {
                nodeLabel
            }
        case .array(let items):
            DisclosureGroup {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    PlistNodeView(key: String(index), value: item)
                }
            } label: {
                nodeLabel
            }
        default:
            PlistLeafView(key: key, value: value)
        }
    }

    private var nodeLabel: some View {
        HStack(spacing: 6) {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)

            Text(value.typeLabel)
                .font(.caption2)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }
}

/// A leaf value in the plist tree.
private struct PlistLeafView: View {
    let key: String?
    let value: PlistValue

    var body: some View {
        HStack(spacing: 6) {
            if let key {
                Text(key)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if let preview = value.preview {
                Text(preview)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(valueColor)
                    .textSelection(.enabled)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 1)
    }

    private var valueColor: Color {
        switch value {
        case .bool: .orange
        case .integer, .real: .blue
        case .string: .primary
        case .date: .purple
        case .data: .gray
        default: .primary
        }
    }
}
