---
name: voice
description: Voice mode — from now on every answer is short and is also spoken aloud at once through the Mac's speakers with the macOS `say` command, no file and no tap needed. Use when the user types /voice or /voice on, or says «голосом», «озвучивай ответы», «голосовой режим». `/voice off` (also `-off`, `--off`, «без голоса», «выключи голос») turns it off.
argument-hint: "[on|off]"
---

# Voice mode

The user is looking at something else — code under review, a device — and asks quick questions. Every
answer from now on is spoken aloud the moment it is ready, so they never have to look at the chat or tap
anything.

## The argument

- **None, or `on`** — turn the mode on (below).
- **`off`, `-off` or `--off`** — turn it off: run `killall say 2>/dev/null` to cut off anything still playing,
  reply in text with one line ("Голос выключен."), and from then on answer as usual, without speaking.

## Turn on

Reply with one short line ("Голос включён.") and speak it, so the user hears the mode is on.

## Every answer while the mode is on

1. **Short.** One or two sentences: the answer itself, no preamble, no recap, no offer to go deeper.
   A question that genuinely cannot be answered that short (a plan, a review, a walk through code) gets
   its normal written answer, and only its first sentence — the verdict — is spoken, unless the user asked
   for the whole answer to be read out.
2. **Write it** as the reply text, in the user's language.
3. **Speak it** in the same turn, with a backgrounded Bash call so the reply is not held up, through the
   script next to this file (this skill's base directory is given when it loads):

   ```bash
   "<this skill's base directory>/scripts/speak.sh" <<'TEXT'
   <the spoken text>
   TEXT
   ```

   - The script cuts off the previous answer first, so a new one never talks over it.
   - It stops the answer by itself the moment the microphone starts recording: the user starts dictating,
     and the voice goes quiet. (A small watcher, built from `scripts/mic-watch.swift` on first use.)
   - If the user is still dictating when the answer is ready, it waits until the microphone has been off
     for 2 seconds, so the voice never lands in their recording; a new message from them drops it.
   - Name no voice: the Mac's system voice speaks, which is the voice the user picked in System Settings →
     Accessibility → Read & Speak (Siri voices included). Name one (`speak.sh Milena`) only when the reply is
     in a language the system voice does not speak; take it from `say -v '?'`.
   - The text goes in through the here-doc, so quotes and `$` need no escaping.

## What goes into the spoken text

- Plain words only. No code, file paths, links, symbol names, `snake_case`, numbers with units
  glued on — the synthesizer reads them as noise. Say what the thing is: not "`syncInterval` in
  `RepetitionTaskDao`" but "синхронизация этапов в базе телефона".
- When the written answer walks through code, say the line numbers aloud too ("строки с 13 по 22: ..."),
  so the user can follow in the editor without guessing where the voice is.
- Name the thing each sentence is about; "вызывается проверка" says nothing until it says what is checked.
- The written reply may keep the symbols; only the spoken copy is cleaned.
- Numbers as the language says them aloud ("девять часов", not "9h").

## Stopping

- A new message from the user cuts off the answer being spoken (the plugin's `UserPromptSubmit` hook runs
  `killall say`), and so does turning the microphone on.
- `/voice off` ends the mode, as above.

## Limits to keep in mind

- macOS only; the sound plays on the Mac this session runs on, not on the user's phone.
- No sound can be started from the chat app itself, so this is the only way to answer aloud without a tap.
