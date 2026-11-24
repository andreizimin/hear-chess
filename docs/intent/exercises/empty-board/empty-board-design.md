---
parent: exercises
prefix: EX-EMPTY
---

# Empty-Board Drills

## Context and Design Philosophy

The empty board is the first rung: knowing where every square is and what it looks like, with no pieces at all. Training guides agree it comes first and that diagonals are its hardest part. These drills aim at a picture of the board, not at rules for working answers out, so they rely on the player answering quickly: the ladder rewards fast answers, which favours seeing over calculating.

All questions are asked from White's side, using the board's direction names (up is towards rank 8).

## Drills

### Square colour

"f six. Light or dark?" Answer kind: light or dark.

| Level | Squares asked |
|---|---|
| 1 | Corners and the four centre squares (d4, e4, d5, e5) |
| 2 | Any square on the edge of the board, plus the centre squares |
| 3 | Any square |

Each level includes the squares of the levels below it.

### Directions

"Two right from e four?" Answer kind: square. The starting square and offset are chosen so the answer is on the board.

| Level | Offset |
|---|---|
| 1 | One step up, down, left or right |
| 2 | Two or three steps up, down, left or right |
| 3 | One to three steps in a diagonal direction |
| 4 | A knight's jump: one step up or down and two left or right, or two up or down and one left or right. The up-or-down part is spoken first: "one up, two right" |

### Diagonals

Three question types share one drill:

- **Same diagonal** — "c one and h six. Same diagonal?" Answer kind: yes or no. Each question has an even chance of the answer being yes. The two squares are always different, and the no cases use two squares of the same colour, so colour alone does not give the answer away.
- **Diagonal end** — "From c one, up-right to the edge?" Answer kind: square. Only directions with at least one square to travel are asked, so the answer is never the starting square.
- **Long diagonals** — "a one to h eight. Is d four on it?" Answer kind: yes or no. Each question has an even chance of the answer being yes. The square asked is never one of the diagonal's two ends, and in the no cases it is the diagonal's colour (dark for a1–h8, light for h1–a8), so colour alone does not give the answer away.

| Level | Questions |
|---|---|
| 1 | Long diagonals only |
| 2 | Same diagonal and diagonal end, with the first (or only) square on the edge of the board |
| 3 | Same diagonal and diagonal end, from any square |

At levels 2 and 3, same diagonal and diagonal end are equally likely.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| Three drills: colour, directions, diagonals | These three | Adding "name the square at a position" (e.g. "third square on the fourth rank") | Coordinates-by-position mostly tests counting, which is what the rung should replace with seeing. Directions already cover moving around the board. |
| Colour levels start with corners and centre | Landmarks first | Random squares from the start | Corners and the centre are the anchors players build the rest of the board from. |
| "No" answers keep the colour equal (same diagonal and long diagonals) | Yes | Random squares | Every diagonal is one colour, so a square of the other colour is always "no"; a player could answer from colour alone and skip the diagonal. |
| Knight-jump offsets as the last directions level | Yes | Leaving knight jumps to piece routes | It is pure geometry on an empty board and prepares the piece-routes rung. |

## Open Questions & Future Decisions

### Deferred
1. Asking from Black's side as a higher level.
2. Whether quadrant drills ("which quarter of the board is f6 in?") help beginners enough to add.
