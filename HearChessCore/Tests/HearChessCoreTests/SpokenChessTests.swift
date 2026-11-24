import Testing
@testable import HearChessCore

@Suite("Spoken chess")
struct SpokenChessTests {
    let colour = Allowed.exercise(.lightOrDark)
    let yesNo = Allowed.exercise(.yesOrNo)
    let square = Allowed.exercise(.square)

    // MARK: Output

    // @spec SPOKEN-OUT-001
    @Test func squareIsSpokenAsLetterSpellingAndNumberWord() throws {
        #expect(SpokenChess.speak(try sq("a4")) == "ay four")
        #expect(SpokenChess.speak(try sq("e4")) == "ee four")
        #expect(SpokenChess.speak(try sq("h8")) == "aitch eight")
        #expect(SpokenChess.speak(try sq("c1")) == "see one")
    }

    // @spec SPOKEN-OUT-002
    @Test func everyFileLetterHasAPronunciationThatIsNotAWord() {
        let table = SpokenChess.letterPronunciation
        #expect(Set(table.keys) == Set(files))
        #expect(table["a"] == "ay")
        for (_, spelling) in table {
            #expect(!["a", "an", "the", "be", "see", "sea"].contains(spelling.lowercased()))
        }
    }

    // @spec SPOKEN-OUT-003
    @Test func promptsAreBuiltFromTemplates() throws {
        #expect(SpokenChess.text(for: .squareColour(try sq("f6"))) == "Ef six. Light or dark?")
        #expect(SpokenChess.text(for: .direction(from: try sq("e4"), steps: [Step(2, .right)])) == "Two right from ee four?")
        #expect(SpokenChess.text(for: .direction(from: try sq("e4"), steps: [Step(1, .up), Step(2, .right)])) == "One up, two right from ee four?")
        #expect(SpokenChess.text(for: .direction(from: try sq("b2"), steps: [Step(3, .upRight)])) == "Three up-right from bee two?")
        #expect(SpokenChess.text(for: .sameDiagonal(try sq("c1"), try sq("h6"))) == "See one and aitch six. Same diagonal?")
        #expect(SpokenChess.text(for: .diagonalEnd(from: try sq("c1"), direction: .upRight)) == "From see one, up-right to the edge?")
        let a1h8 = Diagonal(start: try sq("a1"), end: try sq("h8"))
        #expect(SpokenChess.text(for: .longDiagonal(a1h8, try sq("d4"))) == "Ay one to aitch eight. Is dee four on it?")
    }

    // @spec SPOKEN-OUT-004
    @Test func correctionSaysRightAnswerInAFewWords() throws {
        let colourEx = Exercise(drill: .squareColour, level: 1, prompt: .squareColour(try sq("f6")),
                                answerKind: .lightOrDark, correctAnswers: [.colour(.dark)])
        #expect(SpokenChess.correction(for: colourEx) == "Ef six is dark.")
        let squareEx = Exercise(drill: .directions, level: 1, prompt: .direction(from: try sq("e4"), steps: [Step(2, .right)]),
                                answerKind: .square, correctAnswers: [.square(try sq("g4"))])
        #expect(SpokenChess.correction(for: squareEx) == "Gee four.")
        let yesEx = Exercise(drill: .diagonals, level: 2, prompt: .sameDiagonal(try sq("c1"), try sq("h6")),
                             answerKind: .yesOrNo, correctAnswers: [.yes])
        #expect(SpokenChess.correction(for: yesEx).hasPrefix("Yes"))
        let noEx = Exercise(drill: .diagonals, level: 2, prompt: .sameDiagonal(try sq("c1"), try sq("h5")),
                            answerKind: .yesOrNo, correctAnswers: [.no])
        #expect(SpokenChess.correction(for: noEx).hasPrefix("No"))
    }

    // MARK: Reading one transcription

    // @spec SPOKEN-IN-001
    @Test func onlyAllowedKindAndCommandsAreConsidered() throws {
        #expect(SpokenChess.read("e four", allowed: colour) == .nothing)
        #expect(SpokenChess.read("dark", allowed: square) == .nothing)
        #expect(SpokenChess.read("dark", allowed: colour) == .answer(.colour(.dark)))
        #expect(SpokenChess.read("resume", allowed: colour) == .nothing)
        #expect(SpokenChess.read("resume", allowed: .paused) == .command(.resume))
        #expect(SpokenChess.read("dark", allowed: .paused) == .nothing)
        #expect(SpokenChess.read("yes", allowed: .yesOrNo) == .answer(.yes))
        #expect(SpokenChess.read("repeat", allowed: .yesOrNo) == .nothing)
    }

    // @spec SPOKEN-IN-002
    @Test(arguments: [("light", SquareColour.light), ("white", .light), ("Light.", .light), ("dark", .dark), ("black", .dark)])
    func lightOrDarkWords(word: String, expected: SquareColour) {
        #expect(SpokenChess.read(word, allowed: colour) == .answer(.colour(expected)))
    }

    // @spec SPOKEN-IN-003
    @Test func yesOrNoWords() {
        for word in ["yes", "yeah", "yep", "correct", "same", "Yes."] {
            #expect(SpokenChess.read(word, allowed: yesNo) == .answer(.yes), "\(word)")
        }
        for word in ["no", "nope", "different", "not the same", "not same", "not correct"] {
            #expect(SpokenChess.read(word, allowed: yesNo) == .answer(.no), "\(word)")
        }
    }

    // @spec SPOKEN-IN-004
    @Test func squareFromFileWordThenRankWordOrSingleToken() throws {
        #expect(SpokenChess.read("e four", allowed: square) == .answer(.square(try sq("e4"))))
        #expect(SpokenChess.read("b4", allowed: square) == .answer(.square(try sq("b4"))))
        #expect(SpokenChess.read("B4", allowed: square) == .answer(.square(try sq("b4"))))
        #expect(SpokenChess.read("e 4", allowed: square) == .answer(.square(try sq("e4"))))
        #expect(SpokenChess.read("four e", allowed: square) == .nothing)
        #expect(SpokenChess.read("e and four", allowed: square) == .nothing, "file and rank must be adjacent")
    }

    // @spec SPOKEN-IN-005
    @Test func fileWordsIncludeHomophonesNatoAndGerman() throws {
        let cases: [(String, String)] = [
            ("ay", "a"), ("hey", "a"), ("alpha", "a"), ("Anton", "a"),
            ("bee", "b"), ("be", "b"), ("bravo", "b"), ("Berta", "b"),
            ("see", "c"), ("sea", "c"), ("charlie", "c"), ("Cäsar", "c"), ("Caesar", "c"),
            ("dee", "d"), ("delta", "d"), ("Dora", "d"),
            ("ee", "e"), ("echo", "e"), ("Emil", "e"),
            ("ef", "f"), ("foxtrot", "f"), ("Friedrich", "f"),
            ("gee", "g"), ("jee", "g"), ("golf", "g"), ("Gustav", "g"),
            ("aitch", "h"), ("age", "h"), ("hotel", "h"), ("Heinrich", "h"),
        ]
        for (word, file) in cases {
            #expect(SpokenChess.read("\(word) five", allowed: square) == .answer(.square(try sq("\(file)5"))), "\(word)")
        }
    }

    // @spec SPOKEN-IN-006
    @Test func rankWordsIncludeDigitsNumberWordsAndHomophones() throws {
        let cases: [(String, Int)] = [
            ("1", 1), ("one", 1), ("won", 1), ("2", 2), ("two", 2), ("to", 2), ("too", 2),
            ("three", 3), ("four", 4), ("for", 4), ("fore", 4), ("five", 5), ("six", 6),
            ("seven", 7), ("eight", 8), ("ate", 8), ("8", 8),
        ]
        for (word, rank) in cases {
            #expect(SpokenChess.read("d \(word)", allowed: square) == .answer(.square(try sq("d\(rank)"))), "\(word)")
        }
    }

    // @spec SPOKEN-IN-007
    @Test func wholeWordSquareHomophones() throws {
        #expect(SpokenChess.read("before", allowed: square) == .answer(.square(try sq("b4"))))
    }

    // @spec SPOKEN-IN-008
    @Test func commandWords() {
        let all = Allowed(answerKind: nil, commands: Set(Command.allCases))
        let cases: [(String, Command)] = [
            ("repeat", .repeat), ("again", .repeat),
            ("skip", .dontKnow), ("I don't know", .dontKnow), ("not sure", .dontKnow), ("pass", .dontKnow),
            ("pause", .pause), ("resume", .resume), ("continue", .resume), ("stop", .stop),
        ]
        for (word, command) in cases {
            #expect(SpokenChess.read(word, allowed: all) == .command(command), "\(word)")
        }
    }

    // @spec SPOKEN-IN-009
    @Test func fillerWordsAreIgnored() throws {
        #expect(SpokenChess.read("um dark", allowed: colour) == .answer(.colour(.dark)))
        #expect(SpokenChess.read("I think it's light", allowed: colour) == .answer(.colour(.light)))
        #expect(SpokenChess.read("uh e four", allowed: square) == .answer(.square(try sq("e4"))))
        #expect(SpokenChess.read("um", allowed: colour) == .nothing)
        #expect(SpokenChess.read("dark please", allowed: colour) == .answer(.colour(.dark)))
    }

    // @spec SPOKEN-IN-010
    @Test func disagreeingOrMixedTranscriptionReadsAsNothing() {
        #expect(SpokenChess.read("light no dark", allowed: colour) == .nothing)
        #expect(SpokenChess.read("dark dark", allowed: colour) == .answer(.colour(.dark)))
        #expect(SpokenChess.read("yes no", allowed: yesNo) == .nothing)
        #expect(SpokenChess.read("repeat e four", allowed: square) == .nothing)
        #expect(SpokenChess.read("dark repeat", allowed: colour) == .nothing)
    }

    // @spec SPOKEN-IN-011
    @Test func longestPhraseMatchesFirst() {
        #expect(SpokenChess.read("not the same", allowed: yesNo) == .answer(.no))
        #expect(SpokenChess.read("not same", allowed: yesNo) == .answer(.no))
        #expect(SpokenChess.read("same", allowed: yesNo) == .answer(.yes))
    }

    // MARK: Certainty

    // @spec SPOKEN-CERT-001
    @Test func bestAlternativeCommandWins() {
        #expect(SpokenChess.hear(["repeat", "dark", "light"], allowed: colour) == .command(.repeat))
    }

    // @spec SPOKEN-CERT-002
    @Test func lowerRankedCommandIsIgnored() {
        #expect(SpokenChess.hear(["dark", "stop"], allowed: colour) == .understood(.colour(.dark)))
        #expect(SpokenChess.hear(["hmm", "stop"], allowed: colour) == .notUnderstood)
    }

    // @spec SPOKEN-CERT-003
    @Test func understoodWhenBestReadsAndNoOtherDisagrees() throws {
        #expect(SpokenChess.hear(["dark", "dark", "hmm"], allowed: colour) == .understood(.colour(.dark)))
        #expect(SpokenChess.hear(["e four", "e for"], allowed: square) == .understood(.square(try sq("e4"))))
    }

    // @spec SPOKEN-CERT-004
    @Test func unsureWhenAlternativesDisagree() throws {
        #expect(SpokenChess.hear(["b four", "d four", "e four", "g four"], allowed: square)
            == .unsure([.square(try sq("b4")), .square(try sq("d4")), .square(try sq("e4"))]))
        #expect(SpokenChess.hear(["dark", "light"], allowed: colour) == .unsure([.colour(.dark), .colour(.light)]))
    }

    // @spec SPOKEN-CERT-005
    @Test func unsureWhenOnlyALowerRankedAlternativeReads() throws {
        #expect(SpokenChess.hear(["hmm", "b four"], allowed: square) == .unsure([.square(try sq("b4"))]))
        #expect(SpokenChess.hear(["hmm", "dark"], allowed: colour) == .unsure([.colour(.dark)]))
    }

    // @spec SPOKEN-CERT-006
    @Test func yesOrNoIsNeverUnsure() {
        #expect(SpokenChess.hear(["yes", "no"], allowed: yesNo) == .notUnderstood)
        #expect(SpokenChess.hear(["hmm", "yes"], allowed: yesNo) == .notUnderstood)
        #expect(SpokenChess.hear(["yes", "yeah"], allowed: yesNo) == .understood(.yes))
        #expect(SpokenChess.hear(["no", "hmm"], allowed: yesNo) == .understood(.no))
    }

    // @spec SPOKEN-CERT-007
    @Test func notUnderstoodWhenNothingReads() {
        #expect(SpokenChess.hear(["hello there", "fellow"], allowed: colour) == .notUnderstood)
        #expect(SpokenChess.hear([], allowed: colour) == .notUnderstood)
    }
}
