# Touch — EARS specs

Design: `touch-design.md`

## Gestures

- [ ] **TOUCH-001**: The app shall accept every training gesture anywhere on the screen, with no on-screen buttons needed during training.
- [ ] **TOUCH-002**: When the player swipes right during a light-or-dark question, the app shall answer light; during a yes-or-no question, yes.
- [ ] **TOUCH-003**: When the player swipes left during a light-or-dark question, the app shall answer dark; during a yes-or-no question, no.
- [ ] **TOUCH-004**: When the player makes a two-finger tap during a session, the app shall repeat the question.
- [ ] **TOUCH-005**: When the player makes a long press while an answer is awaited, the app shall answer "I don't know".
- [ ] **TOUCH-006**: When the player makes a two-finger double-tap during a session, the app shall pause the session, or resume it if paused.
- [ ] **TOUCH-007**: When the player makes a three-finger swipe down during a session, the app shall stop the session.
- [ ] **TOUCH-008**: When a gesture has no meaning at the current moment, the app shall ignore it.
- [ ] **TOUCH-009**: The app shall recognize a two-finger tap only after ruling out a two-finger double-tap.
- [ ] **TOUCH-010**: While a session is running, the app shall ask the system to defer its edge gestures so swipes near an edge reach the app.
- [ ] **TOUCH-011**: While VoiceOver is on, the training surface shall pass gestures directly to the app, so the training gestures work the same as with VoiceOver off.

## Picking a square

- [ ] **TOUCH-SQ-001**: When a square answer is awaited and the player swipes up or down with no pick in progress, the app shall start a pick: say "file, e" and start the file choice at e, without that swipe moving the choice.
- [ ] **TOUCH-SQ-002**: While picking a file or rank, the app shall move to the next choice on a swipe up and to the previous one on a swipe down, speaking each choice as it is reached.
- [ ] **TOUCH-SQ-003**: If the player swipes past a or h while picking a file, or past 1 or 8 while picking a rank, then the app shall stay on the end choice and play a short bump sound.
- [ ] **TOUCH-SQ-004**: When the player double-taps while picking a file, the app shall choose that file, say "rank, four" and start the rank choice at 4.
- [ ] **TOUCH-SQ-005**: When the player double-taps while picking a rank, the app shall take the chosen square as the answer and speak it back ("g four").
- [ ] **TOUCH-SQ-006**: While picking a square, the app shall ignore left and right swipes.
- [ ] **TOUCH-SQ-007**: When the player makes a two-finger tap while picking a square, the app shall repeat the question and restart the pick from the file choice.
- [ ] **TOUCH-SQ-008**: When a voice answer arrives while the player is picking a square by touch, the app shall use the voice answer and abandon the pick.

## Screen

- [ ] **TOUCH-SCR-001**: While a session runs with voice input off, the app shall keep the screen awake and dimmed.
- [ ] **TOUCH-SCR-002**: While a session runs with voice input available, the app shall let the screen lock as normal.
- [ ] **TOUCH-SCR-003**: When a session ends, the app shall let the screen lock as normal again.
