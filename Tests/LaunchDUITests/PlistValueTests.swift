import Testing
import Foundation
@testable import LaunchdUI

@Suite("PlistValue")
struct PlistValueTests {

    @Test("Converts string")
    func convertsString() {
        let result = PlistValue.from("hello")
        #expect(result == .string("hello"))
    }

    @Test("Converts integer")
    func convertsInteger() {
        let result = PlistValue.from(NSNumber(value: 42))
        #expect(result == .integer(42))
    }

    @Test("Converts boolean true")
    func convertsBoolTrue() {
        let result = PlistValue.from(NSNumber(value: true))
        #expect(result == .bool(true))
    }

    @Test("Converts boolean false")
    func convertsBoolFalse() {
        let result = PlistValue.from(NSNumber(value: false))
        #expect(result == .bool(false))
    }

    @Test("Converts double")
    func convertsDouble() {
        let result = PlistValue.from(NSNumber(value: 3.14))
        #expect(result == .real(3.14))
    }

    @Test("Converts date")
    func convertsDate() {
        let date = Date(timeIntervalSince1970: 1000000)
        let result = PlistValue.from(date)
        #expect(result == .date(date))
    }

    @Test("Converts data")
    func convertsData() {
        let data = Data([0x01, 0x02, 0x03])
        let result = PlistValue.from(data)
        #expect(result == .data(data))
    }

    @Test("Converts array")
    func convertsArray() {
        let result = PlistValue.from(["a", "b"] as [Any])
        #expect(result == .array([.string("a"), .string("b")]))
    }

    @Test("Converts dictionary with sorted keys")
    func convertsDictionary() {
        let dict: [String: Any] = ["zebra": "z", "apple": "a"]
        let result = PlistValue.from(dict)
        #expect(result == .dictionary([
            (key: "apple", value: .string("a")),
            (key: "zebra", value: .string("z")),
        ]))
    }

    @Test("Converts nested structures")
    func convertsNested() {
        let dict: [String: Any] = [
            "args": ["/usr/bin/test", "-d"] as [Any],
            "keep": true,
        ]
        let result = PlistValue.from(dict)
        if case .dictionary(let entries) = result {
            #expect(entries.count == 2)
            #expect(entries[0].key == "args")
            #expect(entries[0].value == .array([.string("/usr/bin/test"), .string("-d")]))
            #expect(entries[1].key == "keep")
            #expect(entries[1].value == .bool(true))
        } else {
            Issue.record("Expected dictionary")
        }
    }

    @Test("Type labels are correct")
    func typeLabels() {
        #expect(PlistValue.string("x").typeLabel == "String")
        #expect(PlistValue.integer(1).typeLabel == "Number")
        #expect(PlistValue.real(1.0).typeLabel == "Real")
        #expect(PlistValue.bool(true).typeLabel == "Boolean")
        #expect(PlistValue.array([]).typeLabel == "Array(0)")
        #expect(PlistValue.dictionary([]).typeLabel == "Dict(0)")
    }

    @Test("Converts float to real, not integer")
    func convertsFloat() {
        // Float objCType is 'f' (0x66), not 'd' (0x64)
        // Bug: current code only checks for 'd', so Float falls through to .integer truncation
        let result = PlistValue.from(NSNumber(value: Float(3.14)))
        #expect(result == .real(Double(Float(3.14))))
    }

    @Test("Converts float whole number to real, not integer")
    func convertsFloatWholeNumber() {
        // Float(2.0) should be .real(2.0), not .integer(2)
        let result = PlistValue.from(NSNumber(value: Float(2.0)))
        #expect(result == .real(2.0))
    }

    @Test("Previews are correct")
    func previews() {
        #expect(PlistValue.string("hello").preview == "hello")
        #expect(PlistValue.integer(42).preview == "42")
        #expect(PlistValue.bool(true).preview == "true")
        #expect(PlistValue.array([]).preview == nil)
        #expect(PlistValue.dictionary([]).preview == nil)
    }
}
