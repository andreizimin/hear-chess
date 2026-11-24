# Spoken Chess — EARS specs

Design: `spoken-chess-design.md`

## Output

- [ ] **SPOKEN-OUT-001**: When speaking a square, spoken chess shall produce its file letter followed by its rank as a number word ("e four").
- [ ] **SPOKEN-OUT-002**: When speaking a file letter, spoken chess shall produce text that the speech engine pronounces as the letter's name (in particular "a" as "ay", not as the article).
- [ ] **SPOKEN-OUT-003**: Spoken chess shall build every prompt, correction and session phrase from templates kept in one place, one template per kind of phrase.
- [ ] **SPOKEN-OUT-004**: When speaking the correction after a wrong answer, spoken chess shall produce the right answer in a few words ("f six is dark", "g four").

## Reading one transcription

- [ ] **SPOKEN-IN-001**: When reading a transcription for an answer, spoken chess shall consider only answers of the kind the current question expects (light or dark, yes or no, or square) plus commands.
- [ ] **SPOKEN-IN-002**: When reading a light-or-dark answer, spoken chess shall read "light" and "white" as light, and "dark" and "black" as dark.
- [ ] **SPOKEN-IN-003**: When reading a yes-or-no answer, spoken chess shall read "yes", "yeah", "yep", "correct" and "same" as yes, and "no", "nope", "different", "not the same" and "not same" as no.
- [ ] **SPOKEN-IN-004**: When reading a square answer, spoken chess shall read a file word followed by a rank word, or a single token of a file letter and rank digit ("b4", "B4"), as that square.
- [ ] **SPOKEN-IN-005**: When reading a square answer, spoken chess shall accept as file words the letter itself, its listed homophones ("ay", "hey", "bee", "be", "see", "sea", "dee", "ee", "ef", "gee", "jee", "aitch", "age"), the NATO alphabet (alpha to hotel) and the German chess alphabet (Anton, Berta, Cäsar or Caesar, Dora, Emil, Friedrich, Gustav, Heinrich).
- [ ] **SPOKEN-IN-006**: When reading a square answer, spoken chess shall accept as rank words the digits 1–8, the number words one to eight, and the homophones "won", "to", "too", "for", "fore" and "ate".
- [ ] **SPOKEN-IN-007**: When reading a square answer, spoken chess shall read listed whole-word homophones of a square ("before" for b four) as that square.
- [ ] **SPOKEN-IN-008**: When reading any transcription, spoken chess shall read "repeat" and "again" as repeat; "skip", "I don't know", "not sure" and "pass" as I don't know; "pause" as pause; "resume" and "continue" as resume; and "stop" as stop.
- [ ] **SPOKEN-IN-009**: When reading any transcription, spoken chess shall ignore filler words ("um", "uh", "it's", "I think").
- [ ] **SPOKEN-IN-010**: If a transcription contains answer words that disagree (such as "light no dark" or "yes not the same"), then spoken chess shall read it as nothing.

## Certainty across alternatives

- [ ] **SPOKEN-CERT-001**: When the best-ranked transcription alternative reads as a command, spoken chess shall give that command as the result.
- [ ] **SPOKEN-CERT-002**: When a lower-ranked alternative reads as a command and the best-ranked one does not, spoken chess shall ignore that command.
- [ ] **SPOKEN-CERT-003**: When the best-ranked alternative reads as an answer and no other alternative reads as a different answer, spoken chess shall give the result understood, with that answer.
- [ ] **SPOKEN-CERT-004**: When alternatives read as two or more different answers, spoken chess shall give the result unsure, with the candidate answers in the recognizer's order, at most three.
- [ ] **SPOKEN-CERT-005**: When the best-ranked alternative reads as nothing and a lower-ranked alternative reads as an answer, spoken chess shall give the result unsure, with the candidate answers in the recognizer's order, at most three.
- [ ] **SPOKEN-CERT-006**: When reading a yes-or-no answer whose alternatives read as both yes and no, spoken chess shall give the result not understood.
- [ ] **SPOKEN-CERT-007**: When no alternative reads as a command or an answer of the expected kind, spoken chess shall give the result not understood.
