// Connects the session engine to iOS: speech, listening, audio, gestures, the store and timers.
// Designs: docs/intent/session/session-design.md, docs/intent/audio/audio-design.md

import AVFoundation
import Combine
import HearChessCore
import MediaPlayer
import SwiftUI
import UIKit

@MainActor
final class AppModel: ObservableObject {
    @Published var statusText = "Tap anywhere to start"
    @Published var lastSpoken = ""
    @Published var lastHeard = ""

    private let store: ProgressStore
    private var engine: SessionEngine!
    private let speaker = Speaker()
    private let listener = Listener()
    private var ticker: Timer?
    private var savedBrightness: CGFloat?
    private var launched = false

    private static let permissionStepKey = "permissionStepDone"

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        // @spec STORE-SAVE-001
        store = ProgressStore(directory: support.appendingPathComponent("HearChess", isDirectory: true), fileSystem: LocalFileSystem())
    }

    private var now: Double { ProcessInfo.processInfo.systemUptime }

    // MARK: Launch

    // @spec VOICE-PERM-001, STORE-LOAD-001
    func launch() {
        guard !launched else { return }
        launched = true
        store.load()
        let permissionDone = UserDefaults.standard.bool(forKey: Self.permissionStepKey)
        engine = SessionEngine(
            progress: store.progress,
            savingEnabled: store.savingEnabled,
            permissionStepDone: permissionDone,
            voiceCheck: { Listener.isAvailable },
            seedSource: { UInt64.random(in: .min ... .max) }
        )
        speaker.onFinished = { [weak self] in Task { @MainActor in self?.send(.speechFinished) } }
        listener.onHeard = { [weak self] alternatives, startedAt in
            Task { @MainActor in
                self?.lastHeard = alternatives.first ?? ""
                self?.send(.heard(alternatives, startedAt: startedAt))
            }
        }
        listener.onError = { [weak self] in Task { @MainActor in self?.send(.recognitionError) } }
        setUpRemoteCommands()
        observeAudioSession()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.send(.tick) }
        }
        if !permissionDone { runPermissionStep() }
    }

    private func runPermissionStep() {
        statusText = "Setting up"
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        speaker.onFinished = nil
        speaker.speak("hear-chess needs the microphone and speech recognition to hear your answers. They stay on this iPhone.")
        Listener.requestPermissions { [weak self] _ in
            guard let self else { return }
            UserDefaults.standard.set(true, forKey: Self.permissionStepKey)
            self.engine.permissionStepDone = true
            self.speaker.onFinished = { [weak self] in Task { @MainActor in self?.send(.speechFinished) } }
            self.statusText = "Tap anywhere to start"
        }
    }

    func appBecameActive() {
        guard engine != nil else { return }
        send(.appResumed)
    }

    // MARK: Events in

    func gesture(_ g: HearChessCore.Gesture) { send(.gesture(g)) }

    private func send(_ event: SessionEvent) {
        guard let engine else { return }
        let effects = engine.handle(event, at: now)
        for effect in effects { perform(effect) }
        updateStatus()
    }

    private func updateStatus() {
        switch engine.state {
        case .idle: statusText = engine.permissionStepDone ? "Tap anywhere to start" : "Setting up"
        case .askingToStart: statusText = "Start training?"
        case .starting: statusText = "Starting"
        case .asking: statusText = "Asking"
        case .listening: statusText = engine.voiceOn ? "Listening" : "Waiting for a swipe"
        case .confirming: statusText = "Confirming"
        case .pickingFile: statusText = "Picking a file"
        case .pickingRank: statusText = "Picking a rank"
        case .feedback: statusText = "Feedback"
        case .paused: statusText = "Paused"
        case .ending: statusText = "Session ended"
        }
    }

    // MARK: Effects out

    private func perform(_ effect: Effect) {
        switch effect {
        case let .speak(text):
            lastSpoken = text
            speaker.speak(text)
        case .stopSpeaking:
            speaker.stop()
        case let .listen(allowed):
            listener.start(hints: SpokenChess.hints(for: allowed))
        case .stopListening:
            listener.stop()
        case let .play(sound):
            play(sound)
        case let .keepScreenAwake(on):
            keepScreenAwake(on)
        case let .audio(mode):
            setAudio(mode)
        case let .nowPlaying(on):
            setNowPlaying(on)
        case let .save(progress):
            store.save(progress)
        case .sessionEnded:
            break
        }
    }

    private func play(_ sound: Sound) {
        switch sound {
        case .right: AudioServicesPlaySystemSound(1057)
        case .wrong: AudioServicesPlaySystemSound(1053)
        case .bump: AudioServicesPlaySystemSound(1104)
        }
    }

    // @spec TOUCH-SCR-001, TOUCH-SCR-002, TOUCH-SCR-003
    private func keepScreenAwake(_ on: Bool) {
        UIApplication.shared.isIdleTimerDisabled = on
        let screen = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
        if on {
            savedBrightness = screen?.brightness
            screen?.brightness = 0
        } else if let saved = savedBrightness {
            screen?.brightness = saved
            savedBrightness = nil
        }
    }

    // @spec AUDIO-001, AUDIO-002, AUDIO-003, AUDIO-BG-001
    private func setAudio(_ mode: AudioMode) {
        let session = AVAudioSession.sharedInstance()
        switch mode {
        case .playAndRecord:
            try? session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
            try? session.setActive(true)
        case .playOnly:
            try? session.setCategory(.playback, mode: .spokenAudio)
            try? session.setActive(true)
        case .released:
            listener.shutDown()
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    // @spec AUDIO-CMD-001
    private func setNowPlaying(_ on: Bool) {
        let center = MPNowPlayingInfoCenter.default()
        if on {
            center.nowPlayingInfo = [MPMediaItemPropertyTitle: "hear-chess training"]
            center.playbackState = .playing
        } else {
            center.nowPlayingInfo = nil
            center.playbackState = .stopped
        }
    }

    // MARK: System events

    private func setUpRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        for command in [center.togglePlayPauseCommand, center.playCommand, center.pauseCommand] {
            command.isEnabled = true
            command.addTarget { [weak self] _ in self?.send(.media(.playPause)); return .success }
        }
        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { [weak self] _ in self?.send(.media(.nextTrack)); return .success }
        center.previousTrackCommand.isEnabled = true
        center.previousTrackCommand.addTarget { [weak self] _ in self?.send(.media(.previousTrack)); return .success }
    }

    private func observeAudioSession() {
        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            Task { @MainActor in self?.send(type == .began ? .interruptionBegan : .interruptionEnded) }
        }
        nc.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: raw) else { return }
            switch reason {
            case .oldDeviceUnavailable: Task { @MainActor in self?.send(.headphonesDisconnected) }
            case .newDeviceAvailable: Task { @MainActor in self?.send(.headphonesConnected) }
            default: break
            }
        }
    }
}
