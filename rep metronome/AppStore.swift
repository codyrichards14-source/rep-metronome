import Combine
import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var settings: ReminderSettings {
        didSet { persistSettings() }
    }
    @Published var logs: [BladderLogEntry] {
        didSet { persistLogs() }
    }

    private let defaults: UserDefaults
    private let settingsKey = "reminderSettings"
    private let logsKey = "bladderLogs"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        if let settingsData = defaults.data(forKey: settingsKey),
           let decodedSettings = try? decoder.decode(ReminderSettings.self, from: settingsData) {
            settings = decodedSettings
        } else {
            settings = .default
        }

        if let logsData = defaults.data(forKey: logsKey),
           let decodedLogs = try? decoder.decode([BladderLogEntry].self, from: logsData) {
            logs = decodedLogs.sorted { $0.timestamp > $1.timestamp }
        } else {
            logs = []
        }
    }

    func addLog(outputMilliliters: Int, timestamp: Date, notes: String) {
        let entry = BladderLogEntry(timestamp: timestamp, outputMilliliters: outputMilliliters, notes: notes.trimmingCharacters(in: .whitespacesAndNewlines))
        logs.insert(entry, at: 0)
    }

    func deleteLogs(atOffsets offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            logs.remove(at: offset)
        }
    }

    var nextReminderDate: Date {
        settings.startDate.addingTimeInterval(settings.intervalHours * 3600)
    }

    var latestLog: BladderLogEntry? {
        logs.max(by: { $0.timestamp < $1.timestamp })
    }

    var todaysTotalOutput: Int {
        let calendar = Calendar.current
        return logs
            .filter { calendar.isDateInToday($0.timestamp) }
            .reduce(0) { $0 + $1.outputMilliliters }
    }

    var weeklyAverageOutput: Int {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date())) ?? Date()
        let recentLogs = logs.filter { $0.timestamp >= sevenDaysAgo }

        guard !recentLogs.isEmpty else { return 0 }
        let total = recentLogs.reduce(0) { $0 + $1.outputMilliliters }
        return total / recentLogs.count
    }

    func markCathCompleted(at date: Date = Date()) {
        settings.startDate = date
    }

    private func persistSettings() {
        if let data = try? encoder.encode(settings) {
            defaults.set(data, forKey: settingsKey)
        }
    }

    private func persistLogs() {
        if let data = try? encoder.encode(logs) {
            defaults.set(data, forKey: logsKey)
        }
    }
}
