#!/bin/bash
# Speaks the text read from stdin in the given voice, cutting off any answer still playing or waiting. While the
# user is dictating it waits for the microphone to go quiet first, and it stops on its own the moment the microphone
# turns on again. Usage: speak.sh [voice] <<'TEXT' ... TEXT
# With no voice named, the Mac's system voice speaks (System Settings → Accessibility → Read & Speak) — the only way
# to reach the Siri and premium voices, which `say -v` cannot name.
voice="${1:-}"
dir="$(cd "$(dirname "$0")" && pwd)"
# One folder for the script and for the hook that cancels it: the per-user temp folder, whatever TMPDIR says.
state="$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || echo "${TMPDIR:-/tmp}/")"
watcher="${state}voice-mic-watch"
pidfile="${state}voice-speak.pid"

# Built once, and again whenever the source changes; without a Swift compiler the answer is spoken at once.
if [ ! -x "$watcher" ] || [ "$dir/mic-watch.swift" -nt "$watcher" ]; then
  swiftc -O "$dir/mic-watch.swift" -o "$watcher" >/dev/null 2>&1
fi

# Read before backgrounding: a command started with & in a script gets /dev/null as its stdin, not ours.
text="$(cat)"
# The synthesizer reads marks aloud ("backslash", "quote"): drop quotes, backslashes and markdown, and say an arrow
# as a pause.
text="$(printf '%s' "$text" | perl -CSD -Mutf8 -pe 's/[«»„“”"`\\*#_|]//g; s/\s*[→⇒]\s*/, /g')"

# Only the newest answer may speak: an older one still waiting for the microphone would talk over it later.
kill "$(cat "$pidfile" 2>/dev/null)" 2>/dev/null
killall say 2>/dev/null
echo $$ > "$pidfile"
children=""
trap 'kill $children 2>/dev/null; exit 0' TERM INT

if [ -x "$watcher" ]; then
  "$watcher" --wait-quiet &
  children=$!
  wait "$children" || exit 0
fi

say ${voice:+-v "$voice"} -r 185 "$text" &
speech=$!
children="$speech"
if [ -x "$watcher" ]; then
  "$watcher" "$speech" &
  children="$speech $!"
fi
wait "$speech"
[ "$(cat "$pidfile" 2>/dev/null)" = "$$" ] && rm -f "$pidfile"
exit 0
