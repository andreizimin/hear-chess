---
parent: high-level-design
prefix: STORE
---

# Store

## Context and Design Philosophy

The store keeps the player's progress on the phone: the ladder's skill estimates and a short history of sessions. There is no account and no server. The data is small, so the store favours being simple and safe over being clever.

## What is stored

- The ladder's skill estimate for every drill: its level and its recent results at that level (at most 20, as the ladder keeps them).
- One summary for each of the last 100 sessions: date, length, seed, right and total answers, and drills that moved level. A summary is written whenever a session ends, however it ended. A session cut short by the app being force-quit has no summary, but its answered exercises are already saved.
- Whether the first-session introduction has been given, saved as soon as it has.

The data structures are defined in the training core and are encodable, so saving and loading can be tested without a device.

## Saving and loading

Progress is one file in the app's Application Support folder, which is included in the phone's normal backups. It is saved after every answered exercise, by writing a new file and replacing the old one in one step, so a crash or force-quit never leaves a half-written file. Saves happen one at a time, in order. If a save fails (for example, the phone is full), the progress stays in memory and is written by the next save.

It is loaded when the app starts:

- **Same version** — used as is.
- **Older version** — converted to the current format and saved in it.
- **Newer version** than the app understands — left untouched. The app trains with fresh progress but saves nothing for as long as it runs, and says so once at the start of each session.
- **Unreadable** — renamed with the date and time and kept, and the app starts with fresh progress. At most three such copies are kept; the oldest is deleted first.

A drill that has no skill estimate in the file starts at level 1.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| Storage | One JSON file | SwiftData / Core Data; SQLite | A few kilobytes of data with no queries; a file is simplest, transparent and fully testable in the core. |
| When to save | After every answered exercise | At the end of each session | A session interrupted in the background loses nothing. |
| Newer-version file | Keep it and save nothing this run | Overwrite it; refuse to start | Never destroys progress a newer app wrote, while still letting the player train. |
| Unreadable file | Keep up to three dated copies, start fresh | Delete it; refuse to start | A later fix could still recover the progress, without letting copies pile up. |
| History length | The last 100 sessions | Everything | Keeps the file to a few kilobytes; older sessions are not used by anything. |
| Backups | Rely on the phone's own backup | iCloud sync | Keeps the no-account, on-device design; normal backups already include Application Support. |
