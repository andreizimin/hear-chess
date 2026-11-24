import Testing
@testable import HearChessCore

/// A square by name, failing the test (not crashing) if it cannot be made.
func sq(_ name: String, sourceLocation: SourceLocation = #_sourceLocation) throws -> Square {
    try #require(Square(name: name), "square \(name)", sourceLocation: sourceLocation)
}

/// Every square on the board, built without depending on the board's own constructors.
let allSquares: [Square] = (0..<8).flatMap { f in (0..<8).map { r in Square(unchecked: f, r) } }

let files = Array("abcdefgh")
