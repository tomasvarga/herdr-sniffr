#!/usr/bin/env bash
# Record the showcase in a FRESH isolated herdr session (unique name → no restore).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SESS="sc$(date +%s)"
tcfg="$HOME/.config/tuicr/config.toml"
bak="/tmp/tuicr.bak.$$"; [ -f "$tcfg" ] && cp "$tcfg" "$bak" || true
printf 'no_update_check = true\nappearance = "dark"\nmouse = true\n' > "$tcfg"
tape="/tmp/showcase.$$.tape"; sed "s/__SESSION__/$SESS/" "$HERE/showcase.tape" > "$tape"
cleanup(){ [ -f "$bak" ] && mv "$bak" "$tcfg" || true; herdr session stop "$SESS" >/dev/null 2>&1 || true; rm -f "$tape"; }
trap cleanup EXIT
DEMO_PR="${DEMO_PR:-tomasvarga/sniffr-demo#7}"
bash "$HERE/reset.sh" "gh:${DEMO_PR%#*}/pr/${DEMO_PR##*#}" || true
cd "$HERE"
env -u HERDR_SOCKET_PATH -u HERDR_PANE_ID -u HERDR_SESSION -u HERDR_ENV \
    -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID \
    HERDR_CONFIG_PATH="$HERE/../demo-herdr.toml" \
    vhs "$tape"
echo "wrote $HERE/showcase.mp4  (session $SESS)"
