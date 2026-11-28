# Spoken Chess — EARS specs

Design: `spoken-chess-design.md`

## Output

- [x] **SPOKEN-OUT-001**: When speaking a square, spoken chess shall produce the capital file letter followed by its rank digit (for example "A4" for a4, "E4" for e4).
- [x] **SPOKEN-OUT-003**: Spoken chess shall build every prompt, correction and session phrase from templates kept in one place, one template per kind of phrase.
- [x] **SPOKEN-OUT-004**: When speaking the correction after a wrong answer, spoken chess shall produce the right answer in a few words ("F6 is dark", "G4").
- [x] **SPOKEN-OUT-005**: Spoken chess shall keep one table giving each file letter\'s name in IPA (A eɪ, B biː, C siː, D diː, E iː, F ɛf, G dʒiː, H eɪtʃ), and shall give, for any phrase, the range of each standalone capital letter A–H with that letter\'s IPA.

## Reading one transcription

- [x] **SPOKEN-IN-001**: When reading a transcription, spoken chess shall consider only the answers and commands allowed at that moment, as given by the caller: during an exercise, answers of the exercise's kind (light or dark, yes or no, or square) and the exercise commands; at other moments, the commands or yes-or-no answers the caller names.
- [x] **SPOKEN-IN-002**: When reading a light-or-dark answer, spoken chess shall read "light" and "white" as light, and "dark" and "black" as dark.
- [x] **SPOKEN-IN-003**: When reading a yes-or-no answer, spoken chess shall read "yes", "yeah", "yep", "correct" and "same" as yes, and "no", "nope", "different", "not the same", "not same" and "not correct" as no.
- [x] **SPOKEN-IN-004**: When reading a square answer, spoken chess shall read a file word immediately followed by a rank word, or a single token of a file letter and rank digit ("b4", "B4"), as that square.
- [x] **SPOKEN-IN-005**: When reading a square answer, spoken chess shall accept as file words the letter itself, its listed homophones ("ay", "hey", "bee", "be", "see", "sea", "dee", "ee", "ef", "gee", "jee", "aitch", "age"), the NATO alphabet (alpha to hotel) and the German chess alphabet (Anton, Berta, Cäsar or Caesar, Dora, Emil, Friedrich, Gustav, Heinrich).
- [x] **SPOKEN-IN-006**: When reading a square answer, spoken chess shall accept as rank words the digits 1–8, the number words one to eight, and the homophones "won", "to", "too", "for", "fore" and "ate".
- [x] **SPOKEN-IN-007**: When reading a square answer, spoken chess shall read listed whole-word homophones of a square ("before" for b four) as that square.
- [x] **SPOKEN-IN-008**: Where commands are allowed, spoken chess shall read "repeat" and "again" as repeat; "skip", "I don't know", "not sure" and "pass" as I don't know; "pause" as pause; "resume" and "continue" as resume; and "stop" as stop.
- [x] **SPOKEN-IN-009**: When reading any transcription, spoken chess shall ignore filler words ("um", "uh", "it's", "I think") and any other word it does not know ("dark please" reads as dark), except that a word other than a filler between a file word and a rank word stops them reading as a square ("e and four" is not e4).
- [x] **SPOKEN-IN-010**: If a transcription contains answer words that disagree (such as "light no dark"), or both a command and an answer ("repeat e four"), then spoken chess shall read it as nothing.
- [x] **SPOKEN-IN-011**: When matching answer words, spoken chess shall match the longest listed phrase first, so "not the same" is read only as no and not also as "same".

## Certainty across alternatives

Precedence: a command from the best-ranked alternative (CERT-001) comes first, then the yes-or-no rule (CERT-006), then understood (CERT-003), then unsure (CERT-004, CERT-005), and otherwise not understood (CERT-007).

- [x] **SPOKEN-CERT-001**: When the best-ranked transcription alternative reads as a command, spoken chess shall give that command as the result, whatever the other alternatives read as.
- [x] **SPOKEN-CERT-002**: Spoken chess shall ignore any command read only from an alternative other than the best-ranked one.
- [x] **SPOKEN-CERT-003**: When reading a light-or-dark or square answer, and the best-ranked alternative reads as an answer and no other alternative reads as a different answer, spoken chess shall give the result understood, with that answer.
- [x] **SPOKEN-CERT-004**: When reading a light-or-dark or square answer, and the alternatives read as two or more different answers, spoken chess shall give the result unsure, with the candidate answers in the recognizer's order, at most three.
- [x] **SPOKEN-CERT-005**: When reading a light-or-dark or square answer, and the best-ranked alternative reads as nothing while a lower-ranked one reads as an answer, spoken chess shall give the result unsure, with the candidates in the recognizer's order, at most three (possibly only one).
- [x] **SPOKEN-CERT-006**: When reading a yes-or-no answer and the best-ranked alternative does not read as a command, spoken chess shall give the result understood only if the best-ranked alternative reads as yes or no and no alternative reads as the other; otherwise it shall give the result not understood.
- [x] **SPOKEN-CERT-007**: When no alternative reads as an allowed command or answer, spoken chess shall give the result not understood.
