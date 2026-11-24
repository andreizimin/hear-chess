---
parent: high-level-design
prefix: BOARD
---

# Board

## Context and Design Philosophy

The board is the chess geometry every exercise is built on: squares, their colours, directions between them and the lines that run through them. It is part of the training core, so it is plain Swift with no iOS dependencies, and every other part of the app asks it questions rather than computing geometry itself. Exercises need exact, unambiguous answers, so the board is built from small value types with no hidden state.

Piece movement, attacks, check and legal moves belong to the board too. They are not needed by the empty-board rung and are designed when the piece-routes rung is.

## Squares

A square is a file (a–h) and a rank (1–8). Internally both are numbers 0–7, with a1 as (0, 0) and h8 as (7, 7). A square can be created from its file and rank numbers or from its name. A name is exactly one file letter and one rank digit, in either case and ignoring surrounding spaces ("e4", "E4"); anything else, including squares outside the board ("i1", "e9", "e44"), is rejected rather than wrapped or clamped.

## Colour

a1 is dark. A square is dark when its file number plus its rank number is even, and light otherwise. So h1 and a8 are light, and d4 and e5 are dark.

## Directions

There are eight directions, named from White's side of the board:

| Direction | File step | Rank step |
|---|---|---|
| up | 0 | +1 |
| down | 0 | −1 |
| right | +1 | 0 |
| left | −1 | 0 |
| up-right | +1 | +1 |
| up-left | −1 | +1 |
| down-right | +1 | −1 |
| down-left | −1 | −1 |

"Up" is towards rank 8 and "right" is towards the h-file. Moving from a square by a number of steps in a direction, or by any file and rank offset (such as one up and two right), gives either a square or nothing when the result is off the board.

## Lines and diagonals

Every square lies on one file, one rank and two diagonals: one running up-right and one running up-left. A diagonal is identified by its two end squares, the squares where it meets the edge of the board, written lower rank first (for example c1–h6).

The board answers:

- the two diagonals through a square;
- whether two squares share a diagonal, a file or a rank (a square shares every line with itself);
- the end square reached by travelling from a square in a diagonal direction until the edge, or nothing when the square is already at the edge in that direction (a1 down-left, c1 down-right);
- the length of a diagonal (1 to 8 squares).

Each corner lies on one diagonal of length 1, made of the corner alone (a1–a1 and h8–h8 run up-left; h1–h1 and a8–a8 run up-right). It is a real diagonal for these questions, but exercises never ask about it.

The two long diagonals, a1–h8 and h1–a8, are the only diagonals of length 8. a1–h8 is all dark squares and h1–a8 all light; every diagonal is a single colour.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| Square representation | File and rank numbers 0–7 | 0–63 index; bitboards | Exercises ask about files, ranks and directions directly; two small numbers map onto those questions with no conversion. Speed is irrelevant at this scale. |
| Off-board results | Return nothing | Clamp to the edge; wrap around | A clamped or wrapped square would be a wrong but plausible answer. Exercises must know when a move leaves the board. |
| Direction names | From White's side (up = towards rank 8) | From the side to move; compass names | Every empty-board exercise is asked from White's side. Black's side is a later setting that maps directions, not a second set of names. |

## Open Questions & Future Decisions

### Deferred
1. Pieces, movement, attacks, check and legal moves — designed with the piece-routes rung.
2. Asking empty-board questions from Black's side — whether it is a separate level or a setting.
