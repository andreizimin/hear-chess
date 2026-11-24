// The ladder: skill estimates, level moves and choosing the next drill.
// Design: docs/intent/ladder/ladder-design.md

/// How an answer was given.
public enum AnswerMethod: String, Hashable, Codable, Sendable {
    case voice
    case touch
}

/// What happened when an exercise was answered.
public enum Outcome: Hashable, Sendable {
    case right(AnswerMethod, seconds: Double)
    case wrong(AnswerMethod)
    case dontKnow(AnswerMethod)
}

/// One recorded result.
public struct ExerciseResult: Hashable, Codable, Sendable {
    public let right: Bool
    public let method: AnswerMethod
    /// Answer time in seconds, kept only for right voice answers.
    public let seconds: Double?

    public init(right: Bool, method: AnswerMethod, seconds: Double?) {
        self.right = right
        self.method = method
        self.seconds = seconds
    }
}

/// A drill's level and its recent results at that level.
public struct SkillEstimate: Hashable, Codable, Sendable {
    public var level: Int
    public var results: [ExerciseResult]

    public init(level: Int = 1, results: [ExerciseResult] = []) {
        self.level = level
        self.results = results
    }
}

/// A drill moving to a new level.
public struct LevelChange: Hashable, Codable, Sendable {
    public let drill: Drill
    public let from: Int
    public let to: Int

    public init(drill: Drill, from: Int, to: Int) {
        self.drill = drill
        self.from = from
        self.to = to
    }
}

public struct Ladder: Hashable, Codable, Sendable {
    public private(set) var estimates: [Drill: SkillEstimate]

    public init(estimates: [Drill: SkillEstimate] = [:]) {
        self.estimates = estimates
    }

    public static let maxResults = 20

    /// Target voice answer time in seconds.
    public static func targetTime(_ drill: Drill) -> Double { 0 }

    /// The drill's estimate; level 1 with no results if none is stored.
    public func estimate(_ drill: Drill) -> SkillEstimate { SkillEstimate() }

    /// Records a result for an exercise asked at `askedAtLevel`, applies the level rules,
    /// and returns the level change if one happened.
    @discardableResult
    public mutating func record(_ outcome: Outcome, drill: Drill, askedAtLevel: Int) -> LevelChange? { nil }

    /// The drill's weight when choosing the next exercise.
    public func weight(_ drill: Drill) -> Double { 0 }

    /// Chooses the next drill among `drills`, never a fourth time in a row after `recent`
    /// (the drills chosen so far this session, oldest first).
    public func chooseDrill<R: RandomNumberGenerator>(from drills: [Drill], recent: [Drill], using rng: inout R) -> Drill {
        drills[0]
    }
}
