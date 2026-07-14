#!/usr/bin/env bash
# Reset ONE tuicr session (the demo PR) so the showcase starts empty. Surgical:
# removes only $SLUG from index.json + active_sessions.json and deletes its
# session file. Backs both up first; never touches other sessions.
set -uo pipefail
SLUG="${1:-gh:tomasvarga/sniffr-demo/pr/7}"
R="$HOME/Library/Application Support/tuicr/reviews"
[ -d "$R" ] || { echo "no tuicr dir"; exit 0; }
cp "$R/index.json" "$R/index.json.bak" 2>/dev/null || true
cp "$R/active_sessions.json" "$R/active_sessions.json.bak" 2>/dev/null || true
sp=$(jq -r --arg s "$SLUG" '.sessions[]?|select(.slug==$s)|.path' "$R/active_sessions.json" 2>/dev/null | head -1)
[ -z "$sp" ] && sp=$(jq -r --arg s "$SLUG" '.entries[$s].path // empty' "$R/index.json" 2>/dev/null)
jq --arg s "$SLUG" 'if .entries then .entries |= del(.[$s]) else . end' "$R/index.json" > "$R/index.json.tmp" && mv "$R/index.json.tmp" "$R/index.json"
jq --arg s "$SLUG" '.sessions |= map(select(.slug != $s))' "$R/active_sessions.json" > "$R/active_sessions.json.tmp" && mv "$R/active_sessions.json.tmp" "$R/active_sessions.json"
[ -n "$sp" ] && [ -f "$sp" ] && rm -f "$sp"
echo "reset tuicr session $SLUG (deleted ${sp:-<none>})"
