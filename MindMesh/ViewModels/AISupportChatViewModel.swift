import SwiftUI

@MainActor
final class AISupportChatViewModel: ObservableObject {
    @Published var messages: [SupportChatMessage] = []
    @Published var draft = ""
    @Published private(set) var recentSessions: [SupportChatSession] = []
    @Published private(set) var isProcessing = false
    @Published private(set) var sourceLabel = AppStrings.current.supportChatUnavailable
    @Published private(set) var sourceDetail = AppStrings.current.supportNotConfigured
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
        let t = AppStrings.current
        return [
            t.quickPromptOverwhelmed,
            t.quickPromptNegativeThoughts,
            t.quickPromptGuilt,
            t.quickPromptHelpUnderstand
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
                sourceLabel = AppStrings.current.supportChatUnavailable
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
        let t = AppStrings.current
        if case AISupportChatServiceError.foundationModelUnavailable = error {
            return t.supportFoundationUnavailable
        }

        if case AISupportChatServiceError.notConfigured = error {
            return t.supportNotConfigured
        }

        return t.supportModelNoReply
    }

    private func detailMessage(for error: Error) -> String {
        let t = AppStrings.current
        if case let AISupportChatServiceError.foundationModelUnavailable(detail) = error {
            return detail
        }

        if case AISupportChatServiceError.notConfigured = error {
            return t.missingOpenAIOrBackend
        }

        return t.invalidRemoteRequest
    }

    private static func makeWelcomeMessage(snapshot: MoodReflectionSnapshot?) -> String {
        AppStrings.current.supportWelcome(snapshotTitle: snapshot?.title)
    }

    private static func makeSessionTitle(from messages: [SupportChatMessage]) -> String {
        guard let firstUserMessage = messages.first(where: { $0.role == .user })?.text.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return AppStrings.current.premiumChatTitle
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
