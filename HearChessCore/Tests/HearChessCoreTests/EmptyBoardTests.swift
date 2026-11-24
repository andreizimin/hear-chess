import Testing
@testable import HearChessCore

/// Generates `count` exercises for a drill and level, each from its own seed, with no previous question.
func sample(_ drill: Drill, level: Int, count: Int = 400) -> [Exercise] {
    (0..<count).map { seed in
        var rng = SeededRandom(seed: UInt64(seed))
        return EmptyBoard.generate(drill: drill, level: level, previous: nil, using: &rng)
    }
}

let corners: Set<String> = ["a1", "h1", "a8", "h8"]
let centre: Set<String> = ["d4", "e4", "d5", "e5"]

func isEdge(_ s: Square) -> Bool { s.file == 0 || s.file == 7 || s.rank == 0 || s.rank == 7 }

@Suite("Empty-board drills")
struct EmptyBoardTests {
    // MARK: All drills

    // @spec EX-EMPTY-001
    @Test func emptyBoardHasThreeDrillsWithLevels() {
        #expect(EmptyBoard.drills == [.squareColour, .directions, .diagonals])
        #expect(Drill.squareColour.maxLevel == 3)
        #expect(Drill.directions.maxLevel == 4)
        #expect(Drill.diagonals.maxLevel == 3)
    }

    // @spec EX-EMPTY-002
    @Test func sameInputsGiveSameExercise() {
        for drill in EmptyBoard.drills {
            for level in 1...drill.maxLevel {
                for seed in UInt64(0)..<50 {
                    var a = SeededRandom(seed: seed), b = SeededRandom(seed: seed)
                    let first = EmptyBoard.generate(drill: drill, level: level, previous: nil, using: &a)
                    let second = EmptyBoard.generate(drill: drill, level: level, previous: nil, using: &b)
                    #expect(first == second)
                    var c = SeededRandom(seed: seed), d = SeededRandom(seed: seed)
                    let third = EmptyBoard.generate(drill: drill, level: level, previous: first, using: &c)
                    let fourth = EmptyBoard.generate(drill: drill, level: level, previous: first, using: &d)
                    #expect(third == fourth)
                }
            }
        }
        // Different seeds should not all give the same question.
        #expect(Set(sample(.squareColour, level: 3, count: 50).map(\.contentKey)).count > 5)
    }

    // @spec EX-EMPTY-003
    @Test func neverRepeatsThePreviousQuestionsContent() {
        for drill in EmptyBoard.drills {
            for level in 1...drill.maxLevel {
                for seed in UInt64(0)..<200 {
                    var rng = SeededRandom(seed: seed)
                    let previous = EmptyBoard.generate(drill: drill, level: level, previous: nil, using: &rng)
                    var again = SeededRandom(seed: seed)
                    let next = EmptyBoard.generate(drill: drill, level: level, previous: previous, using: &again)
                    #expect(next.contentKey != previous.contentKey, "\(drill) L\(level) seed \(seed)")
                }
            }
        }
        // Square order does not change content.
        let c1 = Square(unchecked: 2, 0), h6 = Square(unchecked: 7, 5)
        let ab = Exercise(drill: .diagonals, level: 2, prompt: .sameDiagonal(c1, h6), answerKind: .yesOrNo, correctAnswers: [.yes])
        let ba = Exercise(drill: .diagonals, level: 2, prompt: .sameDiagonal(h6, c1), answerKind: .yesOrNo, correctAnswers: [.yes])
        #expect(!ab.contentKey.isEmpty)
        #expect(ab.contentKey == ba.contentKey)
    }

    // @spec EX-EMPTY-004
    @Test func directionsQuestionsUseWhitesSideNames() {
        // Every directions answer equals the board's own move from White's side.
        for level in 1...4 {
            for ex in sample(.directions, level: level, count: 100) {
                guard case let .direction(from, steps) = ex.prompt else { Issue.record("not a direction prompt"); continue }
                var target: Square? = from
                for step in steps { target = target?.offset(file: step.direction.fileStep * step.count, rank: step.direction.rankStep * step.count) }
                #expect(ex.correctAnswers == [.square(target!)])
            }
        }
    }

    // @spec EX-EMPTY-005
    @Test func checkingAcceptsOnlyCorrectAnswers() {
        let f6 = Square(unchecked: 5, 5)
        let ex = Exercise(drill: .squareColour, level: 3, prompt: .squareColour(f6), answerKind: .lightOrDark, correctAnswers: [.colour(.dark)])
        #expect(ex.check(.colour(.dark)))
        #expect(!ex.check(.colour(.light)))
        #expect(!ex.check(nil))
        #expect(!ex.check(.yes))
    }

    // @spec EX-EMPTY-006
    @Test func randomChoicesCoverAllowedSquaresUniformly() {
        let squares = sample(.squareColour, level: 3, count: 6400).compactMap { ex -> String? in
            if case let .squareColour(s) = ex.prompt { return s.name } else { return nil }
        }
        let counts = Dictionary(grouping: squares, by: { $0 }).mapValues(\.count)
        #expect(counts.count == 64)
        #expect(counts.values.allSatisfy { (50...150).contains($0) }, "roughly 100 each")
    }

    // MARK: Square colour

    // @spec EX-EMPTY-COL-001
    @Test func colourDrillAsksForSquareColour() {
        for ex in sample(.squareColour, level: 3, count: 100) {
            guard case let .squareColour(s) = ex.prompt else { Issue.record("wrong prompt"); continue }
            #expect(ex.answerKind == .lightOrDark)
            #expect(ex.correctAnswers == [.colour(s.colour)])
        }
    }

    // @spec EX-EMPTY-COL-002
    @Test func colourLevel1AsksCornersAndCentreOnly() {
        let asked = Set(sample(.squareColour, level: 1).compactMap { ex -> String? in
            if case let .squareColour(s) = ex.prompt { s.name } else { nil }
        })
        #expect(asked == corners.union(centre))
    }

    // @spec EX-EMPTY-COL-003
    @Test func colourLevel2AsksEdgeAndCentreOnly() {
        let asked = sample(.squareColour, level: 2, count: 1000).compactMap { ex -> Square? in
            if case let .squareColour(s) = ex.prompt { s } else { nil }
        }
        #expect(!asked.isEmpty)
        #expect(asked.allSatisfy { isEdge($0) || centre.contains($0.name) })
        #expect(Set(asked.map(\.name)).count == 28 + 4)
    }

    // @spec EX-EMPTY-COL-004
    @Test func colourLevel3AsksAnySquare() {
        let asked = Set(sample(.squareColour, level: 3, count: 2000).compactMap { ex -> String? in
            if case let .squareColour(s) = ex.prompt { s.name } else { nil }
        })
        #expect(asked.count == 64)
    }

    // MARK: Directions

    func steps(_ level: Int, count: Int = 400) -> [(Square, [Step], Exercise)] {
        sample(.directions, level: level, count: count).compactMap { ex in
            if case let .direction(from, steps) = ex.prompt { (from, steps, ex) } else { nil }
        }
    }

    // @spec EX-EMPTY-DIR-001
    @Test func directionsDrillAsksForSquareReached() {
        for (_, _, ex) in steps(1) {
            #expect(ex.answerKind == .square)
            #expect(ex.correctAnswers.count == 1)
        }
        #expect(!steps(1).isEmpty)
    }

    // @spec EX-EMPTY-DIR-002
    @Test func directionsAnswerIsAlwaysOnTheBoard() {
        for level in 1...4 {
            let all = steps(level)
            #expect(all.count == 400, "every directions exercise has a direction prompt")
            for (from, steps, ex) in all {
                let dx = steps.reduce(0) { $0 + $1.direction.fileStep * $1.count }
                let dy = steps.reduce(0) { $0 + $1.direction.rankStep * $1.count }
                #expect((0..<8).contains(from.file + dx) && (0..<8).contains(from.rank + dy))
                #expect(ex.correctAnswers == [.square(Square(unchecked: from.file + dx, from.rank + dy))])
            }
        }
    }

    // @spec EX-EMPTY-DIR-003
    @Test func directionsLevel1IsOneOrthogonalStep() {
        let orthogonal: Set<Direction> = [.up, .down, .left, .right]
        for (_, steps, _) in steps(1) {
            #expect(steps.count == 1 && steps[0].count == 1 && orthogonal.contains(steps[0].direction))
        }
        #expect(!steps(1).isEmpty)
    }

    // @spec EX-EMPTY-DIR-004
    @Test func directionsLevel2IsTwoOrThreeOrthogonalSteps() {
        let orthogonal: Set<Direction> = [.up, .down, .left, .right]
        let all = steps(2)
        for (_, steps, _) in all {
            #expect(steps.count == 1 && [2, 3].contains(steps[0].count) && orthogonal.contains(steps[0].direction))
        }
        #expect(Set(all.map { $0.1[0].count }) == [2, 3])
    }

    // @spec EX-EMPTY-DIR-005
    @Test func directionsLevel3IsOneToThreeDiagonalSteps() {
        let all = steps(3)
        for (_, steps, _) in all {
            #expect(steps.count == 1 && (1...3).contains(steps[0].count) && steps[0].direction.isDiagonal)
        }
        #expect(Set(all.map { $0.1[0].direction }).count == 4)
    }

    // @spec EX-EMPTY-DIR-006
    @Test func directionsLevel4IsAKnightsJump() {
        let all = steps(4)
        #expect(!all.isEmpty)
        for (_, steps, _) in all {
            #expect(steps.count == 2)
            guard steps.count == 2 else { continue }
            let counts = steps.map(\.count)
            #expect(counts == [1, 2] || counts == [2, 1])
            #expect([Direction.up, .down].contains(steps[0].direction))
            #expect([Direction.left, .right].contains(steps[1].direction))
        }
    }

    // @spec EX-EMPTY-DIR-007
    @Test func knightJumpSpeaksUpOrDownFirst() throws {
        let jumps = steps(4, count: 50).filter { $0.1.count == 2 }
        #expect(jumps.count == 50)
        for (_, steps, ex) in jumps {
            #expect(steps[0].direction == .up || steps[0].direction == .down)
            let text = SpokenChess.text(for: ex.prompt)
            let vertical = text.range(of: steps[0].direction == .up ? "up" : "down")
            let sideways = text.range(of: steps[1].direction == .left ? "left" : "right")
            #expect(vertical != nil && sideways != nil && vertical!.lowerBound < sideways!.lowerBound)
        }
    }

    // MARK: Diagonals

    func diagonalPrompts(_ level: Int, count: Int = 600) -> [Exercise] { sample(.diagonals, level: level, count: count) }

    // @spec EX-EMPTY-DIAG-001
    @Test func diagonalsDrillHasThreeQuestionTypes() {
        var types = Set<String>()
        for level in 1...3 {
            for ex in diagonalPrompts(level, count: 200) {
                switch ex.prompt {
                case .sameDiagonal: types.insert("same")
                case .diagonalEnd: types.insert("end")
                case .longDiagonal: types.insert("long")
                default: Issue.record("unexpected prompt \(ex.prompt)")
                }
            }
        }
        #expect(types == ["same", "end", "long"])
    }

    // @spec EX-EMPTY-DIAG-002
    @Test func sameDiagonalGivesTwoDifferentSquares() {
        var seen = 0
        defer { #expect(seen > 0) }
        for ex in diagonalPrompts(3) {
            guard case let .sameDiagonal(a, b) = ex.prompt else { continue }
            seen += 1
            #expect(a != b)
            #expect(ex.answerKind == .yesOrNo)
            #expect(ex.correctAnswers == [Board.shareDiagonal(a, b) ? .yes : .no])
        }
    }

    // @spec EX-EMPTY-DIAG-003
    @Test func sameDiagonalIsYesAboutHalfTheTime() {
        let answers = diagonalPrompts(3, count: 2000).compactMap { ex -> Bool? in
            if case .sameDiagonal = ex.prompt { ex.correctAnswers == [.yes] } else { nil }
        }
        let yes = answers.filter { $0 }.count
        #expect(answers.count > 500)
        #expect(Double(yes) / Double(max(answers.count, 1)) > 0.4 && Double(yes) / Double(max(answers.count, 1)) < 0.6)
    }

    // @spec EX-EMPTY-DIAG-004
    @Test func sameDiagonalNoCasesUseSameColour() {
        var noCases = 0
        for ex in diagonalPrompts(3, count: 1000) {
            guard case let .sameDiagonal(a, b) = ex.prompt, ex.correctAnswers == [.no] else { continue }
            noCases += 1
            #expect(a.colour == b.colour)
        }
        #expect(noCases > 0)
    }

    // @spec EX-EMPTY-DIAG-005
    @Test func diagonalEndAsksForEdgeSquare() {
        var seen = 0
        for ex in diagonalPrompts(3) {
            guard case let .diagonalEnd(from, direction) = ex.prompt else { continue }
            seen += 1
            #expect(direction.isDiagonal)
            #expect(ex.answerKind == .square)
            #expect(ex.correctAnswers == [.square(Board.diagonalEnd(from: from, direction: direction)!)])
        }
        #expect(seen > 0)
    }

    // @spec EX-EMPTY-DIAG-006
    @Test func diagonalEndAlwaysHasSomewhereToGo() {
        var seen = 0
        defer { #expect(seen > 0) }
        for level in 2...3 {
            for ex in diagonalPrompts(level) {
                guard case let .diagonalEnd(from, direction) = ex.prompt else { continue }
                seen += 1
                #expect(from.moved(direction, steps: 1) != nil)
            }
        }
    }

    // @spec EX-EMPTY-DIAG-007
    @Test func longDiagonalAsksIfSquareIsOnIt() {
        for ex in diagonalPrompts(1, count: 200) {
            guard case let .longDiagonal(diagonal, square) = ex.prompt else { Issue.record("level 1 must be long diagonals"); continue }
            #expect(Board.longDiagonals.contains(diagonal))
            #expect(ex.answerKind == .yesOrNo)
            #expect(ex.correctAnswers == [diagonal.contains(square) ? .yes : .no])
        }
    }

    // @spec EX-EMPTY-DIAG-008
    @Test func longDiagonalIsYesAboutHalfAndNeverAsksEnds() {
        var yes = 0, total = 0
        for ex in diagonalPrompts(1, count: 2000) {
            guard case let .longDiagonal(diagonal, square) = ex.prompt else { continue }
            total += 1
            if ex.correctAnswers == [.yes] { yes += 1 }
            #expect(square != diagonal.start && square != diagonal.end)
        }
        #expect(total == 2000)
        #expect(Double(yes) / Double(max(total, 1)) > 0.4 && Double(yes) / Double(max(total, 1)) < 0.6)
    }

    // @spec EX-EMPTY-DIAG-009
    @Test func longDiagonalNoCasesUseTheDiagonalsColour() {
        var noCases = 0
        for ex in diagonalPrompts(1, count: 1000) {
            guard case let .longDiagonal(diagonal, square) = ex.prompt, ex.correctAnswers == [.no] else { continue }
            noCases += 1
            #expect(square.colour == diagonal.colour)
        }
        #expect(noCases > 0)
    }

    // @spec EX-EMPTY-DIAG-010
    @Test func diagonalsLevel1IsLongDiagonalsOnly() {
        for ex in diagonalPrompts(1, count: 200) {
            if case .longDiagonal = ex.prompt {} else { Issue.record("unexpected \(ex.prompt)") }
        }
    }

    // @spec EX-EMPTY-DIAG-011
    @Test func diagonalsLevel2MixesSameAndEndFromEdge() {
        var same = 0, end = 0
        for ex in diagonalPrompts(2, count: 2000) {
            switch ex.prompt {
            case let .sameDiagonal(a, _): same += 1; #expect(isEdge(a))
            case let .diagonalEnd(from, _): end += 1; #expect(isEdge(from))
            default: Issue.record("unexpected \(ex.prompt)")
            }
        }
        #expect(same > 800 && end > 800)
    }

    // @spec EX-EMPTY-DIAG-012
    @Test func diagonalsLevel3MixesSameAndEndFromAnySquare() {
        var same = 0, end = 0, inner = 0
        for ex in diagonalPrompts(3, count: 2000) {
            switch ex.prompt {
            case let .sameDiagonal(a, _): same += 1; if !isEdge(a) { inner += 1 }
            case let .diagonalEnd(from, _): end += 1; if !isEdge(from) { inner += 1 }
            default: Issue.record("unexpected \(ex.prompt)")
            }
        }
        #expect(same > 800 && end > 800)
        #expect(inner > 0, "level 3 includes non-edge starting squares")
    }
}
