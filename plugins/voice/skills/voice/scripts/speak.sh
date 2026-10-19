#!/bin/bash
# Speaks the text read from stdin in the given voice, cutting off any answer still playing, and stops on its own the
# moment the microphone starts recording. Usage: speak.sh [voice] <<'TEXT' ... TEXT
voice="${1:-Milena}"
dir="$(cd "$(dirname "$0")" && pwd)"
watcher="${TMPDIR:-/tmp}/voice-mic-watch"

# Built once, and again whenever the source changes; without a Swift compiler the answer is still spoken.
if [ ! -x "$watcher" ] || [ "$dir/mic-watch.swift" -nt "$watcher" ]; then
  swiftc -O "$dir/mic-watch.swift" -o "$watcher" >/dev/null 2>&1
fi

# Read before backgrounding: a command started with & in a script gets /dev/null as its stdin, not ours.
text="$(cat)"
killall say 2>/dev/null
say -v "$voice" -r 185 "$text" &
speech=$!
[ -x "$watcher" ] && "$watcher" "$speech" &
wait "$speech"
exit 0
