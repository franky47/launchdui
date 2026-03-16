import SwiftUI

/// Raw XML source view of plist contents.
struct PlistSourceView: View {
    let value: PlistValue

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Text(xmlSource)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var xmlSource: String {
        (try? PlistReader.xmlSource(for: value)) ?? "Unable to generate XML"
    }
}
