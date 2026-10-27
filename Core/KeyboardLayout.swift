import Foundation

/// The positions are transcribed from the supplied screenshot, not phonetic QWERTY.
enum KeyboardLayout {
    static let letterRows: [[String]] = [
        ["՝", "։", "ձ", "յ", "-", "՛", "՜", "՞", ",", "օ", "ռ", "ժ"],
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
