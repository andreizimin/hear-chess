---
parent: high-level-design
prefix: AUDIO
---

# Audio

## Context and Design Philosophy

Audio keeps training going when the phone is in a pocket: with the screen locked, through headphones, and controlled by headphone buttons. It configures how the app shares the phone's audio, keeps the app alive during a session and maps the system's media controls to session actions. It is the riskiest part of the app, because it depends on how iOS treats an app that both speaks and listens in the background.

## Audio session

During a session the app's audio session plays and records at the same time, routes to headphones when connected and to the speaker otherwise, and supports Bluetooth headsets with a microphone. Other apps' audio (music, podcasts) is paused while a session runs and allowed to resume when it ends.

## Locked screen

The app declares background audio, so a session that is running keeps running when the screen locks or the player switches app. Speaking and listening both continue in the background. Outside a session the app does no background work.

## Headphone and lock-screen controls

While a session runs, the app shows as the playing audio on the lock screen and in Control Center, and handles the standard media commands:

| Command | Session action |
|---|---|
| Play / pause | Pause or resume |
| Next track | Skip the question (counts as "I don't know") |
| Previous track | Repeat the question |

When no session is running, play starts one.

## Interruptions and route changes

A phone call, alarm or other interruption pauses the session. When the interruption ends the session stays paused until the player resumes it. Unplugging or disconnecting headphones pauses the session too, so it never suddenly speaks out loud.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| Keeping the app alive | Background audio for the length of a session | Foreground only | Eyes-free training in a pocket is a core goal; foreground-only would require the screen to stay on. |
| Other apps' audio | Paused during a session | Mixed with the session | Training needs the player's full attention, and music would interfere with recognition. |
| Headphones disconnected | Pause | Continue through the speaker | Avoids speaking out loud in public by surprise. |
| After an interruption | Stay paused | Resume automatically | The player may no longer be ready to train; resuming is one button. |

## Open Questions & Future Decisions

### Deferred
1. Whether on-device recognition keeps working for a whole session with the screen locked. This is the first thing to verify on a device, before the rest of the slice is built.
2. Bluetooth headset microphones switch headphones to a lower-quality audio mode; whether speech still sounds clear enough.
