// Spoken chess: prompts to words, and recognized speech to answers.
// Design: docs/intent/spoken-chess/spoken-chess-design.md

/// Commands a player can say.
public enum Command: String, CaseIterable, Hashable, Codable, Sendable {
    case `repeat`
    case dontKnow
    case pause
    case resume
    case stop
}

/// What may be heard at a given moment.
public struct Allowed: Hashable, Sendable {
    public var answerKind: AnswerKind?
    public var commands: Set<Command>

    public init(answerKind: AnswerKind?, commands: Set<Command>) {
        self.answerKind = answerKind
        self.commands = commands
    }

    /// During an exercise: answers of its kind plus repeat, I don't know, pause and stop.
    public static func exercise(_ kind: AnswerKind) -> Allowed {
        Allowed(answerKind: kind, commands: [.repeat, .dontKnow, .pause, .stop])
    }

    /// While paused: only resume and stop.
    public static let paused = Allowed(answerKind: nil, commands: [.resume, .stop])

    /// "Start training?": yes or no only.
    public static let yesOrNo = Allowed(answerKind: .yesOrNo, commands: [])
}

/// How one transcription reads.
public enum Reading: Hashable, Sendable {
    case answer(Answer)
    case command(Command)
    case nothing
}

/// The result of reading all of the recognizer's alternatives.
public enum Hearing: Hashable, Sendable {
    case command(Command)
    case understood(Answer)
    case unsure([Answer])
    case notUnderstood
}

public enum SpokenChess {
    // MARK: Output

    /// Each file letter's name in IPA, for the voice to apply so the engine says the letter's name.
    public static let letterIPA: [Character: String] = [
        "A": "eɪ", "B": "biː", "C": "siː", "D": "diː", "E": "iː", "F": "ɛf", "G": "dʒiː", "H": "eɪtʃ",
    ]

    /// A standalone capital file letter in a phrase, with its IPA name.
    public struct LetterPronunciation: Hashable, Sendable {
        public let range: Range<String.Index>
        public let ipa: String
    }

    /// The standalone capital letters A–H in a phrase, each with its IPA name.
    // @spec SPOKEN-OUT-005
    public static func letterPronunciations(in phrase: String) -> [LetterPronunciation] {
        var result: [LetterPronunciation] = []
        var i = phrase.startIndex
        while i < phrase.endIndex {
            let next = phrase.index(after: i)
            let before = i == phrase.startIndex ? nil : phrase[phrase.index(before: i)]
            let after = next == phrase.endIndex ? nil : phrase[next]
            if let ipa = letterIPA[phrase[i]],
               !(before?.isLetter ?? false) && !(before == "'"),
               !(after?.isLetter ?? false) && !(after == "'") {
                result.append(LetterPronunciation(range: i..<next, ipa: ipa))
            }
            i = next
        }
        return result
    }

    static let numberWords = ["one", "two", "three", "four", "five", "six", "seven", "eight"]

    /// "E4" for e4.
    // @spec SPOKEN-OUT-001
    public static func speak(_ square: Square) -> String {
        "\(square.fileLetter.uppercased())\(square.rank + 1)"
    }

    static func spokenFile(_ file: Int) -> String { Array("ABCDEFGH")[file].description }
    static func spokenRank(_ rank: Int) -> String { numberWords[rank] }

    static func directionWords(_ d: Direction) -> String {
        switch d {
        case .up: "up"
        case .down: "down"
        case .right: "right"
        case .left: "left"
        case .upRight: "up-right"
        case .upLeft: "up-left"
        case .downRight: "down-right"
        case .downLeft: "down-left"
        }
    }

    static func sentence(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }

    /// The words spoken for a prompt.
    // @spec SPOKEN-OUT-003
    public static func text(for prompt: Prompt) -> String {
        switch prompt {
        case let .squareColour(s):
            return sentence("\(speak(s)). Light or dark?")
        case let .direction(from, steps):
            let parts = steps.map { "\(numberWords[$0.count - 1]) \(directionWords($0.direction))" }
            return sentence("\(parts.joined(separator: ", ")) from \(speak(from))?")
        case let .sameDiagonal(a, b):
            return sentence("\(speak(a)) and \(speak(b)). Same diagonal?")
        case let .diagonalEnd(from, direction):
            return sentence("from \(speak(from)), \(directionWords(direction)) to the edge?")
        case let .longDiagonal(d, s):
            return sentence("\(speak(d.start)) to \(speak(d.end)). Is \(speak(s)) on it?")
        }
    }

    /// The words spoken after a wrong answer, such as "F6 is dark." or "G4."
    // @spec SPOKEN-OUT-004
    public static func correction(for exercise: Exercise) -> String {
        guard let answer = exercise.correction else { return "" }
        switch (answer, exercise.prompt) {
        case let (.colour(c), .squareColour(s)):
            return sentence("\(speak(s)) is \(c.rawValue).")
        case let (.square(s), _):
            return sentence("\(speak(s)).")
        case (.yes, .sameDiagonal): return "Yes, same diagonal."
        case (.no, .sameDiagonal): return "No, not the same diagonal."
        case (.yes, .longDiagonal): return "Yes, it's on it."
        case (.no, .longDiagonal): return "No, it's not on it."
        case (.yes, _): return "Yes."
        case (.no, _): return "No."
        case let (.colour(c), _): return sentence("\(c.rawValue).")
        }
    }

    /// The question asked to confirm an unsure candidate, such as "B4?" or "Dark?".
    public static func candidate(_ answer: Answer) -> String {
        switch answer {
        case let .square(s): sentence("\(speak(s))?")
        case let .colour(c): sentence("\(c.rawValue)?")
        case .yes: "Yes?"
        case .no: "No?"
        }
    }

    // MARK: Input

    /// One recognized item in a transcription.
    enum Item: Hashable {
        case filler
        case unknown
        case colour(SquareColour)
        case yes
        case no
        case command(Command)
        case file(Int)
        case rank(Int)
        case square(Square)
    }

    // @spec SPOKEN-IN-002, SPOKEN-IN-003, SPOKEN-IN-005, SPOKEN-IN-006, SPOKEN-IN-007, SPOKEN-IN-008, SPOKEN-IN-009
    static let lexicon: [String: Item] = {
        var l: [String: Item] = [:]
        for w in ["um", "uh", "er", "erm", "it's", "i think"] { l[w] = .filler }
        for w in ["light", "white"] { l[w] = .colour(.light) }
        for w in ["dark", "black"] { l[w] = .colour(.dark) }
        for w in ["yes", "yeah", "yep", "correct", "same"] { l[w] = .yes }
        for w in ["no", "nope", "different", "not the same", "not same", "not correct"] { l[w] = .no }
        for w in ["repeat", "again"] { l[w] = .command(.repeat) }
        for w in ["skip", "i don't know", "i dont know", "not sure", "pass"] { l[w] = .command(.dontKnow) }
        l["pause"] = .command(.pause)
        for w in ["resume", "continue"] { l[w] = .command(.resume) }
        l["stop"] = .command(.stop)
        let fileWords: [[String]] = [
            ["a", "ay", "hey", "alpha", "anton"],
            ["b", "bee", "be", "bravo", "berta"],
            ["c", "see", "sea", "cee", "charlie", "cäsar", "caesar"],
            ["d", "dee", "delta", "dora"],
            ["e", "ee", "echo", "emil"],
            ["f", "ef", "foxtrot", "friedrich"],
            ["g", "gee", "jee", "golf", "gustav"],
            ["h", "aitch", "age", "hotel", "heinrich"],
        ]
        for (file, words) in fileWords.enumerated() { for w in words { l[w] = .file(file) } }
        let rankWords: [[String]] = [
            ["1", "one", "won"], ["2", "two", "to", "too"], ["3", "three"], ["4", "four", "for", "fore"],
            ["5", "five"], ["6", "six"], ["7", "seven"], ["8", "eight", "ate"],
        ]
        for (rank, words) in rankWords.enumerated() { for w in words { l[w] = .rank(rank) } }
        l["before"] = .square(Square(unchecked: 1, 3))
        return l
    }()

    static let longestPhrase = lexicon.keys.map { $0.split(separator: " ").count }.max() ?? 1

    static func tokens(_ text: String) -> [String] {
        let cleaned = text.lowercased().map { c -> Character in
            c.isLetter || c.isNumber || c == "'" || c == "’" ? (c == "’" ? "'" : c) : " "
        }
        return String(cleaned).split(separator: " ").map(String.init)
    }

    /// Splits a transcription into items, matching the longest listed phrase first.
    // @spec SPOKEN-IN-011
    static func items(_ text: String) -> [Item] {
        let words = tokens(text)
        var result: [Item] = []
        var i = 0
        while i < words.count {
            var matched = false
            for length in stride(from: min(longestPhrase, words.count - i), through: 1, by: -1) {
                let phrase = words[i..<(i + length)].joined(separator: " ")
                if let item = lexicon[phrase] {
                    result.append(item)
                    i += length
                    matched = true
                    break
                }
            }
            if !matched {
                result.append(Square(name: words[i]).map(Item.square) ?? .unknown)
                i += 1
            }
        }
        return result.filter { $0 != .filler }
    }

    /// Words and phrases allowed at a moment, given to the recognizer as contextual hints.
    // @spec VOICE-IN-002
    public static func hints(for allowed: Allowed) -> [String] {
        var words: [String] = []
        for (phrase, item) in lexicon.sorted(by: { $0.key < $1.key }) {
            switch item {
            case let .command(c) where allowed.commands.contains(c): words.append(phrase)
            case .colour where allowed.answerKind == .lightOrDark: words.append(phrase)
            case .yes, .no: if allowed.answerKind == .yesOrNo { words.append(phrase) }
            default: break
            }
        }
        if allowed.answerKind == .square {
            for file in 0..<8 {
                for rank in 0..<8 {
                    let sq = Square(unchecked: file, rank)
                    words.append(sq.name)
                    words.append("\(sq.fileLetter) \(numberWords[rank])")
                }
            }
        }
        return words
    }

    /// Reads one transcription against what is allowed.
    // @spec SPOKEN-IN-001, SPOKEN-IN-004, SPOKEN-IN-010
    public static func read(_ transcription: String, allowed: Allowed) -> Reading {
        let list = items(transcription)
        var answers: [Answer] = []
        var commands: [Command] = []
        for (index, item) in list.enumerated() {
            switch item {
            case let .command(c) where allowed.commands.contains(c):
                commands.append(c)
            case let .colour(c) where allowed.answerKind == .lightOrDark:
                answers.append(.colour(c))
            case .yes where allowed.answerKind == .yesOrNo:
                answers.append(.yes)
            case .no where allowed.answerKind == .yesOrNo:
                answers.append(.no)
            case let .square(s) where allowed.answerKind == .square:
                answers.append(.square(s))
            case let .file(f) where allowed.answerKind == .square:
                if index + 1 < list.count, case let .rank(r) = list[index + 1] {
                    answers.append(.square(Square(unchecked: f, r)))
                }
            default:
                break
            }
        }
        if !commands.isEmpty && !answers.isEmpty { return .nothing }
        if let c = commands.first { return Set(commands).count == 1 ? .command(c) : .nothing }
        if let a = answers.first { return Set(answers).count == 1 ? .answer(a) : .nothing }
        return .nothing
    }

    /// Reads the recognizer's alternatives, best first.
    // @spec SPOKEN-CERT-001, SPOKEN-CERT-002, SPOKEN-CERT-003, SPOKEN-CERT-004,
    //       SPOKEN-CERT-005, SPOKEN-CERT-006, SPOKEN-CERT-007
    public static func hear(_ alternatives: [String], allowed: Allowed) -> Hearing {
        let readings = alternatives.map { read($0, allowed: allowed) }
        guard let best = readings.first else { return .notUnderstood }
        if case let .command(c) = best { return .command(c) }

        var answers: [Answer] = []
        for reading in readings {
            if case let .answer(a) = reading, !answers.contains(a) { answers.append(a) }
        }

        if allowed.answerKind == .yesOrNo {
            if case let .answer(a) = best, answers.count == 1 { return .understood(a) }
            return .notUnderstood
        }
        if case let .answer(a) = best {
            return answers.count == 1 ? .understood(a) : .unsure(Array(answers.prefix(3)))
        }
        return answers.isEmpty ? .notUnderstood : .unsure(Array(answers.prefix(3)))
    }
}
