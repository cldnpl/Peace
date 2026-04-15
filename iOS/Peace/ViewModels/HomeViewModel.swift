import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var userName = UserDefaults.standard.string(forKey: "peace.userName") ?? ""
    @Published var moodEntries: [MoodEntry] = []

    private let store: MoodJournalStore
    private var cancellables: Set<AnyCancellable> = []

    init(store: MoodJournalStore = .shared) {
        self.store = store
        self.moodEntries = store.entries

        store.$entries
            .receive(on: RunLoop.main)
            .assign(to: &$moodEntries)
    }
    func weekMoods(language: AppLanguage) -> [(day: String, entry: MoodEntry?)] {
        let calendar = Calendar.current
        let weekdays = language.weekdaySymbolsMondayFirst
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let mondayOffset = (todayWeekday == 1 ? -6 : -(todayWeekday - 2))

        return weekdays.enumerated().map { index, day in
            let date = calendar.date(byAdding: .day, value: mondayOffset + index, to: today) ?? today
            return (day, store.entry(for: date))
        }
    }

    func greeting(language: AppLanguage) -> String {
        let t = AppStrings(language: language)
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<12: return t.greetingMorning
        case 12..<18: return t.greetingAfternoon
        default: return t.greetingEvening
        }
    }

    func displayName(language: AppLanguage) -> String {
        let t = AppStrings(language: language)
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? t.displayNameFallback : trimmed
    }

    func greetingLine(language: AppLanguage) -> String {
        "\(greeting(language: language)) \(displayName(language: language))"
    }

    func dailyTitle(language: AppLanguage) -> String {
        let t = AppStrings(language: language)
        if let snapshot = store.reflectionSnapshot(language: language) {
            return snapshot.title
        }
        return t.startWithCheckin
    }

    func dailyMessage(language: AppLanguage) -> String {
        let t = AppStrings(language: language)
        if let snapshot = store.reflectionSnapshot(language: language) {
            return snapshot.message
        }
        return t.startTrackingMessage
    }
}
