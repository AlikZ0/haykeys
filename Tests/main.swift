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

var state = KeyboardState()
expect(state.output(for: "ա") == "ա", "Lowercase by default")
state.tapShift(at: 100)
expect(state.shift == .once && state.output(for: "ա") == "Ա", "One-shot Shift")
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
