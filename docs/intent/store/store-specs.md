# Store — EARS specs

Design: `store-design.md`

## Contents

- [ ] **STORE-001**: The store shall keep each drill's skill estimate: its level and its recent results at that level (at most 20).
- [ ] **STORE-002**: The store shall keep a summary of each of the last 100 sessions: start date and time, unpaused length in seconds, seed, right answers, total answers (counting "I don't know" and skips) and drills that moved level.
- [ ] **STORE-003**: When a session ends, for any reason, the store shall save its summary.
- [ ] **STORE-004**: When the introduction has been given, the store shall save that fact at once.
- [ ] **STORE-005**: The store's data types shall be defined in the training core and be encodable and decodable without iOS frameworks.

## Saving

- [ ] **STORE-SAVE-001**: The store shall keep progress in one JSON file in the app's Application Support folder, recording a format version.
- [ ] **STORE-SAVE-002**: When an exercise has been answered (including "I don't know" and skips), the store shall save progress.
- [ ] **STORE-SAVE-003**: When saving, the store shall write a new file and replace the old one in one step.
- [ ] **STORE-SAVE-004**: The store shall perform saves one at a time, in the order they were requested.
- [ ] **STORE-SAVE-005**: If a save fails, then the store shall keep the progress in memory and write it with the next save.

## Loading

- [ ] **STORE-LOAD-001**: When the app starts, the store shall load progress from the file.
- [ ] **STORE-LOAD-002**: When the file has an older format version, the store shall convert it to the current format and save it.
- [ ] **STORE-LOAD-003**: When the file has a newer format version than the app understands, the store shall leave it untouched, start with fresh progress, and save nothing while the app runs, overriding every other rule that saves.
- [ ] **STORE-LOAD-004**: While progress is not being saved because of a newer-version file, the app shall say so once at the start of each session.
- [ ] **STORE-LOAD-005**: If the file can be read but its contents cannot be decoded, then the store shall rename it with the current date and time, keep it, and start with fresh progress.
- [ ] **STORE-LOAD-006**: When the store keeps a renamed unreadable copy and more than three such copies exist, the store shall delete the oldest until three remain.
- [ ] **STORE-LOAD-007**: When a drill has no skill estimate in the loaded progress, the store shall start it at level 1.
- [ ] **STORE-LOAD-008**: When no progress file exists, the store shall start with fresh progress.
- [ ] **STORE-LOAD-009**: If the file exists but cannot be opened (for example, the phone's protected data is not yet available), then the store shall leave it untouched, save nothing, and load it again when it becomes available.
