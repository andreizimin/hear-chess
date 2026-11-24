// Board geometry: squares, colours, directions and diagonals.
// Design: docs/intent/board/board-design.md

/// The colour of a square.
public enum SquareColour: String, Hashable, Codable, Sendable {
    case light
    case dark
}

/// A square on the board. File and rank are 0–7, with a1 as (0, 0).
public struct Square: Hashable, Codable, Sendable, CustomStringConvertible {
    public let file: Int
    public let rank: Int

    public init?(file: Int, rank: Int) {
        // Placeholder until implemented.
        return nil
    }

    /// Creates a square without checking; only for values known to be on the board.
    init(unchecked file: Int, _ rank: Int) {
        self.file = file
        self.rank = rank
    }

    public init?(name: String) {
        // Placeholder until implemented.
        return nil
    }

    /// The square's name, such as "e4".
    public var name: String { "" }

    public var colour: SquareColour { .light }

    public var description: String { name }

    /// The square `steps` steps away in `direction`, or nil if off the board or `steps` < 1.
    public func moved(_ direction: Direction, steps: Int) -> Square? { nil }

    /// The square at a file and rank offset, or nil if off the board.
    public func offset(file fileOffset: Int, rank rankOffset: Int) -> Square? { nil }
}

/// The eight directions, named from White's side.
public enum Direction: String, CaseIterable, Hashable, Codable, Sendable {
    case up, down, right, left, upRight, upLeft, downRight, downLeft

    public var fileStep: Int { 0 }
    public var rankStep: Int { 0 }

    public var isDiagonal: Bool { false }
}

/// A diagonal, identified by its two end squares; `start` is the end with the lower rank.
public struct Diagonal: Hashable, Codable, Sendable {
    public let start: Square
    public let end: Square

    public init(start: Square, end: Square) {
        self.start = start
        self.end = end
    }

    /// Number of squares on the diagonal, 1–8.
    public var length: Int { 0 }

    /// All squares on the diagonal, from `start` to `end`.
    public var squares: [Square] { [] }

    public func contains(_ square: Square) -> Bool { false }

    /// The colour shared by every square on the diagonal.
    public var colour: SquareColour { start.colour }
}

/// Questions about lines on the board.
public enum Board {
    /// The two whole diagonals through a square.
    public static func diagonals(through square: Square) -> (upRight: Diagonal, upLeft: Diagonal) {
        let d = Diagonal(start: square, end: square)
        return (d, d)
    }

    public static func shareDiagonal(_ a: Square, _ b: Square) -> Bool { false }
    public static func shareFile(_ a: Square, _ b: Square) -> Bool { false }
    public static func shareRank(_ a: Square, _ b: Square) -> Bool { false }

    /// The edge square reached travelling from `square` in a diagonal `direction`,
    /// or nil if `square` is already at the edge in that direction or `direction` is not diagonal.
    public static func diagonalEnd(from square: Square, direction: Direction) -> Square? { nil }

    /// a1–h8 (dark) and h1–a8 (light).
    public static var longDiagonals: [Diagonal] { [] }
}
