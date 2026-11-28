---
parent: high-level-design
prefix: SPOKEN
---

# Spoken Chess

## Context and Design Philosophy

Spoken chess is the language layer between chess and speech. Going out, it turns a structured prompt — a question, a square, a piece of feedback — into the exact words the app speaks. Coming in, it turns what the speech recognizer heard into a structured answer, or says that it cannot tell. It is part of the training core and knows nothing about audio: it works on text, so all of it can be tested without a device.

Two principles shape it. Spoken output sounds like a chess player talking, short and natural. Spoken input is forgiving where speech is unreliable: letters that sound alike are the main source of mistakes, so input accepts phonetic alternatives and never guesses silently between two readings.

## Speaking squares and prompts

A square is written as in algebraic notation with a capital letter: "E4". The speech engine says the rank digit as a number, and the same text reads naturally on screen.

Speech engines read a lone letter unreliably: "A" can come out as the article "uh", and pronunciation spellings such as "ay" are read as words ("aye"). So spoken chess also keeps one table giving each file letter's name in IPA:

| Letter | A | B | C | D | E | F | G | H |
|---|---|---|---|---|---|---|---|---|
| IPA | eɪ | biː | siː | diː | iː | ɛf | dʒiː | eɪtʃ |

For any phrase, spoken chess gives the position of each standalone capital A–H together with its IPA. The voice applies these, so the engine is told each letter's exact sounds. IPA belongs to no speech engine, so the same table serves any voice that accepts IPA. Templates never use a standalone capital A–H for anything but a square's file.

Prompts are short sentences built from templates, one per kind of question. For example:

- "F6. Light or dark?"
- "Two right from E4?"
- "C1 and H6. Same diagonal?"
- "From C1, up-right to the edge?"

Feedback is shorter still: a wrong answer is followed by the correct one in a few words ("F6 is dark", "G4"). Every template is in one place, so wording is changed without touching exercise logic.

## Understanding answers

The speech recognizer gives a few alternative transcriptions of what it heard. Spoken chess reads each alternative and tries to turn it into one of the answers or commands the caller allows at that moment. During an exercise that is answers of the question's kind plus the exercise commands: during a light-or-dark question, "e four" is not an answer and "dark" is. At other moments the caller names what is allowed, such as only "resume" and "stop" while paused, or yes and no for "Start training?".

Answer kinds and the words accepted for them:

| Answer kind | Accepted words |
|---|---|
| Light or dark | "light", "white" / "dark", "black" |
| Yes or no | "yes", "yeah", "yep", "correct", "same" / "no", "nope", "different", "not the same", "not same" |
| Square | a file word followed by a rank word, or a single token made of both ("b4", "B4") |
| Commands (any time) | "repeat", "again" / "skip", "I don't know", "not sure", "pass" / "pause" / "resume", "continue" / "stop" |

File words include the letter itself and the words it is commonly heard as ("ay", "hey", "bee", "be", "see", "sea", "dee", "ee", "ef", "gee", "jee", "aitch", "age"), the NATO alphabet (alpha, bravo, charlie, delta, echo, foxtrot, golf, hotel), and the German chess alphabet (Anton, Berta, Cäsar or Caesar, Dora, Emil, Friedrich, Gustav, Heinrich). Rank words include the digits, the number words and their common homophones ("won", "to", "too", "for", "fore", "ate"). Whole-word homophones of a square ("before" for b four) are accepted too. These lists are a starting set, extended as real misrecognitions are found.

Phrases are matched longest first, so "not the same" is read only as no, never also as "same". A square needs its file word immediately followed by its rank word. A transcription reads as one answer only when everything in it that is an answer word agrees: "dark, dark" reads as dark, but "light no dark" reads as nothing, and so does one that mixes a command and an answer ("repeat e four"). Filler words ("um", "uh", "it's", "I think") and words spoken chess does not know are ignored ("dark please" reads as dark), except that any non-filler word between a file word and a rank word stops them reading as a square.

## Certainty

The recognizer ranks its alternatives, best first. The result of reading them is one of:

- **Command** — the best alternative reads as a command. Commands are recognized only from the best alternative, so a lower-ranked "stop" never interrupts an answer.
- **Understood** — the best alternative reads as an answer, and no other alternative reads as a different answer.
- **Unsure** — the alternatives read as two or more different answers (for example "b four" and "d four"), or the best alternative reads as nothing and a lower-ranked one reads as an answer. The candidates are listed in the recognizer's order, at most three, and there may be only one.
- **Not understood** — nothing else applies.

These are checked in that order: a command first, then understood, then unsure. Yes-or-no questions are never unsure: they are understood only when the best alternative reads as yes or no and no alternative reads as the other, and otherwise not understood, since confirming with "yes?" would be confusing. Spoken chess never picks between candidates.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| Output of square names | Plain letters and numbers, written as notation ("E4") | Phonetic words ("echo four"); the rank as a number word ("E four") | Matches how chess players talk and think about squares, and the text shown on screen is the notation the player is learning. Phonetic output adds a translation step in the player's head; number words read oddly on screen and gain nothing in speech, where the engine says digits reliably. |
| Pronouncing file letters | Capital letter in the text, pronounced from a table of IPA letter names | Pronunciation spellings in the text ("ay four"); the bare letter left to the engine | Listening on a device showed engines read pronunciation spellings as words ("aye four"), and a bare letter can be read as a word ("A" as the article). IPA states the sounds exactly, keeps the text clean for display, and works with any engine that accepts IPA. |
| Input of square names | Plain letters plus NATO and German chess phonetics | Plain only; phonetic only | Plain letters are natural but b/d/e/g are easily confused; accepting phonetics gives the player an easy way to be unmistakable without forcing it. |
| Reading only the expected answer kind | Yes | Reading every possible answer | Most misrecognitions read as nothing in the expected kind, so they fail safely instead of becoming wrong answers. |
| Disagreeing alternatives | Report unsure with candidates | Take the recognizer's top choice | A misheard answer scored as wrong would push the player towards touch and break the eyes-free goal. |

## Open Questions & Future Decisions

### Deferred
1. Speaking pieces, moves and positions — designed with the move-following and position-memory rungs.
2. Whether other languages' phonetic alphabets are worth accepting.
