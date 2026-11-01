import Foundation

var assertions = 0
func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    assertions += 1
    if !condition() { fatalError("FAIL: \(message)") }
}

let letters = KeyboardLayout.letterRows.flatMap { $0 }.filter {
    $0.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
}
let alphabet = Set(Array("աբգդեզէըթժիլխծկհձղճմյնշոչպջռսվտրցւփքօֆ").map(String.init))
expect(letters.count == 38, "The reference layout has 38 separate Armenian letters")
expect(Set(letters) == alphabet, "Every Armenian letter appears, including ւ, օ, ֆ")
expect(Set(letters).count == letters.count, "No duplicate letter positions")
expect(KeyboardLayout.letterRows.map(\.count) == [12, 12, 11, 10], "Reference row sizes")
expect(KeyboardLayout.letterRows[1][9] == "բ", "Reference բ position")
expect(KeyboardLayout.letterRows[3][4] == "պ", "Reference պ position")
expect(KeyboardLayout.letterRows[1][10] == "չ", "Reference չ position")
expect(KeyboardLayout.letterRows[3][7] == "շ", "Reference շ position")
expect(KeyboardLayout.letterRows[0] == ["՝", "։", "ձ", "յ", "՛", ",", "-", "«", "»", "օ", "ռ", "ժ"], "Punctuation follows the latest reference photo")
expect(KeyboardLayout.ligature == "\u{0587}", "Dedicated և inserts the Armenian ligature, not Latin E")
expect(KeyboardLayout.letterRows[1][5] == "ե", "ե remains a normal visible key")
expect(KeyboardLayout.letterRows[1][2] == "է", "է remains distinct from ե")

for (width, landscape) in [(320.0, false), (375.0, false), (390.0, false), (402.0, false), (430.0, false), (667.0, true), (874.0, true)] {
    let geometry = KeyboardGeometry(width: width, landscape: landscape)
    expect(geometry.keyWidth >= 22, "Usable key width at \(width) points")
    let available = width - 2 * geometry.sideInset
    let middle = 11 * geometry.keyWidth + 10 * geometry.keyGap + 2 * geometry.inset(for: 11)
    expect(abs(available - middle) < 0.001, "Eleven-key row keeps the same key width and stays centered")
    expect(geometry.inset(for: 12) == 0, "Full-width rows need no spacer")
}
expect(KeyboardGeometry(width: 402, landscape: false).preferredHeight == 290, "No extra utility footer on a modern iPhone")
expect(KeyboardGeometry(width: 320, landscape: false).preferredHeight == 271, "Compact iPhone layout")
expect(KeyboardGeometry(width: 874, landscape: true).preferredHeight == 212, "Landscape layout")

// Regression: a field's light/default request must not override a dark interface.
expect(KeyboardTheme.resolve(interfaceIsDark: true, fieldRequestsDark: false) == .dark, "Dark interface wins over light/default field request")
expect(KeyboardTheme.resolve(interfaceIsDark: true, fieldRequestsDark: true) == .dark, "Both dark signals")
expect(KeyboardTheme.resolve(interfaceIsDark: false, fieldRequestsDark: true) == .dark, "Field requests dark inside light interface")
expect(KeyboardTheme.resolve(interfaceIsDark: false, fieldRequestsDark: false) == .light, "Light mode returns after leaving dark mode")

var state = KeyboardState()
expect(state.output(for: "ա") == "ա", "Lowercase by default")
expect(state.output(for: KeyboardLayout.ligature) == "և", "և stays available without Shift or suggestions")
state.tapShift(at: 100)
expect(state.shift == .once && state.output(for: "ա") == "Ա", "One-shot Shift")
expect(state.output(for: "ե") == "Ե", "Shift produces Armenian Ե")
state.didInsert("։")
expect(state.shift == .once, "Punctuation does not consume Shift")
state.didInsert("Ա")
expect(state.shift == .off, "A letter consumes one-shot Shift")
state.tapShift(at: 200)
state.tapShift(at: 200.2)
expect(state.shift == .locked, "A double tap enables Caps Lock")
state.didInsert("ԱԲ")
expect(state.shift == .locked, "Caps Lock survives letter input")
expect(state.output(for: "ու") == "ՈՒ", "Uppercase digraph")
state.tapShift(at: 201)
expect(state.shift == .off, "One tap disables Caps Lock")
state.tapShift(at: 202)
state.tapShift(at: 203)
expect(state.shift == .off, "Slow taps do not enable Caps Lock")
state.selectPage(.numbers)
state.tapShift(at: 204)
expect(state.shift == .off && state.page == .numbers, "Shift does not affect the number page")
expect(KeyboardLayout.rows(for: .numbers)[0].prefix(10).joined() == "1234567890", "All digits")
expect(KeyboardLayout.rows(for: .symbols).flatMap { $0 }.contains("֏"), "Dram symbol")

expect(WordSuggestions.currentPrefix(in: nil).isEmpty, "No document context is valid")
expect(WordSuggestions.currentPrefix(in: "բարև, շնոր") == "շնոր", "Prefix starts after punctuation")
expect(WordSuggestions.currentPrefix(in: "բարև ").isEmpty, "A space ends a prefix")
expect(WordSuggestions.matches(in: "շ").isEmpty, "No suggestions for one letter")
expect(WordSuggestions.matches(in: "շնոր").contains("շնորհակալություն"), "Bundled Armenian suggestion")
expect(WordSuggestions.matches(in: "Շնոր").contains("Շնորհակալություն"), "Title case completion")
expect(WordSuggestions.matches(in: "ՇՆՈՐ").contains("ՇՆՈՐՀԱԿԱԼՈՒԹՅՈՒՆ"), "Uppercase completion")
expect(WordSuggestions.matches(in: "շնոր", limit: 2).count == 2, "Suggestion limit")
expect(WordSuggestions.suffix(for: "շնորհակալություն", context: "շնոր") == "հակալություն ", "Append only the missing suffix")
expect(WordSuggestions.suffix(for: "շնորհակալություն", context: "բար") == nil, "Reject a stale suggestion after the cursor moves")
expect(WordSuggestions.suffix(for: "բարև", context: "բարև") == " ", "An exact match adds a space")
print("PASS: \(assertions) core checks")
