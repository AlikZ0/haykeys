import Foundation

enum KeyboardPage: Equatable {
    case letters, numbers, symbols
}

enum ShiftMode: Equatable {
    case off, once, locked
}

struct KeyboardState {
    private(set) var page: KeyboardPage = .letters
    private(set) var shift: ShiftMode = .off
    private var lastShiftTap: TimeInterval?

    mutating func selectPage(_ newPage: KeyboardPage) {
        page = newPage
        lastShiftTap = nil
    }

    mutating func tapShift(at time: TimeInterval) {
        guard page == .letters else { return }
        if shift == .locked {
            shift = .off
            lastShiftTap = nil
        } else if shift == .once,
                  let previous = lastShiftTap,
                  (0...0.32).contains(time - previous) {
            shift = .locked
            lastShiftTap = nil
        } else {
            shift = shift == .off ? .once : .off
            lastShiftTap = time
        }
    }

    func output(for text: String) -> String {
        guard page == .letters, shift != .off else { return text }
        return text.uppercased()
    }

    mutating func didInsert(_ text: String) {
        lastShiftTap = nil
        if shift == .once, text.unicodeScalars.contains(where: { CharacterSet.letters.contains($0) }) {
            shift = .off
        }
    }
}

/// A field may request a light keyboard even while its surrounding UI is dark.
/// Keep the extension dark whenever the interface or the field requests dark.
enum KeyboardTheme: Equatable {
    case light, dark

    static func resolve(interfaceIsDark: Bool, fieldRequestsDark: Bool) -> KeyboardTheme {
        interfaceIsDark || fieldRequestsDark ? .dark : .light
    }
}

struct KeyboardRenderSnapshot: Equatable {
    let page: KeyboardPage
    let shift: ShiftMode
    let theme: KeyboardTheme
}

struct KeyboardRenderChanges {
    let labels: Bool
    let colors: Bool
    let shift: Bool
}

/// Text edits don't change key artwork unless they consume one-shot Shift.
struct KeyboardRenderCache {
    private var previous: KeyboardRenderSnapshot?

    mutating func update(_ next: KeyboardRenderSnapshot) -> KeyboardRenderChanges {
        let changes = KeyboardRenderChanges(
            labels: previous?.page != next.page || previous?.shift != next.shift,
            colors: previous?.theme != next.theme,
            shift: previous?.shift != next.shift
        )
        previous = next
        return changes
    }

    mutating func reset() { previous = nil }
}
