import Foundation

enum Language: String, Codable, CaseIterable, Sendable {
    case en
    case ko

    static func detect(from text: String) -> Language {
        for scalar in text.unicodeScalars {
            if Self.isHangul(scalar) {
                return .ko
            }
        }
        return .en
    }

    private static func isHangul(_ scalar: Unicode.Scalar) -> Bool {
        let value = scalar.value
        return (0xAC00...0xD7A3).contains(value)
            || (0x1100...0x11FF).contains(value)
            || (0x3130...0x318F).contains(value)
            || (0xA960...0xA97F).contains(value)
            || (0xD7B0...0xD7FF).contains(value)
    }
}
