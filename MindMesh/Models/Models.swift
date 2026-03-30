import SwiftUI

enum MoodLevel: Int, CaseIterable, Codable, Identifiable {
    case anxious = 0, neutral, okay, good, excellent

    var id: Int { rawValue }

    var symbolName: String {
        switch self {
        case .anxious: return "bolt.fill"
        case .neutral: return "heart.fill"
        case .okay: return "gauge.with.needle"
        case .good: return "sun.max.fill"
        case .excellent: return "star.fill"
        }
    }

    var label: String {
        switch self {
        case .anxious: return "Tesa"
        case .neutral: return "Stabile"
        case .okay: return "Discreta"
        case .good: return "Buona"
        case .excellent: return "Lucida"
        }
    }

    var detail: String {
        switch self {
        case .anxious: return "Giornata stretta e un po' rumorosa."
        case .neutral: return "Sei in equilibrio, senza picchi."
        case .okay: return "C'è movimento, ma regge bene."
        case .good: return "Hai una buona energia addosso."
        case .excellent: return "Sei centrata e molto presente."
        }
    }

    var color: Color {
        switch self {
        case .anxious: return .mmRose
        case .neutral: return .mmAmber
        case .okay: return .mmAccent2
        case .good: return .mmAccent3
        case .excellent: return .mmTeal
        }
    }

    var energyValue: Double {
        switch self {
        case .anxious: return 0.30
        case .neutral: return 0.48
        case .okay: return 0.64
        case .good: return 0.80
        case .excellent: return 1.0
        }
    }
}

struct MoodEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let mood: MoodLevel
    var note: String

    init(id: UUID = UUID(), date: Date = .now, mood: MoodLevel, note: String = "") {
        self.id = id
        self.date = date
        self.mood = mood
        self.note = note
    }
}

enum InsightType: String {
    case cognitiveBias = "Nodo cieco"
    case pattern = "Schema"
    case sentiment = "Tono"
    case recommendation = "Spunto"

    var symbolName: String {
        switch self {
        case .cognitiveBias: return "exclamationmark.triangle.fill"
        case .pattern: return "point.bottomleft.forward.to.point.topright.scurvepath"
        case .sentiment: return "bubble.left.and.bubble.right.fill"
        case .recommendation: return "lightbulb.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .cognitiveBias: return .mmRose
        case .pattern: return .mmAccent3
        case .sentiment: return .mmAccent2
        case .recommendation: return .mmAmber
        }
    }
}

struct AIInsight: Identifiable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let score: Double
    let tags: [String]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        description: String,
        score: Double,
        tags: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.score = score
        self.tags = tags
        self.createdAt = createdAt
    }
}

enum SupportMessageRole: Codable {
    case assistant
    case user
}

struct SupportChatMessage: Identifiable, Codable {
    let id: UUID
    let role: SupportMessageRole
    let text: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        role: SupportMessageRole,
        text: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

struct SupportChatSession: Identifiable, Codable {
    let id: UUID
    let title: String
    let updatedAt: Date
    let messages: [SupportChatMessage]

    var previewText: String {
        messages
            .last(where: { $0.role == .user })?
            .text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
        ?? messages
            .last?
            .text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
        ?? "Conversazione recente"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

struct CognitivePattern: Identifiable {
    let id: UUID
    let text: String
    let color: Color

    init(id: UUID = UUID(), text: String, color: Color) {
        self.id = id
        self.text = text
        self.color = color
    }
}

extension AIInsight {
    static let samples: [AIInsight] = [
        AIInsight(
            type: .cognitiveBias,
            title: "Studio e pressione si stanno toccando spesso",
            description: "Negli ultimi giorni le note sullo studio hanno un tono più rigido del resto. Vale la pena spezzare i task o rivedere il carico, prima che diventi la voce dominante.",
            score: 0.72,
            tags: ["Carico", "Focus", "Respiro"]
        ),
        AIInsight(
            type: .sentiment,
            title: "Il tono generale sta tornando su",
            description: "Le note di marzo restano per lo più stabili, con un miglioramento netto dopo le giornate in cui hai lasciato meno cose aperte.",
            score: 0.54,
            tags: ["Tono", "Continuità"]
        ),
        AIInsight(
            type: .recommendation,
            title: "Mercoledì mattina è ancora la tua finestra migliore",
            description: "Quando il calendario è pulito nelle prime ore del mercoledì, completi più facilmente i task difficili. È un buon posto dove mettere il lavoro che richiede testa libera.",
            score: 0.85,
            tags: ["Routine", "Energia", "Agenda"]
        )
    ]
}

extension CognitivePattern {
    static let samples: [CognitivePattern] = [
        CognitivePattern(text: "La concentrazione sale quando la giornata parte piano.", color: .mmAccent),
        CognitivePattern(text: "Il movimento leggero migliora il tono della sera.", color: .mmAccent3),
        CognitivePattern(text: "La domenica sera porta più attrito del resto della settimana.", color: .mmRose)
    ]
}
