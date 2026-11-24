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
    // @spec LADDER-005
    public static func targetTime(_ drill: Drill) -> Double {
        switch drill {
        case .squareColour: 3
        case .directions: 5
        case .diagonals: 6
        }
    }

    /// The drill's estimate; level 1 with no results if none is stored.
    // @spec LADDER-001, STORE-LOAD-007
    public func estimate(_ drill: Drill) -> SkillEstimate { estimates[drill] ?? SkillEstimate() }

    /// Records a result for an exercise asked at `askedAtLevel`, applies the level rules,
    /// and returns the level change if one happened.
    // @spec LADDER-001, LADDER-002, LADDER-003, LADDER-004, LADDER-LVL-006
    @discardableResult
    public mutating func record(_ outcome: Outcome, drill: Drill, askedAtLevel: Int) -> LevelChange? {
        var e = estimate(drill)
        guard askedAtLevel == e.level else { return nil }
        let result: ExerciseResult
        switch outcome {
        case let .right(method, seconds): result = ExerciseResult(right: true, method: method, seconds: method == .voice ? seconds : nil)
        case let .wrong(method), let .dontKnow(method): result = ExerciseResult(right: false, method: method, seconds: nil)
        }
        e.results.append(result)
        if e.results.count > Ladder.maxResults { e.results.removeFirst(e.results.count - Ladder.maxResults) }

        let change = levelChange(drill, e)
        if let change {
            e = SkillEstimate(level: change.to, results: [])
        }
        estimates[drill] = e
        return change
    }

    // @spec LADDER-LVL-001, LADDER-LVL-002, LADDER-LVL-003, LADDER-LVL-004, LADDER-LVL-005
    private func levelChange(_ drill: Drill, _ e: SkillEstimate) -> LevelChange? {
        let results = e.results
        if e.level < drill.maxLevel, results.count >= 10 {
            let last10 = results.suffix(10)
            let right = last10.filter(\.right)
            if right.count >= 9 {
                let voiceTimes = right.filter { $0.method == .voice }.compactMap(\.seconds)
                if voiceTimes.count < 5 || Ladder.median(voiceTimes) <= Ladder.targetTime(drill) {
                    return LevelChange(drill: drill, from: e.level, to: e.level + 1)
                }
            }
        }
        if e.level > 1, results.count >= 5, results.suffix(5).filter(\.right).count <= 2 {
            return LevelChange(drill: drill, from: e.level, to: e.level - 1)
        }
        return nil
    }

    // @spec LADDER-LVL-007
    static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        let mid = sorted.count / 2
        return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }

    /// The drill's weight when choosing the next exercise.
    // @spec LADDER-PICK-002, LADDER-PICK-003
    public func weight(_ drill: Drill) -> Double {
        let results = estimate(drill).results
        guard results.count >= 5 else { return 2 }
        let recent = results.suffix(10)
        let wrong = recent.filter { !$0.right }.count
        return 1 + 2 * Double(wrong) / Double(recent.count)
    }

    /// Chooses the next drill among `drills`, never a fourth time in a row after `recent`
    /// (the drills chosen so far this session, oldest first).
    // @spec LADDER-PICK-001, LADDER-PICK-004
    public func chooseDrill<R: RandomNumberGenerator>(from drills: [Drill], recent: [Drill], using rng: inout R) -> Drill {
        var candidates = drills
        if recent.count >= 3, let last = recent.last, recent.suffix(3).allSatisfy({ $0 == last }), drills.count > 1 {
            candidates.removeAll { $0 == last }
        }
        let weights = candidates.map(weight)
        let total = weights.reduce(0, +)
        var pick = Double.random(in: 0..<total, using: &rng)
        for (drill, w) in zip(candidates, weights) {
            if pick < w { return drill }
            pick -= w
        }
        return candidates.last!
    }
}
