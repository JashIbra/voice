#!/usr/bin/env python3
"""Stop hook: while voice mode is on, a reply that was never spoken is sent back to be spoken.

Voice mode is read from the transcript itself, so no state is kept anywhere: the last `/voice` in the
conversation decides — `off`, `-off` or `--off` turns it off, anything else turns it on. A turn counts
as spoken when one of its commands starts by running `speak.sh`. Turns started by a background-task
notification are left alone: the user asked nothing there."""
import json
import re
import sys

OFF_ARGS = {"off", "-off", "--off"}
# The command itself runs the script — not one that merely mentions it, such as a test of this hook.
SPEAK_CALL = re.compile(r"""\s*["']?[^\s"']*speak\.sh\b""")
COMMAND = re.compile(r"<command-name>/?(?:[\w-]+:)?voice</command-name>(?:\s*<command-args>(.*?)</command-args>)?", re.S)


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text")
    return ""


def blocks_of(entry, kind):
    content = entry.get("message", {}).get("content")
    if not isinstance(content, list):
        return []
    return [b for b in content if isinstance(b, dict) and b.get("type") == kind]


def voice_switch(entry):
    """True / False when this entry turns voice mode on / off, None when it does neither."""
    if entry.get("type") == "user":
        match = COMMAND.search(text_of(entry.get("message", {}).get("content")))
        if match:
            return (match.group(1) or "").strip().lower() not in OFF_ARGS
    if entry.get("type") == "assistant":
        for call in blocks_of(entry, "tool_use"):
            tool_input = call.get("input") or {}
            if call.get("name") == "Skill" and str(tool_input.get("skill", "")).split(":")[-1] == "voice":
                return str(tool_input.get("args") or "").strip().lower() not in OFF_ARGS
    return None


def is_prompt(entry):
    """A message from the user (typed or a slash command), or a notification — not a tool result, and not a
    hook's feedback (stored as a meta entry): that one continues the turn the user started."""
    return entry.get("type") == "user" and not entry.get("isMeta") and not blocks_of(entry, "tool_result") and text_of(
        entry.get("message", {}).get("content")).strip() != ""


def is_typed_by_user(entry):
    text = text_of(entry.get("message", {}).get("content")).strip()
    return not text.startswith("<") or "<command-name>" in text


def spoke(entry):
    return entry.get("type") == "assistant" and any(
        call.get("name") == "Bash" and SPEAK_CALL.match(str((call.get("input") or {}).get("command", "")))
        for call in blocks_of(entry, "tool_use")
    )


def main():
    data = json.load(sys.stdin)
    entries = []
    with open(data["transcript_path"], encoding="utf-8") as f:
        for line in f:
            try:
                entries.append(json.loads(line))
            except ValueError:
                pass

    voice_on = False
    for entry in entries:
        switch = voice_switch(entry)
        if switch is not None:
            voice_on = switch
    if not voice_on:
        return

    turn_start = max((i for i, e in enumerate(entries) if is_prompt(e)), default=None)
    if turn_start is None or not is_typed_by_user(entries[turn_start]):
        return
    if any(spoke(e) for e in entries[turn_start + 1:]):
        return
    print(json.dumps({
        "decision": "block",
        "reason": (
            "Voice mode is on and this reply was not spoken. Speak it now with the voice skill's speak.sh "
            "(backgrounded Bash call, plain words, the reply's language), then end the turn with one short line. "
            "Do not repeat the written reply and do not mention this check."
        ),
    }, ensure_ascii=False))


main()
