import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var userName = "Claudia"
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

    var weekMoods: [(day: String, entry: MoodEntry?)] {
        let calendar = Calendar.current
        let weekdays = ["Lu", "Ma", "Me", "Gi", "Ve", "Sa", "Do"]
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let mondayOffset = (todayWeekday == 1 ? -6 : -(todayWeekday - 2))

        return weekdays.enumerated().map { index, day in
            let date = calendar.date(byAdding: .day, value: mondayOffset + index, to: today) ?? today
            return (day, store.entry(for: date))
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<12: return "Buongiorno"
        case 12..<18: return "Buon pomeriggio"
        default: return "Buonasera"
        }
    }

    var dailyTitle: String {
        if let snapshot = store.reflectionSnapshot() {
            return snapshot.title
        }
        return "Comincia da un check-in."
    }

    var dailyMessage: String {
        if let snapshot = store.reflectionSnapshot() {
            return snapshot.message
        }
        return "Quando inizi a registrare l'umore con continuita, qui troverai una sintesi reale della settimana."
    }
}
