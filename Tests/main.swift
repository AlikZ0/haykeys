import Foundation

var assertions = 0
func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    assertions += 1
    if !condition() { fatalError("FAIL: \(message)") }
}

let letters = KeyboardLayout.letterRows.flatMap { $0 }.filter {
    $0 != KeyboardLayout.ligature && $0.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
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
expect(KeyboardLayout.letterRows[0] == ["՝", "։", "ձ", "յ", "՛", ",", "և", "«", "»", "օ", "ռ", "ժ"], "Punctuation follows the latest reference photo")
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
expect(KeyboardGeometry(width: 402, landscape: false).preferredHeight == 230, "No suggestion bar or extra utility footer on a modern iPhone")
expect(KeyboardGeometry(width: 320, landscape: false).preferredHeight == 230, "Compact iPhone layout")
expect(KeyboardGeometry(width: 874, landscape: true).preferredHeight == 182, "Landscape layout")

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
expect(KeyboardLayout.letterRows[0][6] == "և", "և replaces the first-row hyphen")
expect(KeyboardLayout.rows(for: .numbers).flatMap { $0 }.contains("-"), "Hyphen still available on numbers page")
// An explicit top gutter prevents the first row from entering the rounded cap.
for (width, landscape) in [(320.0, false), (402.0, false), (720.0, true)] {
    let layout = KeyboardGeometry(width: width, landscape: landscape)
    expect(layout.topInset >= 8, "Top row has breathing room in each orientation")
    expect(layout.bottomInset == 0, "Extension does not add an extra bottom footer")
    let keyArea = layout.preferredHeight - layout.topInset - layout.bottomInset
    expect(keyArea == 5 * layout.keyHeight + 4 * layout.rowGap, "Vertical budget fits all five rows without stretching")
}

var history = ClipboardHistory()
for number in 0..<105 { history.add("value \(number)") }
expect(history.entries.count == 100, "History is bounded to 100 texts")
expect(history.entries.first?.text == "value 104" && history.entries.last?.text == "value 5", "Newest first, oldest entries removed")
history.add("value 10")
expect(history.entries.first?.text == "value 10" && history.entries.count == 100, "Duplicate moves to front without growing history")
let exactText = "  Բարև և 👨‍👩‍👧‍👦\nsecond line  "
history.add(exactText)
expect(history.entries.first?.text == exactText, "History preserves spaces, newlines and Unicode")
history.add("  \n")
expect(history.entries.first?.text == exactText, "Empty clipboard text is ignored")
let encoded = try JSONEncoder().encode(history)
let decoded = try JSONDecoder().decode(ClipboardHistory.self, from: encoded)
expect(decoded.entries == history.entries, "History survives a persistence round trip")
let removed = history.entries[0].id
history.remove(id: removed)
expect(history.entries.count == 99 && !history.entries.contains(where: { $0.id == removed }), "Delete one entry")
history.clear()
expect(history.entries.isEmpty, "Clear all entries")
expect(KeyboardSettings.soundEnabled(stored: nil), "Clicks are enabled on a fresh keyboard installation")
expect(!KeyboardSettings.soundEnabled(stored: false), "Explicit mute persists")
expect(KeyboardSettings.soundEnabled(stored: true), "Sound can be enabled again")
for enabled in [true, false] {
    let request = SoundSettingsRequest(enabled: enabled)
    expect(SoundSettingsRequest.parse(request.payload) == request, "Sound transaction round-trip")
    expect(SoundSettingsRequest.parse(request.acknowledgement) == nil, "Acknowledgement cannot be reapplied as a request")
    expect(SoundSettingsRequest.parse(request.payload + "typing") == nil, "Ordinary surrounding text is never parsed as settings")
}
expect(SoundSettingsRequest.parse("~HayKeys.Sound.v1|invalid|1~") == nil, "Reject invalid nonce")
expect(SoundSettingsRequest.parse("hello") == nil, "Normal user text is unaffected")
expect(SoundSettingsRequest.parse("~HayKeys.Sound.v1|00000000-0000-0000-0000-000000000000|2~") == nil, "Reject invalid boolean")
var renderCache = KeyboardRenderCache()
let baseline = KeyboardRenderSnapshot(page: .letters, shift: .off, theme: .dark)
let initialRender = renderCache.update(baseline)
expect(initialRender.labels && initialRender.colors && initialRender.shift, "Initial keyboard draws all artwork")
var redundantArtworkUpdates = 0
for _ in 0..<1000 {
    let changes = renderCache.update(baseline)
    if changes.labels || changes.colors || changes.shift { redundantArtworkUpdates += 1 }
}
expect(redundantArtworkUpdates == 0, "1000 unchanged text callbacks require zero key-artwork passes")
let shiftChange = renderCache.update(KeyboardRenderSnapshot(page: .letters, shift: .once, theme: .dark))
expect(shiftChange.labels && shiftChange.shift && !shiftChange.colors, "Shift updates labels and icon without recoloring all keys")
let consumedShift = renderCache.update(baseline)
expect(consumedShift.labels && consumedShift.shift, "One-shot Shift consumption returns labels to lowercase")
let lightChange = renderCache.update(KeyboardRenderSnapshot(page: .letters, shift: .off, theme: .light))
expect(lightChange.colors && !lightChange.labels && !lightChange.shift, "Theme transition recolors without replacing labels or Shift image")
renderCache.reset()
let rebuilt = renderCache.update(baseline)
expect(rebuilt.labels && rebuilt.colors && rebuilt.shift, "Rebuilt keys receive complete artwork")
print("PASS: \(assertions) core checks")
