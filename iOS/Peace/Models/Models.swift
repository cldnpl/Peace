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

    func label(in language: AppLanguage) -> String {
        let t = AppStrings(language: language)
        switch self {
        case .anxious:
            return t.text(it: "Tesa", en: "Tense", es: "Tensa", fr: "Tendue", zh: "紧绷", ar: "متوترة", da: "Anspændt", nb: "Anspent", sv: "Spänd")
        case .neutral:
            return t.text(it: "Stabile", en: "Steady", es: "Estable", fr: "Stable", zh: "平稳", ar: "مستقرة", da: "Stabil", nb: "Stabil", sv: "Stabil")
        case .okay:
            return t.text(it: "Discreta", en: "Okay", es: "Bastante bien", fr: "Correcte", zh: "还可以", ar: "لا بأس", da: "Okay", nb: "Grei", sv: "Okej")
        case .good:
            return t.text(it: "Buona", en: "Good", es: "Buena", fr: "Bonne", zh: "不错", ar: "جيدة", da: "God", nb: "God", sv: "Bra")
        case .excellent:
            return t.text(it: "Lucida", en: "Clear", es: "Lúcida", fr: "Claire", zh: "清晰", ar: "صافية", da: "Klar", nb: "Klar", sv: "Klar")
        }
    }

    var label: String {
        label(in: AppLanguagePreferences.currentLanguage)
    }

    func detail(in language: AppLanguage) -> String {
        let t = AppStrings(language: language)
        switch self {
        case .anxious:
            return t.text(it: "Giornata stretta e un po' rumorosa.", en: "A tight, noisy kind of day.", es: "Un día tenso y algo ruidoso.", fr: "Une journée tendue et un peu bruyante.", zh: "这一天有些紧绷，也有点嘈杂。", ar: "يوم مشدود ومزعج قليلاً.", da: "En stram og lidt støjende dag.", nb: "En stram og litt støyende dag.", sv: "En spänd och lite stökig dag.")
        case .neutral:
            return t.text(it: "Sei in equilibrio, senza picchi.", en: "You're balanced, without strong peaks.", es: "Estás en equilibrio, sin picos fuertes.", fr: "Tu es en équilibre, sans grands pics.", zh: "你现在比较平衡，没有明显波动。", ar: "أنت في توازن من دون قمم حادة.", da: "Du er i balance uden store udsving.", nb: "Du er i balanse uten store topper.", sv: "Du är i balans utan stora toppar.")
        case .okay:
            return t.text(it: "C'è movimento, ma regge bene.", en: "There's movement, but it holds together well.", es: "Hay movimiento, pero se sostiene bien.", fr: "Il y a du mouvement, mais ça tient bien.", zh: "有些起伏，但整体还稳得住。", ar: "هناك حركة، لكنه ما زال متماسكاً.", da: "Der er bevægelse, men det holder godt.", nb: "Det er bevegelse, men det holder godt.", sv: "Det finns rörelse, men det håller ihop bra.")
        case .good:
            return t.text(it: "Hai una buona energia addosso.", en: "You have good energy around you.", es: "Tienes buena energía encima.", fr: "Tu as une bonne énergie en toi.", zh: "你的状态里有不错的能量。", ar: "لديك طاقة جيدة.", da: "Du har en god energi.", nb: "Du har god energi.", sv: "Du har bra energi.")
        case .excellent:
            return t.text(it: "Sei centrata e molto presente.", en: "You feel centered and very present.", es: "Te sientes centrada y muy presente.", fr: "Tu te sens centrée et très présente.", zh: "你很专注，也很在场。", ar: "أنت متزنة وحاضرة جداً.", da: "Du er centreret og meget nærværende.", nb: "Du er samlet og veldig til stede.", sv: "Du känns centrerad och mycket närvarande.")
        }
    }

    var detail: String {
        detail(in: AppLanguagePreferences.currentLanguage)
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
        ?? AppStrings.current.recentConversationFallback
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
