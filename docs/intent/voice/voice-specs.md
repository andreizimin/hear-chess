# Voice — EARS specs

Design: `voice-design.md`

## Speaking

- [ ] **VOICE-OUT-001**: Voice shall speak with the best installed English voice, preferring an enhanced or premium voice when one is installed.
- [ ] **VOICE-OUT-002**: Voice shall speak at 90% of the system's default speech rate.
- [ ] **VOICE-OUT-003**: When an utterance finishes, voice shall report that it has finished.
- [ ] **VOICE-OUT-004**: When asked to stop speaking, voice shall stop the current utterance at once.

## Listening

- [ ] **VOICE-IN-001**: Voice shall recognize speech in English using on-device recognition only, whatever the phone's language.
- [ ] **VOICE-IN-002**: When listening for an answer, voice shall give the recognizer the words accepted for the current answer kind as contextual hints.
- [ ] **VOICE-IN-003**: Voice shall listen only while the session is listening for or confirming an answer, and never while the app is speaking.
- [ ] **VOICE-IN-004**: When about 0.8 seconds of silence follow recognized speech, voice shall treat the answer as finished.
- [ ] **VOICE-IN-005**: When an answer is finished, voice shall pass all of the recognizer's alternative transcriptions to spoken chess, best first, with the time the player started speaking.
- [ ] **VOICE-IN-006**: If a recognition request ends or fails while an answer is still awaited, then voice shall start a new request without saying anything.
- [ ] **VOICE-IN-007**: If recognition fails three times in a row within one exercise, then voice shall turn voice input off for the rest of the session and the app shall say once that answers are by touch.

## Permissions and availability

- [ ] **VOICE-PERM-001**: When the app opens for the first time, before any session, the app shall speak a one-sentence explanation and then ask for microphone and speech-recognition permission.
- [ ] **VOICE-PERM-002**: If microphone or speech-recognition permission is refused, or English on-device recognition is not available, then voice input shall be off.
- [ ] **VOICE-PERM-003**: When a session starts while voice input is off, the app shall say that answers are by touch.
