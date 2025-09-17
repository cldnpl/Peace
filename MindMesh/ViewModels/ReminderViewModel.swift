import SwiftUI
import UserNotifications

@MainActor
final class ReminderStore: ObservableObject {
    static let shared = ReminderStore()

    @Published var isEnabled: Bool = false
    @Published var reminderTime: Date = .now
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()
    private let enabledKey = "mindmesh.reminder.enabled"
    private let timeKey = "mindmesh.reminder.time"
    private let identifier = "mindmesh.daily.reminder"

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        reminderTime = UserDefaults.standard.object(forKey: timeKey) as? Date ?? defaultReminderTime
        refreshAuthorizationStatus()
    }

    var statusText: String {
        if !isEnabled {
            return "Nessun promemoria attivo."
        }

        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Promemoria attivo ogni giorno alle \(formattedTime(reminderTime))."
        case .denied:
            return "Le notifiche sono disattivate. Puoi riattivarle dalle impostazioni di sistema."
        case .notDetermined:
            return "Serve il tuo consenso per attivare il promemoria."
        @unknown default:
            return "Controlla le impostazioni notifiche per confermare il promemoria."
        }
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: enabledKey)

        if enabled {
            Task {
                await requestPermissionIfNeeded()
                await scheduleReminderIfPossible()
            }
        } else {
            removeReminder()
        }
    }

    func updateReminderTime(_ date: Date) {
        reminderTime = date
        UserDefaults.standard.set(date, forKey: timeKey)

        guard isEnabled else { return }
        Task {
            await scheduleReminderIfPossible()
        }
    }

    func refreshAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    private func requestPermissionIfNeeded() async {
        refreshAuthorizationStatus()

        guard authorizationStatus == .notDetermined else { return }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            authorizationStatus = granted ? .authorized : .denied
        } catch {
            authorizationStatus = .denied
        }
    }

    private func scheduleReminderIfPossible() async {
        refreshAuthorizationStatus()

        guard isEnabled else { return }
        guard authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral else { return }

        removeReminder()

        let content = UNMutableNotificationContent()
        content.title = "MindMesh"
        content.body = "Prenditi un momento per segnare come stai oggi."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await add(request)
        } catch {
            assertionFailure("Unable to schedule reminder: \(error)")
        }
    }

    private func removeReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    private var defaultReminderTime: Date {
        Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now) ?? .now
    }

    private func formattedTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
