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

struct MapNode: Identifiable, Equatable {
    let id: UUID
    var label: String
    var color: Color
    var position: CGPoint
    var size: CGFloat
    var isRoot: Bool

    init(
        id: UUID = UUID(),
        label: String,
        color: Color = .mmAccent,
        position: CGPoint = .zero,
        size: CGFloat = 56,
        isRoot: Bool = false
    ) {
        self.id = id
        self.label = label
        self.color = color
        self.position = position
        self.size = size
        self.isRoot = isRoot
    }
}

struct MapEdge: Identifiable {
    let id: UUID
    let fromID: UUID
    let toID: UUID

    init(id: UUID = UUID(), from: UUID, to: UUID) {
        self.id = id
        self.fromID = from
        self.toID = to
    }
}

struct MindMap: Identifiable, Hashable {
    let id: UUID
    var title: String
    var nodes: [MapNode]
    var edges: [MapEdge]
    var createdAt: Date

    var nodeCount: Int { nodes.count }

    var symbolName: String {
        let lowercaseTitle = title.lowercased()
        if lowercaseTitle.contains("studio") {
            return "book.closed.fill"
        }
        if lowercaseTitle.contains("salute") {
            return "heart.text.square.fill"
        }
        if lowercaseTitle.contains("lavoro") || lowercaseTitle.contains("progetto") {
            return "briefcase.fill"
        }
        return "target"
    }

    init(
        id: UUID = UUID(),
        title: String,
        nodes: [MapNode] = [],
        edges: [MapEdge] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.nodes = nodes
        self.edges = edges
        self.createdAt = createdAt
    }

    static func == (lhs: MindMap, rhs: MindMap) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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

struct UserStats {
    var mapsCreated: Int
    var currentStreak: Int
    var totalNodes: Int
}

extension MindMap {
    static let sample: MindMap = {
        let rootID = UUID()
        let nodes: [MapNode] = [
            MapNode(id: rootID, label: "Piani di\nprimavera", color: .mmAccent, position: CGPoint(x: 0.50, y: 0.50), size: 72, isRoot: true),
            MapNode(label: "Studio\nSwift", color: .mmAccent, position: CGPoint(x: 0.20, y: 0.20), size: 50),
            MapNode(label: "Corpo e\nritmo", color: .mmTeal, position: CGPoint(x: 0.75, y: 0.20), size: 50),
            MapNode(label: "Relazioni", color: .mmRose, position: CGPoint(x: 0.18, y: 0.68), size: 50),
            MapNode(label: "Lavoro", color: .mmAmber, position: CGPoint(x: 0.78, y: 0.65), size: 50),
            MapNode(label: "Progetti\nlaterali", color: .mmAccent2, position: CGPoint(x: 0.50, y: 0.12), size: 50),
            MapNode(label: "UI", color: .mmAccent, position: CGPoint(x: 0.08, y: 0.06), size: 36),
            MapNode(label: "Letture", color: .mmAccent, position: CGPoint(x: 0.28, y: 0.05), size: 36),
            MapNode(label: "Cammino", color: .mmTeal, position: CGPoint(x: 0.65, y: 0.06), size: 36),
            MapNode(label: "Sonno", color: .mmTeal, position: CGPoint(x: 0.85, y: 0.10), size: 36),
            MapNode(label: "Amici", color: .mmRose, position: CGPoint(x: 0.05, y: 0.80), size: 36),
            MapNode(label: "Budget", color: .mmAmber, position: CGPoint(x: 0.88, y: 0.76), size: 36)
        ]

        var edges: [MapEdge] = []
        let root = nodes[0]

        for node in nodes[1...5] {
            edges.append(MapEdge(from: root.id, to: node.id))
        }

        edges.append(MapEdge(from: nodes[1].id, to: nodes[6].id))
        edges.append(MapEdge(from: nodes[1].id, to: nodes[7].id))
        edges.append(MapEdge(from: nodes[2].id, to: nodes[8].id))
        edges.append(MapEdge(from: nodes[2].id, to: nodes[9].id))
        edges.append(MapEdge(from: nodes[3].id, to: nodes[10].id))
        edges.append(MapEdge(from: nodes[4].id, to: nodes[11].id))

        return MindMap(title: "Piani di primavera", nodes: nodes, edges: edges)
    }()

    static let sampleMaps: [MindMap] = [
        .sample,
        MindMap(
            title: "Studio e prototipi",
            nodes: [
                MapNode(label: "Esame UX", color: .mmAccent2),
                MapNode(label: "Test utente", color: .mmAccent3)
            ]
        ),
        MindMap(
            title: "Salute leggera",
            nodes: [
                MapNode(label: "Sonno", color: .mmTeal),
                MapNode(label: "Camminate", color: .mmGreen)
            ]
        )
    ]
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
