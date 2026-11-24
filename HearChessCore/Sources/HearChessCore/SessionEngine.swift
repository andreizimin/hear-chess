// The session engine: the flow of a training session as a state machine.
// Events go in, effects come out. Design: docs/intent/session/session-design.md

import Foundation

/// Gestures on the training surface.
public enum Gesture: Hashable, Sendable {
    case tap
    case swipeLeft, swipeRight, swipeUp, swipeDown
    case doubleTap
    case twoFingerTap
    case longPress
    case twoFingerDoubleTap
    case threeFingerSwipeDown
}

/// Lock-screen and headphone media commands.
public enum MediaCommand: Hashable, Sendable {
    case playPause
    case nextTrack
    case previousTrack
}

/// Something that happened, delivered to the engine with the time it happened.
public enum SessionEvent: Hashable, Sendable {
    case gesture(Gesture)
    case media(MediaCommand)
    /// The utterance most recently asked for has finished.
    case speechFinished
    /// The recognizer's alternatives, best first, and the time its first word began.
    case heard([String], startedAt: Double)
    /// The recognizer reported an error (not a request that ended without speech).
    case recognitionError
    case interruptionBegan
    case interruptionEnded
    case headphonesDisconnected
    case headphonesConnected
    /// The app runs again after iOS suspended it.
    case appResumed
    /// Time passes; the engine checks its timers.
    case tick
}

public enum Sound: Hashable, Sendable {
    case right
    case wrong
    case bump
}

public enum AudioMode: Hashable, Sendable {
    /// Play and record (voice input available).
    case playAndRecord
    /// Play only (voice input off).
    case playOnly
    /// Audio released so other apps can resume.
    case released
}

/// Something the iOS layer must do.
public enum Effect: Hashable, Sendable {
    case speak(String)
    case stopSpeaking
    case listen(Allowed)
    case stopListening
    case play(Sound)
    /// Keep the screen awake at minimum brightness (true), or restore normal locking and brightness (false).
    case keepScreenAwake(Bool)
    case audio(AudioMode)
    /// Take (true) or give up (false) the lock screen's playing-app role.
    case nowPlaying(Bool)
    case save(Progress)
    case sessionEnded(SessionSummary)
}

/// Where the engine is.
public enum EngineState: Hashable, Sendable {
    case idle
    case askingToStart
    case starting
    case asking
    case listening
    case confirming
    case pickingFile
    case pickingRank
    case feedback
    case paused
    case ending
}

// @spec SESSION-START-001, SESSION-START-002, SESSION-START-003, SESSION-START-004, SESSION-START-005,
//       SESSION-EX-001, SESSION-EX-002, SESSION-EX-003, SESSION-EX-004, SESSION-PAUSE-005,
//       VOICE-PERM-001, VOICE-PERM-004, VOICE-IN-003
public final class SessionEngine {
    public static let sessionLength: Double = 7 * 60
    public static let pauseLimit: Double = 10 * 60
    public static let repeatAfterSilence: Double = 15
    public static let startConfirmationWindow: Double = 10
    public static let nowPlayingAfterEnd: Double = 60

    public private(set) var state: EngineState = .idle
    public private(set) var progress: Progress
    /// The exercise currently being asked, if any.
    public private(set) var currentExercise: Exercise?
    /// Whether voice input is on for the running session.
    public private(set) var voiceOn: Bool = false

    /// False when the first-launch permission step is not finished yet; taps then do not start a session.
    public var permissionStepDone: Bool
    /// False when the store is not saving (newer-version or unavailable progress file).
    public var savingEnabled: Bool

    /// When set, supplies the next exercise instead of the ladder and generator (for tests).
    public var exerciseOverride: ((_ previous: Exercise?) -> Exercise)?

    private let voiceCheck: () -> Bool
    private let seedSource: () -> UInt64
    private let wallClock: () -> Date
    private var startDate = Date(timeIntervalSince1970: 0)

    /// What the utterance in progress is for.
    private enum Purpose {
        case startTraining, announcement, prompt, sorry, candidate, sayAgain, pickInfo, speakBack, correction, voiceOff, summary
    }

    // Speech and microphone.
    private var speaking: Purpose?
    private var micOn = false

    // "Start training?"
    private var startAskedAt: Double = 0

    // Session.
    private var rng = SeededRandom(seed: 0)
    private var seed: UInt64 = 0
    private var clockTotal: Double = 0
    private var clockRunningSince: Double?
    private var announcements: [String] = []
    private var announcementIndex = 0
    private var recentDrills: [Drill] = []
    private var rightCount = 0
    private var totalCount = 0
    private var levelChanges: [LevelChange] = []
    private var screenAwake = false
    private var nowPlayingUntil: Double?

    // Exercise.
    private var answered = false
    private var lastAnswerRight = false
    private var promptEnd: Double?
    private var pausedDuringExercise: Double = 0
    private var lastQuiet: Double = 0
    private var autoRepeatUsed = false
    private var sorryCount = 0
    private var recognitionErrors = 0
    private var candidates: [Answer] = []
    private var candidateIndex = 0
    private var candidateSpokenAt: Double = 0
    private var pickFile = 4
    private var pickRank = 3
    private var pickStartedAt: Double = 0

    // Pause.
    private var pausedAt: Double = 0
    private var pausedFrom: EngineState = .listening

    /// - Parameters:
    ///   - voiceCheck: whether voice input is available now (permissions and on-device recognition).
    ///   - seedSource: a fresh random seed for each session.
    ///   - wallClock: the current date and time, recorded as each session's start.
    public init(
        progress: Progress,
        savingEnabled: Bool = true,
        permissionStepDone: Bool = true,
        voiceCheck: @escaping () -> Bool,
        seedSource: @escaping () -> UInt64,
        wallClock: @escaping () -> Date = Date.init
    ) {
        self.wallClock = wallClock
        self.progress = progress
        self.savingEnabled = savingEnabled
        self.permissionStepDone = permissionStepDone
        self.voiceCheck = voiceCheck
        self.seedSource = seedSource
    }

    /// Handles one event at time `time` (seconds, monotonic) and returns the effects to carry out, in order.
    public func handle(_ event: SessionEvent, at time: Double) -> [Effect] {
        switch state {
        case .idle: return idle(event, time)
        case .askingToStart: return askingToStart(event, time)
        case .starting: return starting(event, time)
        case .asking, .feedback: return speakingInSession(event, time)
        case .listening: return listening(event, time)
        case .confirming: return confirming(event, time)
        case .pickingFile, .pickingRank: return picking(event, time)
        case .paused: return paused(event, time)
        case .ending: return ending(event, time)
        }
    }

    // MARK: Speech and microphone helpers

    private func speak(_ text: String, _ purpose: Purpose) -> [Effect] {
        speaking = purpose
        return stopMic() + [.speak(text)]
    }

    private func stopMic() -> [Effect] {
        guard micOn else { return [] }
        micOn = false
        return [.stopListening]
    }

    private func listen(_ allowed: Allowed, voice: Bool? = nil) -> [Effect] {
        guard voice ?? voiceOn else { return [] }
        micOn = true
        return [.listen(allowed)]
    }

    private var exerciseAllowed: Allowed { .exercise(currentExercise?.answerKind ?? .lightOrDark) }

    // MARK: Idle and "Start training?"

    // @spec AUDIO-BG-003, AUDIO-BG-004
    private func idle(_ event: SessionEvent, _ t: Double) -> [Effect] {
        switch event {
        case .gesture(.tap):
            return permissionStepDone ? startSession(t) : []
        case .media(.playPause):
            startAskedAt = t
            state = .askingToStart
            return speak("Start training?", .startTraining)
        case .tick:
            if let until = nowPlayingUntil, t >= until {
                nowPlayingUntil = nil
                return [.nowPlaying(false)]
            }
            return []
        default:
            return []
        }
    }

    private func askingToStart(_ event: SessionEvent, _ t: Double) -> [Effect] {
        let expired = t - startAskedAt > SessionEngine.startConfirmationWindow
        switch event {
        case .speechFinished where speaking == .startTraining:
            speaking = nil
            return listen(.yesOrNo, voice: voiceCheck())
        case .gesture(.tap):
            return stopMic() + startSession(t)
        case .media(.playPause):
            if expired { return cancelStart() + idle(event, t) }
            return stopMic() + startSession(t)
        case let .heard(alternatives, _):
            if case .understood(.yes) = SpokenChess.hear(alternatives, allowed: .yesOrNo), !expired {
                return stopMic() + startSession(t)
            }
            return cancelStart()
        case .tick:
            return expired ? cancelStart() : []
        default:
            return []
        }
    }

    private func cancelStart() -> [Effect] {
        state = .idle
        speaking = nil
        return stopMic()
    }

    // MARK: Starting a session

    // @spec SESSION-START-005, SESSION-START-006, SESSION-INTRO-001, SESSION-INTRO-002, SESSION-INTRO-003,
    //       STORE-LOAD-004, AUDIO-001, AUDIO-002, AUDIO-003, AUDIO-CMD-001, TOUCH-SCR-001, TOUCH-SCR-002
    private func startSession(_ t: Double) -> [Effect] {
        voiceOn = voiceCheck()
        seed = seedSource()
        rng = SeededRandom(seed: seed)
        startDate = wallClock()
        clockTotal = 0
        clockRunningSince = nil
        recentDrills = []
        rightCount = 0
        totalCount = 0
        levelChanges = []
        currentExercise = nil
        nowPlayingUntil = nil

        var fx: [Effect] = [.audio(voiceOn ? .playAndRecord : .playOnly), .nowPlaying(true)]
        screenAwake = !voiceOn
        if screenAwake { fx.append(.keepScreenAwake(true)) }

        announcements = []
        if !savingEnabled { announcements.append(SessionPhrases.notSaving) }
        if !progress.introductionGiven {
            announcements.append(SessionPhrases.introduction(voiceAvailable: voiceOn))
        } else if !voiceOn {
            announcements.append(SessionPhrases.touchOnly)
        }
        announcementIndex = 0
        if announcements.isEmpty { return fx + beginExercise(t) }
        state = .starting
        return fx + speak(announcements[0], .announcement)
    }

    private var speakingIntroduction: Bool {
        announcementIndex < announcements.count
            && announcements[announcementIndex] == SessionPhrases.introduction(voiceAvailable: voiceOn)
            && !progress.introductionGiven
    }

    // @spec SESSION-INTRO-004, SESSION-INTRO-005, SESSION-INTRO-006, STORE-004
    private func starting(_ event: SessionEvent, _ t: Double) -> [Effect] {
        switch event {
        case .speechFinished where speaking == .announcement:
            speaking = nil
            var fx: [Effect] = []
            if speakingIntroduction {
                progress.introductionGiven = true
                fx.append(.save(progress))
            }
            announcementIndex += 1
            if announcementIndex < announcements.count {
                return fx + speak(announcements[announcementIndex], .announcement)
            }
            return fx + beginExercise(t)
        case .gesture(.twoFingerDoubleTap), .media(.playPause), .interruptionBegan, .headphonesDisconnected:
            return pause(t)
        case .gesture(.threeFingerSwipeDown):
            return endSession(t)
        default:
            return []
        }
    }

    // MARK: Exercises

    private func beginExercise(_ t: Double) -> [Effect] {
        if clockRunningSince == nil && clockTotal == 0 { clockRunningSince = t }
        if elapsed(t) >= SessionEngine.sessionLength && totalCount > 0 { return endSession(t) }

        let previous = currentExercise
        let exercise: Exercise
        if let override = exerciseOverride {
            exercise = override(previous)
        } else {
            let drill = progress.ladder.chooseDrill(from: EmptyBoard.drills, recent: recentDrills, using: &rng)
            exercise = EmptyBoard.generate(drill: drill, level: progress.ladder.estimate(drill).level, previous: previous, using: &rng)
        }
        recentDrills.append(exercise.drill)
        currentExercise = exercise
        answered = false
        promptEnd = nil
        pausedDuringExercise = 0
        autoRepeatUsed = false
        sorryCount = 0
        recognitionErrors = 0
        candidates = []
        state = .asking
        return speak(SpokenChess.text(for: exercise.prompt), .prompt)
    }

    private func repeatQuestion() -> [Effect] {
        guard let exercise = currentExercise else { return [] }
        candidates = []
        state = .asking
        return speak(SpokenChess.text(for: exercise.prompt), .prompt)
    }

    /// Session clock: unpaused time since the first question began.
    // @spec SESSION-END-001
    private func elapsed(_ t: Double) -> Double {
        clockTotal + (clockRunningSince.map { t - $0 } ?? 0)
    }

    /// Speech ended while the app was asking or giving feedback in a session.
    // @spec AUDIO-CMD-006
    private func speakingInSession(_ event: SessionEvent, _ t: Double) -> [Effect] {
        switch event {
        case .speechFinished:
            return speechFinishedInSession(t)
        case .gesture(.twoFingerDoubleTap), .media(.playPause), .interruptionBegan, .headphonesDisconnected:
            return pause(t)
        case .gesture(.threeFingerSwipeDown):
            return endSession(t)
        default:
            return []
        }
    }

    // @spec SESSION-FB-003
    private func speechFinishedInSession(_ t: Double) -> [Effect] {
        guard let purpose = speaking else { return [] }
        speaking = nil
        lastQuiet = t
        switch purpose {
        case .prompt:
            if promptEnd == nil { promptEnd = t }
            state = .listening
            return listen(exerciseAllowed)
        case .sorry, .sayAgain, .voiceOff:
            state = .listening
            return listen(exerciseAllowed)
        case .candidate:
            state = .confirming
            return listen(.exercise(.yesOrNo))
        case .pickInfo:
            return listen(exerciseAllowed)
        case .speakBack:
            if lastAnswerRight { return nextOrEnd(t) }
            state = .feedback
            return speak(SpokenChess.correction(for: currentExercise!), .correction)
        case .correction:
            return nextOrEnd(t)
        default:
            return []
        }
    }

    // @spec SESSION-END-002
    private func nextOrEnd(_ t: Double) -> [Effect] {
        elapsed(t) >= SessionEngine.sessionLength ? endSession(t) : beginExercise(t)
    }

    // MARK: Listening

    // @spec SESSION-EX-005, SESSION-EX-006, SESSION-EX-007, SESSION-EX-008, SESSION-FB-001,
    //       TOUCH-002, TOUCH-003, TOUCH-004, TOUCH-005, TOUCH-006, TOUCH-007, TOUCH-008, TOUCH-SQ-001,
    //       AUDIO-CMD-002, AUDIO-CMD-004, AUDIO-CMD-005
    private func listening(_ event: SessionEvent, _ t: Double) -> [Effect] {
        guard let exercise = currentExercise else { return [] }
        switch event {
        case .speechFinished:
            return speechFinishedInSession(t)
        case .tick:
            if !autoRepeatUsed && speaking == nil && t - lastQuiet >= SessionEngine.repeatAfterSilence {
                autoRepeatUsed = true
                return repeatQuestion()
            }
            return []
        case let .heard(alternatives, startedAt):
            guard voiceOn, speaking == nil else { return [] }
            lastQuiet = t
            recognitionErrors = 0
            return heardWhileListening(alternatives, startedAt: startedAt, t)
        case .recognitionError:
            return recognitionError(t)
        case let .gesture(g):
            lastQuiet = t
            switch g {
            case .swipeRight, .swipeLeft:
                let right = g == .swipeRight
                switch exercise.answerKind {
                case .lightOrDark: return answer(.colour(right ? .light : .dark), .touch, at: t, t)
                case .yesOrNo: return answer(right ? .yes : .no, .touch, at: t, t)
                case .square: return []
                }
            case .swipeUp, .swipeDown:
                guard exercise.answerKind == .square else { return [] }
                return startPick(t)
            case .twoFingerTap: return repeatQuestion()
            case .longPress: return answer(nil, .touch, at: t, t)
            case .twoFingerDoubleTap: return pause(t)
            case .threeFingerSwipeDown: return endSession(t)
            default: return []
            }
        case .media(.playPause): return pause(t)
        case .media(.nextTrack): return answer(nil, .touch, at: t, t)
        case .media(.previousTrack): return repeatQuestion()
        case .interruptionBegan, .headphonesDisconnected: return pause(t)
        default:
            return []
        }
    }

    private func heardWhileListening(_ alternatives: [String], startedAt: Double, _ t: Double) -> [Effect] {
        switch SpokenChess.hear(alternatives, allowed: exerciseAllowed) {
        case .command(.repeat): return repeatQuestion()
        case .command(.dontKnow): return answer(nil, .voice, at: startedAt, t)
        case .command(.pause): return pause(t)
        case .command(.stop): return endSession(t)
        case .command(.resume): return []
        case let .understood(a): return answer(a, .voice, at: startedAt, t)
        case let .unsure(list):
            candidates = list
            candidateIndex = 0
            candidateSpokenAt = startedAt
            state = .confirming
            return speak(SpokenChess.candidate(list[0]), .candidate)
        case .notUnderstood:
            sorryCount += 1
            if sorryCount >= 3 {
                sorryCount = 0
                return repeatQuestion()
            }
            return speak("Sorry?", .sorry)
        }
    }

    // @spec VOICE-IN-007, VOICE-IN-008
    private func recognitionError(_ t: Double) -> [Effect] {
        guard voiceOn else { return [] }
        recognitionErrors += 1
        guard recognitionErrors >= 3 else { return micOn ? [.listen(exerciseAllowed)] : [] }
        let fx = stopMic()
        voiceOn = false
        var out = fx
        if !screenAwake {
            screenAwake = true
            out.append(.keepScreenAwake(true))
        }
        return out + speak(SessionPhrases.voiceTurnedOff, .voiceOff)
    }

    // MARK: Answering

    /// Records an answer (nil = I don't know) given at `answerStart`, and gives feedback.
    // @spec SESSION-FB-001, SESSION-FB-002, SESSION-FB-003, SESSION-FB-004, SESSION-TIME-001, SESSION-TIME-002,
    //       STORE-SAVE-002
    private func answer(_ given: Answer?, _ method: AnswerMethod, at answerStart: Double, _ t: Double, speakBack: String? = nil) -> [Effect] {
        guard let exercise = currentExercise, !answered else { return [] }
        answered = true
        candidates = []
        let right = exercise.check(given)
        lastAnswerRight = right
        let seconds = max(0, answerStart - (promptEnd ?? answerStart) - pausedDuringExercise)
        let outcome: Outcome = right ? .right(method, seconds: seconds) : (given == nil ? .dontKnow(method) : .wrong(method))
        var ladder = progress.ladder
        if let change = ladder.record(outcome, drill: exercise.drill, askedAtLevel: exercise.level) { levelChanges.append(change) }
        progress.ladder = ladder
        totalCount += 1
        if right { rightCount += 1 }

        var fx = stopMic()
        if let speakBack {
            state = .feedback
            fx += speak(speakBack, .speakBack)
            return fx + [.play(right ? .right : .wrong), .save(progress)]
        }
        fx += [.play(right ? .right : .wrong), .save(progress)]
        if right { return fx + nextOrEnd(t) }
        state = .feedback
        return fx + speak(SpokenChess.correction(for: exercise), .correction)
    }

    // MARK: Confirming

    // @spec SESSION-CONF-001, SESSION-CONF-002, SESSION-CONF-003, SESSION-CONF-004, SESSION-CONF-005,
    //       SESSION-CONF-006, TOUCH-012
    private func confirming(_ event: SessionEvent, _ t: Double) -> [Effect] {
        switch event {
        case .speechFinished:
            return speechFinishedInSession(t)
        case let .heard(alternatives, startedAt):
            guard voiceOn, speaking == nil else { return [] }
            lastQuiet = t
            recognitionErrors = 0
            switch SpokenChess.hear(alternatives, allowed: .exercise(.yesOrNo)) {
            case .understood(.yes): return confirmYes(t)
            case .understood(.no): return confirmNo()
            case .command(.repeat): return repeatQuestion()
            case .command(.dontKnow): return answer(nil, .voice, at: startedAt, t)
            case .command(.pause): return pause(t)
            case .command(.stop): return endSession(t)
            default: return speak("Sorry?", .candidate)
            }
        case .recognitionError:
            return recognitionError(t)
        case .gesture(.swipeRight): return speaking == nil ? confirmYes(t) : []
        case .gesture(.swipeLeft): return speaking == nil ? confirmNo() : []
        case .gesture(.twoFingerTap): return repeatQuestion()
        case .gesture(.longPress): return answer(nil, .touch, at: t, t)
        case .gesture(.twoFingerDoubleTap), .media(.playPause), .interruptionBegan, .headphonesDisconnected: return pause(t)
        case .gesture(.threeFingerSwipeDown): return endSession(t)
        case .media(.nextTrack): return answer(nil, .touch, at: t, t)
        case .media(.previousTrack): return repeatQuestion()
        default: return []
        }
    }

    private func confirmYes(_ t: Double) -> [Effect] {
        guard candidateIndex < candidates.count else { return [] }
        return answer(candidates[candidateIndex], .voice, at: candidateSpokenAt, t)
    }

    private func confirmNo() -> [Effect] {
        candidateIndex += 1
        if candidateIndex < candidates.count {
            return speak(SpokenChess.candidate(candidates[candidateIndex]), .candidate)
        }
        candidates = []
        return speak("Say it again?", .sayAgain)
    }

    // MARK: Picking a square by touch

    private func startPick(_ t: Double) -> [Effect] {
        pickFile = 4
        pickRank = 3
        pickStartedAt = t
        state = .pickingFile
        return speak("File, \(SpokenChess.spokenFile(pickFile)).", .pickInfo)
    }

    // @spec TOUCH-SQ-001, TOUCH-SQ-002, TOUCH-SQ-003, TOUCH-SQ-004, TOUCH-SQ-005, TOUCH-SQ-006,
    //       TOUCH-SQ-007, TOUCH-SQ-008
    private func picking(_ event: SessionEvent, _ t: Double) -> [Effect] {
        switch event {
        case .speechFinished:
            return speechFinishedInSession(t)
        case let .heard(alternatives, startedAt):
            guard voiceOn, speaking == nil else { return [] }
            lastQuiet = t
            return heardWhileListening(alternatives, startedAt: startedAt, t)
        case .recognitionError:
            return recognitionError(t)
        case .gesture(.swipeUp), .gesture(.swipeDown):
            let up = event == .gesture(.swipeUp)
            let current = state == .pickingFile ? pickFile : pickRank
            let next = current + (up ? 1 : -1)
            guard (0...7).contains(next) else { return [.play(.bump)] }
            if state == .pickingFile {
                pickFile = next
                return speak(SpokenChess.sentence("\(SpokenChess.spokenFile(next))."), .pickInfo)
            }
            pickRank = next
            return speak(SpokenChess.sentence("\(SpokenChess.spokenRank(next))."), .pickInfo)
        case .gesture(.doubleTap):
            if state == .pickingFile {
                state = .pickingRank
                pickRank = 3
                return speak("Rank, \(SpokenChess.spokenRank(pickRank)).", .pickInfo)
            }
            let square = Square(unchecked: pickFile, pickRank)
            return answer(.square(square), .touch, at: pickStartedAt, t, speakBack: SpokenChess.sentence("\(SpokenChess.speak(square))."))
        case .gesture(.twoFingerTap), .media(.previousTrack):
            return repeatQuestion()
        case .gesture(.longPress), .media(.nextTrack):
            return answer(nil, .touch, at: t, t)
        case .gesture(.twoFingerDoubleTap), .media(.playPause), .interruptionBegan, .headphonesDisconnected:
            return pause(t)
        case .gesture(.threeFingerSwipeDown):
            return endSession(t)
        default:
            return []
        }
    }

    // MARK: Pause

    // @spec SESSION-PAUSE-001, SESSION-PAUSE-002, SESSION-PAUSE-003
    private func pause(_ t: Double) -> [Effect] {
        pausedFrom = state
        pausedAt = t
        if let since = clockRunningSince {
            clockTotal += t - since
            clockRunningSince = nil
        }
        speaking = nil
        candidates = []
        state = .paused
        var fx: [Effect] = [.stopSpeaking]
        fx += stopMic()
        return fx + listen(.paused)
    }

    // @spec SESSION-PAUSE-004, SESSION-END-004, AUDIO-CMD-003, AUDIO-CMD-007, AUDIO-INT-001, AUDIO-INT-002,
    //       AUDIO-INT-003, AUDIO-BG-002
    private func paused(_ event: SessionEvent, _ t: Double) -> [Effect] {
        let limitReached = t - pausedAt >= SessionEngine.pauseLimit
        switch event {
        case .gesture(.twoFingerDoubleTap), .media(.playPause), .media(.previousTrack):
            return resume(t)
        case let .heard(alternatives, _):
            guard voiceOn else { return [] }
            switch SpokenChess.hear(alternatives, allowed: .paused) {
            case .command(.resume): return resume(t)
            case .command(.stop): return endSession(t)
            default: return []
            }
        case .gesture(.threeFingerSwipeDown):
            return endSession(t)
        case .tick:
            return limitReached ? endSession(t) : []
        case .appResumed:
            return limitReached ? endSession(t, silently: true) : []
        default:
            return []
        }
    }

    // @spec SESSION-PAUSE-006
    private func resume(_ t: Double) -> [Effect] {
        pausedDuringExercise += t - pausedAt
        if clockTotal > 0 || pausedFrom != .starting { clockRunningSince = t }
        let fx = stopMic()
        if pausedFrom == .starting {
            state = .starting
            clockRunningSince = nil
            return fx + speak(announcements[announcementIndex], .announcement)
        }
        if answered { return fx + nextOrEnd(t) }
        autoRepeatUsed = false
        sorryCount = 0
        return fx + repeatQuestion()
    }

    // MARK: Ending

    // @spec SESSION-END-003, SESSION-END-005, SESSION-END-006, SESSION-END-007, STORE-003, TOUCH-SCR-003
    private func endSession(_ t: Double, silently: Bool = false) -> [Effect] {
        if let since = clockRunningSince {
            clockTotal += t - since
            clockRunningSince = nil
        }
        let summary = SessionSummary(
            start: startDate,
            unpausedSeconds: clockTotal, seed: seed, right: rightCount, total: totalCount, levelChanges: levelChanges)
        progress.add(summary)
        var fx: [Effect] = [.stopSpeaking]
        fx += stopMic()
        if screenAwake {
            screenAwake = false
            fx.append(.keepScreenAwake(false))
        }
        fx += [.save(progress), .sessionEnded(summary)]
        currentExercise = nil
        nowPlayingUntil = t + SessionEngine.nowPlayingAfterEnd
        if silently {
            state = .idle
            speaking = nil
            return fx + [.audio(.released)]
        }
        state = .ending
        let text = totalCount == 0 ? "Session ended." : SessionPhrases.summary(right: rightCount, total: totalCount, changes: levelChanges)
        return fx + speak(text, .summary)
    }

    private func ending(_ event: SessionEvent, _ t: Double) -> [Effect] {
        guard event == .speechFinished, speaking == .summary else { return [] }
        speaking = nil
        state = .idle
        return [.audio(.released)]
    }
}

/// Spoken phrases used by the session.
public enum SessionPhrases {
    public static func introduction(voiceAvailable: Bool) -> String {
        voiceAvailable
            ? "To answer, say it out loud, or swipe: swipe right for light or yes, swipe left for dark or no. Swipe up or down to pick a square."
            : "To answer by touch, swipe right for light or yes, swipe left for dark or no. Swipe up or down to pick a square."
    }

    public static var touchOnly: String { "Voice is off, so answers are by touch." }
    public static var voiceTurnedOff: String { "Voice isn't working, so answers are by touch for now." }
    public static var notSaving: String { "Progress is not being saved, because it was made by a newer version of the app." }

    // @spec SESSION-END-006
    public static func summary(right: Int, total: Int, changes: [LevelChange]) -> String {
        var parts = ["\(right) of \(total) right."]
        for c in changes {
            parts.append("\(drillName(c.drill)) moved \(c.to > c.from ? "up" : "down") to level \(c.to).")
        }
        return parts.joined(separator: " ")
    }

    public static func drillName(_ drill: Drill) -> String {
        switch drill {
        case .squareColour: "Square colour"
        case .directions: "Directions"
        case .diagonals: "Diagonals"
        }
    }
}
