# voice

A voice mode for Claude Code. `/voice` turns it on: from then on every answer is one or two sentences and is
spoken aloud at once through the Mac's speakers with the macOS `say` command — no audio file, nothing to tap.
Made for quick questions while your eyes are on the code.

- The spoken copy is plain words only: code, paths and symbol names stay in the written reply.
- `/voice off` turns it off.
- The answer being spoken stops the moment you send a new message or turn the microphone on (start
  dictating) — no command needed.
- While the mode is on, a reply that was not spoken is sent back to be spoken before the turn ends (a `Stop`
  hook, `plugins/voice/hooks/require-speech.py`).
- macOS only; the sound plays on the machine the session runs on. The microphone watcher is built with
  `swiftc` (Xcode command line tools) on first use; without it, answers are still spoken.

## Install

```
/plugin marketplace add JashIbra/voice
/plugin install voice@voice-marketplace
```

Or copy `plugins/voice/skills/voice/` into `~/.claude/skills/`; the hooks — stopping the voice on a new message,
and sending an unspoken reply back — come only with the plugin install (`plugins/voice/hooks/hooks.json`), so
add them to your settings by hand then.

## License

See [LICENSE](LICENSE).
