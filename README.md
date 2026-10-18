# voice

A voice mode for Claude Code. `/voice` turns it on: from then on every answer is one or two sentences and is
spoken aloud at once through the Mac's speakers with the macOS `say` command — no audio file, nothing to tap.
Made for quick questions while your eyes are on the code.

- The spoken copy is plain words only: code, paths and symbol names stay in the written reply.
- «без голоса» (or "stop voice") turns it off; «стоп» cuts the current answer short.
- macOS only; the sound plays on the machine the session runs on.

## Install

```
/plugin marketplace add JashIbra/voice
/plugin install voice@voice-marketplace
```

Or copy `plugins/voice/skills/voice/` into `~/.claude/skills/`.

## License

See [LICENSE](LICENSE).
