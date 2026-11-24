# Ladder — EARS specs

Design: `ladder-design.md`

## Skill estimate

- [x] **LADDER-001**: The ladder shall keep, for each drill, a skill estimate made of a current level starting at 1 and the most recent results at that level, at most 20, kept across app launches through the store.
- [x] **LADDER-002**: When recording a result, the ladder shall store whether it was right, whether it was answered by voice or touch, and, for a right voice answer, its answer time (as measured by the session, from the end of the prompt).
- [x] **LADDER-003**: If a result arrives for an exercise asked at a level other than the drill's current level (the level changed in between), then the ladder shall discard it.
- [x] **LADDER-004**: When the answer to an exercise is "I don't know" or a skip, the ladder shall record it as wrong.
- [x] **LADDER-005**: The ladder shall use target times of 3 seconds for square colour, 5 seconds for directions and 6 seconds for diagonals.

## Moving levels

- [x] **LADDER-LVL-001**: When a drill has at least 10 results at its current level, at least 9 of the last 10 are right, and at least 5 of those right answers were given by voice, the ladder shall move the drill up one level if the median time of those right voice answers is at or under the drill's target time.
- [x] **LADDER-LVL-002**: When a drill has at least 10 results at its current level, at least 9 of the last 10 are right, and fewer than 5 of those right answers were given by voice, the ladder shall move the drill up one level.
- [x] **LADDER-LVL-003**: When a drill above level 1 has at least 5 results at its current level and at most 2 of the last 5 are right, the ladder shall move the drill down one level.
- [x] **LADDER-LVL-004**: When a drill moves up or down a level, the ladder shall clear its results.
- [x] **LADDER-LVL-005**: While a drill is at its highest level, the ladder shall not move it up; while it is at level 1, the ladder shall not move it down and shall keep its results.
- [x] **LADDER-LVL-006**: The ladder shall check the level rules after every recorded result.
- [x] **LADDER-LVL-007**: When taking the median of an even number of answer times, the ladder shall use the mean of the two middle times.

## Choosing the next exercise

- [x] **LADDER-PICK-001**: When choosing the next exercise, the ladder shall choose a drill at random in proportion to its weight, at that drill's current level.
- [x] **LADDER-PICK-002**: When a drill has fewer than 5 results at its current level, the ladder shall give it weight 2.
- [x] **LADDER-PICK-003**: When a drill has 5 or more results at its current level, the ladder shall give it weight 1 plus twice the number of wrong answers divided by the number of results among its last 10 (or all, if fewer than 10) at that level.
- [x] **LADDER-PICK-004**: Within a session, the ladder shall never choose the same drill more than three times in a row.
