#!/usr/bin/env bash
# Install herdr-sniffr — the herdr integration layer over the standalone `sniffr`
# engine. Works two ways:
#   • from a local clone:  ./install.sh        (symlinks this checkout's launcher)
#   • piped from curl:     curl … | bash       (clones, then symlinks)
# It also ensures the engine (github.com/tomasvarga/sniffr) is installed, since
# the launcher delegates all real work to it.
set -euo pipefail

REPO="${HERDR_SNIFFR_REPO:-https://github.com/tomasvarga/herdr-sniffr.git}"
DEST="${HERDR_SNIFFR_HOME:-$HOME/.local/share/herdr-sniffr}"  # curl install clones here
BIN="${SNIFFR_BIN:-$HOME/.local/bin}"
CORE_HOME="${SNIFFR_HOME:-$HOME/.local/share/sniffr}"

# Running as a herdr plugin build hook? Use the plugin root. Otherwise: from a
# local clone (this file's dir), or piped from curl (no file on disk).
ROOT="${HERDR_PLUGIN_ROOT:-}"
if [ -z "$ROOT" ]; then
  SELF="${BASH_SOURCE[0]:-$0}"
  [ -f "$SELF" ] && ROOT="$(cd "$(dirname "$SELF")" && pwd)"
fi
if [ -z "$ROOT" ] || [ ! -f "$ROOT/bin/sniffr" ]; then
  command -v git >/dev/null || { echo "herdr-sniffr: git is required for a remote install" >&2; exit 1; }
  if [ -d "$DEST/.git" ]; then
    echo "herdr-sniffr: updating clone at $DEST"; git -C "$DEST" pull --ff-only -q || true
  else
    echo "herdr-sniffr: cloning $REPO → $DEST"; mkdir -p "$(dirname "$DEST")"; git clone -q "$REPO" "$DEST"
  fi
  ROOT="$DEST"
fi

# --- ensure the engine is installed ------------------------------------------
# As a herdr plugin this is handled by the `needs = ["sniffr"]` dep; for a plain
# curl install we bootstrap it here so the launcher has something to delegate to.
if [ ! -x "$CORE_HOME/bin/sniffr" ]; then
  echo "herdr-sniffr: installing the sniffr engine → $CORE_HOME"
  if command -v curl >/dev/null; then
    curl -fsSL https://raw.githubusercontent.com/tomasvarga/sniffr/main/install.sh | bash
  else
    echo "herdr-sniffr: sniffr engine not found and curl unavailable — install it manually:" >&2
    echo "  https://github.com/tomasvarga/sniffr" >&2
  fi
fi

chmod +x "$ROOT/bin/sniffr" "$ROOT/bin/sniffr-clip" 2>/dev/null || true
mkdir -p "$BIN"
# Point `sniffr` at the LAUNCHER (overrides the engine's own symlink, if any):
# inside herdr it opens the pane; outside herdr it passes straight through.
ln -sfn "$ROOT/bin/sniffr" "$BIN/sniffr"
echo "herdr-sniffr: linked $BIN/sniffr → $ROOT/bin/sniffr (launcher)"

case ":$PATH:" in *":$BIN:"*) ;; *) echo "  note: add $BIN to your PATH" ;; esac
echo "  needs: herdr + a backend (tuicr or hunk), plus gh, jq, python3, and an agent CLI."
echo "  next: 'sniffr doctor' to check your setup — or 'sniffr setup | pbcopy' and"
echo "        paste into your coding agent to have it finish setup for you."
