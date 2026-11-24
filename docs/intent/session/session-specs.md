# Session — EARS specs

Design: `session-design.md`

## Starting

- [ ] **SESSION-START-001**: When the app is on screen, no session is running, and the player taps the screen, the app shall start a session.
- [ ] **SESSION-START-002**: When no session is running and the headphones' play command arrives, the app shall say "Start training?".
- [ ] **SESSION-START-003**: When the app has asked "Start training?" and a second play command arrives within 10 seconds, or the player says "yes", the app shall start a session.
- [ ] **SESSION-START-004**: When the app has asked "Start training?" and no confirmation arrives within 10 seconds, or any other answer arrives, the app shall not start a session.
- [ ] **SESSION-START-005**: When a session starts, the session shall pick a fresh random seed for its exercises and record it with the session.

## Introduction

- [ ] **SESSION-INTRO-001**: When the player's first session starts, the session shall speak the introduction before the first question.
- [ ] **SESSION-INTRO-002**: Where voice input is available, the introduction shall explain answering by voice and by touch, including swipe right for light or yes and swipe left for dark or no.
- [ ] **SESSION-INTRO-003**: Where voice input is off, the introduction shall explain answering by touch only, including swipe right for light or yes and swipe left for dark or no.
- [ ] **SESSION-INTRO-004**: When the introduction has been spoken to the end, the session shall record it as given.
- [ ] **SESSION-INTRO-005**: If a session ends before the introduction has been spoken to the end, then the session shall give the introduction again at the start of the next session.

## Ending

- [ ] **SESSION-END-001**: The session clock shall count only time when the session is not paused.
- [ ] **SESSION-END-002**: When the session clock reaches 7 minutes, the session shall finish the current exercise and then end.
- [ ] **SESSION-END-003**: When the player says "stop" or makes the stop gesture, the session shall end at once.
- [ ] **SESSION-END-004**: When a session has been paused for 10 minutes, the session shall end.
- [ ] **SESSION-END-005**: When a session ends with an exercise not yet answered, the session shall drop that exercise without recording a result.
- [ ] **SESSION-END-006**: When a session with at least one answer ends, the session shall say how many answers were right out of how many, and name each drill that moved level and its new level.
- [ ] **SESSION-END-007**: When a session with no answers ends, the session shall say "Session ended."

## Asking and listening

- [ ] **SESSION-EX-001**: When an exercise begins, the session shall speak its prompt and start listening only once the prompt has been spoken.
- [ ] **SESSION-EX-002**: While a prompt is being spoken, the session shall ignore all input except pause and stop.
- [ ] **SESSION-EX-003**: While listening, the session shall accept answers from voice and touch at once and use whichever completes an answer first.
- [ ] **SESSION-EX-004**: While listening, the session shall wait for an answer with no time limit.
- [ ] **SESSION-EX-005**: When 15 seconds have passed in silence since the app last spoke during an exercise, the session shall say "Repeat?", at most once per exercise.
- [ ] **SESSION-EX-006**: When an answer is not understood, the session shall say "Sorry?" and keep listening.
- [ ] **SESSION-EX-007**: When an answer is not understood for the third time in a row within an exercise, the session shall repeat the question instead of saying "Sorry?".
- [ ] **SESSION-EX-008**: When the player says "repeat" or makes the repeat gesture, the session shall speak the prompt again without restarting the answer time.

## Confirming unsure answers

- [ ] **SESSION-CONF-001**: When an answer is unsure (spoken chess heard two or more possible answers), the session shall ask about the first candidate by name ("b four?").
- [ ] **SESSION-CONF-002**: When the player says yes to a candidate, the session shall take that candidate as the answer.
- [ ] **SESSION-CONF-003**: When the player says no to a candidate and another candidate remains, the session shall ask about the next candidate.
- [ ] **SESSION-CONF-004**: When the player says no to the last candidate, the session shall say "Say it again?" and return to listening.
- [ ] **SESSION-CONF-005**: When a touch answer arrives while confirming, the session shall take the touch answer as the answer.

## Feedback

- [ ] **SESSION-FB-001**: When the player answers "I don't know" or skips, the session shall treat it as a wrong answer.
- [ ] **SESSION-FB-002**: When an answer is right, the session shall play the right-answer sound and ask the next exercise.
- [ ] **SESSION-FB-003**: When an answer is wrong, the session shall play the wrong-answer sound, speak the correction, and ask the next exercise.
- [ ] **SESSION-FB-004**: When an answer is checked, the session shall pass the result, how it was answered and its answer time to the ladder.

## Answer time

- [ ] **SESSION-TIME-001**: The session shall measure answer time from the end of the prompt's first speaking to the moment the player began giving the answer (start of the spoken answer, or first touch of it), excluding paused time.
- [ ] **SESSION-TIME-002**: When an unsure answer is confirmed, the session shall use the time at which the player first spoke it as the answer time.

## Pause

- [ ] **SESSION-PAUSE-001**: When the player says "pause", makes the pause gesture or the headphones' play/pause command arrives during a session, the session shall pause at once.
- [ ] **SESSION-PAUSE-002**: When an audio interruption begins or headphones disconnect during a session, the session shall pause at once.
- [ ] **SESSION-PAUSE-003**: When the session pauses, it shall stop any speech in progress and stop listening.
- [ ] **SESSION-PAUSE-004**: When a paused session is resumed, the session shall ask the current exercise's question again.
