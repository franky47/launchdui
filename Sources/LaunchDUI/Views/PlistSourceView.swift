import SwiftUI

/// Raw XML source view of plist contents with syntax highlighting.
struct PlistSourceView: View {
    let value: PlistValue

    var body: some View {
        GeometryReader { geo in
            ScrollView([.horizontal, .vertical]) {
                Text(highlightedXML)
                    .font(.system(.subheadline, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
                    .frame(minWidth: geo.size.width, minHeight: geo.size.height, alignment: .topLeading)
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
    }

    private var highlightedXML: AttributedString {
        let xml = (try? PlistReader.xmlSource(for: value)) ?? "Unable to generate XML"
        return XMLHighlighter.highlight(xml)
    }
}

/// Simple XML syntax highlighter producing an AttributedString.
private enum XMLHighlighter {
    static let tagColor = Color(nsColor: .systemPink)
    static let attrKeyColor = Color(nsColor: .systemOrange)
    static let attrValueColor = Color(nsColor: .systemRed)
    static let stringColor = Color.primary
    static let commentColor = Color.gray
    static let defaultColor = Color.primary

    static func highlight(_ xml: String) -> AttributedString {
        var result = AttributedString()
        var i = xml.startIndex

        while i < xml.endIndex {
            if xml[i] == "<" {
                if xml[i...].hasPrefix("<!--") {
                    // Comment
                    let end = xml.range(of: "-->", range: i..<xml.endIndex)?.upperBound ?? xml.endIndex
                    result += styled(String(xml[i..<end]), color: commentColor)
                    i = end
                } else if xml[i...].hasPrefix("<?") {
                    // Processing instruction
                    let end = xml.range(of: "?>", range: i..<xml.endIndex)?.upperBound ?? xml.endIndex
                    result += highlightTag(String(xml[i..<end]))
                    i = end
                } else if xml[i...].hasPrefix("<!") {
                    // DOCTYPE or similar
                    let end = xml.range(of: ">", range: i..<xml.endIndex)?.upperBound ?? xml.endIndex
                    result += styled(String(xml[i..<end]), color: commentColor)
                    i = end
                } else {
                    // Regular tag
                    let end = xml.range(of: ">", range: i..<xml.endIndex)?.upperBound ?? xml.endIndex
                    result += highlightTag(String(xml[i..<end]))
                    i = end
                }
            } else {
                // Text content until next tag
                let end = xml[i...].firstIndex(of: "<") ?? xml.endIndex
                let text = String(xml[i..<end])
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    result += AttributedString(text)
                } else {
                    result += styled(text, color: stringColor)
                }
                i = end
            }
        }

        return result
    }

    private static func highlightTag(_ tag: String) -> AttributedString {
        var result = AttributedString()

        // Find the tag name boundary
        let chars = Array(tag)
        var idx = 0

        // Opening: < or </ or <?
        var bracketPrefix = "<"
        if tag.hasPrefix("</") { bracketPrefix = "</" }
        else if tag.hasPrefix("<?") { bracketPrefix = "<?" }
        idx = bracketPrefix.count

        result += styled(bracketPrefix, color: tagColor)

        // Tag name
        var name = ""
        while idx < chars.count && chars[idx] != " " && chars[idx] != ">" && chars[idx] != "/" && chars[idx] != "?" {
            name.append(chars[idx])
            idx += 1
        }
        result += styled(name, color: tagColor)

        // Remainder: attributes and closing bracket
        while idx < chars.count {
            let ch = chars[idx]

            if ch == "\"" {
                // Attribute value
                var value = "\""
                idx += 1
                while idx < chars.count && chars[idx] != "\"" {
                    value.append(chars[idx])
                    idx += 1
                }
                if idx < chars.count {
                    value.append(chars[idx]) // closing quote
                    idx += 1
                }
                result += styled(value, color: attrValueColor)
            } else if ch == "=" {
                result += styled("=", color: defaultColor)
                idx += 1
            } else if ch == ">" || ch == "/" || ch == "?" {
                // Closing brackets
                var closing = String(ch)
                idx += 1
                while idx < chars.count {
                    closing.append(chars[idx])
                    idx += 1
                }
                result += styled(closing, color: tagColor)
            } else if ch == " " || ch == "\t" || ch == "\n" {
                result += AttributedString(String(ch))
                idx += 1
            } else {
                // Attribute name
                var attrName = ""
                while idx < chars.count && chars[idx] != "=" && chars[idx] != " " && chars[idx] != ">" {
                    attrName.append(chars[idx])
                    idx += 1
                }
                result += styled(attrName, color: attrKeyColor)
            }
        }

        return result
    }

    private static func styled(_ text: String, color: Color) -> AttributedString {
        var s = AttributedString(text)
        s.foregroundColor = color
        return s
    }
}
