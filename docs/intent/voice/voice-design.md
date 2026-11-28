---
parent: high-level-design
prefix: VOICE
---

# Voice

## Context and Design Philosophy

Voice is the app's mouth and ears: iOS speech synthesis for output and iOS speech recognition for input. It does no chess: it speaks the text spoken chess gives it, and hands what it hears back to spoken chess as text. It is a thin iOS-layer wrapper whose job is to make Apple's speech services dependable for short, frequent exchanges.

## Speaking

Speech uses `AVSpeechSynthesizer` with the highest-quality installed English voice (premium, then enhanced, then default), preferring the phone's own English variant among voices of equal quality, at 0.9 times the framework's default rate so square names are easy to follow. Before speaking a phrase, voice marks each standalone capital letter A–H with the IPA that spoken chess gives for it, using the framework's IPA notation attribute, so the engine says the letter's name instead of reading it as a word. Voice reports when an utterance finishes, so the session knows when to start listening. Speaking can be stopped immediately, for pause and stop.

## Listening

Listening uses `SFSpeechRecognizer` for English with on-device recognition required, so it works offline and audio never leaves the phone. English is used whatever the phone's own language is.

Voice listens in three situations, and never while the app itself is speaking:

- while the session is listening for or confirming an answer;
- while a session is paused, for "resume" and "stop" only;
- while "Start training?" waits for confirmation, for yes or no.

Each listening window is its own recognition request, given the words allowed at that moment as contextual hints so the recognizer favours them.

Voice decides an answer is finished after a short pause in speech (a setting, 0.8 seconds by default). It then gives spoken chess the recognizer's alternative transcriptions, best first, together with the recognizer's time for the first word. A result containing only filler is not understood.

If a recognition request ends or fails while an answer is still awaited, voice starts a new one without saying anything. A request that ends because nobody spoke is normal. Only errors reported by the recognizer count as failures, and any recognized speech resets the count. After three failures in a row within one exercise, voice input is off for the rest of the session: the app says once that answers are by touch, and the touch-only behaviour, including keeping the screen awake, applies until the session ends. The next session checks again.

## Permissions and availability

The app needs microphone and speech-recognition permission. It asks for them the first time it opens, before any session, after a one-sentence spoken explanation of why. This is the one step that needs the screen, and taps do not start a session until it is finished.

At the start of every session, voice checks again whether both permissions are granted and English on-device recognition is available. If not, voice input is off for that session, it runs with touch only, and the start of the session says so.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| Recognition engine | Apple's on-device `SFSpeechRecognizer` | Server recognition; a bundled open-source model | On-device keeps the app offline and private, as the HLD requires, and needs no extra model in the app. |
| Recognition language | English, regardless of the phone's language | The phone's language | The app speaks and understands chess in English; a phone set to another language would otherwise lose voice input. |
| Several transcriptions per answer | Pass all alternatives to spoken chess | Only the best transcription | The alternatives are how spoken chess notices "b four" versus "d four" and asks instead of guessing. |
| End of answer | Short pause after speech | A fixed listening window; a wake word | Answers are a word or two; ending on a pause feels immediate. |
| Recognition failures | Restart silently; touch only after three in a row | Report every failure | Failures are usually transient; announcing each would interrupt training. Repeated failures mean voice is not working, and the player should know. |
| Asking for permissions | At first launch, before any session | At the start of the first session | System permission prompts need the screen; doing them once at setup keeps every session eyes-free. |
| No voice permission | Continue with touch only | Refuse to start | Touch is a complete way to answer; a player who declines the microphone can still train. |

## Open Questions & Future Decisions

### Deferred
1. The end-of-answer pause length, tuned on a device.
2. Whether the app's own speech is picked up by the microphone when playing through the speaker, and whether voice processing (echo cancellation) is needed.
