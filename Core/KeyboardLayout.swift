import Foundation

/// Letter positions and the punctuation row follow the user's latest photo.
enum KeyboardLayout {
    /// A permanent key in the first row, replacing the hyphen.
    static let ligature = "և"

    static let letterRows: [[String]] = [
        ["՝", "։", "ձ", "յ", "՛", ",", "և", "«", "»", "օ", "ռ", "ժ"],
        ["խ", "վ", "է", "ր", "դ", "ե", "ը", "ի", "ո", "բ", "չ", "ջ"],
        ["ա", "ս", "տ", "ֆ", "կ", "հ", "ճ", "ք", "լ", "թ", "փ"],
        ["զ", "ց", "գ", "ւ", "պ", "ն", "մ", "շ", "ղ", "ծ"]
    ]

    static let numberRows: [[String]] = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "/"],
        [":", ";", "(", ")", "֏", "$", "&", "@", "\"", "'", "+", "="],
        [".", ",", "?", "!", "[", "]", "{", "}", "«", "»", "%"],
        ["՝", "։", "՛", "՜", "՞", "…", "_", "\\", "€", "₽"]
    ]

    static let symbolRows: [[String]] = [
        ["[", "]", "{", "}", "#", "%", "^", "*", "+", "=", "_", "\\"],
        ["|", "~", "<", ">", "€", "£", "¥", "֏", "₽", "$", "&", "@"],
        ["©", "®", "™", "°", "§", "±", "×", "÷", "•", "…", "№"],
        ["«", "»", "“", "”", "‘", "’", "՝", "։", "՜", "՞"]
    ]

    static func rows(for page: KeyboardPage) -> [[String]] {
        switch page {
        case .letters: return letterRows
        case .numbers: return numberRows
        case .symbols: return symbolRows
        }
    }
}

/// Shared sizing rules; kept free of UIKit so row alignment can be checked on CI.
struct KeyboardGeometry {
    let width: Double
    let landscape: Bool

    var narrow: Bool { width < 350 }
    var sideInset: Double { 6 }
    var keyGap: Double { landscape ? 6 : (narrow ? 4 : 5) }
    var rowGap: Double { 6 }
    var keyHeight: Double { landscape ? 30 : 38 }
    var topInset: Double { landscape ? 8 : 16 }
    var bottomInset: Double { 0 }
    var fontSize: Double { landscape ? 21 : (narrow ? 20 : 22) }
    var preferredHeight: Double { topInset + 5 * keyHeight + 4 * rowGap + bottomInset }
    var keyWidth: Double { max(0, (width - 2 * sideInset - 11 * keyGap) / 12) }

    func inset(for keyCount: Int) -> Double {
        max(0, Double(12 - keyCount) * (keyWidth + keyGap) / 2)
    }
}
