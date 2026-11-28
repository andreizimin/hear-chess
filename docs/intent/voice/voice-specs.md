# Voice — EARS specs

Design: `voice-design.md`

## Speaking

- [ ] **VOICE-OUT-001**: Voice shall speak with the highest-quality installed English voice (premium, then enhanced, then default), preferring among equal-quality voices the English variant of the phone's region.
- [ ] **VOICE-OUT-002**: Voice shall speak at 0.9 times the speech framework's default speech rate (`AVSpeechUtteranceDefaultSpeechRate`).
- [ ] **VOICE-OUT-003**: When an utterance finishes, voice shall report that it has finished.
- [ ] **VOICE-OUT-004**: When asked to stop speaking, voice shall stop the current utterance at once.
- [ ] **VOICE-OUT-005**: When speaking a phrase, voice shall mark each standalone capital letter A–H with its IPA pronunciation from spoken chess, so the speech engine says the letter\'s name.

## Listening

- [ ] **VOICE-IN-001**: Voice shall recognize speech in English using on-device recognition only, whatever the phone's language.
- [ ] **VOICE-IN-002**: When listening, voice shall give the recognizer the words allowed at that moment as contextual hints.
- [ ] **VOICE-IN-003**: Voice shall listen only while the session is listening for or confirming an answer, while a session is paused (for "resume" and "stop"), and while "Start training?" awaits confirmation (for yes or no), and never while the app is speaking.
- [ ] **VOICE-IN-004**: When the end-of-answer pause (a setting, 0.8 seconds by default) follows recognized speech, voice shall treat the answer as finished.
- [ ] **VOICE-IN-005**: When an answer is finished, voice shall pass all of the recognizer's alternative transcriptions to spoken chess, best first, with the recognizer's time for the first word.
- [ ] **VOICE-IN-006**: If a recognition request ends or fails while an answer is still awaited, then voice shall start a new request without saying anything.
- [ ] **VOICE-IN-007**: If the recognizer reports an error three times in a row within one exercise, with no speech recognized in between, then voice shall turn voice input off for the rest of the session and the app shall say once that answers are by touch; a request that ends because no speech was heard is not an error.
- [ ] **VOICE-IN-008**: When voice input is turned off during a session, the voice-off behaviours (touch-only answering and keeping the screen awake) shall apply from then until the session ends.

## Permissions and availability

- [ ] **VOICE-PERM-001**: When the app opens for the first time, before any session, the app shall speak a one-sentence explanation and then ask for microphone and speech-recognition permission; until this step is finished, taps do not start a session.
- [ ] **VOICE-PERM-002**: If microphone or speech-recognition permission is refused, or English on-device recognition is not available, then voice input shall be off.
- [ ] **VOICE-PERM-004**: When a session starts, the app shall check permissions and on-device recognition again to decide whether voice input is available for that session.
