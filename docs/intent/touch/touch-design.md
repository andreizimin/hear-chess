---
parent: high-level-design
prefix: TOUCH
---

# Touch

## Context and Design Philosophy

Touch lets the player answer without looking. The whole screen is one training surface: there are no buttons to find, only gestures that work anywhere, and every gesture's meaning is either always the same or spoken aloud. Touch is live at the same time as voice, so the player can switch between them at any moment.

## Gestures

| Gesture | Meaning |
|---|---|
| Swipe right | Light / yes |
| Swipe left | Dark / no |
| Swipe up or down | Move through choices when picking a square (below) |
| Double-tap | Choose the current choice when picking a square |
| Two-finger tap | Repeat the question |
| Long press | I don't know |
| Two-finger double-tap | Pause or resume |
| Three-finger swipe down | Stop the session |

Before the first session the app explains swipe right for light or yes and swipe left for dark or no, and that other gestures are described in the help. Gestures that mean nothing for the current question are ignored.

## Picking a square

A square answer is picked in two steps, file then rank:

1. The app says "file". Swiping up moves to the next file and swiping down to the previous one, starting at "e"; each file letter is spoken as it is reached. The list stops at a and h rather than wrapping. A double-tap chooses the spoken file.
2. The app says "rank" and the same is done for ranks 1 to 8, starting at 4.
3. The chosen square is the answer, and is spoken back ("g four") as the answer is checked.

While picking, a two-finger tap repeats the question and goes back to step 1.

## Working with VoiceOver

When VoiceOver is on, it normally captures gestures. The training surface lets gestures pass straight through to the app, so the gestures above work the same with VoiceOver on or off.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| One whole-screen surface | Yes | Large on-screen buttons | Buttons need finding; a gesture anywhere works with the phone in a pocket or held without looking. |
| Right = light/yes, left = dark/no | Fixed mapping | Mapping announced per question | A fixed mapping becomes automatic; one that changes per question needs listening every time. |
| Square by file then rank | Two-step stepping | Tapping a grid; drawing letters | A grid needs sight, and drawing letters is error-prone. Stepping is slow but certain, and voice remains the fast way. |
| Starting at e and 4 | Middle of each list | Starting at a and 1 | No square is more than four steps away in either step. |
| VoiceOver | Gestures pass through on the training surface | Using VoiceOver's own gestures | Keeps one set of gestures for everyone, so the help and the habit are the same. |

## Open Questions & Future Decisions

### Deferred
1. Whether gesture help is spoken on request (for example a gesture for "help") or only shown in settings.
2. Haptic feedback for each step while picking a square.
