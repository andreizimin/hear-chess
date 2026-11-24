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
    // @spec EX-EMPTY-001
    public static var drills: [Drill] { [.squareColour, .directions, .diagonals] }

    /// Generates an exercise for a drill and level. The same random state, drill, level and
    /// previous question always give the same exercise, and the result never has the same
    /// content as `previous`.
    // @spec EX-EMPTY-002, EX-EMPTY-003, EX-EMPTY-004, EX-EMPTY-006
    public static func generate<R: RandomNumberGenerator>(
        drill: Drill,
        level: Int,
        previous: Exercise?,
        using rng: inout R
    ) -> Exercise {
        let level = min(max(level, 1), drill.maxLevel)
        while true {
            let candidate: Exercise
            switch drill {
            case .squareColour: candidate = squareColour(level: level, using: &rng)
            case .directions: candidate = directions(level: level, using: &rng)
            case .diagonals: candidate = diagonals(level: level, using: &rng)
            }
            if candidate.contentKey != previous?.contentKey { return candidate }
        }
    }

    // MARK: Square colour

    static let corners = ["a1", "h1", "a8", "h8"].compactMap { Square(name: $0) }
    static let centre = ["d4", "e4", "d5", "e5"].compactMap { Square(name: $0) }
    static let edge = allSquares.filter(isEdge)
    static let allSquares: [Square] = (0..<8).flatMap { f in (0..<8).map { r in Square(unchecked: f, r) } }

    static func isEdge(_ s: Square) -> Bool { s.file == 0 || s.file == 7 || s.rank == 0 || s.rank == 7 }

    // @spec EX-EMPTY-COL-001, EX-EMPTY-COL-002, EX-EMPTY-COL-003, EX-EMPTY-COL-004
    static func squareColour<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> Exercise {
        let pool: [Square]
        switch level {
        case 1: pool = corners + centre
        case 2: pool = edge + centre
        default: pool = allSquares
        }
        let square = pool.randomElement(using: &rng)!
        return Exercise(drill: .squareColour, level: level, prompt: .squareColour(square),
                        answerKind: .lightOrDark, correctAnswers: [.colour(square.colour)])
    }

    // MARK: Directions

    static let orthogonal: [Direction] = [.up, .down, .left, .right]
    static let diagonalDirections: [Direction] = [.upRight, .upLeft, .downRight, .downLeft]

    // @spec EX-EMPTY-DIR-001, EX-EMPTY-DIR-002, EX-EMPTY-DIR-003, EX-EMPTY-DIR-004,
    //       EX-EMPTY-DIR-005, EX-EMPTY-DIR-006, EX-EMPTY-DIR-007
    static func directions<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> Exercise {
        let steps: [Step]
        switch level {
        case 1: steps = [Step(1, orthogonal.randomElement(using: &rng)!)]
        case 2: steps = [Step(Int.random(in: 2...3, using: &rng), orthogonal.randomElement(using: &rng)!)]
        case 3: steps = [Step(Int.random(in: 1...3, using: &rng), diagonalDirections.randomElement(using: &rng)!)]
        default:
            // A knight's jump, with the up-or-down part first.
            let vertical = Int.random(in: 1...2, using: &rng)
            steps = [Step(vertical, Bool.random(using: &rng) ? .up : .down),
                     Step(3 - vertical, Bool.random(using: &rng) ? .left : .right)]
        }
        let df = steps.reduce(0) { $0 + $1.direction.fileStep * $1.count }
        let dr = steps.reduce(0) { $0 + $1.direction.rankStep * $1.count }
        let starts = allSquares.filter { $0.offset(file: df, rank: dr) != nil }
        let from = starts.randomElement(using: &rng)!
        let target = from.offset(file: df, rank: dr)!
        return Exercise(drill: .directions, level: level, prompt: .direction(from: from, steps: steps),
                        answerKind: .square, correctAnswers: [.square(target)])
    }

    // MARK: Diagonals

    // @spec EX-EMPTY-DIAG-001, EX-EMPTY-DIAG-010, EX-EMPTY-DIAG-011, EX-EMPTY-DIAG-012
    static func diagonals<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> Exercise {
        if level == 1 { return longDiagonal(using: &rng) }
        let starts = level == 2 ? edge : allSquares
        return Bool.random(using: &rng)
            ? sameDiagonal(level: level, from: starts, using: &rng)
            : diagonalEnd(level: level, from: starts, using: &rng)
    }

    // @spec EX-EMPTY-DIAG-002, EX-EMPTY-DIAG-003, EX-EMPTY-DIAG-004
    static func sameDiagonal<R: RandomNumberGenerator>(level: Int, from starts: [Square], using rng: inout R) -> Exercise {
        let a = starts.randomElement(using: &rng)!
        let yes = Bool.random(using: &rng)
        let others = allSquares.filter { $0 != a && Board.shareDiagonal(a, $0) == yes && $0.colour == a.colour }
        let b = others.randomElement(using: &rng)!
        return Exercise(drill: .diagonals, level: level, prompt: .sameDiagonal(a, b),
                        answerKind: .yesOrNo, correctAnswers: [yes ? .yes : .no])
    }

    // @spec EX-EMPTY-DIAG-005, EX-EMPTY-DIAG-006
    static func diagonalEnd<R: RandomNumberGenerator>(level: Int, from starts: [Square], using rng: inout R) -> Exercise {
        let from = starts.randomElement(using: &rng)!
        let possible = diagonalDirections.filter { from.moved($0, steps: 1) != nil }
        let direction = possible.randomElement(using: &rng)!
        let end = Board.diagonalEnd(from: from, direction: direction)!
        return Exercise(drill: .diagonals, level: level, prompt: .diagonalEnd(from: from, direction: direction),
                        answerKind: .square, correctAnswers: [.square(end)])
    }

    // @spec EX-EMPTY-DIAG-007, EX-EMPTY-DIAG-008, EX-EMPTY-DIAG-009
    static func longDiagonal<R: RandomNumberGenerator>(using rng: inout R) -> Exercise {
        let diagonal = Board.longDiagonals.randomElement(using: &rng)!
        let yes = Bool.random(using: &rng)
        let pool = yes
            ? diagonal.squares.filter { $0 != diagonal.start && $0 != diagonal.end }
            : allSquares.filter { $0.colour == diagonal.colour && !diagonal.contains($0) }
        let square = pool.randomElement(using: &rng)!
        return Exercise(drill: .diagonals, level: 1, prompt: .longDiagonal(diagonal, square),
                        answerKind: .yesOrNo, correctAnswers: [yes ? .yes : .no])
    }
}
