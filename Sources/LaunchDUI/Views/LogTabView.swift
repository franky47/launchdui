import SwiftUI

/// Displays the tail of a log file with live streaming, auto-scroll, and search.
struct LogTabView: View {
    let fileURL: URL
    @State private var lines: [String] = []
    @State private var loadError: String?
    @State private var isAtBottom = true
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            filePathHeader
            Divider()
            logContent
        }
        .task {
            await startTailing()
        }
    }

    private var filePathHeader: some View {
        HStack {
            Text(fileURL.path)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var logContent: some View {
        if let loadError {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
                Text(loadError)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                searchBar
                Divider()
                GeometryReader { geo in
                    ScrollViewReader { proxy in
                        ScrollView([.horizontal, .vertical]) {
                            Text(highlightedText)
                                .font(.system(.subheadline, design: .monospaced))
                                .textSelection(.enabled)
                                .padding()
                                .frame(minWidth: geo.size.width, minHeight: geo.size.height, alignment: .topLeading)

                            Color.clear.frame(height: 0).id("bottom")
                                .onAppear { isAtBottom = true }
                                .onDisappear { isAtBottom = false }
                        }
                        .onChange(of: lines) {
                            if isAtBottom {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.subheadline)
            TextField("Search logs", text: $searchText)
                .textFieldStyle(.plain)
                .font(.subheadline)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var highlightedText: AttributedString {
        let fullText = lines.joined(separator: "\n")
        guard !searchText.isEmpty else {
            return AttributedString(fullText)
        }

        var attributed = AttributedString(fullText)
        var searchStart = attributed.startIndex
        let end = attributed.endIndex

        while searchStart < end,
              let range = attributed[searchStart..<end].range(of: searchText, options: .caseInsensitive) {
            attributed[range].backgroundColor = .yellow.opacity(0.4)
            attributed[range].foregroundColor = .black
            searchStart = range.upperBound
        }

        return attributed
    }

    private func startTailing() async {
        let tailer = LogTailer(url: fileURL)
        do {
            let initial = try await Task.detached {
                try tailer.readTail()
            }.value

            lines = initial.lines

            for await newBatch in tailer.stream(from: initial.offset) {
                lines.append(contentsOf: newBatch)
                if lines.count > tailer.maxLines {
                    lines.removeFirst(lines.count - tailer.maxLines)
                }
            }
        } catch {
            loadError = error.localizedDescription
        }
    }
}
