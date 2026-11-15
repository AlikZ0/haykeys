import Foundation

struct ClipboardEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let date: Date

    init(text: String, date: Date = Date()) {
        self.id = UUID()
        self.text = text
        self.date = date
    }
}

/// Last 100 distinct text values, newest first; exact text is preserved.
struct ClipboardHistory: Codable {
    static let limit = 100
    private(set) var entries: [ClipboardEntry] = []

    mutating func add(_ text: String, date: Date = Date()) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        entries.removeAll { $0.text == text }
        entries.insert(ClipboardEntry(text: text, date: date), at: 0)
        if entries.count > Self.limit { entries.removeLast(entries.count - Self.limit) }
    }

    mutating func remove(id: UUID) { entries.removeAll { $0.id == id } }
    mutating func clear() { entries.removeAll() }
}
