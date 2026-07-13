# Recording the sniffr demo GIF

`assets/demo.gif` is recorded **automatically** with [VHS](https://github.com/charmbracelet/vhs):
the tape (`assets/demo.tape`) starts a *fresh, isolated herdr session inside VHS's
own terminal*, so sniffr's tuicr split renders in the same frame VHS captures.

## Prerequisites

- `vhs` and `ffmpeg` on `PATH`.
- The demo PR `tomasvarga/sniffr-demo#1` (private) — a token-login handler with a
  SQL-injection concat and a hardcoded credential. Swap in your own.

## The gotchas (each cost a take to discover)

1. **Strip `HERDR_*`** — herdr refuses to start *nested* ("nested herdr is
   disabled"). Recording from inside herdr, you must unset those vars so the
   herdr *inside VHS* starts clean.
2. **Theme** — the fresh session uses herdr's default (`catppuccin`). Point it at
   `assets/demo-herdr.toml` (`[theme] name = "tokyo-night"`, `pane_history = false`
   so old panes aren't restored) via `HERDR_CONFIG_PATH`.
3. **tuicr must be dark too** — temporarily set `appearance = "dark"` in
   `~/.config/tuicr/config.toml` (back it up + restore). Do **not** set `theme =`
   there — that key expects a local theme file and makes tuicr fail to launch.
4. **Clean the tuicr session first** — a stale/dangling session for the PR makes
   `tuicr pr` error ("No such file") or stacks duplicate comments. Delete the
   session file **and** its `index.json` / `active_sessions.json` entries. Match
   on `sniffr-demo` (the slug is stored as separate fields, not one string).
5. **Deterministic findings** — a live agent is non-deterministic (dupes, misses).
   For a clean, repeatable demo, feed curated findings through sniffr's own
   escape hatch: `SNIFFR_CMD="sleep 7 && cat assets/demo-findings.json"`. The
   whole pipeline is still real (split, content-anchoring, injection, reload) —
   only the LLM call is substituted. The 7s sleep gives the async "read while it
   works" beat.

## Record

```bash
tcfg=~/.config/tuicr/config.toml
cp "$tcfg" /tmp/tuicr.bak
printf 'no_update_check = true\nappearance = "dark"\nmouse = true\n' > "$tcfg"

# nuke any stale demo session (files + index) — see gotcha #4
# ... then:
env -u HERDR_SOCKET_PATH -u HERDR_PANE_ID -u HERDR_SESSION -u HERDR_ENV \
    -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID \
    HERDR_CONFIG_PATH="$PWD/assets/demo-herdr.toml" \
    SNIFFR_CMD="sleep 7 && cat '$PWD/assets/demo-findings.json'" \
    SNIFFR_AGENT=codex \
    vhs assets/demo.tape

herdr session stop sndemo
cp /tmp/tuicr.bak "$tcfg"   # ALWAYS restore your tuicr config
```

## Post-process (trim boot + tail, speed the wait)

```bash
ffmpeg -ss 9 -t 18 -i demo.gif \
  -filter_complex "[0:v]setpts=0.55*PTS,fps=15,scale=1200:-1:flags=lanczos,\
split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer" \
  -y assets/demo.gif
```

Result: ~10s, ~175KB. Adjust `-ss`/`-t` to where the comments land in your take.

## Verifying (you can't watch the recording live)

Extract frames and inspect — start (tuicr loading), end (both comments, "Reloaded
PR" in the status bar):

```bash
ffmpeg -i assets/demo.gif -vf fps=1 /tmp/f_%02d.png
```
