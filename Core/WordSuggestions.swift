import Foundation

/// Small, bundled prefix dictionary. No learning, logging, network or autocorrection.
enum WordSuggestions {
    static let words = [
        "բարև", "բարեւ", "բարի", "բարեկամ", "բարեկամություն",
        "շնորհակալություն", "շնորհակալութիւն", "շնորհավոր", "շնորհաւոր", "շնորհք",
        "հայերեն", "հայերէն", "Հայաստան", "հայկական", "Երևան", "Երեւան",
        "այո", "ոչ", "իհարկե", "խնդրում", "ներողություն", "ներողութիւն",
        "ողջույն", "ողջոյն", "ինչպես", "ինչպէս", "լավ", "լաւ", "շատ",
        "այսօր", "վաղը", "երեկ", "երեկո", "առավոտ", "գիշեր", "հիմա",
        "աշխատանք", "աշխատում", "ժամանակ", "հանդիպում", "հեռախոս", "ընկեր",
        "ընտանիք", "տուն", "սիրում", "սիրելի", "հաջողություն", "հաջողութիւն",
        "կարող", "կարողություն", "պատասխան", "նամակ", "հարց", "գրել", "ուղարկել"
    ]

    static func currentPrefix(in context: String?) -> String {
        guard let context else { return "" }
        let reversed = context.reversed().prefix(48).prefix { character in
            character.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
        }
        return String(reversed.reversed())
    }

    static func matches(in context: String?, limit: Int = 3) -> [String] {
        let prefix = currentPrefix(in: context)
        guard prefix.count >= 2, limit > 0 else { return [] }
        return words.filter { $0.lowercased().hasPrefix(prefix.lowercased()) }
            .prefix(limit).map { word in
                if prefix == prefix.uppercased() { return word.uppercased() }
                if let first = prefix.first,
                   String(first) == String(first).uppercased() {
                    return String(word.prefix(1)).uppercased() + String(word.dropFirst())
                }
                return word
            }
    }

    /// Insert only the missing suffix; do not delete or replace the user's prefix.
    static func suffix(for candidate: String, context: String?) -> String? {
        let prefix = currentPrefix(in: context)
        guard prefix.count >= 2, candidate.lowercased().hasPrefix(prefix.lowercased()) else {
            return nil
        }
        return String(candidate.dropFirst(prefix.count)) + " "
    }
}
