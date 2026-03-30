import SwiftUI

@MainActor
final class AISupportChatViewModel: ObservableObject {
    @Published var messages: [SupportChatMessage] = []
    @Published var draft = ""
    @Published private(set) var recentSessions: [SupportChatSession] = []
    @Published private(set) var isProcessing = false
    @Published private(set) var sourceLabel = "Chat non configurata"
    @Published private(set) var sourceDetail = "Configura OpenAI o un backend AI per attivare risposte reali."
    @Published private(set) var isUsingRemoteModel = true

    private let store: MoodJournalStore
    private let primaryService: AISupportChatService
    private let historyStore: AISupportChatHistoryStore
    private var currentSessionID: UUID?

    convenience init(
        serviceSelection: AISupportChatServiceSelection = AISupportServiceFactory.primaryServiceSelection()
    ) {
        self.init(store: MoodJournalStore.shared, serviceSelection: serviceSelection)
    }

    init(
        store: MoodJournalStore,
        serviceSelection: AISupportChatServiceSelection = AISupportServiceFactory.primaryServiceSelection()
    ) {
        self.store = store
        self.primaryService = serviceSelection.service
        self.historyStore = .shared
        self.messages = [SupportChatMessage(role: .assistant, text: Self.makeWelcomeMessage(snapshot: store.reflectionSnapshot()))]
        self.recentSessions = self.historyStore.recentSessions(limit: 6)
        self.isUsingRemoteModel = serviceSelection.isRemote
        self.sourceLabel = serviceSelection.sourceLabel
        self.sourceDetail = serviceSelection.sourceDetail
    }

    var quickPrompts: [String] {
        [
            "Mi sento sopraffatta oggi",
            "Ho pensieri molto negativi",
            "Mi sento in colpa e faccio fatica a staccare",
            "Aiutami a capire cosa sto provando"
        ]
    }

    func sendMessage() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isProcessing else { return }

        draft = ""
        appendUserMessage(trimmed)
        queueAssistantReply(for: trimmed)
    }

    func sendQuickPrompt(_ prompt: String) {
        guard !isProcessing else { return }
        draft = prompt
        sendMessage()
    }

    func resetConversation() {
        draft = ""
        isProcessing = false
        currentSessionID = nil
        messages = [SupportChatMessage(role: .assistant, text: Self.makeWelcomeMessage(snapshot: store.reflectionSnapshot()))]
    }

    func loadSession(_ session: SupportChatSession) {
        draft = ""
        isProcessing = false
        currentSessionID = session.id
        messages = session.messages
    }

    func isCurrentSession(_ session: SupportChatSession) -> Bool {
        currentSessionID == session.id
    }

    private func appendUserMessage(_ text: String) {
        messages.append(SupportChatMessage(role: .user, text: text))
        persistConversation()
    }

    private func queueAssistantReply(for input: String) {
        isProcessing = true
        let context = AISupportChatContext(
            userInput: input,
            conversation: messages,
            snapshot: store.reflectionSnapshot()
        )

        Task {
            do {
                let response = try await primaryService.generateReply(context: context)
                applyResponse(response)
            } catch {
                messages.append(SupportChatMessage(
                    role: .assistant,
                    text: failureMessage(for: error)
                ))
                sourceLabel = "Chat AI non disponibile"
                sourceDetail = detailMessage(for: error)
                isUsingRemoteModel = false
                isProcessing = false
                persistConversation()
            }
        }
    }

    private func applyResponse(_ response: AISupportChatResponse) {
        messages.append(SupportChatMessage(role: .assistant, text: response.text))
        persistConversation()
        sourceLabel = response.sourceLabel
        sourceDetail = response.sourceDetail
        isUsingRemoteModel = response.isRemote
        isProcessing = false
    }

    private func persistConversation() {
        guard messages.contains(where: { $0.role == .user }) else { return }

        let sessionID = currentSessionID ?? UUID()
        currentSessionID = sessionID

        historyStore.save(
            SupportChatSession(
                id: sessionID,
                title: Self.makeSessionTitle(from: messages),
                updatedAt: .now,
                messages: messages
            )
        )
        recentSessions = historyStore.recentSessions(limit: 6)
    }

    private func failureMessage(for error: Error) -> String {
        if case AISupportChatServiceError.foundationModelUnavailable = error {
            return "Apple Intelligence non è disponibile su questo dispositivo, quindi questa chat non può usare il Foundation Model."
        }

        if case AISupportChatServiceError.notConfigured = error {
            return "La chat AI non è ancora attiva. Inserisci una configurazione OpenAI o collega un backend per usare un modello reale."
        }

        return "In questo momento il modello AI non sta rispondendo. Riprova tra poco."
    }

    private func detailMessage(for error: Error) -> String {
        if case let AISupportChatServiceError.foundationModelUnavailable(detail) = error {
            return detail
        }

        if case AISupportChatServiceError.notConfigured = error {
            return "Manca `MINDMESH_OPENAI_API_KEY` oppure un endpoint backend valido."
        }

        return "La richiesta al modello remoto e fallita oppure la configurazione non e valida."
    }

    private static func makeWelcomeMessage(snapshot: MoodReflectionSnapshot?) -> String {
        if let snapshot {
            return """
            Questa chat premium ti aiuta a mettere ordine nelle emozioni difficili, senza fare diagnosi. Dal tuo andamento recente emerge questo: \(snapshot.title.lowercased())

            Se vuoi, raccontami cosa pesa di piu oggi e proviamo a scomporlo insieme.
            """
        }

        return """
        Questa chat premium ti aiuta a dare un nome alle emozioni difficili e a renderle piu leggibili, senza fare diagnosi o sostituire un professionista.

        Scrivimi cosa senti in questo momento, anche in modo disordinato.
        """
    }

    private static func makeSessionTitle(from messages: [SupportChatMessage]) -> String {
        guard let firstUserMessage = messages.first(where: { $0.role == .user })?.text.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return "Chat Premium"
        }

        if firstUserMessage.count <= 42 {
            return firstUserMessage
        }

        return String(firstUserMessage.prefix(42)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}

@MainActor
private final class AISupportChatHistoryStore {
    static let shared = AISupportChatHistoryStore()

    private let storageKey = "mindmesh.ai.support.chat.history"
    private let maximumSessions = 12
    private var sessions: [SupportChatSession] = []

    private init() {
        load()
    }

    func recentSessions(limit: Int) -> [SupportChatSession] {
        Array(sessions.sorted { $0.updatedAt > $1.updatedAt }.prefix(limit))
    }

    func save(_ session: SupportChatSession) {
        sessions.removeAll { $0.id == session.id }
        sessions.append(session)
        sessions.sort { $0.updatedAt > $1.updatedAt }
        if sessions.count > maximumSessions {
            sessions = Array(sessions.prefix(maximumSessions))
        }
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }

        do {
            sessions = try JSONDecoder().decode([SupportChatSession].self, from: data)
                .sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            sessions = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Unable to persist support chat history: \(error)")
        }
    }
}
