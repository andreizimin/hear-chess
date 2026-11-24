---
parent: high-level-design
prefix: VOICE
---

# Voice

## Context and Design Philosophy

Voice is the app's mouth and ears: iOS speech synthesis for output and iOS speech recognition for input. It does no chess: it speaks the text spoken chess gives it, and hands what it hears back to spoken chess as text. It is a thin iOS-layer wrapper whose job is to make Apple's speech services dependable for short, frequent exchanges.

## Speaking

Speech uses `AVSpeechSynthesizer` with the best installed English voice (an enhanced or premium voice when present), at a slightly slower rate than the default so square names are easy to follow. Voice reports when an utterance finishes, so the session knows when to start listening. Speaking can be stopped immediately, for pause and stop.

## Listening

Listening uses `SFSpeechRecognizer` for English with on-device recognition required, so it works offline and audio never leaves the phone. English is used whatever the phone's own language is.

Each answer window is its own recognition request, given the words the current answer kind accepts as contextual hints so the recognizer favours chess words. Listening runs only while the session is listening or confirming; it is stopped while the app speaks.

Voice decides an answer is finished after a short pause in speech (about 0.8 seconds). It then gives spoken chess the recognizer's alternative transcriptions, best first, together with the time the player started speaking, taken from the recognizer's timing of the first word. A result containing only filler is not understood.

If a recognition request ends or fails while the session is still waiting for an answer, voice starts a new one without saying anything. After three failures in a row within one exercise, voice input is off for the rest of the session and the app says once that answers are by touch.

## Permissions and availability

The app needs microphone and speech-recognition permission. It asks for them the first time it opens, before any session, after a one-sentence spoken explanation of why. This is the one step that needs the screen.

Voice input is off when either permission is refused or English on-device recognition is not available on the phone. The session then runs with touch only, and the introduction and the start of each session say so.

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
