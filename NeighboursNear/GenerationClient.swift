import ComposableArchitecture
import FoundationModels

struct AnnouncingGeneratorClient {
    var generate: @Sendable (_ prompt: String) async throws -> AnnouncingsWithSuggestions
}

extension AnnouncingGeneratorClient: DependencyKey {
    static let liveValue: Self = {
        let service = AnnouncingGeneratorService()
        return Self(generate: { prompt in try await service.generate(prompt: prompt) })
    }()
}

extension DependencyValues {
    var announcingGenerator: AnnouncingGeneratorClient {
        get { self[AnnouncingGeneratorClient.self] }
        set { self[AnnouncingGeneratorClient.self] = newValue }
    }
}

private actor AnnouncingGeneratorServiceActor {
    let model = LanguageModelSession(
        model: .default,
        instructions: "User describes what he has or needs which needs to be translated into announcings"
    )
}

private final class AnnouncingGeneratorService {
    private let actor = AnnouncingGeneratorServiceActor()

    func generate(prompt: String) async throws -> AnnouncingsWithSuggestions {
        await MainActor.run { print("Processing prompt: \"\(prompt)\"") }
        do {
            await MainActor.run { print("Calling LLM to generate AnnouncingCommand…") }
            let response = try await actor.model.respond(
                to: prompt,
                generating: AnnouncingsWithSuggestions.self
            )
            await MainActor.run { print("LLM Response: \(response.content)") }
            return response.content
        } catch {
            await MainActor.run { print("LLM parse/response error: \(error)") }
            throw error
        }
    }
}
