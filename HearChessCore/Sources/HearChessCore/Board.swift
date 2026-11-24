// Board geometry: squares, colours, directions and diagonals.
// Design: docs/intent/board/board-design.md

/// The colour of a square.
public enum SquareColour: String, Hashable, Codable, Sendable {
    case light
    case dark
}

/// A square on the board. File and rank are 0–7, with a1 as (0, 0).
// @spec BOARD-SQ-001
public struct Square: Hashable, Codable, Sendable, CustomStringConvertible {
    public let file: Int
    public let rank: Int

    // @spec BOARD-SQ-002
    public init?(file: Int, rank: Int) {
        guard (0..<8).contains(file), (0..<8).contains(rank) else { return nil }
        self.file = file
        self.rank = rank
    }

    /// Creates a square without checking; only for values known to be on the board.
    init(unchecked file: Int, _ rank: Int) {
        self.file = file
        self.rank = rank
    }

    // @spec BOARD-SQ-003, BOARD-SQ-004
    public init?(name: String) {
        let chars = Array(name.trimmingWhitespace().lowercased())
        guard chars.count == 2,
              let fileIndex = "abcdefgh".firstIndex(of: chars[0]),
              let rankNumber = chars[1].wholeNumberValue, (1...8).contains(rankNumber)
        else { return nil }
        self.init(file: "abcdefgh".distance(from: "abcdefgh".startIndex, to: fileIndex), rank: rankNumber - 1)
    }

    /// The square's file letter, "a" to "h".
    public var fileLetter: Character { Array("abcdefgh")[file] }

    /// The square's name, such as "e4".
    // @spec BOARD-SQ-005
    public var name: String { "\(fileLetter)\(rank + 1)" }

    // @spec BOARD-COL-001
    public var colour: SquareColour { (file + rank) % 2 == 0 ? .dark : .light }

    public var description: String { name }

    /// The square `steps` steps away in `direction`, or nil if off the board or `steps` < 1.
    // @spec BOARD-DIR-002, BOARD-DIR-004
    public func moved(_ direction: Direction, steps: Int) -> Square? {
        guard steps >= 1 else { return nil }
        return offset(file: direction.fileStep * steps, rank: direction.rankStep * steps)
    }

    /// The square at a file and rank offset, or nil if off the board.
    // @spec BOARD-DIR-003
    public func offset(file fileOffset: Int, rank rankOffset: Int) -> Square? {
        Square(file: file + fileOffset, rank: rank + rankOffset)
    }
}

/// The eight directions, named from White's side.
// @spec BOARD-DIR-001
public enum Direction: String, CaseIterable, Hashable, Codable, Sendable {
    case up, down, right, left, upRight, upLeft, downRight, downLeft

    public var fileStep: Int {
        switch self {
        case .up, .down: 0
        case .right, .upRight, .downRight: 1
        case .left, .upLeft, .downLeft: -1
        }
    }

    public var rankStep: Int {
        switch self {
        case .right, .left: 0
        case .up, .upRight, .upLeft: 1
        case .down, .downRight, .downLeft: -1
        }
    }

    public var isDiagonal: Bool { fileStep != 0 && rankStep != 0 }

    public var opposite: Direction {
        switch self {
        case .up: .down
        case .down: .up
        case .right: .left
        case .left: .right
        case .upRight: .downLeft
        case .downLeft: .upRight
        case .upLeft: .downRight
        case .downRight: .upLeft
        }
    }
}

/// A diagonal, identified by its two end squares; `start` is the end with the lower rank.
// @spec BOARD-LINE-001
public struct Diagonal: Hashable, Codable, Sendable {
    public let start: Square
    public let end: Square

    public init(start: Square, end: Square) {
        self.start = start
        self.end = end
    }

    /// Number of squares on the diagonal, 1–8.
    // @spec BOARD-LINE-006
    public var length: Int { abs(end.rank - start.rank) + 1 }

    /// All squares on the diagonal, from `start` to `end`.
    public var squares: [Square] {
        let fileStep = end.file >= start.file ? 1 : -1
        return (0..<length).map { Square(unchecked: start.file + fileStep * $0, start.rank + $0) }
    }

    public func contains(_ square: Square) -> Bool { squares.contains(square) }

    /// The colour shared by every square on the diagonal.
    public var colour: SquareColour { start.colour }
}

/// Questions about lines on the board.
public enum Board {
    /// The two whole diagonals through a square.
    // @spec BOARD-LINE-002, BOARD-LINE-007
    public static func diagonals(through square: Square) -> (upRight: Diagonal, upLeft: Diagonal) {
        (line(through: square, .upRight), line(through: square, .upLeft))
    }

    /// The whole diagonal through `square` running in `upward` (up-right or up-left), lower end first.
    private static func line(through square: Square, _ upward: Direction) -> Diagonal {
        Diagonal(start: farthest(from: square, upward.opposite), end: farthest(from: square, upward))
    }

    private static func farthest(from square: Square, _ direction: Direction) -> Square {
        var current = square
        while let next = current.moved(direction, steps: 1) { current = next }
        return current
    }

    // @spec BOARD-LINE-003
    public static func shareDiagonal(_ a: Square, _ b: Square) -> Bool {
        abs(a.file - b.file) == abs(a.rank - b.rank)
    }

    // @spec BOARD-LINE-008
    public static func shareFile(_ a: Square, _ b: Square) -> Bool { a.file == b.file }
    public static func shareRank(_ a: Square, _ b: Square) -> Bool { a.rank == b.rank }

    /// The edge square reached travelling from `square` in a diagonal `direction`,
    /// or nil if `square` is already at the edge in that direction or `direction` is not diagonal.
    // @spec BOARD-LINE-004, BOARD-LINE-005
    public static func diagonalEnd(from square: Square, direction: Direction) -> Square? {
        guard direction.isDiagonal, square.moved(direction, steps: 1) != nil else { return nil }
        return farthest(from: square, direction)
    }

    /// a1–h8 (dark) and h1–a8 (light).
    public static var longDiagonals: [Diagonal] {
        [Diagonal(start: Square(unchecked: 0, 0), end: Square(unchecked: 7, 7)),
         Diagonal(start: Square(unchecked: 7, 0), end: Square(unchecked: 0, 7))]
    }
}

extension String {
    func trimmingWhitespace() -> String {
        var s = Substring(self)
        while let c = s.first, c.isWhitespace { s.removeFirst() }
        while let c = s.last, c.isWhitespace { s.removeLast() }
        return String(s)
    }
}
