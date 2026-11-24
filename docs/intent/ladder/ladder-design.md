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
- the results at the current level since the player reached it, each one right or wrong with its answer time.

"I don't know" and skipping are recorded as wrong. Every drill has a **target time**: the answer time that shows the player recalls rather than works out.

| Drill | Target time |
|---|---|
| Square colour | 3 seconds |
| Directions | 5 seconds |
| Diagonals | 6 seconds |

These are starting values, to be tuned from use.

## Moving levels

- **Up** — when the last 10 results at the current level include at least 9 right, and the median answer time of the right ones is within the drill's target time. The drill moves up one level, and its results start again.
- **Down** — when the last 5 results at the current level include at most 2 right. The drill moves down one level (never below 1), and its results start again.

A drill at its highest level stays there and keeps recording results.

## Choosing the next exercise

The next exercise comes from a drill chosen by weight. A drill's weight is higher the fewer results it has at its current level and the lower its accuracy there, so the player spends more time where they are weakest. The same drill is never chosen more than three times in a row, so drills stay interleaved.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| Level-step rules | Fixed thresholds over recent results | Elo or Glicko rating per drill and per question | Thresholds are easy to understand, explain and tune for a personal app. A rating system needs many results to settle and gives no clear "you moved up" moment. |
| Speed in moving up | Median right-answer time within a target | Accuracy only | Fast recall is the sign of seeing the board rather than working answers out, which is the skill being trained. |
| Interleaving drills | Weighted choice, at most three of one drill in a row | Blocks of one drill at a time | Mixed practice keeps every skill active and avoids answering on autopilot. |

## Open Questions & Future Decisions

### Deferred
1. Opening the next rung, reviews of earlier rungs and the placement run — designed with the second rung.
2. Tuning the thresholds and target times from real use.
