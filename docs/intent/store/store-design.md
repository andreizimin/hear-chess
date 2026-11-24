---
parent: high-level-design
prefix: STORE
---

# Store

## Context and Design Philosophy

The store keeps the player's progress on the phone: the ladder's skill estimates and a short history of sessions. There is no account and no server. The data is small, so the store favours being simple and safe over being clever.

## What is stored

- The ladder's skill estimate for every drill: its level and its results at that level.
- One summary per finished session: date, length, right and total answers, and drills that moved level.
- Whether the first-session introduction has been given.

The data structures are defined in the training core and are encodable, so saving and loading can be tested without a device.

## Saving and loading

Progress is one file in the app's Application Support folder, which is included in the phone's normal backups. It is saved after every answered exercise, by writing a new file and replacing the old one in one step, so a crash or force-quit never leaves a half-written file. It is loaded when the app starts.

The file records a format version. A file from a newer version than the app understands is left untouched and the app starts with fresh progress for this run, rather than overwriting it. A file that cannot be read is kept as a renamed copy, and the app starts with fresh progress.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| Storage | One JSON file | SwiftData / Core Data; SQLite | A few kilobytes of data with no queries; a file is simplest, transparent and fully testable in the core. |
| When to save | After every answered exercise | At the end of each session | A session interrupted in the background loses nothing. |
| Unreadable or newer file | Keep it, start fresh | Delete it; refuse to start | Never destroys progress that a later fix or update could still read. |
| Backups | Rely on the phone's own backup | iCloud sync | Keeps the no-account, on-device design; normal backups already include Application Support. |
