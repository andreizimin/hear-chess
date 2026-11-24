---
parent: high-level-design
prefix: SPOKEN
---

# Spoken Chess

## Context and Design Philosophy

Spoken chess is the language layer between chess and speech. Going out, it turns a structured prompt — a question, a square, a piece of feedback — into the exact words the app speaks. Coming in, it turns what the speech recognizer heard into a structured answer, or says that it cannot tell. It is part of the training core and knows nothing about audio: it works on text, so all of it can be tested without a device.

Two principles shape it. Spoken output sounds like a chess player talking, short and natural. Spoken input is forgiving where speech is unreliable: letters that sound alike are the main source of mistakes, so input accepts phonetic alternatives and never guesses silently between two readings.

## Speaking squares and prompts

A square is spoken as its file letter and rank number: "e four". Output text is written so the speech engine pronounces each letter as a letter. In particular "a" must not be read as the article "uh", and the text for each letter is chosen so it is pronounced reliably.

Prompts are short sentences built from templates, one per kind of question. For example:

- "f six. Light or dark?"
- "Two right from e four?"
- "c one and h six. Same diagonal?"
- "From c one, up-right to the edge?"

Feedback is shorter still: a wrong answer is followed by the correct one in a few words ("f six is dark", "g four"). Every template is in one place, so wording is changed without touching exercise logic.

## Understanding answers

The speech recognizer gives a few alternative transcriptions of what it heard. Spoken chess reads each alternative and tries to turn it into an answer of the kind the current question expects. It considers only that kind: during a light-or-dark question, "e four" is not an answer and "dark" is.

Answer kinds and the words accepted for them:

| Answer kind | Accepted words |
|---|---|
| Light or dark | "light", "white" / "dark", "black" |
| Yes or no | "yes", "yeah", "yep", "correct", "same" / "no", "nope", "different", "not" |
| Square | a file word followed by a rank word |
| Commands (any time) | "repeat", "again" / "skip", "I don't know", "pass" / "pause" / "stop" |

File words include the letter itself and the words it is commonly heard as ("bee", "be", "see", "sea", "dee", "gee", "jee", "aitch"), the NATO alphabet (alpha, bravo, charlie, delta, echo, foxtrot, golf, hotel), and the German chess alphabet (Anton, Berta, Cäsar, Dora, Emil, Friedrich, Gustav, Heinrich). Rank words include the digits, the number words and their common homophones ("won", "to", "too", "for", "fore", "ate").

## Certainty

The result of reading the alternatives is one of:

- **Understood** — every alternative that reads as an answer reads as the same answer.
- **Unsure** — alternatives read as two or more different answers (for example "b four" and "d four").
- **Not understood** — no alternative reads as an answer or a command.

Unsure results carry the candidate answers so the session can ask which was meant. Spoken chess never picks between them.

## Decisions & Alternatives

| Decision | Chosen | Alternatives Considered | Rationale |
|---|---|---|---|
| Output of square names | Plain letters and numbers ("e four") | Phonetic words ("echo four") | Matches how chess players talk and think about squares. Phonetic output adds a translation step in the player's head. |
| Input of square names | Plain letters plus NATO and German chess phonetics | Plain only; phonetic only | Plain letters are natural but b/d/e/g are easily confused; accepting phonetics gives the player an easy way to be unmistakable without forcing it. |
| Reading only the expected answer kind | Yes | Reading every possible answer | Most misrecognitions read as nothing in the expected kind, so they fail safely instead of becoming wrong answers. |
| Disagreeing alternatives | Report unsure with candidates | Take the recognizer's top choice | A misheard answer scored as wrong would push the player towards touch and break the eyes-free goal. |

## Open Questions & Future Decisions

### Deferred
1. Speaking pieces, moves and positions — designed with the move-following and position-memory rungs.
2. The exact letter text for reliable pronunciation, settled by listening on a device.
3. Whether other languages' phonetic alphabets are worth accepting.
