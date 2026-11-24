# Session — EARS specs

Design: `session-design.md`

## Starting

- [x] **SESSION-START-001**: When the app is on screen, no session is running, the first-launch permission step is finished, and the player taps the screen, the app shall start a session (including while "Start training?" is awaiting confirmation).
- [x] **SESSION-START-002**: When no session is running and the headphones' play or play/pause command arrives, the app shall say "Start training?".
- [x] **SESSION-START-003**: When the app has asked "Start training?" and, within 10 seconds, a second play or play/pause command arrives or the player says "yes", the app shall start a session.
- [x] **SESSION-START-004**: When the app has asked "Start training?" and no confirmation arrives within 10 seconds, or any answer other than "yes" arrives, the app shall not start a session.
- [x] **SESSION-START-005**: When a session starts, the session shall pick a fresh random seed for its exercises and record it with the session.
- [x] **SESSION-START-006**: When a session starts, the session shall speak, in this order and only those that apply: the notice that progress is not being saved (newer-version progress file), then either the introduction or, when no introduction is due and voice input is off, the notice that answers are by touch; and then the first question.

## Introduction

- [x] **SESSION-INTRO-001**: When a session starts and the introduction has not yet been recorded as given, the session shall speak the introduction.
- [x] **SESSION-INTRO-002**: Where voice input is available at the session's start, the introduction shall explain answering by voice and by touch, including swipe right for light or yes and swipe left for dark or no.
- [x] **SESSION-INTRO-003**: Where voice input is off at the session's start, the introduction shall explain answering by touch only, including swipe right for light or yes and swipe left for dark or no.
- [x] **SESSION-INTRO-004**: When the introduction has been spoken to the end, the session shall record it as given.
- [x] **SESSION-INTRO-005**: If a session ends before the introduction has been spoken to the end, then the session shall give the introduction again at the start of the next session.
- [x] **SESSION-INTRO-006**: While the introduction is being spoken, the session shall ignore all input except pause and stop, and when a session paused during the introduction resumes, the session shall speak the introduction again from the beginning.

## Ending

- [x] **SESSION-END-001**: The session clock shall count only time when the session is not paused, starting when the first question begins.
- [x] **SESSION-END-002**: When the session clock reaches 7 minutes, the session shall finish the current exercise and then end.
- [x] **SESSION-END-003**: When the player says "stop" or makes the stop gesture, the session shall end at once and then speak the end-of-session summary.
- [x] **SESSION-END-004**: When a session has been paused continuously for 10 minutes, the session shall end.
- [x] **SESSION-END-005**: When a session ends with an exercise not yet answered, the session shall drop that exercise without recording a result.
- [x] **SESSION-END-006**: When a session with at least one answer ends, the session shall say how many answers were right out of how many (counting "I don't know" and skips as wrong answers), and name each drill that moved level and its new level.
- [x] **SESSION-END-007**: When a session with no answers ends, the session shall say "Session ended."

## Asking and listening

- [x] **SESSION-EX-001**: When an exercise begins, the session shall speak its prompt and start listening for an answer only once the prompt has been spoken.
- [x] **SESSION-EX-002**: While a prompt is being spoken, the session shall ignore all input except the pause and stop gestures and the headphones' play/pause command.
- [x] **SESSION-EX-003**: While listening, the session shall accept answers from voice and touch at once and use whichever completes an answer first.
- [x] **SESSION-EX-004**: While listening, the session shall wait for an answer with no time limit.
- [x] **SESSION-EX-005**: When 15 seconds have passed with no speech and no touch since the app last finished speaking during an exercise, the session shall speak the question again, at most once per exercise.
- [x] **SESSION-EX-006**: When an answer is not understood, the session shall say "Sorry?" and keep listening.
- [x] **SESSION-EX-007**: When an answer is not understood for the third time in a row within an exercise, the session shall repeat the question instead of saying "Sorry?" and start counting again from zero; unsure answers do not count towards the three.
- [x] **SESSION-EX-008**: When the player says "repeat" or makes the repeat gesture while the session is listening or confirming, the session shall speak the prompt again without restarting the answer time.

## Confirming unsure answers

- [x] **SESSION-CONF-001**: When an answer is unsure (spoken chess heard one or more possible answers but could not settle on one), the session shall ask about the first candidate by name ("b four?").
- [x] **SESSION-CONF-002**: When the player says yes, or swipes right, to a candidate, the session shall take that candidate as the answer.
- [x] **SESSION-CONF-003**: When the player says no, or swipes left, to a candidate and another candidate remains, the session shall ask about the next candidate.
- [x] **SESSION-CONF-004**: When the player says no, or swipes left, to the last candidate, the session shall say "Say it again?" and return to listening.
- [x] **SESSION-CONF-005**: While confirming, the session shall ignore answer input other than yes or no to the candidate (a spoken or touched exercise answer is not taken), while still accepting repeat, I don't know, pause and stop.

## Feedback

- [x] **SESSION-FB-001**: When the player answers "I don't know" or skips, the session shall treat it as a wrong answer, with the wrong-answer sound and the correction.
- [x] **SESSION-FB-002**: When an answer is right, the session shall play the right-answer sound and ask the next exercise.
- [x] **SESSION-FB-003**: When an answer is wrong, the session shall play the wrong-answer sound, speak the correction, and ask the next exercise.
- [x] **SESSION-FB-004**: When an answer is checked, the session shall pass to the ladder the result, whether it was answered by voice or by touch, and its answer time.

## Answer time

- [x] **SESSION-TIME-001**: The session shall measure answer time from the end of the prompt's first speaking to the start of the answer, excluding paused time; for a voice answer the start is the recognizer's time for the first word of the attempt that produced the answer, and for a touch answer it is the first touch of that answer.
- [x] **SESSION-TIME-002**: When an unsure answer is confirmed, the session shall use the start of the attempt in which the player first spoke it as the answer time.

## Pause

- [x] **SESSION-PAUSE-001**: When the player says "pause", makes the pause gesture, or the headphones' play/pause command arrives during a session that is not paused, the session shall pause at once.
- [x] **SESSION-PAUSE-002**: When an audio interruption begins or headphones disconnect during a session, the session shall pause at once.
- [x] **SESSION-PAUSE-003**: When the session pauses, it shall stop any speech in progress, drop any confirmation or touch pick in progress, and listen only for "resume" and "stop".
- [x] **SESSION-PAUSE-004**: When a paused session is resumed (by saying "resume" or "continue", the pause gesture, or the headphones' play/pause command), the session shall ask the current exercise's question again, and reset that exercise's automatic repeat and "Sorry?" count.
- [x] **SESSION-PAUSE-005**: While a session is paused, the session shall count as running, so the headphones' play/pause command resumes it rather than asking "Start training?".
