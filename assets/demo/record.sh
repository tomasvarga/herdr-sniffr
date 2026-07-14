#!/usr/bin/env bash
# Record the showcase (isolated herdr session inside VHS). Restores tuicr config.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
tcfg="$HOME/.config/tuicr/config.toml"
bak="/tmp/tuicr.bak.$$"; [ -f "$tcfg" ] && cp "$tcfg" "$bak" || true
printf 'no_update_check = true\nappearance = "dark"\nmouse = true\n' > "$tcfg"
cleanup(){ [ -f "$bak" ] && mv "$bak" "$tcfg" || true; herdr session stop scdemo >/dev/null 2>&1 || true; }
trap cleanup EXIT
cd "$HERE"
env -u HERDR_SOCKET_PATH -u HERDR_PANE_ID -u HERDR_SESSION -u HERDR_ENV \
    -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID \
    HERDR_CONFIG_PATH="$HERE/../demo-herdr.toml" \
    vhs showcase.tape
echo "wrote $HERE/showcase.mp4"
