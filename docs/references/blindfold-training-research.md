# Blindfold training: research notes

Background for the training ladder in `docs/high-level-design.md`. Most sources are coaching blogs and training guides rather than research; the cognitive findings at the end are from published studies.

## The method the ladder is built on

Chess House, *How to Develop Blindfold Chess Skill* (https://www.youtube.com/watch?v=Z4U336yifjg). The presenter, who plays several blindfold games at once, argues that almost anyone can learn blindfold chess by working through five stages:

1. **Colours.** With the board upside down (no coordinates visible), fix one corner: h1 is light ("white on right"). Extend from there — g1 next to it is dark, g2 next to that is light, h8 opposite is dark — until any square's colour is known.
2. **Piece visualization.** Put a single piece on a square and, without looking, name every square it attacks. Start in a corner (bishop on h1: g2, f3, e4, d5, c6, b7, a8), then the rook, queen, king and pawn, and the knight last. Then any piece on any square, eyes closed.
3. **Tracking movement.** Use the knight, because it is the hardest. Move it along the edge from each square to the next (h1 to h2: h1–f2–g4–h2), then across the board (h3 to a3: h3–f2–d3–b4–c2–a3).
4. **Practising games.** With a partner and all the pieces set up, each side says three or four moves without moving anything; then both recall the moves aloud and play them on the board to check. Continue the game chunk by chunk, then grow the chunks to five or six moves. Next, clear the board and say as many moves as possible — about ten to start — setting up the position when stuck, until fifteen is reached.
5. **Full blindfold game.** Repeat stage 4 with the board turned around, then play blindfold with someone, five or ten moves at a time, setting up in between, until a full game is played blindfold.

He presents visualization as the core skill of chess calculation: seeing future positions and the steps to reach them.

## What the guides agree on

- **Order of skills.** Learn the empty board first (square names and colours), then move single pieces on it, then follow move sequences from known openings, then hold static positions, and play full blindfold games last. Guides vary in detail but agree on this order.
- **Empty board.** Know each square's colour and position by picturing the board, not by computing it from coordinates. Diagonals are the hardest part of the empty board; treat each diagonal as a single line. Some players find splitting the board into quarters helpful.
- **Piece routes.** Route a bishop or knight between two squares (e.g. bishop g1–c5–f8); find the shortest knight route between two squares, then alternatives; short knight mini-tours (e.g. Ng1–e2–f4–h3).
- **Knight tour against a queen.** Move a knight around the board without ever landing on a square an enemy queen attacks; change the starting square for fresh routes. (Some setups are impossible as stated, so generated variants need checking for solvability.)
- **Move following.** Start with 6–10 ply (3–5 moves) of a real game or opening per day; a follow-up exercise names the colour of the square each moved piece lands on.
- **Positions.** Start with very few pieces — simple endings with one or two pawns — and add pieces as confidence grows. Train from both colours' side.
- **Later stages.** Solve endgame studies and tactics blindfold, analyse your own games without an engine, then play full games.
- **Session length.** About 5–10 minutes a day, with a day or two off each week; around ten hours over ten weeks is a reasonable introductory programme. Noticeable improvement is reported over 6–12 months.

## Cognitive findings

- Blindfold chess relies mainly on visual-spatial working memory and makes little use of verbal working memory (Saariluoma, interference studies).
- Blindfold players recall the functionally important parts of a position far better than unimportant parts.
- Expert position memory works through chunks and templates of familiar patterns; visual short-term memory alone holds only a few items. Familiar, natural positions are easier to hold than random ones.
- Blindfold practice is reported to improve general chess skill.

## Existing apps (for comparison)

- DarkSquares: progressive exercises (square colours, coordinates, quadrants, diagonals, attack detection, position memory); removes visual cues gradually.
- Chessvis: move following, static boards, "who's guarding whom", Lichess puzzles.
- Lichess: coordinate trainer; screen-reader "blind mode" announcing piece names and squares.

None is built for training fully eyes-free by ear.

## Sources

- https://www.chess.com/blog/AdviceCabinet/7-levels-of-blindfold-chess-exercises-for-everyone
- https://www.chess.com/clubs/forum/view/blindfold-exercises-by-gm-advice-cabinet
- https://saychess.substack.com/s/invisible-chess
- https://chessfox.com/?p=27214
- https://www.chess.com/blog/Chesser1492x/how-to-build-your-blindfold-skills
- https://www.chess.com/blog/stamma1/how-to-play-blindfold-chess
- https://lichess.org/video/6w-f16kVz6k (IM Kostya Kavutskiy, visualization methods)
- https://lichess.org/@/NDpatzer/blog/science-of-chess-how-does-chess-calculation-depend-on-words-vs-pictures/gBpG2olI
- https://pubmed.ncbi.nlm.nih.gov/9640433/ (Saariluoma & Kalakoski, apperception and imagery in blindfold chess)
- https://bura.brunel.ac.uk/bitstream/2438/1618/1/Mental%20imagery%20and%20chunks.pdf (Gobet, mental imagery and chunks)
- https://apps.apple.com/us/app/id6758460463 (DarkSquares)
- https://apps.apple.com/us/app/chessvis/id1229226444 (Chessvis)
- https://lichess.org/page/blind-mode-guide
