# Ladder — EARS specs

Design: `ladder-design.md`

## Skill estimate

- [ ] **LADDER-001**: The ladder shall keep, for each drill, a current level starting at 1 and the most recent results at that level, at most 20.
- [ ] **LADDER-002**: When recording a result, the ladder shall store whether it was right, whether it was answered by voice or touch, and, for a right voice answer, its answer time.
- [ ] **LADDER-003**: When recording a result, the ladder shall record it against the level of the exercise at the time it was asked.
- [ ] **LADDER-004**: When the answer to an exercise is "I don't know" or a skip, the ladder shall record it as wrong.
- [ ] **LADDER-005**: The ladder shall use target times of 3 seconds for square colour, 5 seconds for directions and 6 seconds for diagonals.

## Moving levels

- [ ] **LADDER-LVL-001**: When a drill has at least 10 results at its current level, at least 9 of the last 10 are right, and the median time of the right voice answers among those 10 is at or under the drill's target time, the ladder shall move the drill up one level.
- [ ] **LADDER-LVL-002**: When a drill has at least 10 results at its current level, at least 9 of the last 10 are right, and none of those 10 is a right voice answer, the ladder shall move the drill up one level.
- [ ] **LADDER-LVL-003**: When a drill has at least 5 results at its current level and at most 2 of the last 5 are right, the ladder shall move the drill down one level, never below 1.
- [ ] **LADDER-LVL-004**: When a drill moves up or down a level, the ladder shall clear its results.
- [ ] **LADDER-LVL-005**: While a drill is at its highest level, the ladder shall not move it up.
- [ ] **LADDER-LVL-006**: The ladder shall check the level rules after every recorded result.

## Choosing the next exercise

- [ ] **LADDER-PICK-001**: When choosing the next exercise, the ladder shall choose a drill at random in proportion to its weight, at that drill's current level.
- [ ] **LADDER-PICK-002**: When a drill has fewer than 5 results at its current level, the ladder shall give it weight 2.
- [ ] **LADDER-PICK-003**: When a drill has 5 or more results at its current level, the ladder shall give it weight 1 plus twice the share of wrong answers among its last 10 results at that level.
- [ ] **LADDER-PICK-004**: Within a session, the ladder shall never choose the same drill more than three times in a row.
