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

Listening uses `SFSpeechRecognizer` with on-device recognition required, so it works offline and audio never leaves the phone. Each answer window is its own recognition request. The request is given the words the current answer kind accepts as contextual hints, which makes the recognizer favour chess words.

Voice reports partial results as they arrive and decides an answer is finished after a short pause in speech (about 0.8 seconds). It then gives spoken chess the recognizer's alternative transcriptions, not only the best one.

## Permissions

The app needs microphone and speech-recognition permission. They are requested when the player first starts a session. When either is refused, or on-device recognition is not available for the phone's language, voice input is off: the app says once that answers are by touch, and the session continues with touch only.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| Recognition engine | Apple's on-device `SFSpeechRecognizer` | Server recognition; a bundled open-source model | On-device keeps the app offline and private, as the HLD requires, and needs no extra model in the app. |
| Several transcriptions per answer | Pass all alternatives to spoken chess | Only the best transcription | The alternatives are how spoken chess notices "b four" versus "d four" and asks instead of guessing. |
| End of answer | Short pause after speech | A fixed listening window; a wake word | Answers are a word or two; ending on a pause feels immediate. |
| No voice permission | Continue with touch only | Refuse to start | Touch is a complete way to answer; a player who declines the microphone can still train. |

## Open Questions & Future Decisions

### Deferred
1. The end-of-answer pause length, tuned on a device.
2. Whether the app's own speech is picked up by the microphone when playing through the speaker, and whether voice processing (echo cancellation) is needed.
