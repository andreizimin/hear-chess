// The shape every exercise shares, and seeded randomness.
// Design: docs/intent/exercises/exercises-design.md

/// The specific kind of question within a family. The ladder keeps a skill estimate per drill.
public enum Drill: String, CaseIterable, Hashable, Codable, Sendable {
    case squareColour
    case directions
    case diagonals

    /// The highest level the drill has.
    public var maxLevel: Int {
        switch self {
        case .squareColour: 3
        case .directions: 4
        case .diagonals: 3
        }
    }
}

/// What kind of answer a question expects.
public enum AnswerKind: String, Hashable, Codable, Sendable {
    case lightOrDark
    case yesOrNo
    case square
}

/// An answer to a question.
public enum Answer: Hashable, Codable, Sendable {
    case colour(SquareColour)
    case yes
    case no
    case square(Square)

    public var kind: AnswerKind {
        switch self {
        case .colour: .lightOrDark
        case .yes, .no: .yesOrNo
        case .square: .square
        }
    }
}

/// One part of a directions offset, such as "two right".
public struct Step: Hashable, Codable, Sendable {
    public let count: Int
    public let direction: Direction

    public init(_ count: Int, _ direction: Direction) {
        self.count = count
        self.direction = direction
    }
}

/// A structured description of a question, turned into words by spoken chess.
public enum Prompt: Hashable, Codable, Sendable {
    /// "f six. Light or dark?"
    case squareColour(Square)
    /// "Two right from e four?" — steps in the order they are spoken.
    case direction(from: Square, steps: [Step])
    /// "c one and h six. Same diagonal?"
    case sameDiagonal(Square, Square)
    /// "From c one, up-right to the edge?"
    case diagonalEnd(from: Square, direction: Direction)
    /// "a one to h eight. Is d four on it?"
    case longDiagonal(Diagonal, Square)
}

/// One question and its answer.
public struct Exercise: Hashable, Codable, Sendable {
    public let drill: Drill
    public let level: Int
    public let prompt: Prompt
    public let answerKind: AnswerKind
    public let correctAnswers: Set<Answer>

    public init(drill: Drill, level: Int, prompt: Prompt, answerKind: AnswerKind, correctAnswers: Set<Answer>) {
        self.drill = drill
        self.level = level
        self.prompt = prompt
        self.answerKind = answerKind
        self.correctAnswers = correctAnswers
    }

    /// The answer spoken in the correction after a wrong answer.
    public var correction: Answer? { correctAnswers.first }

    /// Two exercises with the same content key ask the same question
    /// (same drill, question type, squares and offset, squares in any order).
    public var contentKey: String { "" }

    /// Right when the answer is one of the correct answers; nil ("I don't know") is wrong.
    public func check(_ answer: Answer?) -> Bool { false }
}

/// A deterministic random source (SplitMix64), so a seed always gives the same exercises.
public struct SeededRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
