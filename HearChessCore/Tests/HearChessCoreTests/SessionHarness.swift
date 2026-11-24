import Testing
@testable import HearChessCore

/// Drives a SessionEngine with a fake clock and records its effects.
final class Harness {
    var t: Double = 1000
    let engine: SessionEngine
    var log: [Effect] = []
    var voiceAvailable: Bool
    private var queue: [Exercise]
    private var queueIndex = 0

    init(
        progress: Progress = Progress(introductionGiven: true),
        voice: Bool = true,
        saving: Bool = true,
        permissionStepDone: Bool = true,
        exercises: [Exercise]? = nil
    ) {
        voiceAvailable = voice
        queue = exercises ?? []
        var box: Harness?
        engine = SessionEngine(
            progress: progress,
            savingEnabled: saving,
            permissionStepDone: permissionStepDone,
            voiceCheck: { box?.voiceAvailable ?? false },
            seedSource: { 42 }
        )
        box = self
        if exercises != nil {
            engine.exerciseOverride = { [unowned self] _ in
                let ex = self.queue[self.queueIndex % self.queue.count]
                self.queueIndex += 1
                return ex
            }
        }
    }

    @discardableResult
    func send(_ event: SessionEvent, after dt: Double = 0) -> [Effect] {
        t += dt
        let fx = engine.handle(event, at: t)
        log += fx
        return fx
    }

    @discardableResult
    func gesture(_ g: Gesture, after dt: Double = 0) -> [Effect] { send(.gesture(g), after: dt) }

    @discardableResult
    func media(_ m: MediaCommand, after dt: Double = 0) -> [Effect] { send(.media(m), after: dt) }

    /// The player starts speaking `startedAfter` seconds from now; the result arrives a moment later.
    @discardableResult
    func say(_ alternatives: [String], startedAfter: Double = 1) -> [Effect] {
        let start = t + startedAfter
        return send(.heard(alternatives, startedAt: start), after: startedAfter + 0.8)
    }

    @discardableResult
    func say(_ text: String, startedAfter: Double = 1) -> [Effect] { say([text], startedAfter: startedAfter) }

    /// Reports speech finished until the engine stops speaking (or `limit` times); returns all effects.
    @discardableResult
    func finishSpeaking(limit: Int = 6, after dt: Double = 1) -> [Effect] {
        var all: [Effect] = []
        for _ in 0..<limit {
            let fx = send(.speechFinished, after: dt)
            all += fx
            if !fx.contains(where: { if case .speak = $0 { true } else { false } }) { break }
        }
        return all
    }

    /// Starts a session with a tap and finishes speaking until the first question is being listened for.
    @discardableResult
    func start() -> [Effect] {
        var fx = gesture(.tap)
        fx += finishSpeaking()
        return fx
    }

    /// The current exercise; records a test failure (instead of crashing) when there is none.
    var exercise: Exercise {
        if let ex = engine.currentExercise { return ex }
        Issue.record("no current exercise")
        return colourF6
    }

    /// Answers the current exercise correctly by voice.
    @discardableResult
    func answerRight(startedAfter: Double = 1) -> [Effect] { say(words(exercise.correctAnswers.first ?? .yes), startedAfter: startedAfter) }

    /// Answers the current exercise wrongly by voice.
    @discardableResult
    func answerWrong() -> [Effect] { say(words(wrongAnswer(for: exercise))) }

    /// Answers wrongly and finishes the correction, landing on the next question.
    func answerWrongAndContinue() {
        answerWrong()
        finishSpeaking()
    }

    func answerRightAndContinue() {
        answerRight()
        finishSpeaking()
    }
}

func words(_ answer: Answer) -> String {
    switch answer {
    case .colour(.light): "light"
    case .colour(.dark): "dark"
    case .yes: "yes"
    case .no: "no"
    case let .square(s): s.name
    }
}

func wrongAnswer(for ex: Exercise) -> Answer {
    switch ex.answerKind {
    case .lightOrDark: ex.correctAnswers.contains(.colour(.light)) ? .colour(.dark) : .colour(.light)
    case .yesOrNo: ex.correctAnswers.contains(.yes) ? .no : .yes
    case .square:
        allSquares.map(Answer.square).first { !ex.correctAnswers.contains($0) }!
    }
}

func spoken(_ fx: [Effect]) -> [String] {
    fx.compactMap { if case let .speak(s) = $0 { s } else { nil } }
}

func listens(_ fx: [Effect]) -> [Allowed] {
    fx.compactMap { if case let .listen(a) = $0 { a } else { nil } }
}

func sounds(_ fx: [Effect]) -> [Sound] {
    fx.compactMap { if case let .play(s) = $0 { s } else { nil } }
}

func saves(_ fx: [Effect]) -> [Progress] {
    fx.compactMap { if case let .save(p) = $0 { p } else { nil } }
}

func endings(_ fx: [Effect]) -> [SessionSummary] {
    fx.compactMap { if case let .sessionEnded(s) = $0 { s } else { nil } }
}

// Fixed exercises for flow tests.
let f6 = Square(unchecked: 5, 5)
let e4 = Square(unchecked: 4, 3)
let g4 = Square(unchecked: 6, 3)
let colourF6 = Exercise(drill: .squareColour, level: 1, prompt: .squareColour(f6), answerKind: .lightOrDark, correctAnswers: [.colour(.dark)])
let colourE4 = Exercise(drill: .squareColour, level: 1, prompt: .squareColour(e4), answerKind: .lightOrDark, correctAnswers: [.colour(.light)])
let twoRightOfE4 = Exercise(drill: .directions, level: 1, prompt: .direction(from: e4, steps: [Step(2, .right)]), answerKind: .square, correctAnswers: [.square(g4)])
let sameDiagC1H6 = Exercise(drill: .diagonals, level: 2, prompt: .sameDiagonal(Square(unchecked: 2, 0), Square(unchecked: 7, 5)), answerKind: .yesOrNo, correctAnswers: [.yes])
