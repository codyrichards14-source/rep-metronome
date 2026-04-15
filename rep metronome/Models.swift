import Foundation

struct BladderLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let outputMilliliters: Int
    let notes: String

    init(id: UUID = UUID(), timestamp: Date, outputMilliliters: Int, notes: String) {
        self.id = id
        self.timestamp = timestamp
        self.outputMilliliters = outputMilliliters
        self.notes = notes
    }
}

struct ReminderSettings: Codable, Equatable {
    var intervalHours: Double
    var startDate: Date
    var notificationsEnabled: Bool
    var alarmSoundEnabled: Bool

    static let `default` = ReminderSettings(
        intervalHours: 4,
        startDate: Date(),
        notificationsEnabled: false,
        alarmSoundEnabled: true
    )
}
