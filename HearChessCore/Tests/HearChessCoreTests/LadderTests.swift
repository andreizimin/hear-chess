import Foundation
import Testing
@testable import HearChessCore

extension Ladder {
    /// Records the same outcome `count` times at the drill's current level.
    mutating func feed(_ outcome: Outcome, _ drill: Drill, times count: Int) -> [LevelChange] {
        (0..<count).compactMap { _ in record(outcome, drill: drill, askedAtLevel: estimate(drill).level) }
    }
}

@Suite("Ladder")
struct LadderTests {
    let fastVoice = Outcome.right(.voice, seconds: 1.0)
    let slowVoice = Outcome.right(.voice, seconds: 20.0)
    let touchRight = Outcome.right(.touch, seconds: 9.0)
    let wrongVoice = Outcome.wrong(.voice)

    // MARK: Skill estimate

    // @spec LADDER-001
    @Test func estimateStartsAtLevel1AndKeepsAtMost20Results() throws {
        var ladder = Ladder()
        #expect(ladder.estimate(.diagonals) == SkillEstimate(level: 1, results: []))
        // Alternate right and wrong so the drill never moves level.
        for i in 0..<30 { ladder.record(i % 2 == 0 ? fastVoice : wrongVoice, drill: .diagonals, askedAtLevel: 1) }
        #expect(ladder.estimate(.diagonals).level == 1)
        #expect(ladder.estimate(.diagonals).results.count == 20)
        // Kept across launches: the ladder round-trips through encoding.
        let data = try JSONEncoder().encode(ladder)
        #expect(try JSONDecoder().decode(Ladder.self, from: data) == ladder)
    }

    // @spec LADDER-002
    @Test func resultStoresRightnessMethodAndVoiceTime() {
        var ladder = Ladder()
        ladder.record(.right(.voice, seconds: 2.5), drill: .squareColour, askedAtLevel: 1)
        ladder.record(.right(.touch, seconds: 7.0), drill: .squareColour, askedAtLevel: 1)
        ladder.record(.wrong(.voice), drill: .squareColour, askedAtLevel: 1)
        #expect(ladder.estimate(.squareColour).results == [
            ExerciseResult(right: true, method: .voice, seconds: 2.5),
            ExerciseResult(right: true, method: .touch, seconds: nil),
            ExerciseResult(right: false, method: .voice, seconds: nil),
        ])
    }

    // @spec LADDER-003
    @Test func resultForAnotherLevelIsDiscarded() {
        var ladder = Ladder()
        ladder.record(fastVoice, drill: .directions, askedAtLevel: 2)
        #expect(ladder.estimate(.directions).results.isEmpty)
        ladder.record(fastVoice, drill: .directions, askedAtLevel: 1)
        #expect(ladder.estimate(.directions).results.count == 1)
    }

    // @spec LADDER-004
    @Test func dontKnowIsRecordedAsWrong() {
        var ladder = Ladder()
        ladder.record(.dontKnow(.touch), drill: .squareColour, askedAtLevel: 1)
        #expect(ladder.estimate(.squareColour).results == [ExerciseResult(right: false, method: .touch, seconds: nil)])
    }

    // @spec LADDER-005
    @Test func targetTimes() {
        #expect(Ladder.targetTime(.squareColour) == 3)
        #expect(Ladder.targetTime(.directions) == 5)
        #expect(Ladder.targetTime(.diagonals) == 6)
    }

    // MARK: Moving levels

    // @spec LADDER-LVL-001
    @Test func movesUpWhenAccurateAndFastByVoice() {
        var ladder = Ladder()
        let changes = ladder.feed(fastVoice, .squareColour, times: 10)
        #expect(changes == [LevelChange(drill: .squareColour, from: 1, to: 2)])
        #expect(ladder.estimate(.squareColour).level == 2)

        var slow = Ladder()
        #expect(slow.feed(slowVoice, .squareColour, times: 10).isEmpty, "too slow by voice")

        var nine = Ladder()
        _ = nine.feed(fastVoice, .squareColour, times: 9)
        #expect(nine.estimate(.squareColour).level == 1, "needs at least 10 results")

        // 9 of 10 right is enough; the median is over right voice answers only.
        var mixed = Ladder()
        _ = mixed.feed(wrongVoice, .squareColour, times: 1)
        _ = mixed.feed(.right(.voice, seconds: 3.0), .squareColour, times: 9)
        #expect(mixed.estimate(.squareColour).level == 2, "median at the target counts")
    }

    // @spec LADDER-LVL-002
    @Test func movesUpOnAccuracyAloneWhenFewerThan5VoiceAnswers() {
        var touch = Ladder()
        _ = touch.feed(touchRight, .directions, times: 10)
        #expect(touch.estimate(.directions).level == 2)

        var mostlyTouch = Ladder()
        _ = mostlyTouch.feed(slowVoice, .directions, times: 4)
        _ = mostlyTouch.feed(touchRight, .directions, times: 6)
        #expect(mostlyTouch.estimate(.directions).level == 2, "4 slow voice answers are too few to judge speed")

        var enoughVoice = Ladder()
        _ = enoughVoice.feed(slowVoice, .directions, times: 5)
        _ = enoughVoice.feed(touchRight, .directions, times: 5)
        #expect(enoughVoice.estimate(.directions).level == 1, "5 slow voice answers hold it back")
    }

    // @spec LADDER-LVL-003
    @Test func movesDownWhenStrugglingAboveLevel1() {
        var ladder = Ladder()
        _ = ladder.feed(fastVoice, .diagonals, times: 10)
        #expect(ladder.estimate(.diagonals).level == 2)
        _ = ladder.feed(wrongVoice, .diagonals, times: 4)
        #expect(ladder.estimate(.diagonals).level == 2, "needs at least 5 results")
        let changes = ladder.feed(wrongVoice, .diagonals, times: 1)
        #expect(changes == [LevelChange(drill: .diagonals, from: 2, to: 1)])

        var mixed = Ladder()
        _ = mixed.feed(fastVoice, .diagonals, times: 10)
        _ = mixed.feed(fastVoice, .diagonals, times: 2)
        _ = mixed.feed(wrongVoice, .diagonals, times: 3)
        #expect(mixed.estimate(.diagonals).level == 1, "2 of the last 5 right moves down")
    }

    // @spec LADDER-LVL-004
    @Test func movingClearsResults() {
        var ladder = Ladder()
        _ = ladder.feed(fastVoice, .squareColour, times: 10)
        #expect(ladder.estimate(.squareColour).level == 2)
        #expect(ladder.estimate(.squareColour).results.isEmpty)
        _ = ladder.feed(wrongVoice, .squareColour, times: 5)
        #expect(ladder.estimate(.squareColour).level == 1)
        #expect(ladder.estimate(.squareColour).results.isEmpty)
    }

    // @spec LADDER-LVL-005
    @Test func noMoveAboveTopOrBelowLevel1() {
        var ladder = Ladder(estimates: [.squareColour: SkillEstimate(level: 3)])
        _ = ladder.feed(fastVoice, .squareColour, times: 15)
        #expect(ladder.estimate(.squareColour).level == 3)

        var bottom = Ladder()
        _ = bottom.feed(wrongVoice, .squareColour, times: 7)
        #expect(bottom.estimate(.squareColour).level == 1)
        #expect(bottom.estimate(.squareColour).results.count == 7, "level 1 keeps its results")
    }

    // @spec LADDER-LVL-006
    @Test func rulesAreCheckedAfterEveryResult() {
        var ladder = Ladder()
        var changes: [LevelChange?] = []
        for _ in 0..<10 { changes.append(ladder.record(fastVoice, drill: .squareColour, askedAtLevel: ladder.estimate(.squareColour).level)) }
        #expect(changes.dropLast().allSatisfy { $0 == nil })
        #expect(changes.last! == LevelChange(drill: .squareColour, from: 1, to: 2))
    }

    // @spec LADDER-LVL-007
    @Test func evenMedianIsMeanOfMiddleTwo() {
        // 10 right voice answers: five at 2 s and five at 4 s -> median 3 s, at the 3 s target.
        var ladder = Ladder()
        _ = ladder.feed(.right(.voice, seconds: 2), .squareColour, times: 5)
        _ = ladder.feed(.right(.voice, seconds: 4), .squareColour, times: 5)
        #expect(ladder.estimate(.squareColour).level == 2)

        // Five at 2 s and five at 4.2 s -> median 3.1 s, over the target.
        var over = Ladder()
        _ = over.feed(.right(.voice, seconds: 2), .squareColour, times: 5)
        _ = over.feed(.right(.voice, seconds: 4.2), .squareColour, times: 5)
        #expect(over.estimate(.squareColour).level == 1)
    }

    // MARK: Choosing

    // @spec LADDER-PICK-001
    @Test func drillsAreChosenInProportionToWeight() {
        var ladder = Ladder()
        // squareColour: 5 results, all wrong at level 1 -> weight 3. directions: none -> weight 2. diagonals: 5 right -> weight 1.
        _ = ladder.feed(wrongVoice, .squareColour, times: 5)
        _ = ladder.feed(touchRight, .diagonals, times: 5)
        var rng = SeededRandom(seed: 7)
        var counts: [Drill: Int] = [:]
        for _ in 0..<6000 { counts[ladder.chooseDrill(from: EmptyBoard.drillsForTests, recent: [], using: &rng), default: 0] += 1 }
        #expect((2700...3300).contains(counts[.squareColour, default: 0]))
        #expect((1700...2300).contains(counts[.directions, default: 0]))
        #expect((700...1300).contains(counts[.diagonals, default: 0]))
    }

    // @spec LADDER-PICK-002
    @Test func fewerThan5ResultsGivesWeight2() {
        var ladder = Ladder()
        #expect(ladder.weight(.directions) == 2)
        _ = ladder.feed(wrongVoice, .directions, times: 4)
        #expect(ladder.weight(.directions) == 2)
    }

    // @spec LADDER-PICK-003
    @Test func weightFromShareOfWrongAnswers() {
        var ladder = Ladder()
        _ = ladder.feed(wrongVoice, .directions, times: 2)
        _ = ladder.feed(touchRight, .directions, times: 3)
        #expect(abs(ladder.weight(.directions) - (1 + 2 * 2.0 / 5.0)) < 1e-9, "2 wrong of 5")
        _ = ladder.feed(wrongVoice, .directions, times: 1)
        _ = ladder.feed(touchRight, .directions, times: 2)
        // 8 results at level 1: wrong, wrong, R, R, R, wrong, R, R -> 3 of 8 wrong
        #expect(abs(ladder.weight(.directions) - (1 + 2 * 3.0 / 8.0)) < 1e-9)
    }

    // @spec LADDER-PICK-004
    @Test func neverMoreThanThreeOfOneDrillInARow() {
        var ladder = Ladder()
        _ = ladder.feed(wrongVoice, .squareColour, times: 5)
        _ = ladder.feed(touchRight, .directions, times: 9)
        _ = ladder.feed(touchRight, .diagonals, times: 9)
        var rng = SeededRandom(seed: 1)
        var recent: [Drill] = []
        for _ in 0..<2000 {
            let next = ladder.chooseDrill(from: EmptyBoard.drillsForTests, recent: recent, using: &rng)
            recent.append(next)
        }
        var run = 1
        for i in 1..<recent.count {
            run = recent[i] == recent[i - 1] ? run + 1 : 1
            #expect(run <= 3)
        }
    }
}

extension EmptyBoard {
    /// The drill list used by ladder tests, independent of EmptyBoard.drills.
    static let drillsForTests: [Drill] = [.squareColour, .directions, .diagonals]
}
