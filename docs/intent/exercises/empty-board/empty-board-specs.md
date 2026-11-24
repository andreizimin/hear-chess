# Empty-Board Drills — EARS specs

Design: `empty-board-design.md`

## All empty-board drills

- [x] **EX-EMPTY-001**: The empty-board drills shall be square colour, directions and diagonals, each with its own levels.
- [x] **EX-EMPTY-002**: When generating an empty-board exercise, the generator shall take as inputs a seeded random source, the drill, the level and the previous question asked in the session (if any), and shall always produce the same exercise for the same inputs.
- [x] **EX-EMPTY-003**: When generating an empty-board exercise, the generator shall never produce a question with the same content as the previous question asked in the session (the same drill, question type, squares and offset, in any order of squares), whichever drill the previous question came from.
- [x] **EX-EMPTY-004**: The empty-board drills shall ask every question from White's side, using the board's direction names.
- [x] **EX-EMPTY-005**: When checking an empty-board answer, the drill shall mark it right when it is one of the exercise's correct answers, and wrong otherwise.
- [x] **EX-EMPTY-006**: Where an empty-board drill draws a random choice with a stated probability or from a set of squares, it shall draw independently for each question, and uniformly over the allowed squares unless a probability is stated.

## Square colour drill

- [x] **EX-EMPTY-COL-001**: The square-colour drill shall ask for a square's colour, with light or dark as the answer kind ("f six. Light or dark?").
- [x] **EX-EMPTY-COL-002**: At square-colour level 1, the drill shall ask only the four corners and the centre squares d4, e4, d5 and e5.
- [x] **EX-EMPTY-COL-003**: At square-colour level 2, the drill shall ask only squares on the edge of the board and the centre squares d4, e4, d5 and e5.
- [x] **EX-EMPTY-COL-004**: At square-colour level 3, the drill shall ask any square.

## Directions drill

- [x] **EX-EMPTY-DIR-001**: The directions drill shall give a starting square and an offset and ask for the square reached, with a square as the answer kind ("Two right from e four?").
- [x] **EX-EMPTY-DIR-002**: When generating a directions exercise, the drill shall choose the starting square and offset so the answer is on the board.
- [x] **EX-EMPTY-DIR-003**: At directions level 1, the drill shall use one step in a single direction: up, down, left or right.
- [x] **EX-EMPTY-DIR-004**: At directions level 2, the drill shall use two or three steps in a single direction: up, down, left or right.
- [x] **EX-EMPTY-DIR-005**: At directions level 3, the drill shall use one to three steps in a single direction: up-right, up-left, down-right or down-left.
- [x] **EX-EMPTY-DIR-006**: At directions level 4, the drill shall use a knight's jump: one step up or down with two steps left or right, or two steps up or down with one step left or right.
- [x] **EX-EMPTY-DIR-007**: When asking a directions level-4 question, the drill shall speak the up-or-down part first ("one up, two right").

## Diagonals drill

- [x] **EX-EMPTY-DIAG-001**: The diagonals drill shall have three question types: same diagonal, diagonal end and long diagonals.
- [x] **EX-EMPTY-DIAG-002**: A same-diagonal question shall give two different squares and ask whether they share a diagonal, with yes or no as the answer kind ("c one and h six. Same diagonal?").
- [x] **EX-EMPTY-DIAG-003**: When generating a same-diagonal question, the drill shall make the answer yes with probability one half.
- [x] **EX-EMPTY-DIAG-004**: When generating a same-diagonal question whose answer is no, the drill shall use two squares of the same colour.
- [x] **EX-EMPTY-DIAG-005**: A diagonal-end question shall give a square and a diagonal direction and ask for the edge square where that diagonal meets the edge of the board, with a square as the answer kind ("From c one, up-right to the edge?" — answer h6).
- [x] **EX-EMPTY-DIAG-006**: When generating a diagonal-end question, the drill shall use only directions in which at least one square can be travelled from the starting square.
- [x] **EX-EMPTY-DIAG-007**: A long-diagonals question shall name one of the two long diagonals (a1–h8 or h1–a8) and a square, and ask whether the square is on it, with yes or no as the answer kind ("a one to h eight. Is d four on it?").
- [x] **EX-EMPTY-DIAG-008**: When generating a long-diagonals question, the drill shall make the answer yes with probability one half and never ask about either end square of the named diagonal.
- [x] **EX-EMPTY-DIAG-009**: When generating a long-diagonals question whose answer is no, the drill shall use a square of the named diagonal's colour (dark for a1–h8, light for h1–a8).
- [x] **EX-EMPTY-DIAG-010**: At diagonals level 1, the drill shall ask only long-diagonals questions.
- [x] **EX-EMPTY-DIAG-011**: At diagonals level 2, the drill shall ask same-diagonal and diagonal-end questions with equal probability, with the first (or only) square on the edge of the board.
- [x] **EX-EMPTY-DIAG-012**: At diagonals level 3, the drill shall ask same-diagonal and diagonal-end questions with equal probability, from any square.
