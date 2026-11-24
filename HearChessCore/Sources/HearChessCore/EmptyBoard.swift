// Empty-board drills: square colour, directions and diagonals.
// Design: docs/intent/exercises/empty-board/empty-board-design.md

/// The three diagonal question types.
public enum DiagonalQuestion: String, CaseIterable, Sendable {
    case sameDiagonal
    case diagonalEnd
    case longDiagonal
}

public enum EmptyBoard {
    /// The drills of the empty-board rung.
    public static var drills: [Drill] { [] }

    /// Generates an exercise for a drill and level. The same random state, drill, level and
    /// previous question always give the same exercise, and the result never has the same
    /// content as `previous`.
    public static func generate<R: RandomNumberGenerator>(
        drill: Drill,
        level: Int,
        previous: Exercise?,
        using rng: inout R
    ) -> Exercise {
        // Placeholder until implemented.
        let a1 = Square(unchecked: 0, 0)
        return Exercise(drill: drill, level: level, prompt: .squareColour(a1), answerKind: .lightOrDark, correctAnswers: [])
    }
}
