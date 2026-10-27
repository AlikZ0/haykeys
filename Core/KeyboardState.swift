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
