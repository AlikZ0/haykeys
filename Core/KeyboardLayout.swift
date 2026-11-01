import Foundation

/// Letter positions and the punctuation row follow the user's latest photo.
enum KeyboardLayout {
    /// A dedicated key in the bottom row, independent of the suggestion bar.
    static let ligature = "և"

    static let letterRows: [[String]] = [
        ["՝", "։", "ձ", "յ", "՛", ",", "-", "«", "»", "օ", "ռ", "ժ"],
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
    var rowGap: Double { landscape ? 6 : (narrow ? 7 : 8) }
    var keyHeight: Double { landscape ? 30 : (narrow ? 40 : 42) }
    var suggestionHeight: Double { landscape ? 28 : (narrow ? 30 : 34) }
    var bottomInset: Double { landscape ? 4 : 6 }
    var fontSize: Double { landscape ? 21 : (narrow ? 20 : 22) }
    var preferredHeight: Double { suggestionHeight + 5 * keyHeight + 5 * rowGap + bottomInset }
    var keyWidth: Double { max(0, (width - 2 * sideInset - 11 * keyGap) / 12) }

    func inset(for keyCount: Int) -> Double {
        max(0, Double(12 - keyCount) * (keyWidth + keyGap) / 2)
    }
}
