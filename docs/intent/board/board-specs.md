# Board — EARS specs

Design: `board-design.md`

## Squares

- [x] **BOARD-SQ-001**: The board shall represent a square as a file number 0–7 (a–h) and a rank number 0–7 (ranks 1–8), with a1 as file 0, rank 0.
- [x] **BOARD-SQ-002**: When a square is created from file and rank numbers outside 0–7, the board shall give no square (creation fails without an error being thrown).
- [x] **BOARD-SQ-003**: When a square is created from a name, the board shall accept exactly one file letter a–h followed by one rank digit 1–8, in either letter case, ignoring any leading and trailing whitespace.
- [x] **BOARD-SQ-004**: When a square is created from any other name (such as "i1", "e9", "e44" or "e"), the board shall give no square (creation fails without an error being thrown).
- [x] **BOARD-SQ-005**: The board shall give each square's name as a lower-case file letter followed by its rank digit ("e4").

## Colour

- [x] **BOARD-COL-001**: The board shall give a square's colour as dark when its file number plus its rank number is even, and light otherwise (a1 dark, h1 light).

## Directions

- [x] **BOARD-DIR-001**: The board shall define eight directions from White's side: up (rank +1), down (rank −1), right (file +1), left (file −1), up-right, up-left, down-right and down-left.
- [x] **BOARD-DIR-002**: When asked for the square a number of steps (1 or more) from a square in a direction, the board shall give that square, or nothing if it is off the board.
- [x] **BOARD-DIR-003**: When asked for the square at a file and rank offset from a square, the board shall give that square, or nothing if it is off the board.
- [x] **BOARD-DIR-004**: When asked for the square a number of steps that is 0 or negative from a square in a direction, the board shall give nothing.

## Lines and diagonals

- [x] **BOARD-LINE-001**: The board shall identify a diagonal by its two end squares on the edge of the board, the end with the lower rank first (for example c1–h6).
- [x] **BOARD-LINE-002**: When asked for the diagonals through a square, the board shall give the two whole diagonals containing it, edge to edge: the one running up-right and the one running up-left (for d4: a1–h8 and g1–a7).
- [x] **BOARD-LINE-003**: When asked whether two squares share a diagonal, the board shall answer yes when both lie on the same diagonal, including when they are the same square.
- [x] **BOARD-LINE-004**: When asked for the end of a diagonal from a square in a diagonal direction, and at least one step in that direction stays on the board, the board shall give the edge square where the diagonal meets the edge of the board in that direction.
- [x] **BOARD-LINE-005**: If the square is already on the edge in the asked diagonal direction (such as a1 down-left), then the board shall give nothing as the diagonal end.
- [x] **BOARD-LINE-006**: The board shall give a diagonal's length as its number of squares, from 1 to 8.
- [x] **BOARD-LINE-007**: The board shall treat each corner as lying on a diagonal of length 1 made of that corner alone, in addition to its long diagonal.
- [x] **BOARD-LINE-008**: When asked whether two squares share a file or a rank, the board shall answer yes when both lie on that file or rank, including when they are the same square.
