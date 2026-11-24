---
parent: high-level-design
prefix: AUDIO
---

# Audio

## Context and Design Philosophy

Audio keeps training going when the phone is in a pocket: with the screen locked, through headphones, and controlled by headphone buttons. It configures how the app shares the phone's audio, keeps the app alive during a session and maps the system's media controls to session actions. It is the riskiest part of the app, because it depends on how iOS treats an app that both speaks and listens in the background.

## Audio session

When voice input is available, the app's audio session plays and records at the same time during a session, routes to headphones when connected and to the speaker otherwise, and supports Bluetooth headsets with a microphone. When voice input is off, the session only plays, so Bluetooth headphones stay in their normal high-quality mode. Other apps' audio (music, podcasts) is paused while a session runs and allowed to resume when it ends.

## Locked screen and background

The app declares background audio, so a running session keeps going when the screen locks or the player switches app, with speaking and listening both continuing.

A paused session stays alive in the background for up to 10 minutes and then ends, as the session design says. If iOS suspends the app while it is paused, the session's state is kept, and the session picks up where it was when the app runs again within those 10 minutes.

Outside a session the app does no background work. For one minute after a session ends it remains the lock screen's playing app, so a headphone press can start another session (after the "Start training?" confirmation); after that it gives up the playing-app role, and headphone presses go to other apps again.

## Headphone and lock-screen controls

While a session runs, the app shows as the playing audio on the lock screen and in Control Center, and handles the standard media commands:

| Command | While listening or confirming | While asking or giving feedback | While paused |
|---|---|---|---|
| Play / pause | Pause | Pause | Resume |
| Next track | Skip the question (counts as "I don't know") | Ignored | Ignored |
| Previous track | Repeat the question | Ignored | Resume |

With no session running, play starts the "Start training?" confirmation.

## Interruptions and route changes

A phone call, alarm or other interruption pauses the session. When the interruption ends the session stays paused until the player resumes it, and resuming asks the current question again, dropping any confirmation that was in progress. Disconnecting headphones pauses the session at once, so it never suddenly speaks out loud. Reconnecting them leaves the session paused.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| Keeping the app alive | Background audio for the length of a session | Foreground only | Eyes-free training in a pocket is a core goal; foreground-only would require the screen to stay on. |
| Other apps' audio | Paused during a session | Mixed with the session | Training needs the player's full attention, and music would interfere with recognition. |
| Headphones disconnected | Pause | Continue through the speaker | Avoids speaking out loud in public by surprise. |
| After an interruption | Stay paused | Resume automatically | The player may no longer be ready to train; resuming is one button. |
| Playing-app role after a session | Kept for one minute | Kept until another app plays; given up at once | Allows a quick second session from the headphones without capturing headphone presses meant for music later. |
| Play-only audio when voice is off | Yes | Always play and record | Recording forces Bluetooth headphones into a lower-quality mode that brings nothing when the microphone is not used. |

## Open Questions & Future Decisions

### Deferred
1. Whether on-device recognition keeps working for a whole session with the screen locked. This is the first thing to verify on a device, before the rest of the slice is built.
2. Whether a suspended app still receives the play command as the lock screen's playing app, and whether a paused session can stay alive in the background without playing audio.
3. Bluetooth headset microphones switch headphones to a lower-quality audio mode; whether speech still sounds clear enough.
