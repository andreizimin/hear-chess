// On-device English speech recognition. Design: docs/intent/voice/voice-design.md

import AVFoundation
import Speech

// @spec VOICE-IN-001, VOICE-IN-002, VOICE-IN-004, VOICE-IN-005, VOICE-IN-006
final class Listener {
    /// Alternatives (best first) and the uptime at which the first word began.
    var onHeard: (([String], Double) -> Void)?
    var onError: (() -> Void)?

    /// The end-of-answer pause, in seconds.
    var endOfAnswerPause: TimeInterval = 0.8

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var requestStartedAt: Double = 0
    private var hints: [String] = []
    private var endTimer: Timer?
    private var latest: SFSpeechRecognitionResult?
    private var active = false

    static var isAvailable: Bool {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized,
              AVAudioApplication.shared.recordPermission == .granted,
              let r = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        else { return false }
        return r.supportsOnDeviceRecognition
    }

    static func requestPermissions(_ done: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async { done(status == .authorized && granted) }
            }
        }
    }

    func start(hints: [String]) {
        self.hints = hints
        active = true
        startEngineIfNeeded()
        beginRequest()
    }

    func stop() {
        active = false
        endRequest()
    }

    /// Stops the microphone entirely, at the end of a session.
    func shutDown() {
        stop()
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }

    private func startEngineIfNeeded() {
        guard !audioEngine.isRunning else { return }
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        audioEngine.prepare()
        try? audioEngine.start()
    }

    private func beginRequest() {
        endRequest()
        guard let recognizer, active else { return }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        request.contextualStrings = hints
        request.taskHint = .confirmation
        self.request = request
        requestStartedAt = ProcessInfo.processInfo.systemUptime
        latest = nil
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async { self?.handle(result, error) }
        }
    }

    private func endRequest() {
        endTimer?.invalidate()
        endTimer = nil
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
    }

    private func handle(_ result: SFSpeechRecognitionResult?, _ error: Error?) {
        guard active else { return }
        if let result {
            latest = result
            endTimer?.invalidate()
            endTimer = Timer.scheduledTimer(withTimeInterval: endOfAnswerPause, repeats: false) { [weak self] _ in
                self?.finishAnswer()
            }
            if result.isFinal { finishAnswer() }
            return
        }
        if let error = error as NSError? {
            // A request that ended because nobody spoke is normal: start a new one silently.
            let noSpeech = error.domain == "kAFAssistantErrorDomain" && [1110, 203, 216].contains(error.code)
            if !noSpeech && error.code != 301 { onError?() }
            if active { beginRequest() }
        }
    }

    private func finishAnswer() {
        guard let result = latest else { return }
        latest = nil
        let alternatives = result.transcriptions.map(\.formattedString)
        let firstWord = result.bestTranscription.segments.first?.timestamp ?? 0
        let startedAt = requestStartedAt + firstWord
        endRequest()
        onHeard?(alternatives, startedAt)
        if active { beginRequest() }
    }
}
