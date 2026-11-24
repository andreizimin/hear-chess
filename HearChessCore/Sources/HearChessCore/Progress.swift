// Stored progress and the progress store.
// Design: docs/intent/store/store-design.md

import Foundation

/// One finished session.
public struct SessionSummary: Hashable, Codable, Sendable {
    public let start: Date
    public let unpausedSeconds: Double
    public let seed: UInt64
    public let right: Int
    public let total: Int
    public let levelChanges: [LevelChange]

    public init(start: Date, unpausedSeconds: Double, seed: UInt64, right: Int, total: Int, levelChanges: [LevelChange]) {
        self.start = start
        self.unpausedSeconds = unpausedSeconds
        self.seed = seed
        self.right = right
        self.total = total
        self.levelChanges = levelChanges
    }
}

/// Everything the store keeps.
public struct Progress: Hashable, Codable, Sendable {
    public static let currentFormatVersion = 1
    public static let maxSessions = 100

    public var formatVersion: Int
    public var ladder: Ladder
    public var sessions: [SessionSummary]
    public var introductionGiven: Bool

    public init(ladder: Ladder = Ladder(), sessions: [SessionSummary] = [], introductionGiven: Bool = false) {
        self.formatVersion = Progress.currentFormatVersion
        self.ladder = ladder
        self.sessions = sessions
        self.introductionGiven = introductionGiven
    }

    /// Adds a summary, keeping only the most recent `maxSessions`.
    public mutating func add(_ summary: SessionSummary) {}
}

/// File operations the store needs, so they can be replaced in tests.
public protocol ProgressFileSystem: Sendable {
    func fileExists(_ url: URL) -> Bool
    func read(_ url: URL) throws -> Data
    /// Writes to a new file and replaces `url` with it in one step.
    func writeAtomically(_ data: Data, to url: URL) throws
    func move(_ from: URL, to: URL) throws
    func remove(_ url: URL) throws
    func contents(of directory: URL) throws -> [URL]
}

/// Why a progress file could not be opened at all.
public struct FileUnavailable: Error {
    public init() {}
}

/// How loading went.
public enum LoadOutcome: Hashable, Sendable {
    case loaded
    case noFile
    case converted
    /// A newer app wrote the file; nothing will be saved this run.
    case newerVersion
    /// The file could not be decoded; it was kept as a renamed copy.
    case unreadable
    /// The file could not be opened yet; it was left untouched.
    case unavailable
}

public final class ProgressStore: @unchecked Sendable {
    public static let fileName = "progress.json"

    public let directory: URL
    public private(set) var progress: Progress
    /// False after loading a newer-version file or while the file is unavailable.
    public private(set) var savingEnabled: Bool

    private let fileSystem: ProgressFileSystem
    private let now: () -> Date

    public init(directory: URL, fileSystem: ProgressFileSystem, now: @escaping () -> Date = Date.init) {
        self.directory = directory
        self.fileSystem = fileSystem
        self.now = now
        self.progress = Progress()
        self.savingEnabled = true
    }

    public var fileURL: URL { directory.appendingPathComponent(ProgressStore.fileName) }

    @discardableResult
    public func load() -> LoadOutcome { .noFile }

    /// Replaces the progress in memory and saves it, if saving is enabled.
    public func save(_ progress: Progress) {}
}
