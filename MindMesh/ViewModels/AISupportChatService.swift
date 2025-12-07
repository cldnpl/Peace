import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct AISupportChatContext {
    let userInput: String
    let conversation: [SupportChatMessage]
    let snapshot: MoodReflectionSnapshot?
}

struct AISupportChatResponse {
    let text: String
    let sourceLabel: String
    let sourceDetail: String
    let isRemote: Bool
}

protocol AISupportChatService {
    func generateReply(context: AISupportChatContext) async throws -> AISupportChatResponse
}

struct AISupportChatServiceSelection {
    let service: AISupportChatService
    let sourceLabel: String
    let sourceDetail: String
    let isRemote: Bool
}

enum AISupportServiceFactory {
    private static let localBackendURL = URL(string: "http://127.0.0.1:8787/api/ai/support-chat")!

    static func primaryService() -> AISupportChatService {
        primaryServiceSelection().service
    }

    static func primaryServiceSelection() -> AISupportChatServiceSelection {
        if let selection = foundationModelSelection() {
            return selection
        }

        return fallbackSelection()
    }

    private static func fallbackSelection() -> AISupportChatServiceSelection {
        configuredServiceSelection() ?? localBackendSelection()
    }

    private static func localBackendSelection() -> AISupportChatServiceSelection {
        AISupportChatServiceSelection(
            service: RemoteAISupportChatService(endpointURL: localBackendURL),
            sourceLabel: "Backend AI Locale",
            sourceDetail: "Connesso a http://127.0.0.1:8787",
            isRemote: true
        )
    }

    private static func configuredServiceSelection() -> AISupportChatServiceSelection? {
        if let endpointURL = AIConfiguration.supportChatEndpointURL {
            return AISupportChatServiceSelection(
                service: RemoteAISupportChatService(endpointURL: endpointURL),
                sourceLabel: "Backend AI configurato",
                sourceDetail: "La chat usa il backend AI remoto configurato.",
                isRemote: true
            )
        }

        if let configuration = OpenAIConfiguration.current {
            return AISupportChatServiceSelection(
                service: OpenAIDirectSupportChatService(configuration: configuration),
                sourceLabel: "OpenAI · \(configuration.model)",
                sourceDetail: "La chat usa direttamente OpenAI.",
                isRemote: true
            )
        }

        return nil
    }

    #if canImport(FoundationModels)
    private static func foundationModelSelection() -> AISupportChatServiceSelection? {
        guard #available(iOS 26.0, *) else {
            return nil
        }

        let service = FoundationModelAISupportChatService()
        guard service.isAvailable else {
            return nil
        }

        return AISupportChatServiceSelection(
            service: service,
            sourceLabel: "Apple Foundation Model",
            sourceDetail: "Risposta on-device con Apple Intelligence.",
            isRemote: false
        )
    }
    #else
    private static func foundationModelSelection() -> AISupportChatServiceSelection? {
        nil
    }
    #endif
}

private enum AISupportPromptBuilder {
    static let instructions = """
    Sei un supporto emotivo scritto in italiano. Devi sembrare caldo, presente, umano e naturale, non meccanico.
    Obiettivo: aiutare la persona a sentirsi capita e a fare chiarezza, senza usare frasi standard o paternalistiche.
    Regole:
    - rispondi in italiano;
    - parti da quello che la persona ha appena scritto, non dai dati dell'app;
    - usa il contesto dell'app solo se davvero utile e in modo leggero;
    - evita formule rigide tipo "provo a..." o "ti seguo";
    - non fare diagnosi, non dire che sei un terapeuta, non fingere certezze cliniche;
    - se emerge rischio imminente di autolesione o suicidio, interrompi il tono normale e indirizza subito a emergenza o a una persona reale da contattare adesso;
    - fai risposte brevi o medie, molto naturali, con massimo un suggerimento pratico per volta;
    - niente elenchi salvo quando servono davvero.
    """

    static func prompt(for context: AISupportChatContext) -> String {
        let recentMessages = context.conversation.suffix(8).map { message in
            let role = message.role == .assistant ? "assistant" : "user"
            return "\(role): \(message.text)"
        }.joined(separator: "\n")

        let snapshotSummary: String
        if let snapshot = context.snapshot {
            snapshotSummary = """
            Contesto facoltativo dall'app:
            - sintesi: \(snapshot.title)
            - andamento: \(snapshot.trendLabel)
            - energia: \(snapshot.energyLabel)
            """
        } else {
            snapshotSummary = "Contesto facoltativo dall'app: non disponibile."
        }

        return """
        Conversazione recente:
        \(recentMessages)

        \(snapshotSummary)

        Ultimo messaggio dell'utente:
        \(context.userInput)

        Rispondi all'ultimo messaggio in modo empatico, naturale e specifico.
        """
    }
}

enum AIConfiguration {
    static var supportChatEndpointURL: URL? {
        guard
            let rawValue = Bundle.main.object(forInfoDictionaryKey: "MINDMESH_AI_CHAT_ENDPOINT") as? String,
            !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return URL(string: rawValue)
    }
}

struct OpenAIConfiguration {
    let apiKey: String
    let model: String
    let baseURL: URL

    static var current: OpenAIConfiguration? {
        guard
            let apiKey = Bundle.main.object(forInfoDictionaryKey: "MINDMESH_OPENAI_API_KEY") as? String,
            !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        let rawModel = (Bundle.main.object(forInfoDictionaryKey: "MINDMESH_OPENAI_MODEL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let model = rawModel?.isEmpty == false ? rawModel! : "gpt-5.4-mini"

        let rawBaseURL = (Bundle.main.object(forInfoDictionaryKey: "MINDMESH_OPENAI_BASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let baseURL = URL(string: rawBaseURL ?? "") ?? URL(string: "https://api.openai.com/v1/responses")!

        return OpenAIConfiguration(apiKey: apiKey, model: model, baseURL: baseURL)
    }
}

final class OpenAIDirectSupportChatService: AISupportChatService {
    private let configuration: OpenAIConfiguration
    private let session: URLSession

    init(configuration: OpenAIConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func generateReply(context: AISupportChatContext) async throws -> AISupportChatResponse {
        var request = URLRequest(url: configuration.baseURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        let payload = OpenAIResponsesRequest(
            model: configuration.model,
            instructions: AISupportPromptBuilder.instructions,
            input: AISupportPromptBuilder.prompt(for: context),
            reasoning: .init(effort: "low"),
            max_output_tokens: 420
        )

        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AISupportChatServiceError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AISupportChatServiceError.httpStatus(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(OpenAIResponsesAPIResponse.self, from: data)
        let text = decoded.finalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw AISupportChatServiceError.emptyReply
        }

        return AISupportChatResponse(
            text: text,
            sourceLabel: "OpenAI · \(configuration.model)",
            sourceDetail: "Risposta generata direttamente da OpenAI.",
            isRemote: true
        )
    }
}

final class RemoteAISupportChatService: AISupportChatService {
    private let endpointURL: URL
    private let session: URLSession

    init(endpointURL: URL, session: URLSession = .shared) {
        self.endpointURL = endpointURL
        self.session = session
    }

    func generateReply(context: AISupportChatContext) async throws -> AISupportChatResponse {
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = RemoteSupportChatRequest(
            message: context.userInput,
            conversation: context.conversation.suffix(8).map {
                RemoteSupportChatRequest.MessagePayload(role: $0.role == .assistant ? "assistant" : "user", text: $0.text)
            },
            snapshot: context.snapshot.map {
                RemoteSupportChatRequest.SnapshotPayload(
                    title: $0.title,
                    message: $0.message,
                    trendLabel: $0.trendLabel,
                    energyLabel: $0.energyLabel,
                    consistencyLabel: $0.consistencyLabel
                )
            }
        )

        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AISupportChatServiceError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AISupportChatServiceError.httpStatus(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(RemoteSupportChatResponse.self, from: data)
        let trimmedReply = decoded.reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReply.isEmpty else {
            throw AISupportChatServiceError.emptyReply
        }

        let isLocalEndpoint = endpointURL.host == "127.0.0.1" || endpointURL.host == "localhost"
        let modelLabel = decoded.model?.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseLabel = isLocalEndpoint ? "Backend AI Locale" : "Backend AI"
        let sourceLabel = modelLabel.map { "\(baseLabel) · \($0)" } ?? baseLabel
        let sourceDetail = isLocalEndpoint
            ? "Risposta generata dal backend locale su http://127.0.0.1:8787."
            : "Risposta generata dal backend AI configurato."

        return AISupportChatResponse(
            text: trimmedReply,
            sourceLabel: sourceLabel,
            sourceDetail: sourceDetail,
            isRemote: true
        )
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
final class FoundationModelAISupportChatService: AISupportChatService {
    private let model: SystemLanguageModel

    init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    var isAvailable: Bool {
        switch model.availability {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }

    func generateReply(context: AISupportChatContext) async throws -> AISupportChatResponse {
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw AISupportChatServiceError.foundationModelUnavailable(
                "Apple Intelligence non disponibile: \(String(describing: reason))."
            )
        }

        let session = LanguageModelSession(
            model: model,
            instructions: AISupportPromptBuilder.instructions
        )
        let response = try await session.respond(to: AISupportPromptBuilder.prompt(for: context))
        let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw AISupportChatServiceError.emptyReply
        }

        return AISupportChatResponse(
            text: text,
            sourceLabel: "Apple Foundation Model",
            sourceDetail: "Risposta on-device con Apple Intelligence.",
            isRemote: false
        )
    }
}
#endif

final class UnavailableAISupportChatService: AISupportChatService {
    func generateReply(context: AISupportChatContext) async throws -> AISupportChatResponse {
        throw AISupportChatServiceError.notConfigured
    }
}

private struct OpenAIResponsesRequest: Encodable {
    struct ReasoningPayload: Encodable {
        let effort: String
    }

    let model: String
    let instructions: String
    let input: String
    let reasoning: ReasoningPayload?
    let max_output_tokens: Int
}

private struct OpenAIResponsesAPIResponse: Decodable {
    struct OutputItem: Decodable {
        struct ContentItem: Decodable {
            let type: String?
            let text: String?
        }

        let content: [ContentItem]?
    }

    let output_text: String?
    let output: [OutputItem]?

    var finalText: String {
        if let output_text, !output_text.isEmpty {
            return output_text
        }

        let extracted = output?
            .flatMap { $0.content ?? [] }
            .compactMap { item -> String? in
                guard let text = item.text, !text.isEmpty else { return nil }
                return text
            }
            .joined(separator: "\n") ?? ""

        return extracted
    }
}

private struct RemoteSupportChatRequest: Encodable {
    struct MessagePayload: Encodable {
        let role: String
        let text: String
    }

    struct SnapshotPayload: Encodable {
        let title: String
        let message: String
        let trendLabel: String
        let energyLabel: String
        let consistencyLabel: String
    }

    let message: String
    let conversation: [MessagePayload]
    let snapshot: SnapshotPayload?
}

private struct RemoteSupportChatResponse: Decodable {
    let reply: String
    let model: String?
}

enum AISupportChatServiceError: Error {
    case invalidResponse
    case httpStatus(Int)
    case emptyReply
    case notConfigured
    case foundationModelUnavailable(String)
}
