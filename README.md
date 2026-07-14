# herdr-sniffr

<img src="assets/icon.png" width="88" align="right" alt="herdr-sniffr">

An AI **sniffs your PR for issues before you review it**. Point `sniffr` at a
GitHub pull request: it opens the PR in your terminal reviewer —
**[tuicr](https://tuicr.dev)** by default, **[hunk](https://hunk.dev)**, or
your own tool — then an AI agent reviews the diff **in the background** and drops
its findings in as draft comments, so by the time you start reading, the risky
lines are already flagged. Agent-agnostic (Codex, Claude, Cursor, Grok,
opencode, ollama) and backend-agnostic (tuicr · hunk · custom).

> The command is **`sniffr`**; the plugin/repo is **herdr-sniffr**. This is the
> **herdr layer** over the standalone [`sniffr`](https://github.com/tomasvarga/sniffr)
> engine — it opens the reviewer pane and wires herdr's reload + toast, then
> hands the actual review to the engine (which it installs for you). Not on
> herdr? Use the engine directly.

![sniffr in action](assets/demo.gif)

Part of a terminal PR-review workflow on [herdr](https://herdr.dev); pairs with
[herdr-pickr](https://github.com/tomasvarga/herdr-pickr) (add it as a `[[backend]]`).

> **sniffr never posts to GitHub.** Every comment is a **local draft** on your
> machine — you read them, prune the noise, and submit what's left yourself. The
> AI's pass is private scaffolding for *you*, never something the PR author sees
> unless you choose to send it.

Run `sniffr doctor` first — it checks deps, herdr, `gh` auth, your agent, and
notifications, and tells you exactly what's missing.

## How it works

```
sniffr <pr>
  → your reviewer opens the PR in a herdr split — you start reading immediately
    (tuicr by default; hunk or a custom backend — see "Backends")
  → a detached worker runs your agent over the diff
  → findings injected as LOCAL-DRAFT comments, anchored to the right lines (never pushed)
  → a notification fires when they land
```

## Quick setup (recommended)

Paste this into any coding agent with shell access (Claude Code, Codex, Cursor,
…). It installs sniffr, resolves deps, picks a backend + agent, and verifies —
asking you only when there's a real choice. (Same as `sniffr setup` once
installed.)

```text
Set up sniffr on my machine — a CLI that, pointed at a GitHub PR, opens it in my
terminal reviewer and has an AI agent drop local-draft review comments on the
risky lines before I read them. Work through this, asking me only when there's a
real choice; show me any install command before running it. sniffr never posts
to GitHub (comments are local drafts), so don't push code or post to a PR.

1. If `sniffr` isn't installed, run:
   curl -fsSL https://raw.githubusercontent.com/tomasvarga/herdr-sniffr/main/install.sh | bash
   and make sure ~/.local/bin is on my PATH.
2. Run `sniffr doctor` and fix each ✗: install missing core deps (gh, jq,
   python3, herdr from herdr.dev); if gh isn't authenticated tell me to run
   `gh auth login` myself; note that sniffr must run from inside a herdr pane.
3. Backend (where comments land): sniffr auto-detects tuicr → hunk. If neither
   is installed, ask which I prefer and install it (tuicr: tuicr.dev; hunk:
   `brew install modem-dev/tap/hunk`). For a non-default choice write
   `backend = "hunk"` to ~/.config/sniffr/config.toml.
4. Agent: detect which of codex/claude/cursor-agent/grok/opencode/ollama is
   installed + authenticated, then `sniffr --set-agent <name>`. If none, tell me
   which to install.
5. Verify with `sniffr doctor` (all ✓), then run `sniffr <a real PR of mine>`
   from a herdr pane and confirm draft comments appear. Remind me they're local
   drafts I prune (dd) and submit myself.
```

## Install (manual)

One-liner (clones herdr-sniffr to `~/.local/share/herdr-sniffr`, **bootstraps the
[`sniffr`](https://github.com/tomasvarga/sniffr) engine** into `~/.local/share/sniffr`,
and links the launcher onto your PATH as `sniffr`):

```bash
curl -fsSL https://raw.githubusercontent.com/tomasvarga/herdr-sniffr/main/install.sh | bash
```

Re-run it any time to update (it `git pull`s the clone). Or from a local checkout:

```bash
git clone https://github.com/tomasvarga/herdr-sniffr && ./herdr-sniffr/install.sh
```

Then `sniffr doctor` to check your setup.

## Usage

```bash
sniffr <pr>                 # number | owner/repo#N | URL   (run from a herdr pane)
sniffr <pr> --agent grok    # one-off agent override
sniffr <pr> --agent codex,claude,grok   # several agents, one pass (stamped per agent)
sniffr <pr> --backend hunk  # deliver findings to hunk instead of tuicr
sniffr <pr> --model gpt-5.6-codex-high   # model for the agent (else its default)
sniffr --set-agent grok     # save the default agent (--show-agent prints it)
sniffr queue                # pick from the PRs actually awaiting your review
sniffr doctor               # preflight: deps, herdr, gh auth, agent, backend
```

Pick the agent (first match wins): `--agent` flag · `SNIFFR_AGENT` env · saved
default (`~/.config/sniffr/agent`) · `codex`. Built-ins: **codex · claude ·
cursor-agent · grok · opencode · ollama**. Any other tool via `SNIFFR_CMD='<command>'`
(gets the review prompt on stdin, must print a JSON array of findings). Findings
are stamped with the agent name so they're distinct from yours; in tuicr `dd`
drops one, `:clearc` clears all.

**Multiple agents, one pass** — pass a comma list (`--agent codex,claude,grok`).
Each reviews the same diff and its findings are injected **stamped by agent**, so
you see who flagged what (two agents on the same line = high signal). They run
sequentially (~30s each), appearing progressively.

Pick the **model** (first match wins): `--model` flag · `SNIFFR_MODEL` env ·
`model =` in config · else **each agent's own default** (e.g. cursor's `auto`).
Applies to any agent (codex · claude · cursor-agent · grok · opencode · ollama);
use that agent's model naming, e.g. `--model gpt-5.6-codex-high` (cursor-agent),
`provider/model` (opencode), or a tag like `llama3.1` (ollama — also needs
`ollama serve` running + the model pulled). (`cursor` is accepted as an alias for
`cursor-agent`.)

**Tune the review** — set `prompt` in `~/.config/sniffr/config.toml` to change
*what* the agent looks for (security-only, perf-sensitive, project rules, …).
sniffr always appends the machine-readable output contract itself, so you only
describe the focus, never the format. `max` caps findings per review.

```toml
prompt = "You are a security-focused reviewer. Prioritize auth and input validation; ignore style."
max    = 8
```

**Pane placement** — how the reviewer opens in herdr (default: a right split).
This is a herdr-plugin setting, so it lives in the **herdr plugins config dir**
(`~/.config/herdr/plugins/config/sniffr/config.toml`), separate from the engine's
`~/.config/sniffr/config.toml` above:

```toml
# ~/.config/herdr/plugins/config/sniffr/config.toml
[pane]
placement = "split"   # "split" (side-by-side) or "zoom" (maximize the reviewer)
direction = "right"   # "right" or "down"
ratio     = 0.5        # split size, 0.0–1.0
```

### Backends — where the findings go

sniffr's core (diff → agent → line-anchored findings) is backend-agnostic; a
**backend** decides how they're presented. sniffr has native support for two
reviewers — **tuicr** and **hunk** (both separate tools you install) — and
anything else plugs in as a **custom** backend. Selection (first match wins):
`--backend` flag · `SNIFFR_BACKEND` env · `backend =` in
`~/.config/sniffr/config.toml` · else sniffr **auto-detects** whichever
supported reviewer is installed (tuicr, then hunk).

**Choosing a backend:**

| Your setup | What to do |
|------------|------------|
| Have **tuicr** | nothing — it's auto-selected |
| Prefer / only have **hunk** | `backend = "hunk"` (or `--backend hunk`) |
| Your own reviewer | add a `[backends.<name>]` block (below) |
| Not sure what you have | `sniffr doctor` — shows the resolved backend + how to fix a missing one |

- **`tuicr`** (default) — [tuicr.dev](https://tuicr.dev); sniffr opens `tuicr pr`,
  injects local-draft comments into the live session, reloads.
- **`hunk`** — [hunk.dev](https://hunk.dev); sniffr opens `hunk patch` and injects
  into the live hunk session via its comment API. Same async model as tuicr.
- **custom** — define your own reviewer in `config.toml`. sniffr resolves the
  findings, then runs your `open` command (launch the viewer in a split) and
  pipes the findings JSON to your `inject` command:

  ```toml
  # ~/.config/sniffr/config.toml
  backend = "tuicr"          # the default when --backend / env aren't set

  [backends.myreviewr]
  open   = "myreviewr open {url}"   # {url} {repo} {num} {diff} {pane}
  inject = "myreviewr import --stdin"
  ```

  This is how any other review tool (e.g. herdr-reviewr) plugs in without sniffr
  hardcoding its API. See [`config/config.example.toml`](config/config.example.toml).

### `sniffr queue` — pick from your review list

Instead of pasting a URL, ask GitHub what's waiting on you and pick from a menu:

```bash
sniffr queue                # menu of PRs awaiting your review → pick → sniff it
sniffr queue --agent grok   # …and use grok on whatever you pick
```

It runs one `gh search` for open PRs where you're a requested reviewer (across
**all** your repos — no checkout), then filters to what actually matters by
default:

- **no bots** — drops Dependabot/Renovate dependency bumps
- **no drafts** — skips WIP
- **recent only** — activity in the last **3 weeks** (buries stale/dangling
  review requests)

Arrow keys / number to select, `q` to cancel. Picking a PR runs the normal
`sniffr <pr>` path on it — so `queue` is purely a target-picker and never
diverges from the manual flow. Dials for when the defaults are wrong:

```bash
sniffr queue --since 2mo    # widen the activity window (21d|3w|2mo|1y)
sniffr queue --all          # the full list: bots + drafts + no date cutoff
sniffr queue --include-bots # add bots back
sniffr queue --drafts       # add drafts back
```

## Requirements

**herdr ≥ 0.7.0**, the **[`sniffr`](https://github.com/tomasvarga/sniffr) engine**
(installed automatically), `gh` (authenticated), `jq`, `python3` (≥3.11 for
config), and at least one **agent CLI** (codex/claude/cursor-agent/grok/opencode/
ollama) on your `PATH`. Plus the binary for your backend: **tuicr** (default) or
**[hunk](https://hunk.dev)**. Runs from inside a herdr pane. GitHub only for now.
macOS and Linux (`sniffr doctor` verifies all of the above).

## Limitations

- **This plugin needs herdr** — it opens the reviewer in a herdr split and
  reloads it. Not on herdr? The [`sniffr`](https://github.com/tomasvarga/sniffr)
  engine runs standalone (attach mode or `--format json`); this plugin is just
  the herdr integration on top of it.
- **Line anchoring** is by content: the agent quotes the exact line, and sniffr
  parses the diff to resolve the real new-side line number (the agent's own count
  is only a tiebreaker). A quote that can't be matched becomes a file-level comment.
- Comments are **local drafts** — never pushed until you submit them in tuicr.
- **Re-running duplicates comments.** sniffr appends; it doesn't dedup against a
  previous pass (tuicr has no CLI to remove drafts). Prune in the TUI — `dd` drops
  one, `:clearc` clears all — before re-sniffing the same PR.

## License

MIT — see [LICENSE](LICENSE).
