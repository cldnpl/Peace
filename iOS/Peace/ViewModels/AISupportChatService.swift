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
        let t = AppStrings.current
        return AISupportChatServiceSelection(
            service: RemoteAISupportChatService(endpointURL: localBackendURL),
            sourceLabel: t.sourceLocalBackend,
            sourceDetail: t.sourceLocalBackendDetail,
            isRemote: true
        )
    }

    private static func configuredServiceSelection() -> AISupportChatServiceSelection? {
        let t = AppStrings.current
        if let endpointURL = AIConfiguration.supportChatEndpointURL {
            return AISupportChatServiceSelection(
                service: RemoteAISupportChatService(endpointURL: endpointURL),
                sourceLabel: t.sourceConfiguredBackend,
                sourceDetail: t.sourceConfiguredBackendDetail,
                isRemote: true
            )
        }

        if let configuration = OpenAIConfiguration.current {
            return AISupportChatServiceSelection(
                service: OpenAIDirectSupportChatService(configuration: configuration),
                sourceLabel: t.sourceOpenAI(configuration.model),
                sourceDetail: t.sourceOpenAIDetail,
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
            sourceLabel: AppStrings.current.sourceFoundationModel,
            sourceDetail: AppStrings.current.sourceFoundationDetail,
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
    static func instructions(language: AppLanguage) -> String {
        """
        You are an emotionally supportive chat assistant. Write entirely in \(language.aiLanguageName).
        You must sound warm, grounded, human, and natural, never mechanical.
        Goal: help the person feel understood and gain clarity, without canned phrases or a patronizing tone.
        Rules:
        - respond in \(language.aiLanguageName);
        - start from what the person just wrote, not from the app data;
        - use the app context only if it is actually useful, and keep it light;
        - avoid rigid formulas and therapist-sounding scripts;
        - do not diagnose, do not pretend to be a therapist, and do not fake clinical certainty;
        - if there is imminent risk of self-harm or suicide, stop the normal tone and immediately direct the user to emergency help or a real person they can contact now;
        - keep answers short to medium, very natural, with at most one practical suggestion at a time;
        - avoid bullet lists unless they truly help.
        """
    }

    static func prompt(for context: AISupportChatContext, language: AppLanguage) -> String {
        let recentMessages = context.conversation.suffix(8).map { message in
            let role = message.role == .assistant ? "assistant" : "user"
            return "\(role): \(message.text)"
        }.joined(separator: "\n")

        let snapshotSummary: String
        if let snapshot = context.snapshot {
            snapshotSummary = """
            Optional app context:
            - summary: \(snapshot.title)
            - recent trend: \(snapshot.trendLabel)
            - energy: \(snapshot.energyLabel)
            """
        } else {
            snapshotSummary = "Optional app context: not available."
        }

        return """
        Recent conversation:
        \(recentMessages)

        \(snapshotSummary)

        User's latest message:
        \(context.userInput)

        Reply to the user's latest message in \(language.aiLanguageName), in an empathic, natural, and specific way.
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
        let language = AppLanguagePreferences.currentLanguage
        let t = AppStrings(language: language)
        var request = URLRequest(url: configuration.baseURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        let payload = OpenAIResponsesRequest(
            model: configuration.model,
            instructions: AISupportPromptBuilder.instructions(language: language),
            input: AISupportPromptBuilder.prompt(for: context, language: language),
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
            sourceLabel: t.sourceOpenAI(configuration.model),
            sourceDetail: t.sourceOpenAIDetail,
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
        let t = AppStrings.current
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
        let baseLabel = isLocalEndpoint ? t.sourceLocalBackend : t.sourceBackendAI
        let sourceLabel = modelLabel.map { "\(baseLabel) · \($0)" } ?? baseLabel
        let sourceDetail = isLocalEndpoint
            ? t.sourceLocalResponseDetail
            : t.sourceConfiguredResponseDetail

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
                AppStrings.current.appleIntelligenceUnavailable(String(describing: reason))
            )
        }

        let language = AppLanguagePreferences.currentLanguage
        let session = LanguageModelSession(
            model: model,
            instructions: AISupportPromptBuilder.instructions(language: language)
        )
        let response = try await session.respond(to: AISupportPromptBuilder.prompt(for: context, language: language))
        let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw AISupportChatServiceError.emptyReply
        }

        return AISupportChatResponse(
            text: text,
            sourceLabel: AppStrings.current.sourceFoundationModel,
            sourceDetail: AppStrings.current.sourceFoundationDetail,
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
