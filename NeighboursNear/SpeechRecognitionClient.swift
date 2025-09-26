import Speech
import AVFoundation
import ComposableArchitecture

struct SpeechRecognitionClient {
    /// Requests authorization to use speech recognition.
    var authorize: @Sendable () async throws -> Bool
    /// Starts streaming partial and final transcripts.
    /// The stream yields (transcript, isFinal) tuples.
    var startStream: @Sendable () async throws -> AsyncStream<(String, Bool)>
    /// Stops the current stream and audio engine.
    var stop: @Sendable () async -> Void
}

extension SpeechRecognitionClient: DependencyKey {
    static let liveValue: Self = {
        let service = SpeechRecognitionService()
        return Self(
            authorize: { try await service.authorize() },
            startStream: { try await service.startStream() },
            stop: { await service.stop() }
        )
    }()
}

extension DependencyValues {
    var speechRecognition: SpeechRecognitionClient {
        get { self[SpeechRecognitionClient.self] }
        set { self[SpeechRecognitionClient.self] = newValue }
    }
}

private final class SpeechRecognitionService {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    @MainActor func authorize() async throws -> Bool {
        print("Requesting speech authorization…")
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                print("Authorization status: \(status.rawValue)")
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    @MainActor func startStream() async throws -> AsyncStream<(String, Bool)> {
        print("startStream() called — resetting audio session")
        await stop()

        let request = SFSpeechAudioBufferRecognitionRequest()
        self.request = request
        request.shouldReportPartialResults = true
        print("Created SFSpeechAudioBufferRecognitionRequest; partial results: true")

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        print("Audio tap installed on input node (bufferSize: 1024)")

        do {
            try audioEngine.start()
            print("Audio engine started")
        } catch {
            print("Failed to start audio engine: \(error)")
            throw error
        }

        let recognizer = self.speechRecognizer
        let requestRef = self.request

        return AsyncStream { continuation in
            self.recognitionTask = recognizer?.recognitionTask(with: requestRef!) { [weak self] result, error in
                if let error = error {
                    print("Recognition error: \(error)")
                }
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    continuation.yield((text, result.isFinal))
                    print("Transcript update: isFinal=\(result.isFinal) text=\"\(text)\"")
                }
                if error != nil { continuation.finish() }
            }

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    await self?.stop()
                }
            }
        }
    }

    @MainActor func stop() async {
        request?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}



