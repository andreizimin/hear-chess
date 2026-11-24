import Foundation
import Testing
@testable import HearChessCore

/// An in-memory file system that records what happens and can be told to fail.
final class FakeFileSystem: ProgressFileSystem, @unchecked Sendable {
    var files: [URL: Data] = [:]
    var log: [String] = []
    var failWrites = false
    var unavailable: Set<URL> = []

    func fileExists(_ url: URL) -> Bool { files[url] != nil }

    func read(_ url: URL) throws -> Data {
        if unavailable.contains(url) { throw FileUnavailable() }
        guard let data = files[url] else { throw CocoaError(.fileNoSuchFile) }
        return data
    }

    func writeAtomically(_ data: Data, to url: URL) throws {
        if failWrites { log.append("write-failed"); throw CocoaError(.fileWriteOutOfSpace) }
        log.append("write:\(url.lastPathComponent)")
        files[url] = data
    }

    func move(_ from: URL, to: URL) throws {
        log.append("move:\(from.lastPathComponent)->\(to.lastPathComponent)")
        files[to] = files.removeValue(forKey: from)
    }

    func remove(_ url: URL) throws {
        log.append("remove:\(url.lastPathComponent)")
        files.removeValue(forKey: url)
    }

    func contents(of directory: URL) throws -> [URL] {
        files.keys.filter { $0.deletingLastPathComponent().standardizedFileURL == directory.standardizedFileURL }
    }
}

let storeDirectory = URL(fileURLWithPath: "/tmp/hear-chess-test-store", isDirectory: true)

func makeStore(_ fs: FakeFileSystem, now: Date = Date(timeIntervalSince1970: 1_800_000_000)) -> ProgressStore {
    ProgressStore(directory: storeDirectory, fileSystem: fs, now: { now })
}

func summary(_ n: Int) -> SessionSummary {
    SessionSummary(start: Date(timeIntervalSince1970: Double(n)), unpausedSeconds: 420, seed: UInt64(n), right: 3, total: 4, levelChanges: [])
}

func progressJSON(version: Int) -> Data {
    var p = Progress(introductionGiven: true)
    p.formatVersion = version
    return try! JSONEncoder().encode(p)
}

@Suite("Progress store")
struct ProgressStoreTests {
    // MARK: Contents

    // @spec STORE-001
    @Test func keepsEachDrillsSkillEstimate() throws {
        var ladder = Ladder()
        ladder.record(.right(.voice, seconds: 2), drill: .directions, askedAtLevel: 1)
        let fs = FakeFileSystem()
        let store = makeStore(fs)
        store.save(Progress(ladder: ladder))
        let reloaded = makeStore(fs)
        #expect(reloaded.load() == .loaded)
        #expect(reloaded.progress.ladder.estimate(.directions) == ladder.estimate(.directions))
    }

    // @spec STORE-002
    @Test func keepsTheLast100SessionSummaries() {
        var progress = Progress()
        for n in 0..<130 { progress.add(summary(n)) }
        #expect(progress.sessions.count == 100)
        #expect(progress.sessions.first?.seed == 30)
        #expect(progress.sessions.last?.seed == 129)
        let s = summary(1)
        #expect(s.unpausedSeconds == 420 && s.right == 3 && s.total == 4)
    }

    // @spec STORE-003
    @Test func savedSummaryIsPersisted() {
        let fs = FakeFileSystem()
        let store = makeStore(fs)
        var p = Progress()
        p.add(summary(5))
        store.save(p)
        let reloaded = makeStore(fs)
        reloaded.load()
        #expect(reloaded.progress.sessions == [summary(5)])
    }

    // @spec STORE-004
    @Test func introductionFlagIsPersisted() {
        let fs = FakeFileSystem()
        makeStore(fs).save(Progress(introductionGiven: true))
        let reloaded = makeStore(fs)
        reloaded.load()
        #expect(reloaded.progress.introductionGiven)
    }

    // @spec STORE-005
    @Test func progressRoundTripsThroughJSON() throws {
        var ladder = Ladder()
        ladder.record(.wrong(.touch), drill: .diagonals, askedAtLevel: 1)
        var p = Progress(ladder: ladder, introductionGiven: true)
        p.add(SessionSummary(start: Date(timeIntervalSince1970: 100), unpausedSeconds: 3, seed: 9, right: 1, total: 2,
                             levelChanges: [LevelChange(drill: .squareColour, from: 1, to: 2)]))
        let decoded = try JSONDecoder().decode(Progress.self, from: JSONEncoder().encode(p))
        #expect(decoded == p)
    }

    // MARK: Saving

    // @spec STORE-SAVE-001
    @Test func progressIsOneJSONFileWithFormatVersion() throws {
        let fs = FakeFileSystem()
        let store = makeStore(fs)
        store.save(Progress())
        #expect(store.fileURL == storeDirectory.appendingPathComponent("progress.json"))
        let data = try #require(fs.files[store.fileURL])
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["formatVersion"] as? Int == Progress.currentFormatVersion)
        #expect(fs.files.count == 1)
    }

    // @spec STORE-SAVE-002
    @Test func savingReplacesProgressInMemoryAndOnDisk() {
        let fs = FakeFileSystem()
        let store = makeStore(fs)
        var ladder = Ladder()
        ladder.record(.dontKnow(.voice), drill: .squareColour, askedAtLevel: 1)
        store.save(Progress(ladder: ladder))
        #expect(store.progress.ladder == ladder)
        #expect(fs.log == ["write:progress.json"])
    }

    // @spec STORE-SAVE-003
    @Test func savesUseTheAtomicWrite() {
        let fs = FakeFileSystem()
        let store = makeStore(fs)
        store.save(Progress())
        store.save(Progress(introductionGiven: true))
        #expect(fs.log == ["write:progress.json", "write:progress.json"])
    }

    // @spec STORE-SAVE-004
    @Test func savesHappenInOrder() {
        let fs = FakeFileSystem()
        let store = makeStore(fs)
        for n in 0..<5 {
            var p = Progress()
            p.add(summary(n))
            store.save(p)
        }
        let reloaded = makeStore(fs)
        reloaded.load()
        #expect(reloaded.progress.sessions == [summary(4)])
    }

    // @spec STORE-SAVE-005
    @Test func failedSaveIsWrittenByTheNextSave() {
        let fs = FakeFileSystem()
        let store = makeStore(fs)
        fs.failWrites = true
        store.save(Progress(introductionGiven: true))
        #expect(store.progress.introductionGiven, "kept in memory")
        fs.failWrites = false
        var p = store.progress
        p.add(summary(1))
        store.save(p)
        let reloaded = makeStore(fs)
        reloaded.load()
        #expect(reloaded.progress.introductionGiven && reloaded.progress.sessions == [summary(1)])
    }

    // MARK: Loading

    // @spec STORE-LOAD-001
    @Test func loadReadsTheFile() {
        let fs = FakeFileSystem()
        fs.files[storeDirectory.appendingPathComponent("progress.json")] = progressJSON(version: Progress.currentFormatVersion)
        let store = makeStore(fs)
        #expect(store.load() == .loaded)
        #expect(store.progress.introductionGiven)
        #expect(store.savingEnabled)
    }

    // STORE-LOAD-002 (older format versions) has no test yet: format version 1 is the first,
    // so there is no older format to convert. The first format change adds its test.

    // @spec STORE-LOAD-003
    @Test func newerVersionIsLeftUntouchedAndNothingIsSaved() {
        let fs = FakeFileSystem()
        let url = storeDirectory.appendingPathComponent("progress.json")
        let newer = progressJSON(version: Progress.currentFormatVersion + 1)
        fs.files[url] = newer
        let store = makeStore(fs)
        #expect(store.load() == .newerVersion)
        #expect(!store.savingEnabled)
        #expect(store.progress == Progress())
        store.save(Progress(introductionGiven: true))
        #expect(fs.files[url] == newer)
        #expect(fs.log.isEmpty)
    }

    // STORE-LOAD-004 (saying so at each session start) is the session's job and is tested with the session.

    // @spec STORE-LOAD-005
    @Test func undecodableFileIsKeptAsDatedCopy() {
        let fs = FakeFileSystem()
        let url = storeDirectory.appendingPathComponent("progress.json")
        fs.files[url] = Data("not json".utf8)
        let store = makeStore(fs, now: Date(timeIntervalSince1970: 1_800_000_000))
        #expect(store.load() == .unreadable)
        #expect(store.progress == Progress())
        #expect(fs.files[url] == nil)
        let copies = fs.files.keys.map(\.lastPathComponent).filter { $0.hasPrefix("progress-unreadable-") }
        #expect(copies.count == 1)
        #expect(store.savingEnabled)
    }

    // @spec STORE-LOAD-006
    @Test func atMostThreeUnreadableCopiesAreKept() {
        let fs = FakeFileSystem()
        let url = storeDirectory.appendingPathComponent("progress.json")
        for n in 0..<5 {
            fs.files[url] = Data("broken \(n)".utf8)
            let store = makeStore(fs, now: Date(timeIntervalSince1970: 1_800_000_000 + Double(n) * 60))
            store.load()
        }
        let copies = fs.files.keys.map(\.lastPathComponent).filter { $0.hasPrefix("progress-unreadable-") }.sorted()
        #expect(copies.count == 3)
        // The newest three remain.
        let contents = copies.compactMap { name in fs.files.first { $0.key.lastPathComponent == name }?.value }.map { String(decoding: $0, as: UTF8.self) }
        #expect(Set(contents) == ["broken 2", "broken 3", "broken 4"])
    }

    // @spec STORE-LOAD-007
    @Test func missingDrillStartsAtLevel1() {
        let p = Progress()
        #expect(p.ladder.estimate(.diagonals) == SkillEstimate(level: 1, results: []))
    }

    // @spec STORE-LOAD-008
    @Test func noFileStartsFresh() {
        let store = makeStore(FakeFileSystem())
        #expect(store.load() == .noFile)
        #expect(store.progress == Progress())
        #expect(store.savingEnabled)
    }

    // @spec STORE-LOAD-009
    @Test func unopenableFileIsLeftAloneAndNothingIsSavedUntilLoaded() {
        let fs = FakeFileSystem()
        let url = storeDirectory.appendingPathComponent("progress.json")
        let original = progressJSON(version: Progress.currentFormatVersion)
        fs.files[url] = original
        fs.unavailable = [url]
        let store = makeStore(fs)
        #expect(store.load() == .unavailable)
        #expect(!store.savingEnabled)
        store.save(Progress())
        #expect(fs.files[url] == original)
        #expect(fs.files.count == 1, "not renamed")
        fs.unavailable = []
        #expect(store.load() == .loaded)
        #expect(store.savingEnabled)
        #expect(store.progress.introductionGiven)
    }
}
