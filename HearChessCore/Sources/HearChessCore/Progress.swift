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
// @spec STORE-001, STORE-005
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
    // @spec STORE-002
    public mutating func add(_ summary: SessionSummary) {
        sessions.append(summary)
        if sessions.count > Progress.maxSessions { sessions.removeFirst(sessions.count - Progress.maxSessions) }
    }
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

    public static let unreadablePrefix = "progress-unreadable-"
    public static let maxUnreadableCopies = 3

    private struct Header: Decodable {
        let formatVersion: Int
    }

    // @spec STORE-LOAD-001, STORE-LOAD-002, STORE-LOAD-003, STORE-LOAD-005, STORE-LOAD-008, STORE-LOAD-009
    @discardableResult
    public func load() -> LoadOutcome {
        guard fileSystem.fileExists(fileURL) else {
            progress = Progress()
            savingEnabled = true
            return .noFile
        }
        let data: Data
        do {
            data = try fileSystem.read(fileURL)
        } catch {
            progress = Progress()
            savingEnabled = false
            return .unavailable
        }
        let decoder = JSONDecoder()
        guard let header = try? decoder.decode(Header.self, from: data) else { return keepUnreadable() }
        if header.formatVersion > Progress.currentFormatVersion {
            progress = Progress()
            savingEnabled = false
            return .newerVersion
        }
        guard var loaded = try? decoder.decode(Progress.self, from: data) else { return keepUnreadable() }
        savingEnabled = true
        if header.formatVersion < Progress.currentFormatVersion {
            loaded.formatVersion = Progress.currentFormatVersion
            save(loaded)
            return .converted
        }
        progress = loaded
        return .loaded
    }

    // @spec STORE-LOAD-005, STORE-LOAD-006
    private func keepUnreadable() -> LoadOutcome {
        let stamp = Int(now().timeIntervalSince1970)
        let copy = directory.appendingPathComponent("\(ProgressStore.unreadablePrefix)\(stamp).json")
        try? fileSystem.move(fileURL, to: copy)
        if let all = try? fileSystem.contents(of: directory) {
            let copies = all.filter { $0.lastPathComponent.hasPrefix(ProgressStore.unreadablePrefix) }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
            for old in copies.dropLast(ProgressStore.maxUnreadableCopies) { try? fileSystem.remove(old) }
        }
        progress = Progress()
        savingEnabled = true
        return .unreadable
    }

    /// Replaces the progress in memory and saves it, if saving is enabled.
    /// A failed save keeps the progress in memory; the next save writes it.
    // @spec STORE-SAVE-001, STORE-SAVE-002, STORE-SAVE-003, STORE-SAVE-004, STORE-SAVE-005, STORE-LOAD-003
    public func save(_ progress: Progress) {
        self.progress = progress
        guard savingEnabled, let data = try? JSONEncoder().encode(progress) else { return }
        try? fileSystem.writeAtomically(data, to: fileURL)
    }
}

/// The real file system, using Foundation.
public struct LocalFileSystem: ProgressFileSystem {
    public init() {}

    public func fileExists(_ url: URL) -> Bool { FileManager.default.fileExists(atPath: url.path) }

    public func read(_ url: URL) throws -> Data {
        do { return try Data(contentsOf: url) } catch { throw FileUnavailable() }
    }

    public func writeAtomically(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    public func move(_ from: URL, to: URL) throws { try FileManager.default.moveItem(at: from, to: to) }

    public func remove(_ url: URL) throws { try FileManager.default.removeItem(at: url) }

    public func contents(of directory: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
    }
}
