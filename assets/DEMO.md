# Recording the sniffr demo GIF

sniffr's whole point is the **async, multi-pane** moment — you run it, tuicr opens
*immediately* in one herdr split, and the agent's comments land in that pane a few
seconds later while you're already reading. That can't be captured with
[VHS](https://github.com/charmbracelet/vhs): VHS records a single terminal, but
this plays out across herdr panes, and every sniffr command needs a live herdr
session. So this demo is a **real screen recording inside herdr**, not a tape.

## Tooling

A GIF screen recorder — [Kap](https://getkap.co) or Gifox on macOS (or QuickTime
screen capture → convert to GIF with `ffmpeg`/`gifski`). Record the **whole herdr
window** so both panes (gh-dash/your shell + the tuicr split) are visible.

## Setup for a clean take

- **A small PR with 1–3 genuine issues** so the findings are real and land fast.
  A throwaway demo repo you control is ideal (you can also re-run freely).
- **A fast agent** so the wait is short — `SNIFFR_AGENT=grok sniffr …` or codex.
  ~20–30s is normal; you'll trim the wait in editing.
- **Terminal size:** wide enough that the tuicr split isn't cramped (the diff +
  a comment gutter). ~120×32 in the herdr window is a good target.
- Start from a clean session so no stray panes are in frame.

## Shot sequence (aim for < 30s final)

1. **Establish it's ready** — `sniffr doctor` → the green ✓ column. (~2s)
2. **Fire it** — `sniffr <owner/repo#N>` (or `sniffr queue` → pick one). The
   message prints and a tuicr split opens on the right **instantly**. (~2s)
3. **Show you're already reading** — scroll the diff in the tuicr pane while the
   agent works. This is the point: you don't wait. (~5–10s)
4. **The payoff** — the notification fires, the pane reloads, and the agent's
   comments appear inline, anchored to the right lines, stamped with the agent
   name (distinct from your own). (~3s)
5. *(optional)* `dd` on a comment to drop one / `:clearc` to clear — shows the
   drafts are yours to prune and are never pushed. (~3s)

## Editing

- **Cut the agent wait.** Speed up or hard-cut the gap between step 3 and 4 —
  keep just enough to convey "kept reading, then they appeared."
- Keep it loopable and captionless; the README text carries the explanation.

## Wiring it in

Save the result as `assets/demo.gif`, then add near the top of `README.md`:

```md
![sniffr in action](assets/demo.gif)
```
