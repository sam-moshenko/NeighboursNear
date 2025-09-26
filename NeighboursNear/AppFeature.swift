import Foundation
import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var announcings: [Announcing] = []
        var suggestions: [AnnouncingSuggestion] = []
        var transcript: String = ""
    }

    enum Action {
        case onAppear
        case speechAuthorizationResponse(Bool)
        case startSpeechStream
        case stopSpeech
        case speechEvent(transcript: String, isFinal: Bool)
        case finalizeTapped
        case generationResponse(Result<AnnouncingsWithSuggestions, Error>)
    }

    @Dependency(\.speechRecognition) var speech
    @Dependency(\.announcingGenerator) var generator

    enum CancelID { case speech }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            return .run { send in
                let authorized = try await speech.authorize()
                await send(.speechAuthorizationResponse(authorized))
            }

        case let .speechAuthorizationResponse(authorized):
            guard authorized else { return .none }
            return .send(.startSpeechStream)

        case .startSpeechStream:
            return .run { send in
                do {
                    let stream = try await speech.startStream()
                    for await (text, isFinal) in stream {
                        await send(.speechEvent(transcript: text, isFinal: isFinal))
                    }
                } catch {
                    print("Failed to start speech stream: \(error)")
                }
            }
            .cancellable(id: "speech", cancelInFlight: true)

        case .stopSpeech:
            return .merge(
                .run { _ in await speech.stop() },
                .cancel(id: "speech")
            )

        case let .speechEvent(transcript, _isFinal):
            state.transcript = transcript
            return .none

        case .finalizeTapped:
            let text = state.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return .none }
            return .merge(
                .send(.stopSpeech),
                .run { [text] send in
                    do {
                        let announcingsWithSuggestions = try await generator.generate(text)
                        await send(.generationResponse(.success(announcingsWithSuggestions)))
                    } catch {
                        await send(.generationResponse(.failure(error)))
                    }
                }
            )

        case let .generationResponse(result):
            switch result {
            case let .success(announcingsWithSuggestions):
                state.announcings = announcingsWithSuggestions.announcings
                state.suggestions = announcingsWithSuggestions.suggestions
                state.transcript = ""
                return .send(.startSpeechStream)

            case let .failure(error):
                print("Failed to generate shape commands: \(error)")
                return .send(.startSpeechStream)
            }
        }
    }
}
