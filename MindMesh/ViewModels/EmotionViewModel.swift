import SwiftUI
import Combine

struct MoodReflectionSnapshot {
    let title: String
    let message: String
    let detailTitle: String
    let detailValue: String
    let detailMessage: String
}

@MainActor
final class MoodJournalStore: ObservableObject {
    static let shared = MoodJournalStore()

    @Published private(set) var entries: [MoodEntry] = []

    private let storageKey = "mindmesh.mood.entries"

    private init() {
        load()
    }

    func saveEntry(mood: MoodLevel, note: String) {
        entries.removeAll { Calendar.current.isDateInToday($0.date) }
        entries.append(MoodEntry(mood: mood, note: note))
        entries.sort { $0.date < $1.date }
        persist()
    }

    func entry(for date: Date) -> MoodEntry? {
        entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func recentEntries(lastDays: Int, from referenceDate: Date = .now) -> [MoodEntry] {
        guard let startDate = Calendar.current.date(byAdding: .day, value: -(lastDays - 1), to: referenceDate) else {
            return []
        }

        return entries
            .filter { $0.date >= Calendar.current.startOfDay(for: startDate) }
            .sorted { $0.date < $1.date }
    }

    func reflectionSnapshot(lastDays: Int = 7, minimumEntries: Int = 3) -> MoodReflectionSnapshot? {
        let recentEntries = recentEntries(lastDays: lastDays)
        guard recentEntries.count >= minimumEntries else { return nil }

        let averageEnergy = recentEntries
            .map(\.mood.energyValue)
            .reduce(0, +) / Double(recentEntries.count)

        let firstHalf = Array(recentEntries.prefix(max(1, recentEntries.count / 2)))
        let secondHalf = Array(recentEntries.suffix(max(1, recentEntries.count / 2)))

        let firstAverage = firstHalf.map(\.mood.energyValue).reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.map(\.mood.energyValue).reduce(0, +) / Double(secondHalf.count)
        let trend = secondAverage - firstAverage

        let dominantMood = recentEntries
            .reduce(into: [MoodLevel: Int]()) { counts, entry in
                counts[entry.mood, default: 0] += 1
            }
            .max { $0.value < $1.value }?
            .key ?? .neutral

        let title: String
        if trend > 0.12 {
            title = "Il tono si sta alleggerendo."
        } else if trend < -0.12 {
            title = "Negli ultimi giorni c'e un po' piu attrito."
        } else if averageEnergy >= 0.72 {
            title = "La settimana regge bene."
        } else {
            title = "L'umore e abbastanza stabile."
        }

        let message = "Negli ultimi \(recentEntries.count) check-in torna spesso una voce \(dominantMood.label.lowercased()). Questo e il momento giusto per notare il ritmo, non per giudicarlo."

        let detailTitle = "Registrazioni utili"
        let detailValue = "\(recentEntries.count)/7"

        let detailMessage: String
        if trend > 0.12 {
            detailMessage = "La seconda parte della settimana e piu leggera della prima."
        } else if trend < -0.12 {
            detailMessage = "Vale la pena proteggere un po' di spazio nei prossimi due giorni."
        } else {
            detailMessage = "Il tono cambia poco: segno utile, non noioso."
        }

        return MoodReflectionSnapshot(
            title: title,
            message: message,
            detailTitle: detailTitle,
            detailValue: detailValue,
            detailMessage: detailMessage
        )
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            entries = []
            return
        }

        do {
            entries = try JSONDecoder().decode([MoodEntry].self, from: data)
                .sorted { $0.date < $1.date }
        } catch {
            entries = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Unable to persist mood entries: \(error)")
        }
    }
}

@MainActor
final class EmotionViewModel: ObservableObject {
    @Published var entries: [MoodEntry] = []
    @Published var selectedMood: MoodLevel? = nil
    @Published var noteText = ""
    @Published var showSuccess = false

    private let store: MoodJournalStore
    private var cancellables: Set<AnyCancellable> = []

    init(store: MoodJournalStore = .shared) {
        self.store = store
        self.entries = store.entries
        self.selectedMood = store.entries.last?.mood

        store.$entries
            .receive(on: RunLoop.main)
            .sink { [weak self] entries in
                self?.entries = entries
                if let todayMood = entries.last(where: { Calendar.current.isDateInToday($0.date) })?.mood {
                    self?.selectedMood = todayMood
                }
            }
            .store(in: &cancellables)
    }

    var weekData: [(day: String, entry: MoodEntry?)] {
        let calendar = Calendar.current
        let days = ["Lu", "Ma", "Me", "Gi", "Ve", "Sa", "Do"]
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let mondayOffset = (todayWeekday == 1 ? -6 : -(todayWeekday - 2))

        return days.enumerated().map { index, day in
            guard let date = calendar.date(byAdding: .day, value: mondayOffset + index, to: today) else {
                return (day, nil)
            }
            return (day, store.entry(for: date))
        }
    }

    var hasLoggedToday: Bool {
        entries.contains { Calendar.current.isDateInToday($0.date) }
    }

    var weekBarData: [(day: String, height: Double, color: Color)] {
        weekData.map { item in
            if let entry = item.entry {
                return (item.day, entry.mood.energyValue, entry.mood.color)
            } else {
                return (item.day, 0.05, Color.mmSurface)
            }
        }
    }

    var loggedDaysThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return entries.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }.count
    }

    func logMood() {
        guard let mood = selectedMood else { return }
        store.saveEntry(mood: mood, note: noteText)
        noteText = ""
        withAnimation {
            showSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.showSuccess = false
            }
        }
    }
}
