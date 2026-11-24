---
parent: high-level-design
prefix: LADDER
---

# Ladder

## Context and Design Philosophy

The ladder decides what the player trains next. It holds a skill estimate for every drill, moves each drill's level up or down from results, and picks the next exercise. It is part of the training core and is deliberately simple: a player should be able to understand why the app moved them, and the rules should be easy to tune after real use.

This design covers the first rung, the empty board. Opening later rungs, reviews of earlier rungs and the placement run are designed when the second rung is.

## Skill estimate

For each drill the ladder keeps:

- the current level (starting at 1);
- the most recent results at the current level since the player reached it, up to 20. Each result is right or wrong, how it was answered (voice or touch), and, for a right voice answer, its answer time.

A result is recorded against the level of the exercise when it was asked. "I don't know" and skipping are recorded as wrong. An exercise that was never answered, because the session stopped first, is not recorded.

Every drill has a **target time**: the voice answer time that shows the player recalls rather than works out.

| Drill | Target time |
|---|---|
| Square colour | 3 seconds |
| Directions | 5 seconds |
| Diagonals | 6 seconds |

These are starting values, to be tuned from use. Touch answers are slower for reasons that have nothing to do with recall, so their time is not used.

## Moving levels

- **Up** — when the drill has at least 10 results at the current level, the last 10 include at least 9 right, and the median time of the right voice answers among those 10 is at or under the drill's target time. When those 10 contain no right voice answers (the player answered by touch), accuracy alone decides. The drill moves up one level, and its results start again.
- **Down** — when the drill has at least 5 results at the current level and the last 5 include at most 2 right. The drill moves down one level (never below 1), and its results start again.

Both rules are checked after every recorded result. A drill at its highest level does not move up, but can move down.

## Choosing the next exercise

The next exercise comes from a drill chosen at random by weight:

- a drill with fewer than 5 results at its current level has weight 2;
- otherwise its weight is 1 plus twice its share of wrong answers among its last 10 results at the current level (so between 1 and 3).

Within a session, the same drill is never chosen more than three times in a row, so drills stay interleaved.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| Level-step rules | Fixed thresholds over recent results | Elo or Glicko rating per drill and per question | Thresholds are easy to understand, explain and tune for a personal app. A rating system needs many results to settle and gives no clear "you moved up" moment. |
| Speed in moving up | Median right voice-answer time within a target | Accuracy only | Fast recall is the sign of seeing the board rather than working answers out, which is the skill being trained. |
| Speed for touch answers | Not used | Time to first touch; longer touch targets | Touch time mostly measures swiping, not recall. A touch-only player moves up on accuracy alone rather than being held back by the input method. |
| Interleaving drills | Weighted choice, at most three of one drill in a row | Blocks of one drill at a time | Mixed practice keeps every skill active and avoids answering on autopilot. |
| Results kept | The last 20 per drill | All results | The rules look at the last 10 at most; keeping more only grows the store. |

## Open Questions & Future Decisions

### Deferred
1. Opening the next rung, reviews of earlier rungs and the placement run — designed with the second rung.
2. Tuning the thresholds, weights and target times from real use.
