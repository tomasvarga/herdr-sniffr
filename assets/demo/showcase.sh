#!/usr/bin/env bash
# One-command sniffr showcase for the VHS demo. Opens a split — tuicr (top-right)
# + hunk (bottom-right), driver strip on the left — then shows two beats:
#   1. multi-agent review   (per-agent findings; note the duplicates across lines)
#   2. --consensus          (merged to one comment per bug, with agent chips)
# Findings are curated (assets/demo/*.json) and injected with scripted timing so
# the demo is fast and deterministic; the rendering is exactly what sniffr emits.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PR="${DEMO_PR:-tomasvarga/sniffr-demo#7}"
REPO="${PR%#*}"; NUM="${PR##*#}"; SLUG="gh:${REPO}/pr/${NUM}"
PATCH="${DEMO_PATCH:-$HERE/payments.patch}"
RAW="$HERE/raw.json"; CONS="$HERE/consensus.json"
STEP="${SHOWCASE_STEP:-0.6}"     # delay between comments
BEAT="${SHOWCASE_BEAT:-2.5}"     # pause between beats

icon(){ case "$1" in critical) printf '🔴';; high) printf '🟠';; medium) printf '🟡';; low) printf '⚪';; *) printf '·';; esac; }
# badge body: "<icon> <sev> · <type>[ · N agents (chips)]" + finding + "↳ fix: …"
badge(){ local it="$1" sev typ body rec chips nag head
  sev=$(jq -r '.severity//""' <<<"$it"); typ=$(jq -r '.type//"note"' <<<"$it")
  body=$(jq -r '.body//""' <<<"$it"); rec=$(jq -r '.recommendation//""' <<<"$it")
  chips=$(jq -r '(.agents//[])|join("·")' <<<"$it"); nag=$(jq -r '(.agents//[])|length' <<<"$it")
  head="$(icon "$sev") $sev · $typ"; [ "${nag:-0}" -gt 0 ] && head="$head · ${nag} agents ($chips)"
  printf '%s\n%s' "$head" "$body"; [ -n "$rec" ] && [ "$rec" != null ] && printf '\n↳ fix: %s' "$rec"; }

tui_add(){ local it="$1" who="$2" line typ; line=$(jq -r '.line' <<<"$it"); typ=$(jq -r '.type//"note"' <<<"$it")
  [ "$line" = null ] && return
  tuicr review add --session "$SLUG" --repo "$REPO" --type "$typ" --target-file payments.py --line "$line" --side new --username "$who" "$(badge "$it")" >/dev/null 2>&1; }
hunk_add(){ local it="$1" who="$2" line; line=$(jq -r '.line' <<<"$it"); [ "$line" = null ] && return
  jq -n --arg f payments.py --argjson l "$line" --arg s "$(badge "$it")" --arg a "$who" \
    '{comments:[{filePath:$f,newLine:$l,summary:$s,author:$a}]}' | hunk session comment apply "$HSID" --stdin >/dev/null 2>&1; }
reload_tuicr(){ herdr pane send-text "$TU" ':e' >/dev/null 2>&1; herdr pane send-text "$TU" "$(printf '\r')" >/dev/null 2>&1; }

# ---- layout ---------------------------------------------------------------
outR=$(herdr pane split --current --direction right --ratio 0.28 --focus 2>/dev/null)
TU=$(jq -r '.result.pane.pane_id//empty' <<<"$outR")
herdr pane run "$TU" "tuicr pr $PR"
outB=$(herdr pane split "$TU" --direction down --ratio 0.5 --focus 2>/dev/null)
HU=$(jq -r '.result.pane.pane_id//empty' <<<"$outB")
herdr pane run "$HU" "hunk patch '$PATCH'"
# wait for both sessions
for _ in $(seq 1 40); do tuicr review list --repo "$REPO" 2>/dev/null | jq -e --arg s "$SLUG" 'any(.[]?;.slug==$s)' >/dev/null 2>&1 && break; sleep 0.4; done
HSID=""; for _ in $(seq 1 40); do HSID=$(hunk session list --json 2>/dev/null | jq -r --arg p "$PATCH" '.sessions[]?|select(.sourceLabel==$p)|.sessionId'|head -1); [ -n "$HSID" ] && break; sleep 0.4; done
# start clean (drop any drafts from a previous run)
sleep 1
herdr pane send-text "$TU" ':clearc' >/dev/null 2>&1; herdr pane send-text "$TU" "$(printf '\r')" >/dev/null 2>&1
hunk session comment clear "$HSID" --all --yes >/dev/null 2>&1
sleep 0.5

# ---- BEAT 1: multi-agent review ------------------------------------------
printf '\n  ▸ sniffr %s --agent codex,claude,cursor\n' "$PR"
printf '    multi-agent review — findings land in tuicr (top) + hunk (bottom)\n\n'
while IFS= read -r it; do ag=$(jq -r '.agent//"agent"' <<<"$it"); tui_add "$it" "$ag"; hunk_add "$it" "$ag"; sleep "$STEP"; done < <(jq -c 'sort_by(.line,.agent)[]' "$RAW")
reload_tuicr
hunk session navigate "$HSID" --next-comment >/dev/null 2>&1   # show a comment in hunk
sleep "$BEAT"

# ---- BEAT 2: consensus ----------------------------------------------------
printf '  ▸ sniffr %s --agent codex,claude,cursor --consensus\n' "$PR"
printf '    a cheap model merges duplicates → one comment per bug, with agent chips\n\n'
herdr pane send-text "$TU" ':clearc' >/dev/null 2>&1; herdr pane send-text "$TU" "$(printf '\r')" >/dev/null 2>&1
hunk session comment clear "$HSID" --all --yes >/dev/null 2>&1
sleep 1
while IFS= read -r it; do tui_add "$it" consensus; hunk_add "$it" consensus; sleep "$STEP"; done < <(jq -c 'sort_by(.line)[]' "$CONS")
reload_tuicr
hunk session navigate "$HSID" --next-comment >/dev/null 2>&1   # show a merged comment in hunk
printf '  ✓ %s raw findings → %s deduped, severity-ranked comments\n' "$(jq 'length' "$RAW")" "$(jq 'length' "$CONS")"
sleep "$BEAT"
