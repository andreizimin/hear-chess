# Board — EARS specs

Design: `board-design.md`

## Squares

- [ ] **BOARD-SQ-001**: The board shall represent a square as a file number 0–7 (a–h) and a rank number 0–7 (ranks 1–8), with a1 as file 0, rank 0.
- [ ] **BOARD-SQ-002**: When a square is created from file and rank numbers outside 0–7, the board shall reject it.
- [ ] **BOARD-SQ-003**: When a square is created from a name, the board shall accept exactly one file letter a–h followed by one rank digit 1–8, in either letter case, ignoring leading and trailing spaces.
- [ ] **BOARD-SQ-004**: When a square is created from any other name (such as "i1", "e9", "e44" or "e"), the board shall reject it.
- [ ] **BOARD-SQ-005**: The board shall give each square's name as a lower-case file letter followed by its rank digit ("e4").

## Colour

- [ ] **BOARD-COL-001**: The board shall give a square's colour as dark when its file number plus its rank number is even, and light otherwise (a1 dark, h1 light).

## Directions

- [ ] **BOARD-DIR-001**: The board shall define eight directions from White's side: up (rank +1), down (rank −1), right (file +1), left (file −1), up-right, up-left, down-right and down-left.
- [ ] **BOARD-DIR-002**: When asked for the square a given number of steps from a square in a direction, the board shall give that square, or nothing if it is off the board.
- [ ] **BOARD-DIR-003**: When asked for the square at a file and rank offset from a square, the board shall give that square, or nothing if it is off the board.

## Lines and diagonals

- [ ] **BOARD-LINE-001**: The board shall identify a diagonal by its two end squares on the edge of the board, the end with the lower rank first (for example c1–h6).
- [ ] **BOARD-LINE-002**: When asked for the diagonals through a square, the board shall give the up-right diagonal and the up-left diagonal containing that square.
- [ ] **BOARD-LINE-003**: When asked whether two squares share a diagonal, file or rank, the board shall answer yes when both lie on that same line, including when the two squares are the same square.
- [ ] **BOARD-LINE-004**: When asked for the end of a diagonal from a square in a diagonal direction, the board shall give the last square reached before leaving the board.
- [ ] **BOARD-LINE-005**: If the square is already on the edge in the asked diagonal direction (such as a1 down-left), then the board shall give nothing as the diagonal end.
- [ ] **BOARD-LINE-006**: The board shall give a diagonal's length as its number of squares, from 1 to 8.
- [ ] **BOARD-LINE-007**: The board shall treat each corner as lying on a diagonal of length 1 made of that corner alone, in addition to its long diagonal.
