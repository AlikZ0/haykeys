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

    /// A local emoji panel: no dependency on the user's enabled system keyboards.
    static let emojiRows: [[String]] = [
        ["😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣"],
        ["😊", "😍", "🥰", "😘", "😎", "🤔", "😢", "😭"],
        ["👍", "👎", "👏", "🙌", "🙏", "💪", "👋", "🤝"],
        ["❤️", "💙", "🔥", "✨", "🎉", "✅"]
    ]

    static func rows(for page: KeyboardPage) -> [[String]] {
        switch page {
        case .letters: return letterRows
        case .numbers: return numberRows
        case .symbols: return symbolRows
        case .emoji: return emojiRows
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
    var suggestionHeight: Double { 0 }
    var bottomInset: Double { landscape ? 4 : 6 }
    var fontSize: Double { landscape ? 21 : (narrow ? 20 : 22) }
    var preferredHeight: Double { 5 * keyHeight + 4 * rowGap + bottomInset }
    var keyWidth: Double { max(0, (width - 2 * sideInset - 11 * keyGap) / 12) }

    func inset(for keyCount: Int) -> Double {
        max(0, Double(12 - keyCount) * (keyWidth + keyGap) / 2)
    }
}
