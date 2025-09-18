import SwiftUI
import Combine
import CryptoKit
#if canImport(FoundationModels)
import FoundationModels
#endif

struct AIInsightsView: View {
    @StateObject private var vm = AIInsightsViewModel()
    @EnvironmentObject private var languageStore: AppLanguageStore
    @EnvironmentObject private var premiumStore: PremiumStore
    @State private var showPremiumSheet = false
    @State private var showSupportChat = false

    private var premiumAnalysisTaskID: String {
        "\(premiumStore.hasPremiumAccess)-\(languageStore.selectedLanguage.rawValue)-\(vm.analysisRequestID(language: languageStore.selectedLanguage))"
    }

    private var t: AppStrings {
        AppStrings(language: languageStore.selectedLanguage)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        MMNavigationHeaderBlock(text: t.insightsTitle, topPadding: MMSpacing.xxxl)

                        VStack(alignment: .leading, spacing: MMSpacing.xl) {
                            if let snapshot = vm.snapshot {
                                reflectionCard(snapshot: snapshot)
                                overviewCard(snapshot: snapshot)
                                detailCard(snapshot: snapshot)
                                premiumCard(snapshot: snapshot)
                            } else {
                                emptyState
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                .safeAreaPadding(.horizontal, MMSpacing.lg)
                .safeAreaPadding(.bottom, MMSpacing.md)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPremiumSheet) {
                PremiumSheet()
            }
            .sheet(isPresented: $showSupportChat) {
                AISupportChatView()
            }
            .task(id: premiumAnalysisTaskID) {
                await vm.loadPremiumAnalysisIfNeeded(hasPremiumAccess: premiumStore.hasPremiumAccess, language: languageStore.selectedLanguage)
            }
        }
    }

    private func reflectionCard(snapshot: MoodReflectionSnapshot) -> some View {
        MMCard(borderColor: Color.mmAccent.opacity(0.16), backgroundColor: Color.mmCard.opacity(0.92)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                MMSectionLabel(text: t.last7DaysSection)

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
                MMSectionLabel(text: t.overviewSection)

                HStack(spacing: MMSpacing.md) {
                    StatCard(value: snapshot.dominantMoodLabel, label: t.mostRecurringMood, color: .mmAccent)
                    StatCard(value: snapshot.trendLabel, label: t.recentTrend, color: .mmAccent3)
                }

                HStack(spacing: MMSpacing.md) {
                    StatCard(value: snapshot.energyLabel, label: t.averageEnergy, color: .mmTeal)
                    StatCard(value: snapshot.consistencyLabel, label: t.toneVariation, color: .mmRose)
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
                        MMSectionLabel(text: t.fullAnalysis)
                        Spacer()
                        MMInlineBadge(title: t.premiumBadge, icon: "sparkles", tint: .mmAccent)
                    }

                    if vm.isGeneratingPremiumAnalysis {
                        premiumLoadingState
                    } else if let premiumAnalysis = vm.premiumAnalysis {
                        premiumAnalysisContent(premiumAnalysis)
                    } else if let premiumAnalysisError = vm.premiumAnalysisError {
                        premiumAnalysisErrorState(premiumAnalysisError)
                    }

                    VStack(spacing: 12) {
                        MMSecondaryButton(title: t.regenerateAnalysis, icon: "arrow.clockwise", tint: .mmAccent3) {
                            Task {
                                await vm.regeneratePremiumAnalysis(language: languageStore.selectedLanguage)
                            }
                        }
                        .disabled(!vm.hasEnoughDataForPremiumAnalysis || vm.isGeneratingPremiumAnalysis)

                        MMSecondaryButton(title: t.openPremiumChat, icon: "bubble.left.and.bubble.right.fill", tint: .mmAccent) {
                            showSupportChat = true
                        }
                    }
                }
            }
        } else {
            lockedPremiumCard
        }
    }

    private var lockedPremiumCard: some View {
        MMCard(borderColor: Color.mmAccent.opacity(0.14), backgroundColor: Color.mmCard.opacity(0.92)) {
            VStack(alignment: .leading, spacing: MMSpacing.lg) {
                HStack {
                    MMSectionLabel(text: t.fullAnalysis)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.mmAccent)
                }

                Text(t.lockedAnalysisTitle)
                    .font(MMFont.title(22, weight: .semibold))
                    .foregroundStyle(.mmTextPrimary)

                Text(t.lockedAnalysisBody)
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
                        Text(t.includedInPremium)
                            .font(MMFont.caption(12, weight: .semibold))
                            .foregroundStyle(.mmAccent)

                        Text(t.premiumBundleDescription)
                            .font(MMFont.body(14))
                            .foregroundStyle(.mmTextPrimary)
                            .lineSpacing(3)
                    }
                }

                MMPrimaryButton(title: t.unlockFullAnalysis, icon: "sparkles") {
                    showPremiumSheet = true
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

                Text(t.premiumLoadingTitle)
                    .font(MMFont.title(18, weight: .semibold))
                    .foregroundStyle(.mmTextPrimary)

                Text(t.premiumLoadingBody)
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

                Text(t.premiumGeneratedAt(premiumAnalysis.generatedAt.formatted(date: .abbreviated, time: .shortened)))
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
                Text(t.premiumAnalysisUnavailable)
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
        VStack(alignment: .leading, spacing: MMSpacing.xxxl) {
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

                    Text(t.notEnoughDataTitle)
                        .font(MMFont.display(28, weight: .bold))
                        .foregroundStyle(.mmTextPrimary)

                    Text(t.notEnoughDataBody)
                        .font(MMFont.body(15))
                        .foregroundStyle(.mmTextMuted)
                        .lineSpacing(4)
                }
            }

            if !premiumStore.hasPremiumAccess {
                lockedPremiumCard
            }
        }
    }
}

struct AIInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        AIInsightsView()
            .environmentObject(PremiumStore(storeKitEnabled: false, initialPremiumAccess: true))
            .environmentObject(AppLanguageStore(initialLanguage: .italian))
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

        do {
            let analysis = try await analysisService.generateAnalysis(
                entries: premiumAnalysisEntries,
                snapshot: snapshot,
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
        You are a premium emotional analyst for a journaling app. Write entirely in \(language.aiLanguageName).
        Produce a very detailed, sharp, concrete, and highly personalized reading of the user's recent check-ins.
        Rules:
        - use only the available data and never invent facts;
        - do not make clinical diagnoses;
        - highlight patterns, turning points, contrasts, possible triggers, and factors that seem to help;
        - analyze text notes very carefully when present;
        - be detailed enough to clearly justify the value of a premium plan;
        - avoid vague or generic phrasing;
        - stay interpretive but cautious: speak in terms of hypotheses, signals, and plausible readings, not certainties;
        - always end with three practical, specific, realistic actions.

        Required format:
        Title: [one short, sharp, specific line]

        General picture
        [dense paragraph]

        Recurring patterns
        [dense paragraph]

        Reading of the notes
        [dense paragraph]

        Signals of improvement and signals of friction
        [dense paragraph]

        Interpretive hypotheses
        [dense paragraph]

        What to monitor now
        [dense paragraph]

        Three practical actions
        1. ...
        2. ...
        3. ...

        The response must feel substantial and premium, not brief.
        """
    }

    static func prompt(entries: [MoodEntry], snapshot: MoodReflectionSnapshot, language: AppLanguage) -> String {
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

        return """
        Quantitative summary already observed by the app:
        - summary title: \(snapshot.title)
        - general message: \(snapshot.message)
        - recent trend: \(snapshot.trendLabel)
        - average energy: \(snapshot.energyLabel)
        - consistency: \(snapshot.consistencyLabel)
        - dominant mood: \(snapshot.dominantMoodLabel)

        Recent entries to analyze:
        \(formattedEntries)

        Build a genuinely deep premium analysis of these data in \(language.aiLanguageName).
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
            to: PremiumEmotionalAnalysisPromptBuilder.prompt(entries: entries, snapshot: snapshot, language: language)
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
