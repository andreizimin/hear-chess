// Spoken chess: prompts to words, and recognized speech to answers.
// Design: docs/intent/spoken-chess/spoken-chess-design.md

/// Commands a player can say.
public enum Command: String, CaseIterable, Hashable, Codable, Sendable {
    case `repeat`
    case dontKnow
    case pause
    case resume
    case stop
}

/// What may be heard at a given moment.
public struct Allowed: Hashable, Sendable {
    public var answerKind: AnswerKind?
    public var commands: Set<Command>

    public init(answerKind: AnswerKind?, commands: Set<Command>) {
        self.answerKind = answerKind
        self.commands = commands
    }

    /// During an exercise: answers of its kind plus repeat, I don't know, pause and stop.
    public static func exercise(_ kind: AnswerKind) -> Allowed {
        Allowed(answerKind: kind, commands: [.repeat, .dontKnow, .pause, .stop])
    }

    /// While paused: only resume and stop.
    public static let paused = Allowed(answerKind: nil, commands: [.resume, .stop])

    /// Confirming a candidate or "Start training?": yes or no only.
    public static let yesOrNo = Allowed(answerKind: .yesOrNo, commands: [])
}

/// How one transcription reads.
public enum Reading: Hashable, Sendable {
    case answer(Answer)
    case command(Command)
    case nothing
}

/// The result of reading all of the recognizer's alternatives.
public enum Hearing: Hashable, Sendable {
    case command(Command)
    case understood(Answer)
    case unsure([Answer])
    case notUnderstood
}

public enum SpokenChess {
    /// How each file letter is spelled so the speech engine says its name.
    public static var letterPronunciation: [Character: String] { [:] }

    /// "ee four" for e4.
    public static func speak(_ square: Square) -> String { "" }

    /// The words spoken for a prompt.
    public static func text(for prompt: Prompt) -> String { "" }

    /// The words spoken after a wrong answer, such as "ef six is dark" or "gee four".
    public static func correction(for exercise: Exercise) -> String { "" }

    /// Reads one transcription against what is allowed.
    public static func read(_ transcription: String, allowed: Allowed) -> Reading { .nothing }

    /// Reads the recognizer's alternatives, best first.
    public static func hear(_ alternatives: [String], allowed: Allowed) -> Hearing { .notUnderstood }
}
