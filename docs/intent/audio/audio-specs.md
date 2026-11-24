# Audio — EARS specs

Design: `audio-design.md`

## Audio session

- [ ] **AUDIO-001**: While a session runs with voice input available, the app shall play and record at the same time, output to connected wired or Bluetooth headphones or otherwise the phone's loudspeaker, and use a Bluetooth headset's microphone when it has one.
- [ ] **AUDIO-002**: While a session runs with voice input off, the app's audio shall only play.
- [ ] **AUDIO-003**: When a session starts, the app shall pause other apps' audio, and when it ends, release the audio so other apps can resume straight away.

## Background

- [ ] **AUDIO-BG-001**: While a session is running and not paused, the app shall keep speaking and listening when the screen locks or the player switches app.
- [ ] **AUDIO-BG-002**: If iOS suspends the app while a session is paused, then when the app runs again the app shall restore the session, still paused, unless it has been paused for 10 minutes since the pause began, in which case the session shall end and its summary be saved without being spoken.
- [ ] **AUDIO-BG-003**: While no session is running, the app shall do no background work, except remaining the lock screen's playing app as stated in AUDIO-BG-004.
- [ ] **AUDIO-BG-004**: When a session ends, the app shall remain the lock screen's playing app for one minute, so a play command in that minute asks "Start training?", and then give up that role.

## Media commands

- [ ] **AUDIO-CMD-001**: While a session runs, the app shall show as the playing audio on the lock screen and in Control Center.
- [ ] **AUDIO-CMD-002**: When the play/pause command arrives during a session that is not paused, the app shall pause the session.
- [ ] **AUDIO-CMD-003**: When the play/pause or previous-track command arrives while the session is paused, the app shall resume it.
- [ ] **AUDIO-CMD-004**: When the next-track command arrives while the session is listening for or confirming an answer, the app shall skip the question as "I don't know".
- [ ] **AUDIO-CMD-005**: When the previous-track command arrives while the session is listening for or confirming an answer, the app shall repeat the question.
- [ ] **AUDIO-CMD-006**: When the next-track or previous-track command arrives while the session is asking, giving feedback or speaking the introduction, the app shall ignore it.
- [ ] **AUDIO-CMD-007**: When the next-track command arrives while the session is paused, the app shall ignore it.

## Interruptions and routes

- [ ] **AUDIO-INT-001**: When an audio interruption (phone call, alarm) that paused the session ends, the app shall keep the session paused.
- [ ] **AUDIO-INT-002**: When a session resumes after an interruption, the app shall ask the current question again (any confirmation in progress was dropped when the session paused).
- [ ] **AUDIO-INT-003**: When headphones are reconnected during a paused session, the app shall keep the session paused.
