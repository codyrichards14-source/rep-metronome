import SwiftUI
import UserNotifications

struct ContentView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var notificationManager: NotificationManager

    @State private var selectedTab = 0
    @State private var outputMilliliters = 400
    @State private var logDate = Date()
    @State private var notes = ""

    private let intervalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()

    private let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        heroCard
                        statsSection
                        reminderSettingsCard
                        permissionCard
                    }
                    .padding()
                }
                .navigationTitle("CathCue")
            }
            .tabItem {
                Label("Schedule", systemImage: "bell.badge")
            }
            .tag(0)

            NavigationStack {
                List {
                    Section("New Log") {
                        Stepper(value: $outputMilliliters, in: 0...1500, step: 25) {
                            HStack {
                                Text("Output")
                                Spacer()
                                Text("\(outputMilliliters) mL")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        DatePicker("Cath time", selection: $logDate, displayedComponents: [.date, .hourAndMinute])

                        TextField("Notes (optional)", text: $notes, axis: .vertical)
                            .lineLimit(2...4)

                        Button("Save catheterization log") {
                            store.addLog(outputMilliliters: outputMilliliters, timestamp: logDate, notes: notes)
                            store.markCathCompleted(at: logDate)
                            notes = ""
                            logDate = Date()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Section("History") {
                        if store.logs.isEmpty {
                            Text("No catheterization logs yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(store.logs) { entry in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("\(entry.outputMilliliters) mL")
                                            .font(.headline)
                                        Spacer()
                                        Text(timestampFormatter.string(from: entry.timestamp))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    if !entry.notes.isEmpty {
                                        Text(entry.notes)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: store.deleteLogs)
                        }
                    }
                }
                .navigationTitle("Output Log")
            }
            .tabItem {
                Label("Log", systemImage: "drop")
            }
            .tag(1)
        }
        .task {
            await notificationManager.refreshAuthorizationStatus()
            await syncNotifications()
        }
        .onChange(of: store.settings) { _, _ in
            Task {
                await syncNotifications()
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personalized self-cath reminders")
                .font(.title2.bold())
            Text("Set a safe interval, keep the next reminder visible, and log output after each catheterization.")
                .foregroundStyle(.secondary)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next reminder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(timestampFormatter.string(from: store.nextReminderDate))
                        .font(.headline)
                }
                Spacer()
                Button("Mark done now") {
                    store.markCathCompleted()
                }
                .buttonStyle(.borderedProminent)
            }

            if store.settings.notificationsEnabled {
                Text("Repeats every \(intervalDescription)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Notifications are currently paused.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.teal.opacity(0.18), Color.blue.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(title: "Today", value: "\(store.todaysTotalOutput) mL", detail: "logged output")
            statCard(title: "7-day avg", value: "\(store.weeklyAverageOutput) mL", detail: "per catheterization")
        }
    }

    private func statCard(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var reminderSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reminder schedule")
                .font(.headline)

            Toggle("Enable reminders", isOn: $store.settings.notificationsEnabled)
            Toggle("Play sound/alarm", isOn: $store.settings.alarmSoundEnabled)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Interval")
                    Spacer()
                    Text(intervalDescription)
                        .foregroundStyle(.secondary)
                }
                Slider(value: $store.settings.intervalHours, in: 1...8, step: 0.5)
            }

            DatePicker("Last catheterization", selection: $store.settings.startDate, displayedComponents: [.date, .hourAndMinute])
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notification access")
                .font(.headline)

            Text(permissionDescription)
                .foregroundStyle(.secondary)

            Button("Allow notifications") {
                Task {
                    let granted = await notificationManager.requestAuthorization()
                    if granted {
                        store.settings.notificationsEnabled = true
                    }
                }
            }
            .buttonStyle(.bordered)
            .disabled(notificationManager.authorizationStatus == .authorized)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var permissionDescription: String {
        switch notificationManager.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Notifications are enabled. The app can deliver reminder alerts even when it is closed."
        case .denied:
            return "Notifications are turned off in Settings. You can still log output, but alerts will stay silent."
        case .notDetermined:
            return "Enable notifications so the app can remind the patient when it is time to self cath."
        @unknown default:
            return "Notification status is unavailable."
        }
    }

    private var intervalDescription: String {
        intervalFormatter.string(from: store.settings.intervalHours * 3600) ?? "\(String(format: "%.1f", store.settings.intervalHours)) hr"
    }

    private func syncNotifications() async {
        if store.settings.notificationsEnabled,
           notificationManager.authorizationStatus != .authorized,
           notificationManager.authorizationStatus != .provisional,
           notificationManager.authorizationStatus != .ephemeral {
            store.settings.notificationsEnabled = false
            return
        }

        try? await notificationManager.scheduleReminders(settings: store.settings)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStore())
        .environmentObject(NotificationManager())
}
