import Testing
@testable import HearChessCore

@Suite("Board")
struct BoardTests {
    // MARK: Squares

    // @spec BOARD-SQ-001
    @Test func squareHoldsFileAndRankWithA1AtOrigin() throws {
        let a1 = try sq("a1")
        #expect(a1.file == 0 && a1.rank == 0)
        let h8 = try sq("h8")
        #expect(h8.file == 7 && h8.rank == 7)
        let e4 = try #require(Square(file: 4, rank: 3))
        #expect(e4.name == "e4")
    }

    // @spec BOARD-SQ-002
    @Test(arguments: [(-1, 0), (0, -1), (8, 0), (0, 8), (9, 9)])
    func squareFromOutOfRangeNumbersIsRejected(file: Int, rank: Int) {
        #expect(Square(file: file, rank: rank) == nil)
    }

    // @spec BOARD-SQ-003
    @Test(arguments: ["e4", "E4", " e4", "e4 ", "\te4\n"])
    func squareFromValidNameIsAccepted(name: String) throws {
        let square = try #require(Square(name: name))
        #expect(square.file == 4 && square.rank == 3)
    }

    // @spec BOARD-SQ-004
    @Test(arguments: ["i1", "e9", "e0", "e44", "e", "4", "", "ee4", "e 4", "4e"])
    func squareFromInvalidNameIsRejected(name: String) {
        #expect(Square(name: name) == nil)
    }

    // @spec BOARD-SQ-005
    @Test func squareNameIsLowercaseLetterThenDigit() {
        for square in allSquares {
            #expect(square.name == "\(files[square.file])\(square.rank + 1)")
        }
    }

    // MARK: Colour

    // @spec BOARD-COL-001
    @Test func squareColourFollowsFileAndRankParity() throws {
        #expect(try sq("a1").colour == .dark)
        #expect(try sq("h1").colour == .light)
        #expect(try sq("a8").colour == .light)
        #expect(try sq("d4").colour == .dark)
        #expect(try sq("e5").colour == .dark)
        #expect(try sq("e4").colour == .light)
        for square in allSquares {
            #expect(square.colour == ((square.file + square.rank) % 2 == 0 ? .dark : .light))
        }
    }

    // MARK: Directions

    // @spec BOARD-DIR-001
    @Test func eightDirectionsWithStepsFromWhitesSide() {
        let expected: [Direction: (Int, Int)] = [
            .up: (0, 1), .down: (0, -1), .right: (1, 0), .left: (-1, 0),
            .upRight: (1, 1), .upLeft: (-1, 1), .downRight: (1, -1), .downLeft: (-1, -1),
        ]
        #expect(Direction.allCases.count == 8)
        for (direction, step) in expected {
            #expect(direction.fileStep == step.0 && direction.rankStep == step.1, "\(direction)")
        }
    }

    // @spec BOARD-DIR-002
    @Test func movingStepsGivesSquareOrNothingOffBoard() throws {
        #expect(try sq("e4").moved(.right, steps: 2) == (try sq("g4")))
        #expect(try sq("e4").moved(.up, steps: 4) == (try sq("e8")))
        #expect(try sq("e4").moved(.downLeft, steps: 3) == (try sq("b1")))
        #expect(try sq("e4").moved(.up, steps: 5) == nil)
        #expect(try sq("a1").moved(.left, steps: 1) == nil)
        #expect(try sq("h8").moved(.upRight, steps: 1) == nil)
    }

    // @spec BOARD-DIR-003
    @Test func offsetGivesSquareOrNothingOffBoard() throws {
        #expect(try sq("e4").offset(file: 2, rank: 1) == (try sq("g5")))
        #expect(try sq("b1").offset(file: -1, rank: 2) == (try sq("a3")))
        #expect(try sq("b1").offset(file: -2, rank: 1) == nil)
        #expect(try sq("h8").offset(file: 0, rank: 1) == nil)
    }

    // @spec BOARD-DIR-004
    @Test(arguments: [0, -1, -3])
    func zeroOrNegativeStepsGiveNothing(steps: Int) throws {
        #expect(try sq("e4").moved(.up, steps: steps) == nil)
    }

    // MARK: Lines and diagonals

    // @spec BOARD-LINE-001
    @Test func diagonalIsNamedByEndsLowerRankFirst() throws {
        let (upRight, upLeft) = Board.diagonals(through: try sq("e3"))
        let (c1, h6, g1, a7) = (try sq("c1"), try sq("h6"), try sq("g1"), try sq("a7"))
        #expect(upRight.start == c1 && upRight.end == h6)
        #expect(upLeft.start == g1 && upLeft.end == a7)
    }

    // @spec BOARD-LINE-002
    @Test func diagonalsThroughSquareAreWholeLines() throws {
        let (upRight, upLeft) = Board.diagonals(through: try sq("d4"))
        #expect(upRight == Diagonal(start: try sq("a1"), end: try sq("h8")))
        #expect(upLeft == Diagonal(start: try sq("g1"), end: try sq("a7")))
        #expect(upRight.squares.count == 8)
        #expect(upLeft.squares.map(\.name) == ["g1", "f2", "e3", "d4", "c5", "b6", "a7"])
    }

    // @spec BOARD-LINE-003
    @Test func shareDiagonal() throws {
        #expect(Board.shareDiagonal(try sq("c1"), try sq("h6")))
        #expect(Board.shareDiagonal(try sq("h6"), try sq("c1")))
        #expect(Board.shareDiagonal(try sq("g1"), try sq("a7")))
        #expect(!Board.shareDiagonal(try sq("c1"), try sq("h5")))
        #expect(!Board.shareDiagonal(try sq("c1"), try sq("c3")))
        #expect(Board.shareDiagonal(try sq("e4"), try sq("e4")))
    }

    // @spec BOARD-LINE-004
    @Test func diagonalEndIsEdgeSquareInDirection() throws {
        #expect(Board.diagonalEnd(from: try sq("c1"), direction: .upRight) == (try sq("h6")))
        #expect(Board.diagonalEnd(from: try sq("c1"), direction: .upLeft) == (try sq("a3")))
        #expect(Board.diagonalEnd(from: try sq("d4"), direction: .downLeft) == (try sq("a1")))
        #expect(Board.diagonalEnd(from: try sq("d4"), direction: .downRight) == (try sq("g1")))
        #expect(Board.diagonalEnd(from: try sq("g7"), direction: .upRight) == (try sq("h8")))
    }

    // @spec BOARD-LINE-005
    @Test func diagonalEndFromEdgeInThatDirectionIsNothing() throws {
        #expect(Board.diagonalEnd(from: try sq("a1"), direction: .downLeft) == nil)
        #expect(Board.diagonalEnd(from: try sq("c1"), direction: .downRight) == nil)
        #expect(Board.diagonalEnd(from: try sq("a4"), direction: .upLeft) == nil)
        #expect(Board.diagonalEnd(from: try sq("h8"), direction: .upRight) == nil)
        #expect(Board.diagonalEnd(from: try sq("e4"), direction: .up) == nil, "non-diagonal direction")
    }

    // @spec BOARD-LINE-006
    @Test func diagonalLengthCountsSquares() throws {
        #expect(Diagonal(start: try sq("a1"), end: try sq("h8")).length == 8)
        #expect(Diagonal(start: try sq("c1"), end: try sq("h6")).length == 6)
        #expect(Diagonal(start: try sq("g1"), end: try sq("h2")).length == 2)
        #expect(Diagonal(start: try sq("a1"), end: try sq("a1")).length == 1)
        for square in allSquares {
            let (a, b) = Board.diagonals(through: square)
            #expect((1...8).contains(a.length) && (1...8).contains(b.length))
        }
    }

    // @spec BOARD-LINE-007
    @Test func cornerLiesOnLengthOneDiagonal() throws {
        let a1 = try sq("a1")
        let (upRight, upLeft) = Board.diagonals(through: a1)
        #expect(upRight == Diagonal(start: a1, end: try sq("h8")))
        #expect(upLeft == Diagonal(start: a1, end: a1))
        #expect(upLeft.length == 1)
        let h1 = try sq("h1")
        #expect(Board.diagonals(through: h1).upRight == Diagonal(start: h1, end: h1))
        #expect(Board.diagonals(through: h1).upLeft == Diagonal(start: h1, end: try sq("a8")))
    }

    // @spec BOARD-LINE-008
    @Test func shareFileOrRank() throws {
        #expect(Board.shareFile(try sq("e2"), try sq("e7")))
        #expect(!Board.shareFile(try sq("e2"), try sq("d7")))
        #expect(Board.shareRank(try sq("a3"), try sq("h3")))
        #expect(!Board.shareRank(try sq("a3"), try sq("a4")))
        let e4 = try sq("e4")
        #expect(Board.shareFile(e4, e4) && Board.shareRank(e4, e4))
    }

    @Test func longDiagonalsAreSingleColoured() throws {
        let longs = Board.longDiagonals
        #expect(longs.count == 2)
        #expect(longs.contains(Diagonal(start: try sq("a1"), end: try sq("h8"))))
        #expect(longs.contains(Diagonal(start: try sq("h1"), end: try sq("a8"))))
        for d in longs { #expect(Set(d.squares.map(\.colour)).count == 1) }
    }
}
