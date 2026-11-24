# Touch — EARS specs

Design: `touch-design.md`

## Gestures

- [ ] **TOUCH-001**: The app shall accept every training gesture anywhere on the screen, with no on-screen buttons needed during training.
- [x] **TOUCH-002**: When the player swipes right while the session is listening for an answer, the app shall answer light to a light-or-dark question and yes to a yes-or-no question.
- [x] **TOUCH-003**: When the player swipes left while the session is listening for an answer, the app shall answer dark to a light-or-dark question and no to a yes-or-no question.
- [x] **TOUCH-004**: When the player makes a two-finger tap while the session is listening or confirming, the app shall repeat the question.
- [x] **TOUCH-005**: When the player makes a long press while the session is listening, confirming or picking a square, the app shall answer "I don't know", abandoning any pick in progress.
- [x] **TOUCH-006**: When the player makes a two-finger double-tap at any point in a running session, the app shall pause the session, or resume it if paused.
- [x] **TOUCH-007**: When the player makes a three-finger swipe down at any point in a running session, the app shall stop the session.
- [x] **TOUCH-008**: When a gesture has no meaning at the current moment, the app shall ignore it.
- [ ] **TOUCH-009**: The app shall recognize a two-finger tap only after ruling out a two-finger double-tap.
- [ ] **TOUCH-010**: While a session is running, the app shall ask the system to defer its screen-edge gestures, so that a first swipe starting near an edge reaches the app.
- [ ] **TOUCH-011**: While VoiceOver is on, the training surface shall pass gestures directly to the app, so the training gestures work the same as with VoiceOver off.
- [x] **TOUCH-012**: While the session is confirming an unsure answer, the app shall treat swipe right as yes and swipe left as no to the candidate being asked about, and ignore swipes up and down.

## Picking a square

- [x] **TOUCH-SQ-001**: When a square answer is awaited and the player swipes up or down with no pick in progress, the app shall start a pick: say "file, e" and start the file choice at e, without that swipe moving the choice.
- [x] **TOUCH-SQ-002**: While picking a file or rank, the app shall move to the next choice on a swipe up and to the previous one on a swipe down, speaking each choice as it is reached.
- [x] **TOUCH-SQ-003**: If the player swipes past a or h while picking a file, or past 1 or 8 while picking a rank, then the app shall stay on the end choice and play a short bump sound.
- [x] **TOUCH-SQ-004**: When the player double-taps while picking a file, the app shall choose that file, say "rank, four" and start the rank choice at 4.
- [x] **TOUCH-SQ-005**: When the player double-taps while picking a rank, the app shall take the chosen square as the answer directly, without a confirmation step, and speak it back ("g four").
- [x] **TOUCH-SQ-006**: While picking a square, the app shall ignore left and right swipes.
- [x] **TOUCH-SQ-007**: When the player makes a two-finger tap while picking a square, the app shall repeat the question and restart the pick from the file choice.
- [x] **TOUCH-SQ-008**: When a voice answer arrives while the player is picking a square by touch, the app shall use the voice answer and abandon the pick.

## Screen

- [ ] **TOUCH-SCR-001**: While a session runs with voice input off, the app shall keep the screen awake and lower its brightness to the minimum.
- [ ] **TOUCH-SCR-002**: While a session runs with voice input available, the app shall let the screen lock as normal.
- [ ] **TOUCH-SCR-003**: When a session ends, the app shall let the screen lock as normal again and restore the brightness it had before the app lowered it.
