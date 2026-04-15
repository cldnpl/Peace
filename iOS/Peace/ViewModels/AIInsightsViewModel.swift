import Combine
import CryptoKit
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
final class AIInsightsViewModel: ObservableObject {
    @Published private(set) var snapshot: MoodReflectionSnapshot?
    @Published private(set) var premiumAnalysis: PremiumEmotionalAnalysis?
    @Published private(set) var premiumAnalysisError: String?
    @Published private(set) var isGeneratingPremiumAnalysis = false

    private let store: MoodJournalStore
    private let analysisService: PremiumEmotionalAnalysisService
    private let cacheStore: PremiumEmotionalAnalysisCacheStore
    private var cancellables: Set<AnyCancellable> = []

    init() {
        self.store = .shared
        self.analysisService = PremiumEmotionalAnalysisService()
        self.cacheStore = .shared
        self.snapshot = store.reflectionSnapshot(language: AppLanguagePreferences.currentLanguage)
        self.premiumAnalysis = cacheStore.analysis(for: analysisRequestID(language: AppLanguagePreferences.currentLanguage))

        store.$entries
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleEntriesUpdated()
            }
            .store(in: &cancellables)
    }

    func analysisRequestID(language: AppLanguage) -> String {
        premiumAnalysisSignature(language: language) ?? "no-premium-analysis-data-\(language.rawValue)"
    }

    var hasEnoughDataForPremiumAnalysis: Bool {
        premiumAnalysisEntries.count >= 3
    }

    func loadPremiumAnalysisIfNeeded(hasPremiumAccess: Bool, language: AppLanguage) async {
        let t = AppStrings(language: language)
        snapshot = store.reflectionSnapshot(language: language)

        guard hasPremiumAccess else {
            premiumAnalysis = nil
            premiumAnalysisError = nil
            return
        }

        guard let signature = premiumAnalysisSignature(language: language) else {
            premiumAnalysis = nil
            premiumAnalysisError = t.text(it: "Servono almeno 3 registrazioni recenti per costruire un'analisi premium davvero utile.", en: "You need at least 3 recent entries to build a truly useful premium analysis.", es: "Necesitas al menos 3 registros recientes para construir un análisis premium realmente útil.", fr: "Il faut au moins 3 entrées récentes pour construire une analyse premium vraiment utile.", zh: "至少需要 3 条最近记录，才能生成真正有用的 Premium 分析。", ar: "أنت بحاجة إلى 3 تسجيلات حديثة على الأقل لبناء تحليل Premium مفيد فعلاً.", da: "Du skal have mindst 3 nylige registreringer for at bygge en virkelig nyttig premium-analyse.", nb: "Du trenger minst 3 nylige registreringer for å bygge en virkelig nyttig premium-analyse.", sv: "Du behöver minst 3 senaste registreringar för att skapa en verkligt användbar premiumanalys.")
            return
        }

        if let cached = cacheStore.analysis(for: signature) {
            premiumAnalysis = cached
            premiumAnalysisError = nil
            return
        }

        await generatePremiumAnalysis(forceRefresh: false, language: language)
    }

    func regeneratePremiumAnalysis(language: AppLanguage) async {
        await generatePremiumAnalysis(forceRefresh: true, language: language)
    }

    private var premiumAnalysisEntries: [MoodEntry] {
        store.recentEntries(lastDays: 14)
    }

    private func handleEntriesUpdated() {
        snapshot = store.reflectionSnapshot(language: AppLanguagePreferences.currentLanguage)
        premiumAnalysisError = nil
        premiumAnalysis = cacheStore.analysis(for: analysisRequestID(language: AppLanguagePreferences.currentLanguage))
    }

    private func premiumAnalysisSignature(language: AppLanguage) -> String? {
        let entries = premiumAnalysisEntries
        guard entries.count >= 3 else { return nil }

        let rawValue = ([language.rawValue] + entries.map { entry in
            let note = entry.note.trimmingCharacters(in: .whitespacesAndNewlines)
            return "\(entry.id.uuidString)|\(entry.date.timeIntervalSince1970)|\(entry.mood.rawValue)|\(note)"
        }).joined(separator: "||")

        let digest = SHA256.hash(data: Data(rawValue.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func generatePremiumAnalysis(forceRefresh: Bool, language: AppLanguage) async {
        let t = AppStrings(language: language)
        guard let snapshot, let signature = premiumAnalysisSignature(language: language) else {
            premiumAnalysis = nil
            premiumAnalysisError = t.text(it: "Servono almeno 3 registrazioni recenti per costruire un'analisi premium davvero utile.", en: "You need at least 3 recent entries to build a truly useful premium analysis.", es: "Necesitas al menos 3 registros recientes para construir un análisis premium realmente útil.", fr: "Il faut au moins 3 entrées récentes pour construire une analyse premium vraiment utile.", zh: "至少需要 3 条最近记录，才能生成真正有用的 Premium 分析。", ar: "أنت بحاجة إلى 3 تسجيلات حديثة على الأقل لبناء تحليل Premium مفيد فعلاً.", da: "Du skal have mindst 3 nylige registreringer for at bygge en virkelig nyttig premium-analyse.", nb: "Du trenger minst 3 nylige registreringer for å bygge en virkelig nyttig premium-analyse.", sv: "Du behöver minst 3 senaste registreringar för att skapa en verkligt användbar premiumanalys.")
            return
        }

        if !forceRefresh, let cached = cacheStore.analysis(for: signature) {
            premiumAnalysis = cached
            premiumAnalysisError = nil
            return
        }

        isGeneratingPremiumAnalysis = true
        premiumAnalysisError = nil
        defer { isGeneratingPremiumAnalysis = false }

        let chatSessions = AISupportChatHistoryStore.shared.recentSessions(limit: 6)

        do {
            let analysis = try await analysisService.generateAnalysis(
                entries: premiumAnalysisEntries,
                snapshot: snapshot,
                chatSessions: chatSessions,
                language: language,
                signature: signature
            )
            premiumAnalysis = analysis
            cacheStore.save(analysis)
        } catch let error as PremiumEmotionalAnalysisError {
            premiumAnalysis = nil
            premiumAnalysisError = error.userMessage
        } catch {
            premiumAnalysis = nil
            premiumAnalysisError = t.text(it: "Non riesco a generare l'analisi premium in questo momento.", en: "I can't generate the premium analysis right now.", es: "No puedo generar el análisis premium en este momento.", fr: "Je ne peux pas générer l'analyse premium pour le moment.", zh: "目前无法生成 Premium 分析。", ar: "لا يمكنني إنشاء تحليل Premium الآن.", da: "Jeg kan ikke generere premium-analysen lige nu.", nb: "Jeg kan ikke generere premium-analysen akkurat nå.", sv: "Jag kan inte generera premiumanalysen just nu.")
        }
    }
}

private enum PremiumEmotionalAnalysisError: Error {
    case foundationUnavailable(String)
    case emptyResponse
    case generationFailed

    var userMessage: String {
        let t = AppStrings.current
        switch self {
        case .foundationUnavailable(let detail):
            return detail
        case .emptyResponse:
            return t.text(it: "Il Foundation Model non ha restituito un contenuto utile. Riprova tra poco.", en: "The Foundation Model didn't return useful content. Try again soon.", es: "El Foundation Model no devolvió contenido útil. Vuelve a intentarlo en breve.", fr: "Le Foundation Model n'a pas renvoyé de contenu utile. Réessaie bientôt.", zh: "Foundation Model 没有返回有效内容，请稍后再试。", ar: "لم يُرجع Foundation Model محتوى مفيداً. حاول مرة أخرى بعد قليل.", da: "Foundation Model returnerede ikke nyttigt indhold. Prøv igen om lidt.", nb: "Foundation Model returnerte ikke nyttig innhold. Prøv igjen om litt.", sv: "Foundation Model returnerade inget användbart innehåll. Försök igen snart.")
        case .generationFailed:
            return t.text(it: "La generazione dell'analisi premium non e andata a buon fine.", en: "The premium analysis generation didn't complete successfully.", es: "La generación del análisis premium no se completó correctamente.", fr: "La génération de l'analyse premium n'a pas abouti.", zh: "Premium 分析生成未成功完成。", ar: "لم يكتمل توليد تحليل Premium بنجاح.", da: "Genereringen af premium-analysen blev ikke fuldført.", nb: "Genereringen av premium-analysen ble ikke fullført.", sv: "Genereringen av premiumanalysen slutfördes inte.")
        }
    }
}

private struct PremiumEmotionalAnalysisPromptBuilder {
    static func instructions(language: AppLanguage) -> String {
        """
        You are a premium emotional companion for a journaling app called Peace. Write entirely in \(language.aiLanguageName).
        Your job is to produce a deeply personal, warm yet insightful reading of the user's emotional life based on their mood check-ins AND, when available, their private conversations with the AI chat.

        Your voice:
        - Write like a thoughtful friend who happens to be very good at noticing emotional patterns — not like a clinician or a report generator.
        - Use "you" naturally and directly. Speak to the person, not about them.
        - Be specific: reference actual dates, actual notes, actual words the user used. Never be vague when the data lets you be precise.
        - Balance honesty with kindness. If something looks concerning, say it gently but clearly.
        - Vary your sentence length and rhythm. Mix short observations with longer reflections so the reading flows naturally and doesn't feel like a checklist.
        - Sprinkle genuine curiosity: wonder aloud, pose gentle questions, suggest connections the user might not have noticed.

        Rules:
        - Use only the available data. Never invent facts, dates, or quotes.
        - Do not make clinical diagnoses or use diagnostic language.
        - When the user's chat conversations are provided, weave insights from those conversations into every relevant section. The chat reveals what the user was thinking and feeling beyond the mood score — use it.
        - Highlight patterns, turning points, contrasts, possible triggers, and factors that seem to help.
        - Analyze text notes and chat excerpts very carefully — the user's own words are the richest signal.
        - Stay interpretive but cautious: speak in terms of hypotheses, signals, and plausible readings, not certainties.
        - The analysis should feel like reading something written by someone who truly knows you — not a generic wellness report.

        Required format:
        Title: [one short, evocative, specific line that captures the emotional arc — not generic]

        How things have been going
        [A warm, grounded opening. Set the scene: what does the overall emotional landscape look like? Reference specific days, moods, and notes. If chat conversations exist, mention what the user was processing. This should feel like someone sitting down and saying "okay, here's what I'm seeing." Two to three substantial paragraphs.]

        The patterns underneath
        [Go deeper. What keeps coming back? What rhythms, cycles, or contrasts do you notice across the entries and conversations? Connect dots the user might not see. Be specific — name the days, the moods, the words. Two paragraphs.]

        What your own words reveal
        [Focus on the user's notes and chat messages. Quote or closely reference their actual language. What do their word choices, tone shifts, and recurring themes tell you? This is the most personal section — make it feel like it. One to two paragraphs.]

        Where things seem to be shifting
        [Identify both positive signals and friction points. What's getting better? What's still hard? Be honest but encouraging. Reference specific entries or conversations. One to two paragraphs.]

        A few things worth sitting with
        [Gentle interpretive hypotheses. What might be going on beneath the surface? Frame these as invitations to reflect, not conclusions. If chat conversations reveal unresolved themes, mention them here. One to two paragraphs.]

        Three things you could try
        1. [Practical, specific, realistic — tied to something observed in the data]
        2. [Different angle — maybe about a pattern, a relationship, or a routine]
        3. [Something small and achievable for the next few days]

        Important: the response must be substantial, rich in detail, and genuinely personal. It should feel like a letter written by someone who has been paying close attention — long enough to be valuable, but written with enough warmth and rhythm that it never feels tiring to read.
        """
    }

    static func prompt(entries: [MoodEntry], snapshot: MoodReflectionSnapshot, chatSessions: [SupportChatSession], language: AppLanguage) -> String {
        let formattedEntries = entries.map { entry in
            let note = entry.note.trimmingCharacters(in: .whitespacesAndNewlines)
            let noteSummary = note.isEmpty ? "no note" : note
            return """
            - date: \(entry.date.formatted(date: .abbreviated, time: .omitted))
              mood: \(entry.mood.label(in: language))
              mood detail: \(entry.mood.detail(in: language))
              estimated energy: \(entry.mood.energyValue)
              note: \(noteSummary)
            """
        }.joined(separator: "\n")

        var chatContext = ""
        if !chatSessions.isEmpty {
            let formattedSessions = chatSessions.prefix(4).map { session in
                let userMessages = session.messages
                    .filter { $0.role == .user }
                    .prefix(8)
                    .map { "  user: \($0.text.trimmingCharacters(in: .whitespacesAndNewlines))" }
                    .joined(separator: "\n")
                return """
                - session: \(session.title) (last active: \(session.updatedAt.formatted(date: .abbreviated, time: .shortened)))
                \(userMessages)
                """
            }.joined(separator: "\n\n")

            chatContext = """

            Recent AI chat conversations (the user's own words during emotional support sessions):
            \(formattedSessions)

            These conversations reveal what the user was processing internally. Use them to personalize and deepen the analysis.
            """
        }

        return """
        Quantitative summary already observed by the app:
        - summary title: \(snapshot.title)
        - general message: \(snapshot.message)
        - recent trend: \(snapshot.trendLabel)
        - average energy: \(snapshot.energyLabel)
        - consistency: \(snapshot.consistencyLabel)
        - dominant mood: \(snapshot.dominantMoodLabel)

        Recent mood entries to analyze:
        \(formattedEntries)
        \(chatContext)

        Build a genuinely deep, personal premium analysis of all this data in \(language.aiLanguageName). Remember: weave the chat context naturally into the analysis — don't treat it as a separate section.
        """
    }

    static func parse(_ rawText: String, signature: String) -> PremiumEmotionalAnalysis {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.components(separatedBy: .newlines)
        let firstNonEmptyLine = lines.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? ""

        if firstNonEmptyLine.lowercased().hasPrefix("title:") {
            let title = firstNonEmptyLine
                .dropFirst("Title:".count)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let content = lines.dropFirst()
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return PremiumEmotionalAnalysis(
                signature: signature,
                title: title.isEmpty ? AppStrings.current.premiumAnalysisTitleFallback : title,
                content: content,
                generatedAt: .now
            )
        }

        return PremiumEmotionalAnalysis(
            signature: signature,
            title: AppStrings.current.premiumAnalysisTitleFallback,
            content: trimmed,
            generatedAt: .now
        )
    }
}

private final class PremiumEmotionalAnalysisService {
    func generateAnalysis(
        entries: [MoodEntry],
        snapshot: MoodReflectionSnapshot,
        chatSessions: [SupportChatSession],
        language: AppLanguage,
        signature: String
    ) async throws -> PremiumEmotionalAnalysis {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else {
            throw PremiumEmotionalAnalysisError.foundationUnavailable(
                AppStrings(language: language).text(it: "Questa analisi premium richiede Apple Foundation Model e non e disponibile sulla versione iOS attuale.", en: "This premium analysis requires Apple Foundation Model and isn't available on the current iOS version.", es: "Este análisis premium requiere Apple Foundation Model y no está disponible en la versión actual de iOS.", fr: "Cette analyse premium nécessite Apple Foundation Model et n'est pas disponible sur la version iOS actuelle.", zh: "此 Premium 分析需要 Apple Foundation Model，当前 iOS 版本不可用。", ar: "يتطلب هذا التحليل المميز Apple Foundation Model وهو غير متاح على إصدار iOS الحالي.", da: "Denne premium-analyse kræver Apple Foundation Model og er ikke tilgængelig på den nuværende iOS-version.", nb: "Denne premium-analysen krever Apple Foundation Model og er ikke tilgjengelig på den nåværende iOS-versjonen.", sv: "Den här premiumanalysen kräver Apple Foundation Model och är inte tillgänglig på den nuvarande iOS-versionen.")
            )
        }

        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw PremiumEmotionalAnalysisError.foundationUnavailable(
                AppStrings(language: language).text(it: "Apple Intelligence non e disponibile su questo dispositivo: \(String(describing: reason)).", en: "Apple Intelligence isn't available on this device: \(String(describing: reason)).", es: "Apple Intelligence no está disponible en este dispositivo: \(String(describing: reason)).", fr: "Apple Intelligence n'est pas disponible sur cet appareil : \(String(describing: reason)).", zh: "此设备不支持 Apple Intelligence：\(String(describing: reason)).", ar: "Apple Intelligence غير متاح على هذا الجهاز: \(String(describing: reason)).", da: "Apple Intelligence er ikke tilgængelig på denne enhed: \(String(describing: reason)).", nb: "Apple Intelligence er ikke tilgjengelig på denne enheten: \(String(describing: reason)).", sv: "Apple Intelligence är inte tillgängligt på den här enheten: \(String(describing: reason)).")
            )
        }

        let session = LanguageModelSession(
            model: model,
            instructions: PremiumEmotionalAnalysisPromptBuilder.instructions(language: language)
        )
        let response = try await session.respond(
            to: PremiumEmotionalAnalysisPromptBuilder.prompt(entries: entries, snapshot: snapshot, chatSessions: chatSessions, language: language)
        )
        let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !content.isEmpty else {
            throw PremiumEmotionalAnalysisError.emptyResponse
        }

        return PremiumEmotionalAnalysisPromptBuilder.parse(content, signature: signature)
        #else
        throw PremiumEmotionalAnalysisError.foundationUnavailable(
            AppStrings(language: language).text(it: "Il framework FoundationModels non e disponibile in questa build.", en: "The FoundationModels framework isn't available in this build.", es: "El framework FoundationModels no está disponible en esta compilación.", fr: "Le framework FoundationModels n'est pas disponible dans cette build.", zh: "此构建中不包含 FoundationModels 框架。", ar: "إطار FoundationModels غير متاح في هذه البنية.", da: "FoundationModels-frameworket er ikke tilgængeligt i dette build.", nb: "FoundationModels-rammeverket er ikke tilgjengelig i denne byggen.", sv: "FoundationModels-ramverket är inte tillgängligt i den här builden.")
        )
        #endif
    }
}

@MainActor
private final class PremiumEmotionalAnalysisCacheStore {
    static let shared = PremiumEmotionalAnalysisCacheStore()

    private let storageKey = "mindmesh.premium.emotional.analysis.cache"
    private let maximumAnalyses = 8
    private var analyses: [PremiumEmotionalAnalysis] = []

    private init() {
        load()
    }

    func analysis(for signature: String) -> PremiumEmotionalAnalysis? {
        analyses.first { $0.signature == signature }
    }

    func save(_ analysis: PremiumEmotionalAnalysis) {
        analyses.removeAll { $0.signature == analysis.signature }
        analyses.insert(analysis, at: 0)
        if analyses.count > maximumAnalyses {
            analyses = Array(analyses.prefix(maximumAnalyses))
        }
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }

        do {
            analyses = try JSONDecoder().decode([PremiumEmotionalAnalysis].self, from: data)
        } catch {
            analyses = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(analyses)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Unable to persist premium emotional analyses: \(error)")
        }
    }
}
