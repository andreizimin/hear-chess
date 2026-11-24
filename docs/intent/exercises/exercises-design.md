---
parent: high-level-design
prefix: EX
---

# Exercises

## Context and Design Philosophy

An exercise is one question and its answer. Each rung of the training ladder is a family of exercises, and each family is designed in its own child node. This parent holds what every family shares, so the session, the ladder and spoken chess can handle any exercise without knowing which family it came from.

Exercises are part of the training core. They are generated from a seeded random source, so the same seed always gives the same exercises and tests are repeatable.

## What every exercise has

- **Drill** — the specific kind of question within a family, such as square colour or same-diagonal. The ladder keeps a skill estimate per drill.
- **Level** — how hard this instance is within its drill, a whole number starting at 1. Each drill defines what its levels mean.
- **Prompt** — a structured description of the question, which spoken chess turns into words.
- **Answer kind** — light or dark, yes or no, or square. This tells spoken chess what to listen for and touch which input to offer.
- **Correct answers** — the set of answers accepted as right. Usually one, but a drill may accept several.
- **Correction** — a structured description of the right answer, spoken after a wrong one.

## Checking and generating

An answer is right when it is one of the exercise's correct answers, and wrong otherwise. The time taken to answer is measured by the session, and what a result means for the player's skill — including how "I don't know" is counted — is the ladder's concern.

Each family generates an exercise for a given drill and level from a seeded random source. The session picks a fresh random seed for every session and records it, so any session can be replayed. Generation is given the question asked just before, whichever drill it came from, and never produces an identical question. This parent owns no requirements of its own; each family's specs state these rules for that family.

## Children

| Node | Rung | Status |
|---|---|---|
| `empty-board/` | Empty board | Designed |
| piece routes, move following, position memory, puzzles | Later rungs | Designed with their rungs |

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| Shared exercise shape in a parent node | One shape for all families | Each family with its own interface | The session, ladder, voice and touch handle exercises generically; adding a rung then needs no change outside its own node. |
| Seeded generation | Yes | Unseeded randomness | Repeatable tests, and a reported problem can be replayed. |
