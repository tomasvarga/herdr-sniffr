#!/usr/bin/env bash
# Symlink sniffr into ~/.local/bin.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$ROOT/bin/sniffr"
mkdir -p "$HOME/.local/bin"
ln -sfn "$ROOT/bin/sniffr" "$HOME/.local/bin/sniffr"
echo "sniffr: linked → ~/.local/bin/sniffr"
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "  note: add ~/.local/bin to your PATH" ;;
esac
echo "  needs: herdr, tuicr, gh, jq, python3, + an agent CLI (codex/claude/…)."
echo "  set your agent: sniffr --set-agent <name>"
