// The session engine: the flow of a training session as a state machine.
// Events go in, effects come out. Design: docs/intent/session/session-design.md

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

    /// - Parameters:
    ///   - voiceCheck: whether voice input is available now (permissions and on-device recognition).
    ///   - seedSource: a fresh random seed for each session.
    public init(
        progress: Progress,
        savingEnabled: Bool = true,
        permissionStepDone: Bool = true,
        voiceCheck: @escaping () -> Bool,
        seedSource: @escaping () -> UInt64
    ) {
        self.progress = progress
        self.savingEnabled = savingEnabled
        self.permissionStepDone = permissionStepDone
        self.voiceCheck = voiceCheck
        self.seedSource = seedSource
    }

    /// Handles one event at time `time` (seconds, monotonic) and returns the effects to carry out, in order.
    public func handle(_ event: SessionEvent, at time: Double) -> [Effect] {
        // Placeholder until implemented.
        []
    }
}

/// Spoken phrases used by the session.
public enum SessionPhrases {
    public static func introduction(voiceAvailable: Bool) -> String { "" }
    public static var touchOnly: String { "" }
    public static var voiceTurnedOff: String { "" }
    public static var notSaving: String { "" }
    public static func summary(right: Int, total: Int, changes: [LevelChange]) -> String { "" }
    public static func drillName(_ drill: Drill) -> String { "" }
}
