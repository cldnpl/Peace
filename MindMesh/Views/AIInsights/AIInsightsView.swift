import SwiftUI
import Combine
import CryptoKit
#if canImport(FoundationModels)
import FoundationModels
#endif

struct AIInsightsView: View {
    @StateObject private var vm = AIInsightsViewModel()
    @EnvironmentObject private var premiumStore: PremiumStore
    @State private var showPremiumSheet = false
    @State private var showSupportChat = false

    private var premiumAnalysisTaskID: String {
        "\(premiumStore.hasPremiumAccess)-\(vm.analysisRequestID)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MMSpacing.xxxl) {
                        if let snapshot = vm.snapshot {
                            reflectionCard(snapshot: snapshot)
                            overviewCard(snapshot: snapshot)
                            detailCard(snapshot: snapshot)
                            premiumCard(snapshot: snapshot)
                        } else {
                            emptyState
                        }
                    }
                    .padding(.bottom, 40)
                }
                .safeAreaPadding(.horizontal, MMSpacing.lg)
                .safeAreaPadding(.bottom, MMSpacing.md)
            }
            .navigationTitle("Riflessioni")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPremiumSheet) {
                PremiumSheet()
            }
            .sheet(isPresented: $showSupportChat) {
                AISupportChatView()
            }
            .task(id: premiumAnalysisTaskID) {
                await vm.loadPremiumAnalysisIfNeeded(hasPremiumAccess: premiumStore.hasPremiumAccess)
            }
        }
    }

    private func reflectionCard(snapshot: MoodReflectionSnapshot) -> some View {
        MMCard(borderColor: Color.mmAccent.opacity(0.16), backgroundColor: Color.mmCard.opacity(0.92)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                MMSectionLabel(text: "Ultimi 7 giorni")

                Text(snapshot.title)
                    .font(MMFont.display(30, weight: .bold))
                    .foregroundStyle(.mmTextPrimary)

                Text(snapshot.message)
                    .font(MMFont.body(15))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(4)
            }
        }
    }

    private func detailCard(snapshot: MoodReflectionSnapshot) -> some View {
        MMCard {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                Text(snapshot.detailTitle)
                    .font(MMFont.caption(13, weight: .semibold))
                    .foregroundStyle(.mmTextMuted)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(snapshot.detailValue)
                        .font(MMFont.display(34, weight: .bold))
                        .foregroundStyle(.mmTextPrimary)

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.mmAccent3)
                }

                Text(snapshot.detailMessage)
                    .font(MMFont.body(14))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(4)
            }
        }
    }

    private func overviewCard(snapshot: MoodReflectionSnapshot) -> some View {
        MMCard(backgroundColor: Color.mmCard.opacity(0.9)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                MMSectionLabel(text: "Panoramica")

                HStack(spacing: MMSpacing.md) {
                    StatCard(value: snapshot.dominantMoodLabel, label: "Voce che torna di più", color: .mmAccent)
                    StatCard(value: snapshot.trendLabel, label: "Andamento recente", color: .mmAccent3)
                }

                HStack(spacing: MMSpacing.md) {
                    StatCard(value: snapshot.energyLabel, label: "Energia media", color: .mmTeal)
                    StatCard(value: snapshot.consistencyLabel, label: "Quanto cambia il tono", color: .mmRose)
                }
            }
        }
    }

    @ViewBuilder
    private func premiumCard(snapshot: MoodReflectionSnapshot) -> some View {
        if premiumStore.hasPremiumAccess {
            MMCard(borderColor: Color.mmAccent.opacity(0.18), backgroundColor: Color.mmCard.opacity(0.94)) {
                VStack(alignment: .leading, spacing: MMSpacing.lg) {
                    HStack {
                        MMSectionLabel(text: "Analisi completa")
                        Spacer()
                        MMInlineBadge(title: "Premium", icon: "sparkles", tint: .mmAccent)
                    }

                    if vm.isGeneratingPremiumAnalysis {
                        premiumLoadingState
                    } else if let premiumAnalysis = vm.premiumAnalysis {
                        premiumAnalysisContent(premiumAnalysis)
                    } else if let premiumAnalysisError = vm.premiumAnalysisError {
                        premiumAnalysisErrorState(premiumAnalysisError)
                    }

                    VStack(spacing: 12) {
                        MMSecondaryButton(title: "Rigenera analisi", icon: "arrow.clockwise", tint: .mmAccent3) {
                            Task {
                                await vm.regeneratePremiumAnalysis()
                            }
                        }
                        .disabled(!vm.hasEnoughDataForPremiumAnalysis || vm.isGeneratingPremiumAnalysis)

                        MMSecondaryButton(title: "Apri la chat Premium", icon: "bubble.left.and.bubble.right.fill", tint: .mmAccent) {
                            showSupportChat = true
                        }
                    }
                }
            }
        } else {
            MMCard(borderColor: Color.mmAccent.opacity(0.14), backgroundColor: Color.mmCard.opacity(0.92)) {
                VStack(alignment: .leading, spacing: MMSpacing.lg) {
                    HStack {
                        MMSectionLabel(text: "Analisi completa")
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.mmAccent)
                    }

                    Text("La panoramica è pronta. L'analisi completa si sblocca con Premium.")
                        .font(MMFont.title(22, weight: .semibold))
                        .foregroundStyle(.mmTextPrimary)

                    Text("Con Premium puoi ottenere una lettura dettagliatissima generata on-device dal Foundation Model, costruita davvero sulle registrazioni recenti e sulle note che hai scritto.")
                        .font(MMFont.body(14))
                        .foregroundStyle(.mmTextMuted)
                        .lineSpacing(4)

                    MMCard(
                        padding: MMSpacing.lg,
                        cornerRadius: MMRadius.md,
                        borderColor: Color.mmAccent.opacity(0.14),
                        backgroundColor: Color.mmSurface.opacity(0.76)
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Incluso nel Premium")
                                .font(MMFont.caption(12, weight: .semibold))
                                .foregroundStyle(.mmAccent)

                            Text("Un'analisi premium molto piu profonda dei pattern emotivi recenti, piu una chat di supporto per mettere ordine nei pensieri difficili.")
                                .font(MMFont.body(14))
                                .foregroundStyle(.mmTextPrimary)
                                .lineSpacing(3)
                        }
                    }

                    MMPrimaryButton(title: "Sblocca l'analisi completa", icon: "sparkles") {
                        showPremiumSheet = true
                    }
                }
            }
        }
    }

    private var premiumLoadingState: some View {
        MMCard(
            padding: MMSpacing.lg,
            cornerRadius: MMRadius.md,
            borderColor: Color.mmAccent.opacity(0.14),
            backgroundColor: Color.mmSurface.opacity(0.76)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ProgressView()
                    .tint(.mmAccent)

                Text("Sto preparando una lettura premium molto piu profonda dei tuoi check-in recenti.")
                    .font(MMFont.title(18, weight: .semibold))
                    .foregroundStyle(.mmTextPrimary)

                Text("L'analisi usa Apple Foundation Model e tiene conto del ritmo, delle note testuali, dei cambi di tono e dei segnali da monitorare.")
                    .font(MMFont.body(14))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(3)
            }
        }
    }

    private func premiumAnalysisContent(_ premiumAnalysis: PremiumEmotionalAnalysis) -> some View {
        VStack(alignment: .leading, spacing: MMSpacing.lg) {
            VStack(alignment: .leading, spacing: 8) {
                Text(premiumAnalysis.title)
                    .font(MMFont.title(24, weight: .semibold))
                    .foregroundStyle(.mmTextPrimary)

                Text("Generata il \(premiumAnalysis.generatedAt.formatted(date: .abbreviated, time: .shortened)) · Apple Foundation Model")
                    .font(MMFont.caption(12, weight: .medium))
                    .foregroundStyle(.mmTextDim)
            }

            MMCard(
                padding: MMSpacing.lg,
                cornerRadius: MMRadius.md,
                borderColor: Color.mmAccent2.opacity(0.18),
                backgroundColor: Color.mmSurface.opacity(0.72)
            ) {
                Text(premiumAnalysis.content)
                    .font(MMFont.body(14))
                    .foregroundStyle(.mmTextPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func premiumAnalysisErrorState(_ message: String) -> some View {
        MMCard(
            padding: MMSpacing.lg,
            cornerRadius: MMRadius.md,
            borderColor: Color.mmRose.opacity(0.18),
            backgroundColor: Color.mmRose.opacity(0.08)
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Analisi premium non disponibile")
                    .font(MMFont.title(18, weight: .semibold))
                    .foregroundStyle(.mmTextPrimary)

                Text(message)
                    .font(MMFont.body(14))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(3)
            }
        }
    }

    private var emptyState: some View {
        MMCard(borderColor: Color.mmAccent.opacity(0.14), backgroundColor: Color.mmCard.opacity(0.92)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.mmSurface)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "quote.bubble")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.mmAccent)
                    )

                Text("Non ho ancora abbastanza dati per una riflessione approfondita.")
                    .font(MMFont.display(28, weight: .bold))
                    .foregroundStyle(.mmTextPrimary)

                Text("Registra piu spesso il tuo umore nei prossimi giorni. Quando ci saranno almeno 3 registrazioni recenti, qui comparira una panoramica reale dell'andamento.")
                    .font(MMFont.body(15))
                    .foregroundStyle(.mmTextMuted)
                    .lineSpacing(4)
            }
        }
    }
}

struct AIInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        AIInsightsView()
            .environmentObject(PremiumStore(storeKitEnabled: false, initialPremiumAccess: true))
    }
}

struct PremiumEmotionalAnalysis: Codable {
    let signature: String
    let title: String
    let content: String
    let generatedAt: Date
}

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
        self.snapshot = store.reflectionSnapshot()
        self.premiumAnalysis = cacheStore.analysis(for: analysisRequestID)

        store.$entries
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleEntriesUpdated()
            }
            .store(in: &cancellables)
    }

    var analysisRequestID: String {
        premiumAnalysisSignature() ?? "no-premium-analysis-data"
    }

    var hasEnoughDataForPremiumAnalysis: Bool {
        premiumAnalysisEntries.count >= 3
    }

    func loadPremiumAnalysisIfNeeded(hasPremiumAccess: Bool) async {
        guard hasPremiumAccess else {
            premiumAnalysis = nil
            premiumAnalysisError = nil
            return
        }

        guard let signature = premiumAnalysisSignature() else {
            premiumAnalysis = nil
            premiumAnalysisError = "Servono almeno 3 registrazioni recenti per costruire un'analisi premium davvero utile."
            return
        }

        if let cached = cacheStore.analysis(for: signature) {
            premiumAnalysis = cached
            premiumAnalysisError = nil
            return
        }

        await generatePremiumAnalysis(forceRefresh: false)
    }

    func regeneratePremiumAnalysis() async {
        await generatePremiumAnalysis(forceRefresh: true)
    }

    private var premiumAnalysisEntries: [MoodEntry] {
        store.recentEntries(lastDays: 14)
    }

    private func handleEntriesUpdated() {
        snapshot = store.reflectionSnapshot()
        premiumAnalysisError = nil
        premiumAnalysis = cacheStore.analysis(for: analysisRequestID)
    }

    private func premiumAnalysisSignature() -> String? {
        let entries = premiumAnalysisEntries
        guard entries.count >= 3 else { return nil }

        let rawValue = entries.map { entry in
            let note = entry.note.trimmingCharacters(in: .whitespacesAndNewlines)
            return "\(entry.id.uuidString)|\(entry.date.timeIntervalSince1970)|\(entry.mood.rawValue)|\(note)"
        }.joined(separator: "||")

        let digest = SHA256.hash(data: Data(rawValue.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func generatePremiumAnalysis(forceRefresh: Bool) async {
        guard let snapshot, let signature = premiumAnalysisSignature() else {
            premiumAnalysis = nil
            premiumAnalysisError = "Servono almeno 3 registrazioni recenti per costruire un'analisi premium davvero utile."
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

        do {
            let analysis = try await analysisService.generateAnalysis(
                entries: premiumAnalysisEntries,
                snapshot: snapshot,
                signature: signature
            )
            premiumAnalysis = analysis
            cacheStore.save(analysis)
        } catch let error as PremiumEmotionalAnalysisError {
            premiumAnalysis = nil
            premiumAnalysisError = error.userMessage
        } catch {
            premiumAnalysis = nil
            premiumAnalysisError = "Non riesco a generare l'analisi premium in questo momento."
        }
    }
}

private enum PremiumEmotionalAnalysisError: Error {
    case foundationUnavailable(String)
    case emptyResponse
    case generationFailed

    var userMessage: String {
        switch self {
        case .foundationUnavailable(let detail):
            return detail
        case .emptyResponse:
            return "Il Foundation Model non ha restituito un contenuto utile. Riprova tra poco."
        case .generationFailed:
            return "La generazione dell'analisi premium non e andata a buon fine."
        }
    }
}

private struct PremiumEmotionalAnalysisPromptBuilder {
    static let instructions = """
    Sei un analista emotivo premium per un'app di journaling. Devi scrivere in italiano una lettura molto approfondita, nitida, concreta e altamente personalizzata dei check-in recenti.
    Regole:
    - usa solo i dati disponibili, senza inventare nulla;
    - non fare diagnosi cliniche;
    - evidenzia pattern, svolte, contrasti, trigger possibili e fattori che sembrano aiutare;
    - analizza con molta attenzione le note testuali, se presenti;
    - sii dettagliato: il tono deve giustificare chiaramente un piano premium;
    - evita frasi vaghe o generiche;
    - mantieni una cautela interpretativa: parla di ipotesi, segnali e letture plausibili, non di certezze assolute;
    - chiudi sempre con tre azioni pratiche, specifiche e realistiche.

    Formato obbligatorio:
    Titolo: [una riga breve, intensa e specifica]

    Quadro generale
    [paragrafo denso]

    Pattern ricorrenti
    [paragrafo denso]

    Lettura delle note
    [paragrafo denso]

    Segnali di miglioramento e segnali di attrito
    [paragrafo denso]

    Ipotesi interpretative
    [paragrafo denso]

    Cosa monitorare adesso
    [paragrafo denso]

    Tre azioni pratiche
    1. ...
    2. ...
    3. ...

    La risposta deve essere sostanziosa e da premium, non breve.
    """

    static func prompt(entries: [MoodEntry], snapshot: MoodReflectionSnapshot) -> String {
        let formattedEntries = entries.map { entry in
            let note = entry.note.trimmingCharacters(in: .whitespacesAndNewlines)
            let noteSummary = note.isEmpty ? "nessuna nota" : note
            return """
            - data: \(entry.date.formatted(date: .abbreviated, time: .omitted))
              umore: \(entry.mood.label)
              dettaglio umore: \(entry.mood.detail)
              energia stimata: \(entry.mood.energyValue)
              nota: \(noteSummary)
            """
        }.joined(separator: "\n")

        return """
        Sintesi quantitativa gia osservata dall'app:
        - titolo riassuntivo: \(snapshot.title)
        - messaggio generale: \(snapshot.message)
        - andamento recente: \(snapshot.trendLabel)
        - energia media: \(snapshot.energyLabel)
        - consistenza: \(snapshot.consistencyLabel)
        - voce dominante: \(snapshot.dominantMoodLabel)

        Registrazioni recenti da analizzare:
        \(formattedEntries)

        Costruisci una lettura premium veramente approfondita di questi dati.
        """
    }

    static func parse(_ rawText: String, signature: String) -> PremiumEmotionalAnalysis {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.components(separatedBy: .newlines)
        let firstNonEmptyLine = lines.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? ""

        if firstNonEmptyLine.lowercased().hasPrefix("titolo:") {
            let title = firstNonEmptyLine
                .dropFirst("Titolo:".count)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let content = lines.dropFirst()
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return PremiumEmotionalAnalysis(
                signature: signature,
                title: title.isEmpty ? "Analisi emotiva premium" : title,
                content: content,
                generatedAt: .now
            )
        }

        return PremiumEmotionalAnalysis(
            signature: signature,
            title: "Analisi emotiva premium",
            content: trimmed,
            generatedAt: .now
        )
    }
}

private final class PremiumEmotionalAnalysisService {
    func generateAnalysis(
        entries: [MoodEntry],
        snapshot: MoodReflectionSnapshot,
        signature: String
    ) async throws -> PremiumEmotionalAnalysis {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else {
            throw PremiumEmotionalAnalysisError.foundationUnavailable(
                "Questa analisi premium richiede Apple Foundation Model e non e disponibile sulla versione iOS attuale."
            )
        }

        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw PremiumEmotionalAnalysisError.foundationUnavailable(
                "Apple Intelligence non e disponibile su questo dispositivo: \(String(describing: reason))."
            )
        }

        let session = LanguageModelSession(
            model: model,
            instructions: PremiumEmotionalAnalysisPromptBuilder.instructions
        )
        let response = try await session.respond(
            to: PremiumEmotionalAnalysisPromptBuilder.prompt(entries: entries, snapshot: snapshot)
        )
        let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !content.isEmpty else {
            throw PremiumEmotionalAnalysisError.emptyResponse
        }

        return PremiumEmotionalAnalysisPromptBuilder.parse(content, signature: signature)
        #else
        throw PremiumEmotionalAnalysisError.foundationUnavailable(
            "Il framework FoundationModels non e disponibile in questa build."
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
