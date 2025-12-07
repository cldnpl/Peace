import SwiftUI

@MainActor
final class AISupportChatViewModel: ObservableObject {
    @Published var messages: [SupportChatMessage] = []
    @Published var draft = ""
    @Published private(set) var isProcessing = false
    @Published private(set) var sourceLabel = "Chat non configurata"
    @Published private(set) var sourceDetail = "Configura OpenAI o un backend AI per attivare risposte reali."
    @Published private(set) var isUsingRemoteModel = true

    private let store: MoodJournalStore
    private let primaryService: AISupportChatService

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
        self.messages = [SupportChatMessage(role: .assistant, text: Self.makeWelcomeMessage(snapshot: store.reflectionSnapshot()))]
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
        messages = [SupportChatMessage(role: .assistant, text: Self.makeWelcomeMessage(snapshot: store.reflectionSnapshot()))]
    }

    private func appendUserMessage(_ text: String) {
        messages.append(SupportChatMessage(role: .user, text: text))
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
            }
        }
    }

    private func applyResponse(_ response: AISupportChatResponse) {
        messages.append(SupportChatMessage(role: .assistant, text: response.text))
        sourceLabel = response.sourceLabel
        sourceDetail = response.sourceDetail
        isUsingRemoteModel = response.isRemote
        isProcessing = false
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
}
