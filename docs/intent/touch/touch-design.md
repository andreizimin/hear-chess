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
| Tap (no session running) | Start a session |
| Swipe right | Light / yes |
| Swipe left | Dark / no |
| Swipe up or down | Move through choices when picking a square (below) |
| Double-tap | Choose the current choice when picking a square |
| Two-finger tap | Repeat the question |
| Long press | I don't know |
| Two-finger double-tap | Pause or resume |
| Three-finger swipe down | Stop the session |

The introduction explains swipe right for light or yes and swipe left for dark or no; other gestures are described in the help. Gestures that mean nothing at the current moment are ignored. A two-finger tap is recognized only once a two-finger double-tap has been ruled out. During a session the app asks the system to defer its own edge gestures (Notification Center, Control Center, Home), so a swipe that starts near an edge still reaches the app first.

## Picking a square

A square answer is picked in two steps, file then rank:

1. The app says "file, e". Swiping up moves to the next file and swiping down to the previous one; each file letter is spoken as it is reached. At a and h the list stops, and a further swipe plays a short bump sound. A double-tap chooses the spoken file.
2. The app says "rank, four" and the same is done for ranks 1 to 8.
3. The chosen square is the answer, and is spoken back ("g four") as the answer is checked.

While picking, a two-finger tap repeats the question and starts the pick again, a long press means "I don't know", and left and right swipes are ignored. A voice answer that arrives during a pick is used and the pick is abandoned.

## Screen and lock

When voice input is available, the screen locks as normal during a session, and the player answers by voice and the headphone controls. When voice input is off, the app keeps the screen awake, dimmed, for the length of a session so touch keeps working, and lets it lock normally again when the session ends.

## Working with VoiceOver

When VoiceOver is on, it normally captures gestures. The training surface lets gestures pass straight through to the app, so the gestures above work the same with VoiceOver on or off.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| One whole-screen surface | Yes | Large on-screen buttons or regions | Buttons and regions need finding; a gesture anywhere works with the phone held without looking. |
| Right = light/yes, left = dark/no | Fixed mapping | Mapping announced per question | A fixed mapping becomes automatic; one that changes per question needs listening every time. |
| Square by file then rank | Two-step stepping | Tapping a grid; drawing letters | A grid needs sight, and drawing letters is error-prone. Stepping is slow but certain, and voice remains the fast way. |
| Starting at e and 4 | Middle of each list | Starting at a and 1 | No square is more than four steps away in either step. |
| Keeping the screen awake | Only during a session with voice off | Always during sessions; never | With voice, a locked phone in a pocket is the goal; without voice, touch is the only way to answer and needs the screen. |
| VoiceOver | Gestures pass through on the training surface | Using VoiceOver's own gestures | Keeps one set of gestures for everyone, so the help and the habit are the same. |

## Open Questions & Future Decisions

### Deferred
1. Whether gesture help is spoken on request (for example a gesture for "help") or only shown in settings.
2. Haptic feedback for each step while picking a square.
