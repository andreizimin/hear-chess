# Audio — EARS specs

Design: `audio-design.md`

## Audio session

- [ ] **AUDIO-001**: While a session runs with voice input available, the app shall play and record at the same time, route to connected headphones or otherwise the speaker, and support Bluetooth headsets with a microphone.
- [ ] **AUDIO-002**: While a session runs with voice input off, the app's audio shall only play.
- [ ] **AUDIO-003**: When a session starts, the app shall pause other apps' audio, and when it ends, let them resume.

## Background

- [ ] **AUDIO-BG-001**: While a session is running, the app shall keep speaking and listening when the screen locks or the player switches app.
- [ ] **AUDIO-BG-002**: If iOS suspends the app while a session is paused, then the app shall keep the session's state and continue it when the app runs again, unless the session has been paused for 10 minutes.
- [ ] **AUDIO-BG-003**: While no session is running, the app shall do no background work.
- [ ] **AUDIO-BG-004**: When a session ends, the app shall remain the lock screen's playing app for one minute and then give up that role.

## Media commands

- [ ] **AUDIO-CMD-001**: While a session runs, the app shall show as the playing audio on the lock screen and in Control Center.
- [ ] **AUDIO-CMD-002**: When the play/pause command arrives during a session that is not paused, the app shall pause the session.
- [ ] **AUDIO-CMD-003**: When the play/pause or previous-track command arrives while the session is paused, the app shall resume it.
- [ ] **AUDIO-CMD-004**: When the next-track command arrives while the session is listening for or confirming an answer, the app shall skip the question as "I don't know".
- [ ] **AUDIO-CMD-005**: When the previous-track command arrives while the session is listening for or confirming an answer, the app shall repeat the question.
- [ ] **AUDIO-CMD-006**: When the next-track or previous-track command arrives while the session is asking or giving feedback, the app shall ignore it.
- [ ] **AUDIO-CMD-007**: When the next-track command arrives while the session is paused, the app shall ignore it.

## Interruptions and routes

- [ ] **AUDIO-INT-001**: When an audio interruption (phone call, alarm) ends during a paused session, the app shall keep the session paused.
- [ ] **AUDIO-INT-002**: When a session resumes after an interruption, the app shall drop any confirmation in progress and ask the current question again.
- [ ] **AUDIO-INT-003**: When headphones are reconnected during a paused session, the app shall keep the session paused.
