#!/usr/bin/env bash
# Install sniffr. Works two ways:
#   • from a local clone:  ./install.sh          (symlinks this checkout)
#   • piped from curl:     curl … | bash         (clones, then symlinks)
set -euo pipefail

REPO="${SNIFFR_REPO:-https://github.com/tomasvarga/herdr-sniffr.git}"
DEST="${SNIFFR_HOME:-$HOME/.local/share/sniffr}"   # where a curl install clones to
BIN="${SNIFFR_BIN:-$HOME/.local/bin}"

# Running as a herdr plugin build hook? Use the plugin root. Otherwise: from a
# local clone (this file's dir), or piped from curl (no file on disk).
ROOT="${HERDR_PLUGIN_ROOT:-}"
if [ -z "$ROOT" ]; then
  SELF="${BASH_SOURCE[0]:-$0}"
  [ -f "$SELF" ] && ROOT="$(cd "$(dirname "$SELF")" && pwd)"
fi

if [ -z "$ROOT" ] || [ ! -f "$ROOT/bin/sniffr" ]; then
  command -v git >/dev/null || { echo "sniffr: git is required for a remote install" >&2; exit 1; }
  if [ -d "$DEST/.git" ]; then
    echo "sniffr: updating clone at $DEST"
    git -C "$DEST" pull --ff-only -q || true
  else
    echo "sniffr: cloning $REPO → $DEST"
    mkdir -p "$(dirname "$DEST")"
    git clone -q "$REPO" "$DEST"
  fi
  ROOT="$DEST"
fi

chmod +x "$ROOT/bin/sniffr" "$ROOT/bin/sniffr-clip" 2>/dev/null || true
mkdir -p "$BIN"
ln -sfn "$ROOT/bin/sniffr" "$BIN/sniffr"
echo "sniffr: linked $BIN/sniffr → $ROOT/bin/sniffr"

case ":$PATH:" in *":$BIN:"*) ;; *) echo "  note: add $BIN to your PATH" ;; esac
echo "  needs: herdr + a backend (tuicr or hunk), plus gh, jq, python3, and an agent CLI."
echo "  next: 'sniffr doctor' to check your setup — or 'sniffr setup | pbcopy' and"
echo "        paste into your coding agent to have it finish setup for you."
