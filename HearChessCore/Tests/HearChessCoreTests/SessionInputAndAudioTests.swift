import Foundation
import Testing
@testable import HearChessCore

@Suite("Session engine: touch, audio, voice and store")
struct SessionInputAndAudioTests {
    // MARK: Touch gestures

    // @spec TOUCH-002, TOUCH-003
    @Test func swipesAnswerColourAndYesNo() {
        let colour = Harness(exercises: [colourE4, colourF6])
        colour.start()
        #expect(sounds(colour.gesture(.swipeRight)) == [.right], "right = light")
        colour.finishSpeaking()
        #expect(sounds(colour.gesture(.swipeLeft)) == [.right], "left = dark")

        let yesNo = Harness(exercises: [sameDiagC1H6])
        yesNo.start()
        #expect(sounds(yesNo.gesture(.swipeRight)) == [.right], "right = yes")
        yesNo.finishSpeaking()
        #expect(sounds(yesNo.gesture(.swipeLeft)) == [.wrong], "left = no")
    }

    // @spec TOUCH-007
    @Test func threeFingerSwipeDownStopsAnytime() {
        let h = Harness(exercises: [colourF6])
        h.gesture(.tap)
        #expect(endings(h.gesture(.threeFingerSwipeDown)).count == 1, "even while asking")
    }

    // @spec TOUCH-008
    @Test func meaninglessGesturesAreIgnored() {
        let h = Harness(exercises: [colourF6])
        h.start()
        #expect(h.gesture(.doubleTap).isEmpty)
        #expect(h.gesture(.swipeUp).isEmpty, "no square pick on a colour question")
        #expect(h.engine.state == .listening)
    }

    // MARK: Picking a square

    // @spec TOUCH-SQ-001
    @Test func firstVerticalSwipeStartsAPickAtE() {
        let h = Harness(exercises: [twoRightOfE4])
        h.start()
        let fx = h.gesture(.swipeUp)
        #expect(spoken(fx) == ["File, ee."])
        #expect(h.engine.state == .pickingFile)
    }

    // @spec TOUCH-SQ-002
    @Test func swipesMoveThroughChoicesAndSpeakThem() {
        let h = Harness(exercises: [twoRightOfE4])
        h.start()
        h.gesture(.swipeUp); h.finishSpeaking()
        #expect(spoken(h.gesture(.swipeUp)) == ["Ef."])
        #expect(spoken(h.gesture(.swipeUp)) == ["Gee."])
        #expect(spoken(h.gesture(.swipeDown)) == ["Ef."])
    }

    // @spec TOUCH-SQ-003
    @Test func swipingPastTheEndBumps() {
        let h = Harness(exercises: [twoRightOfE4])
        h.start()
        h.gesture(.swipeUp)
        for _ in 0..<3 { h.gesture(.swipeUp) }   // f, g, h
        let fx = h.gesture(.swipeUp)
        #expect(sounds(fx) == [.bump])
        #expect(spoken(fx).isEmpty)
        h.gesture(.doubleTap)
        for _ in 0..<4 { h.gesture(.swipeDown) }  // 3, 2, 1, then bump
        #expect(sounds(h.log.suffix(1)) == [.bump])
    }

    // @spec TOUCH-SQ-004
    @Test func doubleTapChoosesFileAndStartsRankAt4() {
        let h = Harness(exercises: [twoRightOfE4])
        h.start()
        h.gesture(.swipeUp); h.gesture(.swipeUp); h.gesture(.swipeUp)   // g
        let fx = h.gesture(.doubleTap)
        #expect(spoken(fx) == ["Rank, four."])
        #expect(h.engine.state == .pickingRank)
    }

    // @spec TOUCH-SQ-005
    @Test func doubleTapOnRankAnswersDirectlyAndSpeaksItBack() {
        let h = Harness(exercises: [twoRightOfE4, colourF6])
        h.start()
        h.gesture(.swipeUp); h.gesture(.swipeUp); h.gesture(.swipeUp)   // g
        h.gesture(.doubleTap)                                            // rank 4
        let fx = h.gesture(.doubleTap)
        #expect(spoken(fx).first == "Gee four.")
        #expect(sounds(fx) == [.right])
        #expect(h.engine.state != .confirming)
        #expect(h.engine.progress.ladder.estimate(.directions).results.last?.method == .touch)
    }

    // @spec TOUCH-SQ-006
    @Test func sidewaysSwipesAreIgnoredWhilePicking() {
        let h = Harness(exercises: [twoRightOfE4])
        h.start()
        h.gesture(.swipeUp)
        #expect(h.gesture(.swipeLeft).isEmpty)
        #expect(h.gesture(.swipeRight).isEmpty)
        #expect(h.engine.state == .pickingFile)
    }

    // @spec TOUCH-SQ-007
    @Test func repeatDuringPickRestartsIt() {
        let h = Harness(exercises: [twoRightOfE4])
        h.start()
        h.gesture(.swipeUp); h.gesture(.swipeUp); h.gesture(.doubleTap)
        let fx = h.gesture(.twoFingerTap)
        #expect(spoken(fx) == [SpokenChess.text(for: twoRightOfE4.prompt)])
        h.finishSpeaking()
        #expect(spoken(h.gesture(.swipeUp)) == ["File, ee."], "pick starts again at e")
    }

    // @spec TOUCH-SQ-008
    @Test func voiceAnswerDuringPickWins() {
        let h = Harness(exercises: [twoRightOfE4, colourF6])
        h.start()
        h.gesture(.swipeUp); h.finishSpeaking()
        let fx = h.say("g4")
        #expect(sounds(fx) == [.right])
        #expect(h.engine.progress.ladder.estimate(.directions).results.last?.method == .voice)
    }

    // MARK: Screen

    // @spec TOUCH-SCR-001, TOUCH-SCR-003
    @Test func screenStaysAwakeOnlyWithVoiceOff() {
        let off = Harness(voice: false, exercises: [colourF6])
        #expect(off.gesture(.tap).contains(.keepScreenAwake(true)))
        #expect(off.gesture(.threeFingerSwipeDown).contains(.keepScreenAwake(false)))
    }

    // @spec TOUCH-SCR-002
    @Test func screenLocksNormallyWithVoiceOn() {
        let on = Harness(exercises: [colourF6])
        let fx = on.gesture(.tap)
        #expect(!fx.isEmpty, "the session started")
        #expect(!fx.contains(.keepScreenAwake(true)))
    }

    // MARK: Audio

    // @spec AUDIO-001, AUDIO-002, AUDIO-CMD-001
    @Test func audioModeFollowsVoiceAndAppTakesNowPlaying() {
        let on = Harness(exercises: [colourF6])
        let fx = on.gesture(.tap)
        #expect(fx.contains(.audio(.playAndRecord)))
        #expect(fx.contains(.nowPlaying(true)))
        let off = Harness(voice: false, exercises: [colourF6])
        #expect(off.gesture(.tap).contains(.audio(.playOnly)))
    }

    // @spec AUDIO-003
    @Test func audioIsReleasedWhenTheSessionEnds() {
        let h = Harness(exercises: [colourF6])
        h.start()
        let fx = h.gesture(.threeFingerSwipeDown) + h.finishSpeaking()
        #expect(fx.contains(.audio(.released)))
    }

    // @spec AUDIO-BG-002
    @Test func suspendedPausedSessionIsRestoredOrEnded() {
        let short = Harness(exercises: [colourF6])
        short.start()
        short.gesture(.twoFingerDoubleTap)
        short.send(.appResumed, after: 120)
        #expect(short.engine.state == .paused)

        let long = Harness(exercises: [colourF6])
        long.start()
        long.gesture(.twoFingerDoubleTap)
        let fx = long.send(.appResumed, after: 700)
        #expect(endings(fx).count == 1)
        #expect(spoken(fx).isEmpty, "ended without speaking")
        #expect(!saves(fx).isEmpty)
    }

    // @spec AUDIO-BG-003, AUDIO-BG-004
    @Test func nowPlayingKeptOneMinuteAfterTheEnd() {
        let h = Harness(exercises: [colourF6])
        h.start()
        h.gesture(.threeFingerSwipeDown); h.finishSpeaking()
        #expect(h.send(.tick, after: 30).isEmpty)
        #expect(spoken(h.media(.playPause)) == ["Start training?"], "within the minute")
        h.send(.tick, after: 11)
        let later = Harness(exercises: [colourF6])
        later.start()
        later.gesture(.threeFingerSwipeDown); later.finishSpeaking()
        #expect(later.send(.tick, after: 61) == [.nowPlaying(false)])
        #expect(later.send(.tick, after: 600).isEmpty, "no background work while idle")
    }

    // @spec AUDIO-CMD-004
    @Test func nextTrackSkipsWhileListeningOrConfirming() {
        let h = Harness(exercises: [colourF6, colourE4, twoRightOfE4])
        h.start()
        #expect(sounds(h.media(.nextTrack)) == [.wrong])
        h.finishSpeaking()
        h.answerRightAndContinue()
        h.say(["b four", "d four"]); h.finishSpeaking()
        #expect(sounds(h.media(.nextTrack)) == [.wrong])
    }

    // @spec AUDIO-CMD-005
    @Test func previousTrackRepeatsWhileListening() {
        let h = Harness(exercises: [colourF6])
        h.start()
        #expect(spoken(h.media(.previousTrack)) == [SpokenChess.text(for: colourF6.prompt)])
    }

    // @spec AUDIO-CMD-006
    @Test func trackCommandsIgnoredWhileAskingOrGivingFeedback() {
        let h = Harness(exercises: [colourF6, colourE4])
        h.gesture(.tap)
        #expect(h.media(.nextTrack).isEmpty)
        #expect(h.media(.previousTrack).isEmpty)
        h.finishSpeaking()
        h.answerWrong()                       // correction being spoken
        #expect(h.media(.nextTrack).isEmpty)
        #expect(h.media(.previousTrack).isEmpty)
    }

    // @spec AUDIO-CMD-007
    @Test func nextTrackIgnoredWhilePaused() {
        let h = Harness(exercises: [colourF6])
        h.start()
        h.gesture(.twoFingerDoubleTap)
        #expect(h.media(.nextTrack).isEmpty)
        #expect(h.engine.state == .paused)
    }

    // @spec AUDIO-INT-001, AUDIO-INT-002
    @Test func afterAnInterruptionStaysPausedThenReasks() {
        let h = Harness(exercises: [twoRightOfE4])
        h.start()
        h.say(["b four", "d four"]); h.finishSpeaking()
        h.send(.interruptionBegan)
        #expect(h.send(.interruptionEnded, after: 30).allSatisfy { if case .speak = $0 { false } else { true } })
        #expect(h.engine.state == .paused)
        #expect(spoken(h.media(.playPause)) == [SpokenChess.text(for: twoRightOfE4.prompt)])
    }

    // @spec AUDIO-INT-003
    @Test func reconnectingHeadphonesStaysPaused() {
        let h = Harness(exercises: [colourF6])
        h.start()
        h.send(.headphonesDisconnected)
        h.send(.headphonesConnected, after: 5)
        #expect(h.engine.state == .paused)
    }

    // MARK: Voice

    // @spec VOICE-IN-007, VOICE-IN-008
    @Test func threeRecognizerErrorsTurnVoiceOffForTheSession() {
        let h = Harness(exercises: [colourF6])
        h.start()
        h.send(.recognitionError)
        h.send(.recognitionError)
        let fx = h.send(.recognitionError)
        #expect(!h.engine.voiceOn)
        #expect(spoken(fx) == [SessionPhrases.voiceTurnedOff])
        #expect(fx.contains(.keepScreenAwake(true)))
        // Next session checks again.
        h.gesture(.threeFingerSwipeDown); h.finishSpeaking()
        h.gesture(.tap, after: 120)
        #expect(h.engine.voiceOn)
    }

    // @spec VOICE-IN-007
    @Test func recognizedSpeechResetsTheErrorCount() {
        let h = Harness(exercises: [colourF6])
        h.start()
        h.send(.recognitionError)
        h.send(.recognitionError)
        h.say("banana"); h.finishSpeaking()
        h.send(.recognitionError)
        #expect(h.engine.voiceOn)
    }

    // @spec VOICE-PERM-004
    @Test func voiceAvailabilityIsCheckedAtEachStart() {
        let h = Harness(voice: false, exercises: [colourF6])
        h.gesture(.tap)
        #expect(!h.engine.voiceOn)
        h.gesture(.threeFingerSwipeDown); h.finishSpeaking()
        h.voiceAvailable = true
        h.gesture(.tap, after: 120)
        #expect(h.engine.voiceOn)
    }

    // MARK: Store

    // @spec STORE-LOAD-004
    @Test func notSavingIsSaidAtEachSessionStart() {
        let h = Harness(saving: false, exercises: [colourF6])
        #expect(spoken(h.gesture(.tap)).first == SessionPhrases.notSaving)
        #expect(!SessionPhrases.notSaving.isEmpty)
        h.gesture(.threeFingerSwipeDown); h.finishSpeaking()
        #expect(spoken(h.gesture(.tap, after: 120)).first == SessionPhrases.notSaving)
    }

    // @spec STORE-003
    @Test func summaryIsSavedWhenTheSessionEnds() {
        let h = Harness(exercises: [colourF6, colourE4])
        h.start()
        h.answerRightAndContinue()
        let fx = h.gesture(.threeFingerSwipeDown)
        let saved = saves(fx).last
        #expect(saved?.sessions.count == 1)
        #expect(saved?.sessions.first?.right == 1 && saved?.sessions.first?.total == 1)
    }

    // @spec STORE-002
    @Test func summaryRecordsTheWallClockStart() {
        let start = Date(timeIntervalSince1970: 1_900_000_000)
        let engine = SessionEngine(progress: Progress(introductionGiven: true), voiceCheck: { true }, seedSource: { 1 }, wallClock: { start })
        _ = engine.handle(.gesture(.tap), at: 50)
        let fx = engine.handle(.gesture(.threeFingerSwipeDown), at: 80)
        let summary = fx.compactMap { if case let .sessionEnded(s) = $0 { s } else { nil } }.first
        #expect(summary?.start == start)
        #expect(summary.map { abs($0.unpausedSeconds - 30) < 0.001 } == true)
    }

    // The ladder chooses real exercises when no override is set.
    @Test func defaultExercisesComeFromTheLadderAndGenerator() {
        let engine = SessionEngine(progress: Progress(introductionGiven: true), voiceCheck: { true }, seedSource: { 7 })
        _ = engine.handle(.gesture(.tap), at: 0)
        let ex = engine.currentExercise
        #expect(ex != nil)
        #expect(ex.map { EmptyBoard.drillsForTests.contains($0.drill) && $0.level == 1 } == true)
    }
}
