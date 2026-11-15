import Foundation

enum KeyboardSettings {
    static let soundKey = "haykeys.sound.enabled.v1"
    static func soundEnabled(stored: Bool?) -> Bool { stored ?? true }
}

/// An explicit settings transaction in the containing app's dedicated input field.
/// No app-group entitlement, clipboard or shared file access is involved.
struct SoundSettingsRequest: Equatable {
    let id: UUID
    let enabled: Bool
    var payload: String { "~HayKeys.Sound.v1|\(id.uuidString)|\(enabled ? "1" : "0")~" }
    var acknowledgement: String { "~HayKeys.Sound.applied|\(id.uuidString)~" }

    init(enabled: Bool, id: UUID = UUID()) {
        self.id = id
        self.enabled = enabled
    }

    static func parse(_ value: String) -> SoundSettingsRequest? {
        let parts = value.split(separator: "|", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0] == "~HayKeys.Sound.v1",
              let id = UUID(uuidString: String(parts[1])),
              parts[2] == "0~" || parts[2] == "1~" else { return nil }
        let request = SoundSettingsRequest(enabled: parts[2] == "1~", id: id)
        return request.payload == value ? request : nil
    }
}
