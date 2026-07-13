# Recording the sniffr demo GIF

`assets/demo.gif` is recorded **automatically** with [VHS](https://github.com/charmbracelet/vhs):
the tape starts a *fresh, isolated herdr session inside VHS's own terminal*, so
sniffr's tuicr split renders in the same frame VHS captures. `assets/demo.tape`
is the source.

## Prerequisites

- `vhs` and `ffmpeg` on `PATH`.
- A demo PR with an obvious, reliably-flagged issue. This GIF uses a small
  private repo, `tomasvarga/sniffr-demo#1` (a token-login handler with a
  `== None` check and a SQL-injection string-concat) — swap in your own.
- A working agent (the tape uses the default, `codex`).

## The one gotcha: strip `HERDR_*`

herdr refuses to start **nested** (it detects `HERDR_*` env vars and errors with
"nested herdr is disabled"). Since you're recording from inside herdr, unset
those vars for the `vhs` invocation so the herdr *inside VHS* starts clean:

```bash
env -u HERDR_SOCKET_PATH -u HERDR_PANE_ID -u HERDR_SESSION \
    -u HERDR_ENV -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID -u HERDR_CONFIG_PATH \
    vhs assets/demo.tape
herdr session stop demo   # clean up the throwaway session afterwards
```

The tape (`assets/demo.tape`): `cd ~` → `herdr --session demo` → type
`sniffr <pr>` → sleep while codex works. tuicr opens instantly; the comment
lands ~25–30s in when the agent finishes.

## Post-process (trim the boot + dead tail, speed the wait)

The raw capture is ~55s (mostly the agent-wait). Trim to the interesting window
and 2× it:

```bash
ffmpeg -ss 8 -t 25 -i demo.gif \
  -filter_complex "[0:v]setpts=0.5*PTS,fps=15,scale=1200:-1:flags=lanczos,\
split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer" \
  -y assets/demo.gif
```

Result: ~12s, ~160KB. Adjust `-ss`/`-t` to match where the comment appears in
your capture (extract frames with `ffmpeg -i demo.gif -vf fps=1 f_%02d.png` to
find it).

## Verifying (you can't see the recording live)

Sample frames and inspect them — early (tuicr open, no comments yet) and late
(comment landed, "Reloaded PR" in the status bar):

```bash
ffmpeg -i assets/demo.gif -vf fps=1 /tmp/f_%02d.png
```
