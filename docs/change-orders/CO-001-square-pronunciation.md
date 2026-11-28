# CO-001: Squares are spoken as gibberish ("aye four")

| | |
|---|---|
| Type | Bug |
| Status | Done |
| Requested | 2026-11-27 |
| Approved | 2026-11-27 |
| Completed | 2026-11-27 |
| Ticket | |

## Request

"What it says appears as gibberish — no coordinates like 'e4' but something like 'Aye nine'."

## Intent

The app should say every square the way a chess player does, its file letter's name followed by its rank: "e four", "a one". Instead the speech engine reads the pronunciation spellings it is given ("ay", "ee", "cee", "aitch") as words, so squares come out as "aye four" and similar noise. The output meets the letter of SPOKEN-OUT-001/002 but defeats their purpose: SPOKEN-OUT-002 promises spellings the engine says as letter names, and listening on a device shows no spelling does that reliably. This settles the spoken-chess open question "the exact letter text for reliable pronunciation, settled by listening on a device."

The fix separates *what* is said from *how it sounds*. Spoken chess writes a square as its capital letter and rank digit ("E4"), which is also the right text to display. It also owns one table giving each file letter's name in IPA. The voice applies that IPA to each standalone capital A–H, so the engine is told the exact sounds instead of guessing. IPA is engine-independent: the planned Polly voice can use the same table through SSML `<phoneme>`.

## Predicted Impact

### HLD

None. Speech output and the core/iOS split stay as described.

### LLDs

| Component | Section | Change |
|---|---|---|
| `spoken-chess` | Speaking squares and prompts | A square is written as its capital file letter and rank digit ("E4"). Spoken chess keeps one table of each file letter's name in IPA, for the voice to apply. |
| `spoken-chess` | Decisions & Alternatives | Add row: letter pronunciation by IPA table, against pronunciation spellings ("ay four") and bare letters left to the engine. Spellings were read as words on a device; bare letters are read as words in some contexts ("A" as the article). |
| `spoken-chess` | Open Questions | Remove "the exact letter text for reliable pronunciation" as settled. |
| `voice` | Speech output | When speaking, the voice gives each standalone capital letter A–H the IPA pronunciation from spoken chess, using the speech framework's IPA notation attribute. |

### Specs

| ID | Action | Text (new or revised) |
|---|---|---|
| `SPOKEN-OUT-001` | Revise | When speaking a square, spoken chess shall produce the capital file letter followed by its rank digit (for example "A4" for a4, "E4" for e4). |
| `SPOKEN-OUT-002` | Delete | (the table of pronunciation spellings) |
| `SPOKEN-OUT-005` | Add | Spoken chess shall keep one table giving each file letter's name in IPA (for example /eɪ/ for A, /iː/ for E, /eɪtʃ/ for H), and shall give, for any phrase, the ranges of its standalone capital letters A–H with each one's IPA. |
| `VOICE-OUT-005` | Add | When speaking a phrase, voice shall mark each standalone capital letter A–H with its IPA pronunciation from spoken chess, so the speech engine says the letter's name. |

### Tests

| File | Action | Specs covered |
|---|---|---|
| `HearChessCore/Tests/HearChessCoreTests/SpokenChessTests.swift` | Change | `SPOKEN-OUT-001` (expected text becomes "A4", "E4", …); add tests for `SPOKEN-OUT-005`: every file letter has IPA, letters inside words ("Dark", "Correct") and lowercase are not marked, "A1 to H8" marks two letters |
| `HearChessCore/Tests/HearChessCoreTests/SessionEngineTests.swift` | Change | Expected phrases "Bee four?", "Gee four?", "Dee four?" become "B4?", "G4?", "D4?" |
| `HearChessCore/Tests/HearChessCoreTests/SessionInputAndAudioTests.swift` | Change | "Gee four." becomes "G4."; touch-pick phrases "File, ee.", "Ef.", "Gee." become "File, E.", "F.", "G." (found during the work) |

The voice has no test target (it wraps `AVSpeechSynthesizer`); `VOICE-OUT-005` is checked by ear, like the other VOICE-OUT specs.

### Code

| File | Action | What changes |
|---|---|---|
| `HearChessCore/Sources/HearChessCore/SpokenChess.swift` | Change | `speak(_:)` writes the capital letter; `letterPronunciation` spelling table replaced by an IPA table and a function returning letter ranges with IPA; doc comments updated |
| `HearChessApp/Sources/Speaker.swift` | Change | Builds the utterance from an attributed string, setting `AVSpeechSynthesisIPANotationAttribute` on each range spoken chess returns |

### Other

Rebuild and install on the iPhone with `run-on-iphone.sh`. This CO also introduces `docs/change-orders/` to the project.

## Cross-Segment Effects

- `voice`: absorbs one new spec and a small change to how an utterance is built. It depends on spoken chess's IPA table, the same direction the app already depends on the core.
- `session`: none in behaviour; only expected strings in its tests change, because they quote spoken-chess output.

## Decisions Needed

1. **Letter case in the text.** Recommended: capital letters ("E4"), as in written notation for the board's subtitles, and easy to find without touching words like "Dark". Alternative: lowercase, which matches algebraic notation ("e4") but collides with the article "a" when scanning for letters.
2. **Rank as a number word or a digit.** Recommended at proposal: keep number words. Revised by the requester after seeing the text on the device: digits, as in notation ("H1 to A8").

## Risks and Edge Cases

- **A capital A–H that is not a square letter**, such as a sentence starting with "A" as the article. Guard: no current template starts a phrase with the article; the test for `SPOKEN-OUT-005` runs every template and checks that only square letters are marked.
- **The engine ignores IPA for some voices.** Guard: the IPA attribute is honoured by Apple's voices from iOS 16; the device check covers the default and enhanced voices. If a voice ignores it, the capital letter alone is still the best fallback text.
- **IPA symbols chosen wrongly.** Guard: checked by ear on the device for all eight letters.

## Verification

- `swift test` in `HearChessCore`: all tests pass, including the revised and new spoken-chess tests.
- On the iPhone: a session where every file letter A–H is heard, each said as its letter name, with confirmations ("B4?") and corrections ("G4.") included.

---

## Outcome

### Predicted vs Actual

| Level | Predicted | Actual | Notes |
|---|---|---|---|
| HLD | 0 changes | 0 changes | |
| LLDs | 4 sections | 4 sections | Spoken chess also gained the IPA table in its body |
| Specs | +2 ~1 −1 | +2 ~1 −1 | |
| Tests | 3 files | 3 files | One more group of expected strings than predicted (touch pick) |
| Code | 2 files | 2 files | |

### Surprises

- On seeing "H one to A eight" on the device, the requester asked for notation digits ("H1 to A8"). Decision 2 was reversed: `SPOKEN-OUT-001` now gives the rank digit, and the design's decision row records why. The voice still marks the letter with IPA and reads the digit as a number.
- Touch square-picking speaks file letters on their own ("File, E.", "F."). The prediction listed only phrases built by spoken chess's templates; the session engine also speaks single files through `spokenFile`. That function now gives the capital letter, which the voice pronounces through the same IPA marks, and three expected strings in the touch tests changed.
- `ProgressStoreTests.swift` fails to compile on this branch: it holds tests for the progress store's session history, committed failing in `bae9b2d` and not yet implemented. It is outside this change; the suite was run with that file set aside.

### Commits

| Hash | Message |
|---|---|

### Measurements

| | |
|---|---|
| Tests before → after | unit 161 → 163 (ProgressStore tests excluded, see Surprises) |
| Lines changed | +47 −11 (code), +54 −34 (tests), +22 −13 (docs) |
| Agent time | |
| Installed on iPhone | 2026-11-27 |
