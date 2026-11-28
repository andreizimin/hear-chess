import Testing
@testable import HearChessCore

@Suite("Session engine")
struct SessionEngineTests {
    // MARK: Starting

    // @spec SESSION-START-001, VOICE-PERM-001
    @Test func tapStartsASessionOnlyAfterPermissionStep() {
        let h = Harness(exercises: [colourF6])
        let fx = h.gesture(.tap)
        #expect(h.engine.state != .idle)
        #expect(spoken(fx).contains(SpokenChess.text(for: colourF6.prompt)))

        let blocked = Harness(permissionStepDone: false, exercises: [colourF6])
        #expect(blocked.gesture(.tap).isEmpty)
        #expect(blocked.engine.state == .idle)

        // A tap while "Start training?" is pending starts the session.
        let pending = Harness(exercises: [colourF6])
        pending.media(.playPause)
        pending.finishSpeaking()
        pending.gesture(.tap)
        #expect(pending.engine.state == .starting || pending.engine.state == .asking)
    }

    // @spec SESSION-START-002
    @Test func headphonePlayWithNoSessionAsksStartTraining() {
        let h = Harness(exercises: [colourF6])
        let fx = h.media(.playPause)
        #expect(spoken(fx) == ["Start training?"])
        #expect(h.engine.state == .askingToStart)
    }

    // @spec SESSION-START-003
    @Test func secondPressOrYesWithin10SecondsStarts() {
        let press = Harness(exercises: [colourF6])
        press.media(.playPause)
        press.finishSpeaking()
        let fx = press.media(.playPause, after: 4)
        #expect(spoken(fx).contains(SpokenChess.text(for: colourF6.prompt)))

        let yes = Harness(exercises: [colourF6])
        yes.media(.playPause)
        #expect(listens(yes.finishSpeaking()) == [.yesOrNo], "listens for yes after asking")
        let fx2 = yes.say("yes", startedAfter: 2)
        #expect(spoken(fx2).contains(SpokenChess.text(for: colourF6.prompt)))
    }

    // @spec SESSION-START-004
    @Test func noConfirmationOrOtherAnswerDoesNotStart() {
        let late = Harness(exercises: [colourF6])
        late.media(.playPause)
        late.finishSpeaking()
        late.send(.tick, after: 11)
        #expect(late.engine.state == .idle)
        #expect(spoken(late.media(.playPause)) == ["Start training?"], "a later press asks again")

        let no = Harness(exercises: [colourF6])
        no.media(.playPause)
        no.finishSpeaking()
        no.say("no")
        #expect(no.engine.state == .idle)
    }

    // @spec SESSION-START-005
    @Test func sessionRecordsItsSeed() {
        let h = Harness(exercises: [colourF6])
        h.start()
        h.gesture(.threeFingerSwipeDown)
        h.finishSpeaking()
        #expect(endings(h.log).first?.seed == 42)
    }

    // @spec SESSION-START-006
    @Test func startAnnouncementsComeInOrder() {
        // Not saving + introduction due + voice off: notice, then intro (touch-only), then first question.
        let h = Harness(progress: Progress(introductionGiven: false), voice: false, saving: false, exercises: [colourF6])
        h.gesture(.tap)
        let said = spoken(h.log + h.finishSpeaking())
        let prompt = SpokenChess.text(for: colourF6.prompt)
        #expect(said.count >= 3)
        guard said.count >= 3 else { return }
        #expect(said[0] == SessionPhrases.notSaving)
        #expect(said[1] == SessionPhrases.introduction(voiceAvailable: false))
        #expect(said[2] == prompt)
        #expect(!said.contains(SessionPhrases.touchOnly), "intro replaces the touch-only notice")

        // No intro due + voice off: touch-only notice, then the first question.
        let h2 = Harness(voice: false, exercises: [colourF6])
        h2.gesture(.tap)
        let said2 = spoken(h2.log + h2.finishSpeaking())
        #expect(said2.prefix(2) == [SessionPhrases.touchOnly, prompt])
    }

    // MARK: Introduction

    // @spec SESSION-INTRO-001
    @Test func introductionIsSpokenUntilGiven() {
        let h = Harness(progress: Progress(introductionGiven: false), exercises: [colourF6])
        let fx = h.gesture(.tap)
        #expect(spoken(fx).first == SessionPhrases.introduction(voiceAvailable: true))
        let given = Harness(exercises: [colourF6])
        #expect(!spoken(given.gesture(.tap)).contains(SessionPhrases.introduction(voiceAvailable: true)))
    }

    // @spec SESSION-INTRO-002
    @Test func voiceIntroductionExplainsVoiceAndSwipes() {
        let text = SessionPhrases.introduction(voiceAvailable: true).lowercased()
        #expect(text.contains("say"))
        #expect(text.contains("swipe right") && text.contains("light or yes"))
        #expect(text.contains("swipe left") && text.contains("dark or no"))
    }

    // @spec SESSION-INTRO-003
    @Test func touchIntroductionExplainsSwipesOnly() {
        let text = SessionPhrases.introduction(voiceAvailable: false).lowercased()
        #expect(!text.contains("say"))
        #expect(text.contains("touch"))
        #expect(text.contains("swipe right") && text.contains("light or yes"))
        #expect(text.contains("swipe left") && text.contains("dark or no"))
    }

    // @spec SESSION-INTRO-004, STORE-004
    @Test func introductionIsRecordedAndSavedOnceSpoken() {
        let h = Harness(progress: Progress(introductionGiven: false), exercises: [colourF6])
        h.gesture(.tap)
        let fx = h.send(.speechFinished, after: 5)
        #expect(h.engine.progress.introductionGiven)
        #expect(saves(fx).last?.introductionGiven == true)
    }

    // @spec SESSION-INTRO-005
    @Test func introductionCutShortIsGivenAgain() {
        let h = Harness(progress: Progress(introductionGiven: false), exercises: [colourF6])
        h.gesture(.tap)
        h.gesture(.threeFingerSwipeDown, after: 1)
        h.finishSpeaking()
        #expect(!h.engine.progress.introductionGiven)
        let fx = h.gesture(.tap, after: 5)
        #expect(spoken(fx).first == SessionPhrases.introduction(voiceAvailable: true))
    }

    // @spec SESSION-INTRO-006
    @Test func introductionIgnoresInputAndRestartsAfterPause() {
        let h = Harness(progress: Progress(introductionGiven: false), exercises: [colourF6])
        h.gesture(.tap)
        #expect(h.gesture(.twoFingerTap).isEmpty, "repeat ignored")
        #expect(h.gesture(.swipeRight).isEmpty, "answers ignored")
        #expect(h.media(.nextTrack).isEmpty, "skip ignored")
        h.gesture(.twoFingerDoubleTap)
        #expect(h.engine.state == .paused)
        let fx = h.gesture(.twoFingerDoubleTap, after: 3)
        #expect(spoken(fx).first == SessionPhrases.introduction(voiceAvailable: true))
    }

    // MARK: Ending

    // @spec SESSION-END-001, SESSION-END-002
    @Test func sessionEndsAfter7MinutesOfUnpausedTime() {
        let h = Harness(exercises: [colourF6, colourE4])
        h.start()
        // Pause for 5 minutes: does not count.
        h.gesture(.twoFingerDoubleTap, after: 60)
        h.gesture(.twoFingerDoubleTap, after: 300)
        h.finishSpeaking()
        // 5 more minutes unpaused (6 in total), then answer: still running.
        h.send(.tick, after: 300)
        h.answerRightAndContinue()
        #expect(h.engine.state == .listening)
        // Past 7 minutes: the current exercise finishes and the session ends.
        h.send(.tick, after: 70)
        #expect(endings(h.log).isEmpty && h.engine.state != .idle, "never cuts off mid-exercise")
        h.finishSpeaking()
        h.answerRight()
        h.finishSpeaking()
        #expect(endings(h.log).count == 1)
        #expect(h.engine.state == .idle)
    }

    // @spec SESSION-END-003
    @Test func stopEndsAtOnceThenSpeaksSummary() {
        let h = Harness(exercises: [colourF6, colourE4])
        h.start()
        h.answerRightAndContinue()
        let fx = h.say("stop")
        #expect(fx.contains(.stopListening))
        #expect(spoken(fx).contains(SessionPhrases.summary(right: 1, total: 1, changes: [])))
        #expect(endings(fx).count == 1)
        let viaGesture = Harness(exercises: [colourF6])
        viaGesture.start()
        #expect(endings(viaGesture.gesture(.threeFingerSwipeDown)).count == 1)
    }

    // @spec SESSION-END-004
    @Test func tenMinutesPausedEndsTheSession() {
        let h = Harness(exercises: [colourF6])
        h.start()
        h.gesture(.twoFingerDoubleTap)
        h.send(.tick, after: 599)
        #expect(h.engine.state == .paused)
        h.send(.tick, after: 2)
        #expect(endings(h.log).count == 1)
    }

    // @spec SESSION-END-005
    @Test func unansweredExerciseIsDropped() {
        let h = Harness(exercises: [colourF6, colourE4])
        h.start()
        h.answerRightAndContinue()
        h.gesture(.threeFingerSwipeDown)
        let summary = endings(h.log).first
        #expect(summary?.total == 1)
        #expect(h.engine.progress.ladder.estimate(.squareColour).results.count == 1)
    }

    // @spec SESSION-END-006
    @Test func summarySaysScoreAndLevelChanges() {
        #expect(SessionPhrases.summary(right: 12, total: 14, changes: [LevelChange(drill: .diagonals, from: 1, to: 2)])
            == "12 of 14 right. Diagonals moved up to level 2.")
        #expect(SessionPhrases.summary(right: 3, total: 5, changes: [LevelChange(drill: .squareColour, from: 2, to: 1)])
            == "3 of 5 right. Square colour moved down to level 1.")
        #expect(SessionPhrases.summary(right: 1, total: 2, changes: []) == "1 of 2 right.")
        // "I don't know" counts as an answer.
        let h = Harness(exercises: [colourF6, colourE4])
        h.start()
        h.answerRightAndContinue()
        h.say("I don't know")
        h.finishSpeaking()
        let fx = h.say("stop")
        #expect(spoken(fx).contains("1 of 2 right."))
    }

    // @spec SESSION-END-007
    @Test func noAnswersSaysSessionEnded() {
        let h = Harness(exercises: [colourF6])
        h.start()
        let fx = h.gesture(.threeFingerSwipeDown)
        #expect(spoken(fx) == ["Session ended."])
    }

    // MARK: Asking and listening

    // @spec SESSION-EX-001, VOICE-IN-003
    @Test func listensOnlyAfterThePrompt() {
        let h = Harness(exercises: [colourF6])
        let fx = h.gesture(.tap)
        #expect(spoken(fx) == [SpokenChess.text(for: colourF6.prompt)])
        #expect(listens(fx).isEmpty)
        let after = h.send(.speechFinished, after: 2)
        #expect(listens(after) == [.exercise(.lightOrDark)])
        #expect(h.engine.state == .listening)
    }

    // @spec SESSION-EX-002
    @Test func duringThePromptOnlyPauseAndStopWork() {
        let h = Harness(exercises: [colourF6])
        h.gesture(.tap)
        #expect(h.gesture(.swipeRight).isEmpty)
        #expect(h.gesture(.twoFingerTap).isEmpty)
        #expect(h.media(.nextTrack).isEmpty)
        let pause = h.media(.playPause)
        #expect(pause.contains(.stopSpeaking))
        #expect(h.engine.state == .paused)
    }

    // @spec SESSION-EX-003
    @Test func voiceAndTouchBothAnswer() {
        let h = Harness(exercises: [colourF6, colourE4])
        h.start()
        #expect(sounds(h.gesture(.swipeLeft)) == [.right], "swipe left = dark")
        h.finishSpeaking()
        #expect(sounds(h.say("light")) == [.right])
    }

    // @spec SESSION-EX-004
    @Test func waitsWithNoTimeLimit() {
        let h = Harness(exercises: [colourF6])
        h.start()
        for _ in 0..<20 { h.send(.tick, after: 30) }
        h.finishSpeaking()
        #expect(h.engine.state == .listening)
        #expect(sounds(h.log).isEmpty)
    }

    // @spec SESSION-EX-005
    @Test func repeatsOnceAfter15SecondsOfSilence() {
        let h = Harness(exercises: [colourF6])
        h.start()
        #expect(spoken(h.send(.tick, after: 14)).isEmpty)
        let fx = h.send(.tick, after: 1.5)
        #expect(fx.contains(.stopListening))
        #expect(spoken(fx) == [SpokenChess.text(for: colourF6.prompt)])
        h.finishSpeaking()
        #expect(spoken(h.send(.tick, after: 20)).isEmpty, "only once per exercise")
    }

    // @spec SESSION-EX-006
    @Test func notUnderstoodSaysSorryAndKeepsListening() {
        let h = Harness(exercises: [colourF6])
        h.start()
        let fx = h.say("banana")
        #expect(spoken(fx) == ["Sorry?"])
        #expect(listens(h.finishSpeaking()) == [.exercise(.lightOrDark)])
    }

    // @spec SESSION-EX-007
    @Test func thirdNotUnderstoodRepeatsTheQuestion() {
        let h = Harness(exercises: [colourF6])
        h.start()
        let prompt = SpokenChess.text(for: colourF6.prompt)
        #expect(spoken(h.say("banana")) == ["Sorry?"]); h.finishSpeaking()
        // An unsure answer does not count towards the three.
        h.say(["hmm", "dark"]); h.finishSpeaking(); h.say("no"); h.finishSpeaking()
        #expect(spoken(h.say("banana")) == ["Sorry?"]); h.finishSpeaking()
        #expect(spoken(h.say("banana")) == [prompt]); h.finishSpeaking()
        #expect(spoken(h.say("banana")) == ["Sorry?"], "count starts again")
    }

    // @spec SESSION-EX-008, TOUCH-004
    @Test func repeatSpeaksThePromptWithoutRestartingTheTime() {
        let h = Harness(exercises: [colourF6, colourE4])
        h.start()
        let prompt = SpokenChess.text(for: colourF6.prompt)
        h.send(.tick, after: 2)
        #expect(spoken(h.say("repeat")) == [prompt])
        h.finishSpeaking(after: 2)
        #expect(spoken(h.gesture(.twoFingerTap)) == [prompt])
        h.finishSpeaking(after: 2)
        h.answerRight(startedAfter: 1)
        let time = h.engine.progress.ladder.estimate(.squareColour).results.last?.seconds ?? 0
        #expect(time > 7, "counted from the first prompt, not the repeat")
    }

    // MARK: Confirming

    // @spec SESSION-CONF-001
    @Test func unsureAsksAboutTheFirstCandidate() {
        let h = Harness(exercises: [twoRightOfE4])
        h.start()
        let fx = h.say(["b four", "d four"])
        #expect(spoken(fx) == ["B4?"])
        #expect(h.engine.state == .confirming)
        #expect(listens(h.finishSpeaking()) == [.exercise(.yesOrNo)])
    }

    // @spec SESSION-CONF-002
    @Test func yesOrSwipeRightTakesTheCandidate() {
        let h = Harness(exercises: [twoRightOfE4, twoRightOfE4])
        h.start()
        h.say(["g four", "d four"]); h.finishSpeaking()
        #expect(sounds(h.say("yes")) == [.right])
        h.finishSpeaking()
        h.say(["g four", "d four"]); h.finishSpeaking()
        #expect(sounds(h.gesture(.swipeRight)) == [.right])
    }

    // @spec SESSION-CONF-003
    @Test func noOrSwipeLeftAsksTheNextCandidate() {
        let h = Harness(exercises: [twoRightOfE4])
        h.start()
        h.say(["b four", "g four", "d four"]); h.finishSpeaking()
        #expect(spoken(h.say("no")) == ["G4?"])
        h.finishSpeaking()
        #expect(spoken(h.gesture(.swipeLeft)) == ["D4?"])
    }

    // @spec SESSION-CONF-004
    @Test func noToTheLastCandidateAsksAgain() {
        let h = Harness(exercises: [twoRightOfE4])
        h.start()
        h.say(["b four", "d four"]); h.finishSpeaking()
        h.say("no"); h.finishSpeaking()
        #expect(spoken(h.say("no")) == ["Say it again?"])
        #expect(listens(h.finishSpeaking()) == [.exercise(.square)])
        #expect(h.engine.state == .listening)
    }

    // @spec SESSION-CONF-005, TOUCH-012
    @Test func confirmingOnlyTakesYesOrNoButCommandsStillWork() {
        let h = Harness(exercises: [colourF6])
        h.start()
        h.say(["dark", "light"]); h.finishSpeaking()
        #expect(h.gesture(.swipeUp).isEmpty)
        #expect(h.say("light").allSatisfy { if case .play = $0 { false } else { true } }, "an exercise answer is not taken")
        h.finishSpeaking()
        #expect(spoken(h.say("repeat")) == [SpokenChess.text(for: colourF6.prompt)])
    }

    // MARK: Feedback

    // @spec SESSION-FB-001, TOUCH-005
    @Test func dontKnowIsWrongWithCorrection() {
        let h = Harness(exercises: [colourF6, colourE4])
        h.start()
        let fx = h.say("I don't know")
        #expect(sounds(fx) == [.wrong])
        #expect(spoken(fx) == [SpokenChess.correction(for: colourF6)])
        h.finishSpeaking()
        let press = h.gesture(.longPress)
        #expect(sounds(press) == [.wrong])
    }

    // @spec SESSION-FB-002
    @Test func rightAnswerPlaysSoundAndAsksNext() {
        let h = Harness(exercises: [colourF6, colourE4])
        h.start()
        let fx = h.answerRight()
        #expect(sounds(fx) == [.right])
        #expect(spoken(fx) == [SpokenChess.text(for: colourE4.prompt)])
    }

    // @spec SESSION-FB-003
    @Test func wrongAnswerPlaysSoundCorrectionThenNext() {
        let h = Harness(exercises: [colourF6, colourE4])
        h.start()
        let fx = h.answerWrong()
        #expect(sounds(fx) == [.wrong])
        #expect(spoken(fx) == [SpokenChess.correction(for: colourF6)])
        #expect(spoken(h.send(.speechFinished, after: 1)) == [SpokenChess.text(for: colourE4.prompt)])
    }

    // @spec SESSION-FB-004, STORE-SAVE-002
    @Test func resultGoesToTheLadderAndIsSaved() {
        let h = Harness(exercises: [colourF6, colourE4])
        h.start()
        let fx = h.answerRight(startedAfter: 2)
        let result = h.engine.progress.ladder.estimate(.squareColour).results.last
        #expect(result?.right == true && result?.method == .voice)
        #expect(saves(fx).count == 1)
        h.finishSpeaking()
        h.gesture(.swipeRight)
        #expect(h.engine.progress.ladder.estimate(.squareColour).results.last?.method == .touch)
    }

    // MARK: Answer time

    // @spec SESSION-TIME-001
    @Test func answerTimeRunsFromPromptEndToStartOfAnswer() throws {
        let h = Harness(exercises: [colourF6, colourE4])
        h.start()
        h.answerRight(startedAfter: 2.5)
        let seconds = try #require(h.engine.progress.ladder.estimate(.squareColour).results.last?.seconds)
        #expect(abs(seconds - 2.5) < 0.01)
        // Paused time is excluded.
        h.gesture(.twoFingerDoubleTap, after: 1)
        h.gesture(.twoFingerDoubleTap, after: 100)
        h.finishSpeaking(after: 0)
        h.answerRight(startedAfter: 2)
        let second = try #require(h.engine.progress.ladder.estimate(.squareColour).results.last?.seconds)
        #expect(second < 10)
    }

    // @spec SESSION-TIME-002
    @Test func confirmedAnswerUsesTheFirstSpokenTime() throws {
        let h = Harness(exercises: [twoRightOfE4])
        h.start()
        h.say(["g four", "d four"], startedAfter: 1.5)
        h.finishSpeaking(after: 3)
        h.say("yes", startedAfter: 2)
        let results = h.engine.progress.ladder.estimate(.directions).results
        let seconds = try #require(results.last?.seconds)
        #expect(abs(seconds - 1.5) < 0.01)
    }

    // MARK: Pause

    // @spec SESSION-PAUSE-001, TOUCH-006, AUDIO-CMD-002
    @Test func pauseByVoiceGestureOrHeadphones() {
        for pause in [{ (h: Harness) in h.say("pause") }, { $0.gesture(.twoFingerDoubleTap) }, { $0.media(.playPause) }] {
            let h = Harness(exercises: [colourF6])
            h.start()
            _ = pause(h)
            #expect(h.engine.state == .paused)
        }
    }

    // @spec SESSION-PAUSE-002
    @Test func interruptionOrDisconnectPauses() {
        let a = Harness(exercises: [colourF6]); a.start(); a.send(.interruptionBegan)
        #expect(a.engine.state == .paused)
        let b = Harness(exercises: [colourF6]); b.start(); b.send(.headphonesDisconnected)
        #expect(b.engine.state == .paused)
    }

    // @spec SESSION-PAUSE-003, VOICE-IN-003
    @Test func pauseStopsSpeechDropsConfirmationAndListensForResume() {
        let h = Harness(exercises: [twoRightOfE4])
        h.start()
        h.say(["b four", "d four"])
        let fx = h.gesture(.twoFingerDoubleTap)
        #expect(fx.contains(.stopSpeaking))
        #expect(listens(fx) == [.paused])
        let resumed = h.say("resume")
        #expect(spoken(resumed) == [SpokenChess.text(for: twoRightOfE4.prompt)], "confirmation was dropped")
    }

    // @spec SESSION-PAUSE-004, AUDIO-CMD-003
    @Test func resumeAsksTheQuestionAgainAndResetsCounters() {
        let h = Harness(exercises: [colourF6])
        h.start()
        h.send(.tick, after: 16); h.finishSpeaking()   // automatic repeat used
        h.say("banana"); h.finishSpeaking()
        h.say("banana"); h.finishSpeaking()
        h.media(.playPause)
        let fx = h.media(.previousTrack, after: 5)
        #expect(spoken(fx) == [SpokenChess.text(for: colourF6.prompt)])
        h.finishSpeaking()
        #expect(spoken(h.say("banana")) == ["Sorry?"], "Sorry count reset")
        h.finishSpeaking()
        #expect(spoken(h.send(.tick, after: 16)) == [SpokenChess.text(for: colourF6.prompt)], "automatic repeat reset")
    }

    // @spec SESSION-CONF-006
    @Test func notUnderstoodWhileConfirmingAsksTheSameCandidate() {
        let h = Harness(exercises: [twoRightOfE4])
        h.start()
        h.say(["b four", "d four"]); h.finishSpeaking()
        #expect(spoken(h.say("banana")) == ["Sorry?"])
        #expect(listens(h.finishSpeaking()) == [.exercise(.yesOrNo)])
        #expect(h.engine.state == .confirming)
        #expect(spoken(h.say("no")) == ["D4?"], "still on the first candidate until answered")
    }

    // @spec SESSION-PAUSE-006
    @Test func resumingAfterPausedFeedbackGoesToTheNextQuestion() {
        let h = Harness(exercises: [colourF6, colourE4])
        h.start()
        h.answerWrong()                          // correction being spoken
        h.gesture(.twoFingerDoubleTap)
        let fx = h.gesture(.twoFingerDoubleTap, after: 5)
        #expect(spoken(fx) == [SpokenChess.text(for: colourE4.prompt)])
    }

    // @spec SESSION-PAUSE-005
    @Test func pausedSessionCountsAsRunning() {
        let h = Harness(exercises: [colourF6])
        h.start()
        h.gesture(.twoFingerDoubleTap)
        let fx = h.media(.playPause)
        #expect(!spoken(fx).contains("Start training?"))
        #expect(spoken(fx) == [SpokenChess.text(for: colourF6.prompt)], "it resumes")
    }
}
